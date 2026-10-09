import '../models.dart';
import 'db.dart';

enum LoginStatus { ok, notFound, deactivated, wrongPassword }

class LoginResult {
  const LoginResult(this.status, [this.resident]);
  final LoginStatus status;
  final Resident? resident;
}

final _safeKey = RegExp(r'^[A-Za-z0-9_-]+$');

class ResidentService {
  final Db _db = Db.instance;

  /// resident number (2026-0001) -> database id ("1") via lookup/resident_number
  Future<String?> idForNumber(String number) async {
    final n = number.trim();
    if (!_safeKey.hasMatch(n)) return null;
    final v = await _db.get('lookup/resident_number/$n');
    return v?.toString();
  }

  Future<Resident?> load(String id) async {
    final v = await _db.get('residents/$id');
    return v is Map ? Resident(id, Map<String, dynamic>.from(v)) : null;
  }

  /// Passwords are stored as plain text, so login is a direct comparison.
  bool _verify(String typed, String stored) =>
      stored.isNotEmpty && typed == stored;

  Future<LoginResult> login(String number, String password) async {
    final id = await idForNumber(number);
    if (id == null) return const LoginResult(LoginStatus.notFound);
    final r = await load(id);
    if (r == null) return const LoginResult(LoginStatus.notFound);
    if (r.s('status') == 'archived') {
      return const LoginResult(LoginStatus.deactivated);
    }
    final stored =
        r.s('password').isNotEmpty ? r.s('password') : r.s('password_hash');
    final ok = _verify(password, stored);
    return ok
        ? LoginResult(LoginStatus.ok, r)
        : const LoginResult(LoginStatus.wrongPassword);
  }

  /// Advisory only: the number the next registrant would most likely get.
  ///
  /// Mirrors the counter logic in [register] but never writes, so it can never
  /// reserve a number. Two people registering at the same moment may both see
  /// this value and only one will actually get it. [register] skips any number
  /// already present in residents/ or lookup/, so the real number assigned at
  /// submit can differ from this preview.
  Future<String?> peekNextNumber() async {
    var next = asInt(await _db.get('counters/residents')) + 1;
    while (await _db.get('residents/$next', shallow: true) != null) {
      next++;
    }
    var number = _formatNumber(next);
    while (await _db.get('lookup/resident_number/$number') != null) {
      next++;
      number = _formatNumber(next);
    }
    return number;
  }

  String _formatNumber(int n) => '2026-${n.toString().padLeft(4, '0')}';

  /// Creates residents/<n>, lookup/resident_number/<number> and bumps
  /// counters/residents in a single atomic write.
  Future<Session> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String membershipType,
    required String address,
    required String password,
  }) async {
    var next = asInt(await _db.get('counters/residents')) + 1;
    while (await _db.get('residents/$next', shallow: true) != null) {
      next++;
    }
    var number = _formatNumber(next);
    while (await _db.get('lookup/resident_number/$number') != null) {
      next++;
      number = _formatNumber(next);
    }
    final now = Fmt.dateTime(DateTime.now());
    await _db.patch('', {
      'residents/$next': {
        'address': address,
        'age': '',
        'birthday': '',
        'civil_status': '',
        'contact_number': mobile,
        'created_at': now,
        'email': email,
        'employer': '',
        'employer_address': '',
        'extension_name': '',
        'father_name': '',
        'first_name': firstName,
        'gender': '',
        'is_first_login': 0,
        'last_name': lastName,
        'membership_type': membershipType,
        'middle_name': '',
        'mobile_pin': number,
        'mother_name': '',
        'occupation': '',
        'password': password,
        'photo': '',
        'reference1_name': '',
        'reference1_signature': '',
        'reference2_name': '',
        'reference2_signature': '',
        'resident_number': number,
        'spouse_employer': '',
        'spouse_name': '',
        'spouse_occupation': '',
        'status': 'active',
        'updated_at': now,
      },
      'lookup/resident_number/$number': '$next',
      'counters/residents': next,
    });
    return Session(id: '$next', number: number);
  }

  Future<void> updateProfile(String id, Map<String, String> fields) =>
      _db.patch('residents/$id', {
        ...fields,
        'updated_at': Fmt.dateTime(DateTime.now()),
      });
}
