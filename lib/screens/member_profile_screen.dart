import 'package:flutter/material.dart';
import '../models.dart';
import '../services/resident_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'edit_profile_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key, required this.session});
  final Session session;
  @override
  State<MemberProfileScreen> createState() => _State();
}

class _State extends State<MemberProfileScreen> {
  final _service = ResidentService();
  Resident? _r;

  @override
  void initState() {
    super.initState();
    _service.load(widget.session.id).then((r) {
      if (mounted) setState(() => _r = r);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    String v(String k) => r?.s(k) ?? '';
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Col350(
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 8),
                  child: AppButton(
                    label: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    width: 80,
                    size: 14,
                    radius: 15,
                    height: 35,
                  ),
                ),
              ),
              const Gap(8),
              Image.asset(Assets.user, width: 90, height: 90),
              Text(r == null ? 'Member name' : r.fullName, style: ts(20, bold: true)),
              Text(widget.session.number, style: ts(20, bold: true)),
              const Gap(4),
              const ActiveBadge(width: 75),
              const Gap(25),
              Container(
                width: 300,
                color: C.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(children: [
                  InfoRow(asset: Assets.mail, label: 'Email', value: v('email')),
                  InfoRow(asset: Assets.call, label: 'Mobile Number', value: v('contact_number')),
                  InfoRow(asset: Assets.location, label: 'Address', value: v('address')),
                  InfoRow(asset: Assets.idCard, label: 'Membership Type', value: v('membership_type')),
                  InfoRow(
                      asset: Assets.calendar,
                      label: 'Registration Date',
                      value: Fmt.pretty(
                          v('registration_date').isNotEmpty ? v('registration_date') : v('created_at'))),
                ]),
              ),
              const Gap(25),
              AppButton(
                label: 'Edit Profile',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditProfileScreen(session: widget.session))),
              ),
              const Gap(8),
              AppButton(
                label: 'Logout',
                onPressed: () => goLogin(context),
                background: C.defaultButton,
                foreground: Colors.black,
              ),
              const Gap(25),
            ]),
          ),
        ),
      ),
    );
  }
}
