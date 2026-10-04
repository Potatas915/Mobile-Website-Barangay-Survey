import 'package:flutter/material.dart';
import 'screens/resident_home_screen.dart';
import 'screens/resident_login_screen.dart';
import 'models.dart';
import 'theme.dart';

/// Content column used on every screen (the Designer used 350-wide columns).
class Col350 extends StatelessWidget {
  const Col350({super.key, required this.child, this.width = 350});
  final Widget child;
  final double width;
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width), child: child));
}

class Gap extends StatelessWidget {
  const Gap(this.h, {super.key});
  final double h;
  @override
  Widget build(BuildContext context) => SizedBox(height: h);
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboard,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(25),
          Text(label, style: ts(16, bold: true)),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: ts(14),
            decoration: const InputDecoration(
              filled: true,
              fillColor: C.field,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ],
      );
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = C.green,
    this.foreground = C.white,
    this.width = 300,
    this.size = 20,
    this.radius = 4,
    this.height,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color background, foreground;
  final double width, size, radius;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withAlpha(140),
            elevation: 1,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius)),
          ),
          child: Text(label, style: ts(size, bold: true, color: foreground)),
        ),
      );
}

class ResultData {
  const ResultData(this.success, this.message);
  final bool success;
  final String message;
}

/// The white "Success / Failed" full-screen card (Arrangement_Overlay).
class ResultOverlay extends StatelessWidget {
  const ResultOverlay({super.key, required this.data, required this.onOk});
  final ResultData data;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: C.white,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(data.success ? Assets.ok : Assets.fail,
                  width: 50, height: 50),
              const Gap(5),
              Text(data.success ? 'Success' : 'Failed',
                  style: ts(24,
                      bold: true,
                      color: data.success ? C.deepGreen : C.danger)),
              const Gap(12),
              Text(data.message,
                  textAlign: TextAlign.center, style: ts(20, bold: true)),
              const Gap(25),
              AppButton(label: 'Ok', onPressed: onOk, width: 100, size: 14, radius: 15),
            ],
          ),
        ),
      );
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String asset, title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: C.white,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 75,
            child: Row(children: [
              Image.asset(asset, width: 50, height: 50),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ts(16, bold: true)),
                    Text(subtitle, style: ts(14)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}

class InfoRow extends StatelessWidget {
  const InfoRow(
      {super.key, required this.asset, required this.label, required this.value});
  final String asset, label, value;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 75,
        child: Row(children: [
          SizedBox(
              width: 50,
              height: 25,
              child: Image.asset(asset, fit: BoxFit.contain)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ts(16, bold: true)),
                Text(value, style: ts(14)),
              ],
            ),
          ),
        ]),
      );
}

class ActiveBadge extends StatelessWidget {
  const ActiveBadge({super.key, required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        color: C.green,
        alignment: Alignment.center,
        child: Text('Active', style: ts(20, bold: true, color: C.white)),
      );
}

class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.size});
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(label, style: ts(size, bold: true, color: C.green)),
      );
}

void goHome(BuildContext context, Session session) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      settings: const RouteSettings(name: 'home'),
      builder: (_) => ResidentHomeScreen(session: session),
    ),
    (route) => false,
  );
}

void goLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const ResidentLoginScreen()),
    (route) => false,
  );
}
