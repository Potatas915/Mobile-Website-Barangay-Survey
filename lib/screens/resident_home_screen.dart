import 'package:flutter/material.dart';
import '../models.dart';
import '../services/resident_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'edit_profile_screen.dart';
import 'member_profile_screen.dart';
import 'survey_list_screen.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key, required this.session});
  final Session session;
  @override
  State<ResidentHomeScreen> createState() => _State();
}

class _State extends State<ResidentHomeScreen> {
  final _service = ResidentService();
  String _name = 'Resident Name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _service.load(widget.session.id);
      if (mounted && r != null) setState(() => _name = r.fullName);
    } catch (_) {
      // keep the placeholder name if the database is unreachable
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Scaffold(
      backgroundColor: C.page,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Col350(
            child: Column(children: [
              const Gap(12),
              Container(
                width: double.infinity,
                color: C.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back!', style: ts(20, bold: true)),
                    const Gap(12),
                    Text(_name, style: ts(25, bold: true)),
                    Text('Resident ID: ${s.number}', style: ts(16, bold: true)),
                  ],
                ),
              ),
              const Gap(25),
              const Align(
                  alignment: Alignment.center, child: ActiveBadge(width: 100)),
              const Gap(25),
              MenuTile(
                asset: Assets.person,
                title: 'My Profile',
                subtitle: 'View your information',
                onTap: () => _open(MemberProfileScreen(session: s)),
              ),
              const Gap(12),
              MenuTile(
                asset: Assets.edit,
                title: 'Edit Profile',
                subtitle: 'Update your details',
                onTap: () => _open(EditProfileScreen(session: s)),
              ),
              const Gap(12),
              MenuTile(
                asset: Assets.survey,
                title: 'Survey',
                subtitle: 'Take available surveys',
                onTap: () => _open(SurveyListScreen(session: s)),
              ),
              const Gap(12),
              MenuTile(
                asset: Assets.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                onTap: () => goLogin(context),
              ),
              const Gap(100),
            ]),
          ),
        ),
      ),
    );
  }
}
