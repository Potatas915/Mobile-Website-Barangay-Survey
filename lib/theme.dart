import 'package:flutter/material.dart';

/// Colors copied from the App Inventor Designer.
class C {
  static const green = Color(0xFF1FAE82);
  static const deepGreen = Color(0xFF147A63);
  static const ink = Color(0xFF16241F);
  static const muted = Color(0xFF6B8079);
  static const field = Color(0xFFF3FAF7);
  static const page = Color(0xFFF5F8F7);
  static const mint = Color(0xFFE3F5EE);
  static const danger = Color(0xFFE0517D);
  static const white = Color(0xFFFFFFFF);
  static const defaultButton = Color(0xFFE0E0E0);
}

class Assets {
  static const _d = 'assets/images/';
  static const user = '${_d}user.png';
  static const ok = '${_d}check_circle_100dp_1FAE82_FILL1_wght400_GRAD0_opsz48.png';
  static const fail = '${_d}cancel_100dp_E0517D_FILL1_wght400_GRAD0_opsz48.png';
  static const person = '${_d}person_100dp_1FAE82_FILL1_wght400_GRAD0_opsz48.png';
  static const edit = '${_d}edit_100dp_1FAE82_FILL1_wght400_GRAD0_opsz48.png';
  static const logout = '${_d}logout_100dp_1FAE82_FILL1_wght400_GRAD0_opsz48.png';
  static const survey = '${_d}survey_100dp_1FAE82_FILL1_wght400_GRAD0_opsz48.png';
  static const mail = '${_d}mail_24dp_1FAE82_FILL1_wght400_GRAD0_opsz24.png';
  static const call = '${_d}call_40dp_1FAE82_FILL1_wght400_GRAD0_opsz40.png';
  static const location = '${_d}location_on_40dp_1FAE82_FILL1_wght400_GRAD0_opsz40.png';
  static const idCard = '${_d}id_card_100dp_1FAE82_FILL0_wght400_GRAD0_opsz48.png';
  static const calendar = '${_d}calendar_month_40dp_1FAE82_FILL1_wght400_GRAD0_opsz40.png';
}

TextStyle ts(double size, {bool bold = false, Color color = C.ink}) => TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

ThemeData buildTheme() => ThemeData(
      useMaterial3: false,
      colorScheme: ColorScheme.fromSeed(seedColor: C.green, primary: C.green),
      scaffoldBackgroundColor: C.white,
      appBarTheme: const AppBarTheme(backgroundColor: C.green),
    );
