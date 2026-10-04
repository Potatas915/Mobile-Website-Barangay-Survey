/// One Firebase Realtime Database for the whole app (same hierarchy as the
/// web portal export: residents, lookup, counters, surveys, responses).
class AppConfig {
  static const String databaseUrl =
      'https://web-to-mobile-2c582-default-rtdb.firebaseio.com';

  /// Leave empty while the database rules allow public read/write (as they
  /// did for the App Inventor app). Otherwise paste a database secret/token.
  static const String authToken = '';

  static const Duration timeout = Duration(seconds: 20);
}
