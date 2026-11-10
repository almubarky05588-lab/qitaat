import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان التصميم كما هي في ملف فيجما
class AppColors {
  static const bg = Color(0xFFF6EEE3);
  static const pri = Color(0xFFC2583B);
  static const priD = Color(0xFF8C3A22);
  static const priL = Color(0xFFCB6040);
  static const ink = Color(0xFF2A2017);
  static const ink2 = Color(0xFF4A3F35);
  static const mute = Color(0xFF8C7F72);
  static const ph = Color(0xFFA99C8E);
  static const teal = Color(0xFF1F7A6D);
  static const tealBg = Color(0xFFE1EEE9);
  static const sage = Color(0xFFE4E9DC);
  static const sageB = Color(0xFFB9CFC0);
  static const beige = Color(0xFFEDE3D3);
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0xFFEFE5D8);
  static const pink = Color(0xFFF8E3D9);
  static const pinkB = Color(0xFFF0CDBD);
  static const chipB = Color(0xFFE6D8CC);
  static const tan = Color(0xFFDCCAB0);
  static const sec = Color(0xFFF2E9DD);
  static const unread = Color(0xFFF4E6D9);
  static const red = Color(0xFFD64545);
  static const amberBg = Color(0xFFFFF1D6);
  static const amber = Color(0xFFB07A12);
  static const greyBg = Color(0xFFEFE7DC);
  static const segBg = Color(0xFFEDE3D5);
  static const pillBg = Color(0xFFEFE5D8);
  static const outline2 = Color(0xFF8A7868);
  static const star = Color(0xFFF2B01E);
  static const thumbIcon = Color(0xFFA89A88);
  static const progressDone = Color(0xFF8DB5A5);
  static const progressTodo = Color(0xFFEFE6DA);
  static const uploadBg = Color(0xFFF1E6D8);
  static const toggleOff = Color(0xFFDCCFBF);
  static const fitBg = Color(0xFFEDE4D6);
  static const fitB = Color(0xFFE0D2BF);
  static const lockedB = Color(0xFFE2D6C5);

  static const gradient = LinearGradient(
    colors: [priD, priL],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

const w4 = FontWeight.w400;
const w5 = FontWeight.w500;
const w6 = FontWeight.w600;
const w7 = FontWeight.w700;

TextStyle tx(double size, {FontWeight w = w4, Color c = AppColors.ink, double h = 1.5}) =>
    GoogleFonts.readexPro(fontSize: size, fontWeight: w, color: c, height: h);

String sar(num v) => '$v ر.س';

/// نص أرقام/لاتيني يُعرض من اليسار لليمين داخل واجهة عربية
String ltr(String s) => '\u200E$s';

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.pri,
      primary: AppColors.pri,
      surface: AppColors.bg,
    ),
    textTheme: GoogleFonts.readexProTextTheme(),
    splashColor: AppColors.pri.withOpacity(0.08),
    highlightColor: Colors.transparent,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
  );
}
