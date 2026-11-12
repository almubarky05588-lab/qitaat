import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/theme.dart';
import 'data/api.dart';
import 'data/mock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackend();
  // القوائم من لوحة الإدارة (بحد أقصى 4 ثواني، وإلا نكمل بالقيم الاحتياطية)
  await Mock.load().timeout(const Duration(seconds: 4), onTimeout: () {});
  runApp(const ProviderScope(child: QitaatApp()));
}

class QitaatApp extends StatelessWidget {
  const QitaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
    );
  }
}
