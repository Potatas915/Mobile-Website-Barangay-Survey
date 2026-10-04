import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db.dart';
import '../services/resident_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'registration_screen.dart';

class ResidentLoginScreen extends StatefulWidget {
  const ResidentLoginScreen({super.key});
  @override
  State<ResidentLoginScreen> createState() => _State();
}

class _State extends State<ResidentLoginScreen> {
  final _number = TextEditingController();
  final _password = TextEditingController();
  final _service = ResidentService();
  bool _busy = false;
  ResultData? _result;
  Session? _session;

  @override
  void dispose() {
    _number.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await _service.login(_number.text.trim(), _password.text);
      switch (r.status) {
        case LoginStatus.ok:
          final n = r.resident!.number;
          _session = Session(
              id: r.resident!.id, number: n.isEmpty ? _number.text.trim() : n);
          _result = const ResultData(true, 'Login Successfully');
        case LoginStatus.notFound:
          _result = const ResultData(false, 'User is not found');
        case LoginStatus.deactivated:
          _result = const ResultData(false,
              'This account has been deactivated. Please contact the barangay office.');
        case LoginStatus.wrongPassword:
          _result = const ResultData(false, 'Password is Incorrect');
      }
    } on DbException catch (e) {
      _result = ResultData(false, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _ok() {
    final s = _session;
    if (_result?.success == true && s != null) {
      goHome(context, s);
    } else {
      setState(() => _result = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Stack(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Col350(
                child: Column(children: [
                  Image.asset(Assets.user, width: 90, height: 90),
                  const Gap(10),
                  Text('Resident Portal',
                      style: ts(20, bold: true, color: C.deepGreen)),
                  Text('Log In to your account',
                      textAlign: TextAlign.center, style: ts(30, bold: true)),
                  const Gap(8),
                  Text(
                    'Use your resident number to take surveys and stay updated on community programs. Your default password is the same as your resident number.',
                    textAlign: TextAlign.center,
                    style: ts(16, color: C.muted),
                  ),
                  const Gap(20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Resident Number',
                        style: ts(20, bold: true, color: C.muted)),
                  ),
                  _box(_number, 'Resident Number', false),
                  const Gap(12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Password',
                        style: ts(20, bold: true, color: C.muted)),
                  ),
                  _box(_password, 'Password', true),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _busy ? 'Please wait...' : 'Log In',
                      onPressed: _busy ? null : _login,
                      width: double.infinity,
                      radius: 15,
                    ),
                  ),
                  const Gap(25),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account?", style: ts(16)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegistrationScreen())),
                      child: Text('Sign-Up!',
                          style: ts(16, color: C.deepGreen)),
                    ),
                  ]),
                ]),
              ),
            ),
            if (_result != null) ResultOverlay(data: _result!, onOk: _ok),
          ]),
        ),
      );

  Widget _box(TextEditingController c, String hint, bool obscure) => TextField(
        controller: c,
        obscureText: obscure,
        style: ts(14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: C.field,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
      );
}
