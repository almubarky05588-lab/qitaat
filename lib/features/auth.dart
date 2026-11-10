import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── 01 · البداية ─────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/signup');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const AppLogo(size: 112),
              const SizedBox(height: 20),
              Text('قطعة سيارتك', style: tx(38, w: w7, h: 1.3)),
              const SizedBox(height: 12),
              Text('سوقك لقطع الغيار', style: tx(16, c: AppColors.mute)),
            ]),
          ),
        ),
        Text('الإصدار 2.0', style: tx(12, c: AppColors.mute)),
        const SizedBox(height: 34),
        const SaduPattern(height: 12),
      ]),
    );
  }
}

// ───────────────── 02 · تسجيل حساب ─────────────────

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  UserRole role = UserRole.buyer;
  String city = '';
  bool agree = true;
  String phone = '';

  Widget _roleCard(UserRole r, IconData icon, String title, String sub) {
    final sel = role == r;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = r),
        child: Stack(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel ? AppColors.pink : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? AppColors.pri : AppColors.chipB, width: sel ? 1.5 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconSquare(icon, size: 44, bg: sel ? AppColors.white : AppColors.bg, color: sel ? AppColors.pri : AppColors.mute),
              const SizedBox(height: 8),
              Text(title, style: tx(16, w: w6, c: sel ? AppColors.pri : AppColors.ink)),
              const SizedBox(height: 4),
              Text(sub, style: tx(12, c: AppColors.mute)),
            ]),
          ),
          if (sel)
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, size: 13, color: AppColors.white),
              ),
            ),
        ]),
      ),
    );
  }

  void _pickCity() {
    showAppSheet(
      context,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('اختر مدينتك', style: tx(18, w: w6)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 10, children: [
          for (final c in Mock.cities)
            AppChip(c, selected: c == city, onTap: () {
              setState(() => city = c);
              Navigator.pop(context);
            }),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(children: [
              const AppLogo(size: 76),
              const SizedBox(height: 8),
              Text('قطعة سيارتك', style: tx(20, w: w7, c: AppColors.pri)),
            ]),
          ),
          const SaduPattern(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: VCol(gap: 18, [
              VCol(gap: 4, [
                Text('إنشاء حساب جديد', style: tx(26, w: w7)),
                Text('سجّل برقم جوالك وابدأ تبيع وتشتري قطع الغيار بسهولة', style: tx(15, c: AppColors.mute)),
              ]),
              LabeledField(
                'نوع الحساب',
                Row(children: [
                  _roleCard(UserRole.buyer, LucideIcons.shoppingBag, 'مشتري', 'أدوّر على قطع لسيارتي'),
                  const SizedBox(width: 12),
                  _roleCard(UserRole.merchant, LucideIcons.store, 'تاجر / مورد', 'أبيع وأستقبل طلبات القطع'),
                ]),
              ),
              const LabeledField('الاسم', AppField(hint: 'اكتب اسمك', icon: LucideIcons.user)),
              LabeledField(
                'رقم الجوال',
                AppField(
                  hint: '5X XXX XXXX',
                  icon: LucideIcons.smartphone,
                  ltrText: true,
                  keyboard: TextInputType.phone,
                  onChanged: (v) => phone = v,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 1, height: 24, color: AppColors.chipB),
                    const SizedBox(width: 8),
                    Text(ltr('+966'), style: tx(15, w: w5, c: AppColors.ink2)),
                  ]),
                ),
              ),
              LabeledField(
                'المدينة',
                AppField(key: ValueKey(city), hint: 'اختر مدينتك', value: city.isEmpty ? null : city, icon: LucideIcons.mapPin, chevron: true, onTap: _pickCity),
              ),
              GestureDetector(
                onTap: () => setState(() => agree = !agree),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: agree ? AppColors.pri : AppColors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: agree ? null : Border.all(color: AppColors.chipB),
                    ),
                    child: agree ? const Icon(LucideIcons.check, size: 14, color: AppColors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(TextSpan(style: tx(13, c: AppColors.ink2), children: [
                      const TextSpan(text: 'أوافق على '),
                      TextSpan(text: 'الشروط والأحكام', style: tx(13, c: AppColors.pri)),
                      const TextSpan(text: ' و'),
                      TextSpan(text: 'سياسة الخصوصية', style: tx(13, c: AppColors.pri)),
                    ])),
                  ),
                ]),
              ),
              AppButton('أرسل رمز التحقق', icon: LucideIcons.arrowLeft, disabled: !agree, onTap: () {
                ref.read(roleProvider.notifier).state = role;
                ref.read(phoneProvider.notifier).state = phone.isEmpty ? '55 123 4567' : phone;
                context.push('/otp');
              }),
              Center(
                child: Text.rich(TextSpan(style: tx(14, c: AppColors.mute), children: [
                  const TextSpan(text: 'عندك حساب؟ '),
                  TextSpan(text: 'سجّل دخول', style: tx(14, w: w5, c: AppColors.pri)),
                ])),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 03 · رمز التحقق ─────────────────

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final ctrl = TextEditingController();
  final focus = FocusNode();
  int seconds = 45;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _start();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  void _start() {
    timer?.cancel();
    seconds = 45;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl.dispose();
    focus.dispose();
    super.dispose();
  }

  void _confirm() {
    if (ctrl.text.length < 4) {
      showToast(context, 'أدخل الرمز كامل (4 أرقام)');
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(phoneProvider);
    final code = ctrl.text;
    final mm = '00:${seconds.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          const AppHeader(title: 'رمز التحقق'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.shieldCheck, size: 44, color: AppColors.pri),
                ),
                const SizedBox(height: 20),
                Text('أدخل رمز التحقق', style: tx(24, w: w7)),
                const SizedBox(height: 14),
                Text('أرسلنا رمز مكوّن من 4 أرقام إلى', style: tx(15, c: AppColors.mute)),
                const SizedBox(height: 14),
                Text(ltr('+966 $phone'), style: tx(17, w: w6)),
                const SizedBox(height: 26),
                GestureDetector(
                  onTap: () => focus.requestFocus(),
                  child: Stack(children: [
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: ctrl,
                          focusNode: focus,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          _box(i < code.length ? code[i] : '', i == code.length),
                        ],
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: seconds == 0 ? () => setState(_start) : null,
                  child: Text.rich(TextSpan(style: tx(14, c: AppColors.mute), children: [
                    TextSpan(text: seconds == 0 ? 'أعد إرسال الرمز' : 'إعادة إرسال الرمز بعد '),
                    if (seconds > 0) TextSpan(text: mm, style: tx(14, w: w5, c: AppColors.pri)),
                  ])),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('تعديل رقم الجوال', style: tx(14, w: w5, c: AppColors.teal)),
                ),
              ]),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), child: AppButton('تأكيد', onTap: _confirm)),
        ]),
      ),
    );
  }

  Widget _box(String d, bool focusBox) {
    return Container(
      width: 66,
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: focusBox ? AppColors.pri : (d.isNotEmpty ? AppColors.pinkB : AppColors.chipB), width: focusBox ? 2 : 1),
      ),
      child: d.isNotEmpty
          ? Text(d, style: tx(28, w: w6, h: 1.2))
          : (focusBox ? Container(width: 2, height: 28, color: AppColors.pri) : null),
    );
  }
}
