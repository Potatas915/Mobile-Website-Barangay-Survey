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

  Widget _avatar(Resident? r) {
    const size = 90.0;
    final url = r == null ? '' : (r.s('profile_url').isNotEmpty ? r.s('profile_url') : r.s('photo'));
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(Assets.user, width: size, height: size),
      );
    }
    return Image.asset(Assets.user, width: size, height: size);
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
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
                    height: 40,
                  ),
                ),
              ),
              const Gap(8),
              _avatar(r),
              Text(r == null ? 'Member name' : r.fullName,
                  style: ts(20, bold: true)),
              Text(widget.session.number, style: ts(20, bold: true)),
              const Gap(4),
              ActiveBadge(width: 75, label: r?.s('status')),
              const Gap(15),
              if (r == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text('Loading...', style: ts(16, bold: true)),
                )
              else
                _Details(resident: r),
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

/// Full resident record, grouped into sections. Fields that are empty or
/// absent in the database are skipped so the resident does not see rows of
/// "Not provided". Returns null when a section has nothing to show.
class _Details extends StatelessWidget {
  const _Details({required this.resident});
  final Resident resident;

  @override
  Widget build(BuildContext context) => Column(children: [
        _section('Personal', [
          ['first_name', 'First Name', Assets.person],
          ['middle_name', 'Middle Name', Assets.person],
          ['last_name', 'Last Name', Assets.person],
          ['extension_name', 'Extension Name', Assets.person],
          ['birthday', 'Birthday', Assets.calendar],
          ['age', 'Age', Assets.calendar],
          ['civil_status', 'Civil Status', Assets.idCard],
          ['gender', 'Gender', Assets.idCard],
        ]),
        _section('Family', [
          ['father_name', "Father's Name", Assets.person],
          ['mother_name', "Mother's Name", Assets.person],
          ['spouse_name', 'Spouse Name', Assets.person],
          ['spouse_occupation', 'Spouse Occupation', Assets.idCard],
          ['spouse_employer', 'Spouse Employer', Assets.idCard],
        ]),
        _section('Employment', [
          ['occupation', 'Occupation', Assets.idCard],
          ['employer', 'Employer', Assets.idCard],
          ['employer_address', 'Employer Address', Assets.location],
        ]),
        _section('Contact & Address', [
          ['email', 'Email', Assets.mail],
          ['contact_number', 'Mobile Number', Assets.call],
          ['address', 'Address', Assets.location],
        ]),
        _section('Membership', [
          ['resident_number', 'Resident Number', Assets.idCard],
          ['membership_type', 'Membership Type', Assets.idCard],
          ['mobile_pin', 'Mobile PIN', Assets.idCard],
          ['registration_date', 'Registration Date', Assets.calendar],
          ['created_at', 'Created At', Assets.calendar],
          ['updated_at', 'Last Updated', Assets.calendar],
        ]),
        _section('References', [
          ['reference1_name', 'Reference 1', Assets.person],
          ['reference2_name', 'Reference 2', Assets.person],
          ['reference1_signature', 'Reference 1 Signature', Assets.edit],
          ['reference2_signature', 'Reference 2 Signature', Assets.edit],
        ]),
      ]);

  Widget _section(String title, List<List<String>> fields) {
    final rows = <Widget>[];
    for (final f in fields) {
      final key = f[0], label = f[1], asset = f[2];
      final value = resident.s(key).trim();
      if (value.isEmpty) continue;
      rows.add(InfoRowFlexible(asset: asset, label: label, value: value));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        Container(
          color: C.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: rows),
        ),
        const Gap(8),
      ],
    );
  }
}