import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../services/db.dart';
import '../services/resident_service.dart';
import '../theme.dart';
import '../widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.session});
  final Session session;
  @override
  State<EditProfileScreen> createState() => _State();
}

class _State extends State<EditProfileScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _membership = TextEditingController();
  final _service = ResidentService();
  String _photoUrl = '';
  File? _picked;
  bool _busy = false;
  ResultData? _result;

  @override
  void initState() {
    super.initState();
    _service.load(widget.session.id).then((r) {
      if (r == null || !mounted) return;
      _first.text = r.s('first_name');
      _last.text = r.s('last_name');
      _email.text = r.s('email');
      _mobile.text = r.s('contact_number');
      _address.text = r.s('address');
      _membership.text = r.s('membership_type');
      final url = r.s('profile_url').isNotEmpty ? r.s('profile_url') : r.s('photo');
      setState(() => _photoUrl = url);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _mobile, _address, _membership]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null && mounted) setState(() => _picked = File(x.path));
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.updateProfile(widget.session.id, {
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'email': _email.text.trim(),
        'contact_number': _mobile.text.trim(),
        'address': _address.text.trim(),
        'membership_type': _membership.text.trim(),
      });
      _result = const ResultData(true, 'Edit Successfully');
    } on DbException catch (e) {
      _result = ResultData(false, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _ok() {
    if (_result?.success == true) {
      Navigator.of(context).popUntil((r) => r.settings.name == 'home' || r.isFirst);
    } else {
      setState(() => _result = null);
    }
  }

  Widget _avatar() {
    const size = 100.0;
    if (_picked != null) {
      return Image.file(_picked!, width: size, height: size, fit: BoxFit.cover);
    }
    if (_photoUrl.startsWith('http')) {
      return Image.network(_photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(Assets.user, width: size, height: size));
    }
    return Image.asset(Assets.user, width: size, height: size);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Stack(children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 45, bottom: 25),
              child: Col350(
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Column(children: [
                      Text('Profile Photo (Optional)', style: ts(14, bold: true)),
                      const Gap(12),
                      _avatar(),
                    ]),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Change Photo',
                      onPressed: _pickPhoto,
                      width: 140,
                      size: 14,
                      radius: 15,
                    ),
                  ]),
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
                  LabeledField(label: 'Address', controller: _address),
                  LabeledField(label: 'Membership Type', controller: _membership),
                  const Gap(25),
                  AppButton(
                    label: _busy ? 'Please wait...' : 'Edit Profile',
                    onPressed: _busy ? null : _save,
                  ),
                  const Gap(8),
                  AppButton(
                    label: 'Cancel',
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
