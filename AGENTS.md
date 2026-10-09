# AGENTS.md

Flutter port of an App Inventor barangay resident portal. Small, single-package
app (~10 screens) talking to one shared Firebase Realtime Database over REST.

## Commands

```bash
flutter pub get
flutter analyze          # the only real verification gate; run before reporting done
flutter run
```

There is no lint/format script, no CI, no codegen, and no pre-commit hook.
`analysis_options.yaml` is just `package:flutter_lints/flutter.yaml`.

**`test/widget_test.dart` is a broken `flutter create` template** — it pumps
`MyApp`, which does not exist (the root widget is `ResidentApp` in
`lib/main.dart`), and asserts on a counter that this app never had. It fails to
compile, so `flutter test` is currently meaningless. Don't treat its failure as
a regression; delete or rewrite it before relying on `flutter test`.

**Flutter is not installed in this container.** A standalone Dart SDK cannot
resolve `package:flutter`, so `dart analyze` alone floods the output with
`UNDEFINED_CLASS` / `URI_DOES_NOT_EXIST` for every widget reference. Those are
false positives. If you need partial checking without Flutter, filter the
`--format=machine` output for codes that *don't* stem from missing packages
(`URI_DOES_NOT_EXIST`, `UNDEFINED_*`, `CREATION_WITH_NON_TYPE`,
`EXTENDS_NON_CLASS`, `OVERRIDE_ON_NON_OVERRIDING_MEMBER`, `NON_TYPE_AS_TYPE_ARGUMENT`).
Anything left is real. `theme.dart`'s `CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE`
is also just `Color` being unresolved.

## Database — the thing you will get wrong

Single shared RTDB at `web-to-mobile-2c582` (`lib/config.dart`), same hierarchy
as the web portal. Read/write over REST **without an auth token**, so the rules
must allow `".read": true, ".write": true`. Every request fails with
"Permission denied" if not — set `AppConfig.authToken` to fix.

| Path | Purpose |
| --- | --- |
| `residents/<id>` | the resident record; `id` is a numeric string, not the resident number |
| `lookup/resident_number/<2026-000N>` | resident number -> `id` |
| `counters/residents` | next id, i.e. the number suffix |
| `surveys/<id>` | nested questions/choices |
| `responses/<id>` | submitted answers, with `resident_id` |

Two traps that produce silent bugs:

* **`residents` keys are ids, not numbers.** Login takes `2026-0001` and must
  resolve it through `lookup/` first (`ResidentService.idForNumber`). Resident
  number and DB id are different values; never assume they match.
* **Firebase returns keys `1..n` as a JSON array with `null` in slot 0.** Use
  `entriesOf()` from `lib/services/db.dart` to iterate, never raw `for-in` over
  a map/list from the DB. It normalizes arrays vs objects and sorts numerically.

## Writing to the database

Registration must stay a **single atomic `patch`** covering `residents/<id>`,
`lookup/…`, and `counters/residents`. Don't split it into multiple writes — a
partial failure leaves the counter and the record out of sync, and the number
gets burned.

`ResidentService.peekNextNumber()` is **advisory only**. It duplicates the
counter logic in `register()` purely to preview a number on the sign-up form.
If you change the allocation logic in `register()`, you must mirror it in
`peekNextNumber()`, or the preview silently lies. It writes nothing, so two
simultaneous registrants can both see the same preview and only one gets it.

Passwords are compared as **plain text** (`password`, falling back to
`password_hash`); there is no hashing. Residents still holding a bcrypt hash
(`$2…`) cannot log in until reset.

## Repo conventions

* Colors are never written inline. Use the `C` palette in `lib/theme.dart`
  (`C.green`, `C.muted`, `C.page`, …) and the `ts(size, bold:, color:)` helper.
  The palette is copied from the App Inventor Designer; keep it in sync rather
  than substituting Material defaults.
* Shared UI lives in `lib/widgets.dart` (`Col350`, `AppButton`, `ResultOverlay`,
  `InfoRow`, `Gap`, `BackLink`, `goHome`, `goLogin`). Icon paths are the `Assets`
  constants in `lib/theme.dart`. Prefer extending these over new one-off
  widgets in a screen.
* Screens are plain `StatefulWidget`s passing an explicit `Session`. Navigation
  is `MaterialPageRoute` + `pushAndRemoveUntil` in `goHome`/`goLogin`. Only
  `goHome` sets `RouteSettings(name: 'home')`, and `edit_profile_screen.dart:83`
  `popUntil`s on that name — renaming it silently breaks post-save back-navigation.
* One screen per file in `lib/screens/`, services in `lib/services/`, Firebase
  access strictly through `Db.instance`. No repository/DAO layer, no DI.
* Async loading follows one pattern: a `Future` in `initState`, `setState`
  guarded by `if (mounted) return`, `DbException` caught and surfaced through
  `ResultData`/`ResultOverlay`. Use an explicit `_loading` flag, not a
  sentinel string, or empty states render as permanent "Loading…".

## Line endings (will pollute your diff)

The working tree is **CRLF**, but `HEAD` is **LF**. A plain `git diff` shows
every file as fully rewritten. Use `git diff --ignore-cr-at-eol` to see real
changes, and write files with CRLF to match the tree. Do not "fix" this by
normalizing line endings repo-wide.

`git status` is already dirty across `android/`, `ios/`, and generated files for
the same reason — that state predates your work. Don't revert it.

## Known incomplete / intentional deviations

* **Android release builds cannot reach Firebase.** The `INTERNET` permission
  is in `android/app/src/debug/AndroidManifest.xml` (added automatically by
  Flutter for debug) but **missing from `android/app/src/main/AndroidManifest.xml`**.
  Add it above `<application>` before shipping.
* **`NSPhotoLibraryUsageDescription` is missing** from `ios/Runner/Info.plist`,
  so "Change Photo" breaks on iOS.
* "Change Photo" only previews the picked image; it never uploads. Same as the
  App Inventor original. `photo` is therefore usually empty.
* The README says the project was never compiled or run where it was written.
  Treat any claim that the app builds as unverified until `flutter analyze`
  passes.
