import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/product_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── حسابي (مشتري 20 / تاجر T01) ─────────────────

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(roleProvider) == UserRole.merchant;
    final favs = ref.watch(favoritesProvider);

    Widget cover(IconData icon, Color avatarBg, Color iconColor) => SizedBox(
          height: 262,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(height: 180, decoration: const BoxDecoration(gradient: AppColors.gradient)),
            const Positioned(top: 169, left: 0, right: 0, child: SaduPattern(color: AppColors.bg, height: 12)),
            Positioned(
              top: 124,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 6)),
                  child: Icon(icon, size: 56, color: iconColor),
                ),
              ),
            ),
          ]),
        );

    Widget stats(List<List<String>> items, {Widget? middleTop}) {
      final kids = <Widget>[];
      for (var i = 0; i < items.length; i++) {
        if (i > 0) kids.add(Container(width: 1, height: 40, color: AppColors.line));
        kids.add(Expanded(
          child: Column(children: [
            (i == 1 && middleTop != null) ? middleTop : Text(items[i][0], style: tx(19, w: w6, h: 1.3)),
            Text(items[i][1], style: tx(12, c: AppColors.mute)),
          ]),
        ));
      }
      return AppCard(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16), child: Row(children: kids));
    }

    Widget quick(IconData ic, String t, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                Icon(ic, size: 26, color: AppColors.pri),
                const SizedBox(height: 8),
                Text(t, style: tx(12, w: w5, c: AppColors.ink2), textAlign: TextAlign.center, maxLines: 1),
              ]),
            ),
          ),
        );

    Widget quickRow(List<Widget> items) => Row(children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: 8), items[i]],
        ]);

    final logout = AppButton('تسجيل الخروج', icon: LucideIcons.logOut, iconFirst: true, v: BtnV.red, height: 50, onTap: () => context.go('/signup'));
    final version = Center(child: Text('الإصدار 2.0', style: tx(12, c: AppColors.mute)));

    if (!merchant) {
      return ListView(padding: EdgeInsets.zero, children: [
        cover(LucideIcons.user, AppColors.tealBg, AppColors.teal),
        Center(child: Text('عبدالله', style: tx(24, w: w6))),
        const SizedBox(height: 8),
        const Center(child: StatusBadge('مشتري')),
        const SizedBox(height: 8),
        const Center(child: MetaItem(LucideIcons.mapPin, 'الرياض')),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: VCol(gap: 16, [
            stats([
              ['5', 'طلباتي'],
              ['${favs.length}', 'المفضلة'],
              ['3', 'أتابعهم'],
            ]),
            quickRow([
              quick(LucideIcons.pencil, 'تعديل الملف', () => context.push('/edit-profile')),
              quick(LucideIcons.car, 'سياراتي', () => context.push('/cars')),
              quick(LucideIcons.fileText, 'فواتيري', () => context.push('/invoices')),
              quick(LucideIcons.heart, 'المفضلة', () => context.push('/favorites')),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              MenuGroup(title: 'تسوّقي', items: [
                MenuEntry(LucideIcons.shoppingBag, 'مشترياتي', onTap: () => context.go('/orders')),
                MenuEntry(LucideIcons.gavel, 'مساوماتي', onTap: () => context.push('/part/p4')),
                MenuEntry(LucideIcons.archive, 'طلبات القطع', onTap: () => context.go('/requests')),
              ]),
            ]),
            MenuGroup(title: 'عام', items: [
              MenuEntry(LucideIcons.messageSquare, 'المحادثات', onTap: () => context.push('/chats')),
              MenuEntry(LucideIcons.bell, 'الإشعارات', onTap: () => context.push('/notifications')),
              MenuEntry(LucideIcons.headphones, 'الدعم والمساعدة'),
              MenuEntry(LucideIcons.settings, 'الإعدادات', onTap: () => context.push('/settings')),
            ]),
            GestureDetector(
              onTap: () {
                ref.read(roleProvider.notifier).state = UserRole.merchant;
                context.push('/edit-profile');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.sageB)),
                child: Row(children: [
                  const IconSquare(LucideIcons.store, size: 46, bg: AppColors.white, color: AppColors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('عندك محل قطع غيار؟', style: tx(16, w: w6)),
                      Text('سجّل كتاجر واستقبل طلبات العملاء مباشرة', style: tx(12, c: AppColors.ink2)),
                    ]),
                  ),
                  const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.teal),
                ]),
              ),
            ),
            logout,
            version,
          ]),
        ),
      ]);
    }

    // ── التاجر / المورد ──
    return ListView(padding: EdgeInsets.zero, children: [
      cover(LucideIcons.store, AppColors.beige, AppColors.thumbIcon),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('كار ون', style: tx(24, w: w6)),
        const SizedBox(width: 8),
        const VerifiedBadge(size: 24),
      ]),
      const SizedBox(height: 8),
      const Center(child: StatusBadge.teal('تاجر / مورد')),
      const SizedBox(height: 8),
      const Center(child: MetaItem(LucideIcons.mapPin, 'حفر الباطن')),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: VCol(gap: 16, [
          stats(
            [
              ['تاجر', 'موثّق ✓'],
              ['جديد', 'لا تقييمات بعد'],
              ['0', 'متابعوني'],
            ],
            middleTop: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.star, size: 16, color: Color(0xFFB9AB98)),
              const SizedBox(width: 4),
              Text('جديد', style: tx(19, w: w6, h: 1.3)),
            ]),
          ),
          VCol(gap: 10, cross: CrossAxisAlignment.start, [
            Text('تخصص المحل', style: tx(14, w: w5)),
            Wrap(spacing: 8, children: [for (final b in const ['تويوتا', 'لكزس', 'نيسان']) AppChip(b, bg: const Color(0xFFEBE1D3), noBorder: true, py: 7)]),
          ]),
          quickRow([
            quick(LucideIcons.pencil, 'تعديل الملف', () => context.push('/edit-profile')),
            quick(LucideIcons.car, 'سياراتي', () => context.push('/cars')),
            quick(LucideIcons.fileText, 'فواتيري', () => context.push('/invoices')),
            quick(LucideIcons.users, 'أتابعهم', () {}),
            quick(LucideIcons.heart, 'المفضلة', () => context.push('/favorites')),
          ]),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              MenuGroup(title: 'تسوّقي', items: [
                MenuEntry(LucideIcons.shoppingBag, 'مشترياتي', onTap: () => context.go('/orders')),
                MenuEntry(LucideIcons.gavel, 'مساوماتي', onTap: () => context.push('/m/bids')),
              ]),
              MenuGroup(title: 'متجري', items: [
                MenuEntry(LucideIcons.layoutDashboard, 'لوحة المتجر', sub: 'الأرباح · النشاط · المخزون', onTap: () => context.push('/m/dashboard')),
                MenuEntry(LucideIcons.inbox, 'طلبات العملاء وعروضي', onTap: () => context.push('/m/requests')),
                MenuEntry(LucideIcons.tag, 'طلبات البيع', onTap: () => context.push('/m/sales')),
                MenuEntry(LucideIcons.award, 'باقة لولو (الاشتراك)', onTap: () => context.push('/m/subscription')),
              ]),
              MenuGroup(title: 'عام', items: [
                MenuEntry(LucideIcons.messageSquare, 'المحادثات', onTap: () => context.push('/chats')),
                MenuEntry(LucideIcons.headphones, 'الدعم والمساعدة'),
                MenuEntry(LucideIcons.settings, 'الإعدادات', onTap: () => context.push('/settings')),
              ]),
            ]),
          ),
          const SizedBox(height: 4),
          Text('إعلاناتي', style: tx(20, w: w6)),
          AppButton('إدارة إعلاناتي (بحث، فلترة، تعديل)', icon: LucideIcons.archive, iconFirst: true, v: BtnV.out2, radius: 999, height: 48, fs: 14, onTap: () => context.push('/m/listings')),
          ProductCard(Mock.products[0]),
          ProductCard(Mock.products[1]),
          AppButton('إظهار جميع إعلاناتي (8)', icon: LucideIcons.layoutGrid, iconFirst: true, v: BtnV.out2, radius: 999, height: 48, fs: 14, onTap: () => context.push('/m/listings')),
          const SizedBox(height: 4),
          logout,
          version,
        ]),
      ),
    ]);
  }
}

// ───────────────── T02 · تعديل الملف ─────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool receive = true;
  final brands = <String>{'تويوتا', 'لكزس', 'نيسان'};
  final cats = <String>{'بودي'};

  Widget _section(String t) => Text(t, style: tx(16, w: w6, c: AppColors.pri));

  @override
  Widget build(BuildContext context) {
    final merchant = ref.watch(roleProvider) == UserRole.merchant;
    return AppPage(
      header: const AppHeader(title: 'تعديل الملف'),
      children: [
        Center(
          child: Column(children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                  child: Icon(merchant ? LucideIcons.store : LucideIcons.user, size: 52, color: AppColors.thumbIcon),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.pri, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 3)),
                    child: const Icon(LucideIcons.camera, size: 20, color: AppColors.white),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(merchant ? 'تغيير الشعار' : 'تغيير الصورة', style: tx(14, w: w5, c: AppColors.teal)),
          ]),
        ),
        _section('المعلومات الأساسية'),
        LabeledField('رقم الجوال (تسجيل الدخول)', AppField(value: ltr('+966 55 123 4567'), icon: LucideIcons.smartphone, locked: true)),
        LabeledField('الاسم', AppField(value: merchant ? 'كار ون' : 'عبدالله')),
        LabeledField('المدينة', AppField(value: merchant ? 'حفر الباطن' : 'الرياض', chevron: true)),
        const LabeledField('نبذة (اختياري)', AppField(hint: 'وش يميّزك؟', area: true)),
        _section('حسابات التواصل (اختياري)'),
        const LabeledField('تويتر / X', AppField(hint: '@username', icon: LucideIcons.atSign, ltrText: true)),
        const LabeledField('سناب شات', AppField(hint: 'username', icon: LucideIcons.camera, ltrText: true)),
        const LabeledField('تيك توك', AppField(hint: '@username', icon: LucideIcons.music, ltrText: true)),
        const LabeledField('إنستقرام', AppField(hint: '@username', icon: LucideIcons.camera, ltrText: true)),
        if (merchant) ...[
          const LabeledField('موقع المحل (اختياري)', AppField(hint: 'رابط خرائط قوقل للمحل', icon: LucideIcons.mapPin)),
          _section('بيانات المحل (للتاجر)'),
          const LabeledField('السجل التجاري', AppField(hint: 'رقم السجل التجاري')),
          const LabeledField('الرقم الضريبي (إن وجد)', AppField(hint: 'الرقم الضريبي')),
          const LabeledField('الآيبان (لتحويل المبيعات)', AppField(hint: 'SAxx xxxx xxxx xxxx xxxx xxxx', ltrText: true),
              help: 'اتركه فارغاً للإبقاء على الآيبان المحفوظ، أو اكتب الجديد (24 خانة تبدأ بـ SA)'),
          ToggleRow(title: 'أستقبل طلبات القطع من العملاء', sub: 'أوقفه لو ما تبي تصلك طلبات القطع الموجّهة لتخصصك', value: receive, onChanged: (v) => setState(() => receive = v)),
          LabeledField(
            'تخصص المحل — الماركات',
            ChipWrap(Mock.allBrands, selected: brands, px: 14, py: 8, onTap: (b) => setState(() => brands.contains(b) ? brands.remove(b) : brands.add(b))),
            required: true,
            help: null,
          ),
          Text('طلبات هذه الماركات فقط تصلك (أساس المطابقة)', style: tx(12, c: AppColors.mute)),
          LabeledField(
            'أصناف القطع (اختياري)',
            ChipWrap(Mock.categories, selected: cats, teal: true, px: 14, py: 8, onTap: (c) => setState(() => cats.contains(c) ? cats.remove(c) : cats.add(c))),
          ),
          Text('حدّدها لتضييق الطلبات لصنفك، أو اتركها لاستقبال كل الأصناف', style: tx(12, c: AppColors.mute)),
        ],
        const SizedBox(height: 8),
        AppButton('حفظ', onTap: () {
          showToast(context, 'تم حفظ التعديلات');
          context.pop();
        }),
      ],
    );
  }
}

// ───────────────── 22 · سياراتي ─────────────────

class MyCarsScreen extends StatelessWidget {
  const MyCarsScreen({super.key});

  Widget _car(String t, String vin, bool def) => AppCard(
        border: def ? AppColors.pri : null,
        child: Row(children: [
          IconSquare(LucideIcons.car, size: 56, iconSize: 28, radius: 16, bg: def ? AppColors.pink : AppColors.bg, color: def ? AppColors.pri : AppColors.mute),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: tx(16, w: w6)),
              Text(vin, style: tx(12, c: AppColors.mute)),
              if (def) const SizedBox(height: 4),
              if (def) const StatusBadge('السيارة الأساسية', icon: LucideIcons.check),
            ]),
          ),
          const Icon(LucideIcons.moreVertical, size: 20, color: AppColors.mute),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'سياراتي'),
      gap: 14,
      children: [
        const InfoBox('نستخدم سياراتك عشان نوصلك القطع اللي تناسبها بالضبط'),
        _car('تويوتا كامري 2020', 'رقم الهيكل: JTDKB20U…7781', true),
        _car('لكزس LX 2020', 'رقم الهيكل: JTJHY7AX…0215', false),
        Container(
          height: 58,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.pri, width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(LucideIcons.plus, size: 20, color: AppColors.pri),
            const SizedBox(width: 8),
            Text('أضف سيارة', style: tx(16, w: w5, c: AppColors.pri)),
          ]),
        ),
        const SizedBox(height: 8),
        Text('إضافة سيارة', style: tx(17, w: w6)),
        const LabeledField('الماركة', AppField(value: 'نيسان', chevron: true)),
        const LabeledField('الموديل', AppField(value: 'باترول', chevron: true)),
        const LabeledField('سنة الصنع', AppField(value: '2022', chevron: true)),
        const LabeledField('رقم الهيكل / VIN (اختياري)', AppField(hint: '17 خانة')),
        AppButton('حفظ السيارة', onTap: () => showToast(context, 'تمت إضافة السيارة')),
      ],
    );
  }
}

// ───────────────── 24 · الإعدادات ─────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notif = true, chatNotif = true, dark = false;

  Widget _val(String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(t, style: tx(14, c: AppColors.mute)),
        const SizedBox(width: 4),
        const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.mute),
      ]);

  Widget _group(String title, List<MenuEntry> items) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: tx(13, w: w5, c: AppColors.mute))),
        MenuGroup(items: items),
      ]);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'الإعدادات'),
      children: [
        _group('الحساب', [
          MenuEntry(LucideIcons.user, 'الملف الشخصي', onTap: () => context.push('/edit-profile')),
          MenuEntry(LucideIcons.smartphone, 'رقم الجوال', trailing: _val(ltr('+966 55 123 4567'))),
          MenuEntry(LucideIcons.mapPin, 'عناويني', trailing: _val('2')),
        ]),
        _group('التفضيلات', [
          MenuEntry(LucideIcons.globe, 'اللغة', trailing: _val('العربية')),
          MenuEntry(LucideIcons.bell, 'الإشعارات', trailing: AppToggle(value: notif, onChanged: (v) => setState(() => notif = v))),
          MenuEntry(LucideIcons.messageSquare, 'إشعارات المحادثات', trailing: AppToggle(value: chatNotif, onChanged: (v) => setState(() => chatNotif = v))),
          MenuEntry(LucideIcons.moon, 'الوضع الليلي', trailing: AppToggle(value: dark, onChanged: (v) => setState(() => dark = v))),
        ]),
        _group('الدعم', [
          MenuEntry(LucideIcons.helpCircle, 'مركز المساعدة'),
          MenuEntry(LucideIcons.headphones, 'تواصل معنا'),
          MenuEntry(LucideIcons.fileText, 'الشروط والأحكام'),
          MenuEntry(LucideIcons.shieldCheck, 'سياسة الخصوصية'),
        ]),
        _group('', [MenuEntry(LucideIcons.trash2, 'حذف الحساب', color: AppColors.red)]),
        Center(child: Text('الإصدار 2.0', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}
