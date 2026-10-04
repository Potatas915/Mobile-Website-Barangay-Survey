import 'package:flutter/material.dart';
import 'screens/resident_login_screen.dart';
import 'theme.dart';

void main() => runApp(const ResidentApp());

class ResidentApp extends StatelessWidget {
  const ResidentApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Resident Portal',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const ResidentLoginScreen(),
      );
}
