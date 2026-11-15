import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// الوضع الليلي: يتغيّر من الإعدادات ويُعاد بناء التطبيق كامل بالألوان الجديدة
class AppTheme {
  static bool dark = false;
  static final mode = ValueNotifier<bool>(false);
  static void set(bool v) {
    dark = v;
    mode.value = v;
  }
}

/// لون له قيمتان (نهاري / ليلي) — يبقى const فيشتغل في كل مكان بدون تغيير الشاشات
class DynColor extends Color {
  final int light, night;
  const DynColor(this.light, this.night) : super(light);
  Color get _c => Color(AppTheme.dark ? night : light);
  @override
  double get a => _c.a;
  @override
  double get r => _c.r;
  @override
  double get g => _c.g;
  @override
  double get b => _c.b;
  // ignore: deprecated_member_use
  @override
  int get value => _c.toARGB32();
  @override
  int toARGB32() => _c.toARGB32();
}

/// ألوان التصميم كما هي في ملف فيجما
class AppColors {
  /// لون المحتوى فوق الخلفيات الملوّنة (أزرار، بنرات، فقاعة المحادثة) — أبيض دائماً
  static const onPri = Color(0xFFFFFFFF);
  static const redBg = DynColor(0xFFFBE5E2, 0xFF3A1F1C);
  static const outline = DynColor(0xFFCDBFAF, 0xFF5A4E43);
  static const bg = DynColor(0xFFF6EEE3, 0xFF1A1511);
  static const pri = DynColor(0xFFC2583B, 0xFFD8694B);
  static const priD = DynColor(0xFF8C3A22, 0xFF8C3A22);
  static const priL = DynColor(0xFFCB6040, 0xFFCB6040);
  static const ink = DynColor(0xFF2A2017, 0xFFF2E9DD);
  static const ink2 = DynColor(0xFF4A3F35, 0xFFD4C7B8);
  static const mute = DynColor(0xFF8C7F72, 0xFFA0937F);
  static const ph = DynColor(0xFFA99C8E, 0xFF7A6E62);
  static const teal = DynColor(0xFF1F7A6D, 0xFF4DB3A2);
  static const tealBg = DynColor(0xFFE1EEE9, 0xFF1D3330);
  static const sage = DynColor(0xFFE4E9DC, 0xFF1F2D26);
  static const sageB = DynColor(0xFFB9CFC0, 0xFF35503F);
  static const beige = DynColor(0xFFEDE3D3, 0xFF2B241E);
  static const white = DynColor(0xFFFFFFFF, 0xFF26201B);
  static const line = DynColor(0xFFEFE5D8, 0xFF342C25);
  static const pink = DynColor(0xFFF8E3D9, 0xFF3A261F);
  static const pinkB = DynColor(0xFFF0CDBD, 0xFF5A3A2C);
  static const chipB = DynColor(0xFFE6D8CC, 0xFF3F362E);
  static const tan = DynColor(0xFFDCCAB0, 0xFF4A3F33);
  static const sec = DynColor(0xFFF2E9DD, 0xFF211B16);
  static const unread = DynColor(0xFFF4E6D9, 0xFF2E241D);
  static const red = DynColor(0xFFD64545, 0xFFE86A6A);
  static const amberBg = DynColor(0xFFFFF1D6, 0xFF3A2F18);
  static const amber = DynColor(0xFFB07A12, 0xFFE0B14A);
  static const greyBg = DynColor(0xFFEFE7DC, 0xFF2E2822);
  static const segBg = DynColor(0xFFEDE3D5, 0xFF2B241E);
  static const pillBg = DynColor(0xFFEFE5D8, 0xFF2B241E);
  static const outline2 = DynColor(0xFF8A7868, 0xFFA8998A);
  static const star = DynColor(0xFFF2B01E, 0xFFF2B01E);
  static const thumbIcon = DynColor(0xFFA89A88, 0xFF6E6256);
  static const progressDone = DynColor(0xFF8DB5A5, 0xFF4F8070);
  static const progressTodo = DynColor(0xFFEFE6DA, 0xFF3A3129);
  static const uploadBg = DynColor(0xFFF1E6D8, 0xFF2B241E);
  static const toggleOff = DynColor(0xFFDCCFBF, 0xFF4A4036);
  static const fitBg = DynColor(0xFFEDE4D6, 0xFF2B241E);
  static const fitB = DynColor(0xFFE0D2BF, 0xFF433A31);
  static const lockedB = DynColor(0xFFE2D6C5, 0xFF433A31);

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
  final dark = AppTheme.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFC2583B),
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: Color(AppColors.pri.toARGB32()),
      surface: Color(AppColors.white.toARGB32()),
    ),
    textTheme: GoogleFonts.readexProTextTheme(dark ? ThemeData.dark().textTheme : null),
    splashColor: AppColors.pri.withOpacity(0.08),
    highlightColor: Colors.transparent,
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent),
  );
}
