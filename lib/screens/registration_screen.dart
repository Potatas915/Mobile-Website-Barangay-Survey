import 'package:flutter/material.dart';
import '../models.dart';
import '../services/db.dart';
import '../services/resident_service.dart';
import '../theme.dart';
import '../widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _State();
}

class _State extends State<RegistrationScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _membership = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _service = ResidentService();
  bool _busy = false;
  ResultData? _result;
  Session? _session;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _mobile, _membership, _address, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    final required = [_first, _last, _email, _mobile, _membership, _address, _password];
    if (required.any((c) => c.text.trim().isEmpty)) {
      setState(() => _result = const ResultData(false, 'Missing Information'));
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _result = const ResultData(false, 'Password does not match'));
      return;
    }
    setState(() => _busy = true);
    try {
      _session = await _service.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        mobile: _mobile.text.trim(),
        membershipType: _membership.text.trim(),
        address: _address.text.trim(),
        password: _password.text,
      );
      _result = const ResultData(true, 'Registered Successfully');
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
              padding: const EdgeInsets.only(top: 45, bottom: 25),
              child: Col350(
                child: Column(children: [
                  LabeledField(label: 'First Name', controller: _first),
                  LabeledField(label: 'Last Name', controller: _last),
                  LabeledField(
                      label: 'Email',
                      controller: _email,
                      keyboard: TextInputType.emailAddress),
                  LabeledField(
                      label: 'Mobile Number',
                      controller: _mobile,
                      keyboard: TextInputType.phone),
                  LabeledField(label: 'Membership Type', controller: _membership),
                  LabeledField(label: 'Address', controller: _address),
                  LabeledField(label: 'Password', controller: _password, obscure: true),
                  LabeledField(
                      label: 'Confirm Password',
                      controller: _confirm,
                      obscure: true),
                  const Gap(25),
                  AppButton(
                    label: _busy ? 'Please wait...' : 'Register',
                    onPressed: _busy ? null : _register,
                  ),
                  const Gap(8),
                  AppButton(
                    label: 'Back to Login',
                    onPressed: () => Navigator.of(context).pop(),
                    background: C.page,
                    foreground: C.green,
                  ),
                ]),
              ),
            ),
            if (_result != null) ResultOverlay(data: _result!, onOk: _ok),
          ]),
        ),
      );
}
