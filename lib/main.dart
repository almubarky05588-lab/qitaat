import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'data/mock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    AppTheme.set((await SharedPreferences.getInstance()).getBool('dark') ?? false);
  } catch (_) {}
  await initBackend();
  // القوائم من لوحة الإدارة (بحد أقصى 4 ثواني، وإلا نكمل بالقيم الاحتياطية)
  await Mock.load().timeout(const Duration(seconds: 4), onTimeout: () {});
  runApp(const ProviderScope(child: QitaatApp()));
}

class QitaatApp extends StatelessWidget {
  const QitaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تبديل الوضع الليلي يعيد بناء التطبيق بالألوان الجديدة (والصفحة الحالية تبقى)
    return ValueListenableBuilder<bool>(valueListenable: AppTheme.mode, builder: (context, dark, _) => _app(dark));
  }

  Widget _app(bool dark) {
    return MaterialApp.router(
      key: ValueKey(dark),
      title: 'قطعة سيارتك',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      routerConfig: appRouter,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // الضغط في أي مكان خارج حقول الكتابة يقفل لوحة المفاتيح (والنص يبقى)
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox(),
        ),
      ),
    );
  }
}
