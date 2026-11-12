import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/media.dart';
import '../core/product_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/mock.dart';
import 'checkout.dart' show myOrdersProvider;
import 'requests.dart' show pickFromSheet;

final myListingsProvider = FutureProvider<List<Listing>>((ref) {
  ref.watch(authProvider);
  return Api.listings(sellerId: myId, status: null, limit: 100);
});

final accountStatsProvider = FutureProvider<(int, int)>((ref) async {
  ref.watch(authProvider);
  if (myId == null) return (0, 0);
  return (await Api.followersCount(myId!), await Api.followingCount());
});

Future<void> logout(BuildContext context, WidgetRef ref) async {
  await Api.signOut();
  ref.invalidate(myProfileProvider);
  if (context.mounted) context.go('/signup');
}

// ───────────────── حسابي (مشتري 20 / تاجر T01) ─────────────────

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pv = ref.watch(myProfileProvider);
    final p = pv.valueOrNull;
    if (p == null) return pv.isLoading ? const SafeArea(child: Loading()) : SafeArea(child: ErrorBox(pv.error ?? 'سجّل دخول', onRetry: () => ref.invalidate(myProfileProvider)));
    final merchant = p.isMerchant;
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final stats = ref.watch(accountStatsProvider).valueOrNull ?? (0, 0);
    final orders = ref.watch(myOrdersProvider).valueOrNull ?? const <Order>[];

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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 6)),
                  child: p.avatarUrl != null ? Image.network(p.avatarUrl!, fit: BoxFit.cover) : Icon(icon, size: 56, color: iconColor),
                ),
              ),
            ),
          ]),
        );

    Widget statsCard(List<List<String>> items, {Widget? middleTop}) {
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

    final logoutBtn = AppButton('تسجيل الخروج', icon: LucideIcons.logOut, iconFirst: true, v: BtnV.red, height: 50, onTap: () => logout(context, ref));
    final version = Center(child: Text('الإصدار 2.0', style: tx(12, c: AppColors.mute)));

    Future<void> refresh() async => refreshAll(ref, [myProfileProvider, accountStatsProvider, myListingsProvider, myOrdersProvider]);

    if (!merchant) {
      return RefreshIndicator(
        color: AppColors.pri,
        onRefresh: refresh,
        child: ListView(padding: EdgeInsets.zero, children: [
          cover(LucideIcons.user, AppColors.tealBg, AppColors.teal),
          Center(child: Text(p.displayName, style: tx(24, w: w6))),
          const SizedBox(height: 8),
          const Center(child: StatusBadge('مشتري')),
          const SizedBox(height: 8),
          if (p.city != null) Center(child: MetaItem(LucideIcons.mapPin, p.city!)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: VCol(gap: 16, [
              statsCard([
                ['${orders.length}', 'طلباتي'],
                ['${favs.length}', 'المفضلة'],
                ['${stats.$2}', 'أتابعهم'],
              ]),
              quickRow([
                quick(LucideIcons.pencil, 'تعديل الملف', () => context.push('/edit-profile')),
                quick(LucideIcons.car, 'سياراتي', () => context.push('/cars')),
                quick(LucideIcons.fileText, 'فواتيري', () => context.push('/invoices')),
                quick(LucideIcons.heart, 'المفضلة', () => context.push('/favorites')),
              ]),
              MenuGroup(title: 'تسوّقي', items: [
                MenuEntry(LucideIcons.shoppingBag, 'مشترياتي', onTap: () => context.go('/orders')),
                MenuEntry(LucideIcons.archive, 'طلبات القطع', onTap: () => context.go('/requests')),
                MenuEntry(LucideIcons.shoppingCart, 'السلة', onTap: () => context.push('/cart')),
              ]),
              MenuGroup(title: 'عام', items: [
                MenuEntry(LucideIcons.messageSquare, 'المحادثات', onTap: () => context.push('/chats')),
                MenuEntry(LucideIcons.bell, 'الإشعارات', onTap: () => context.push('/notifications')),
                MenuEntry(LucideIcons.headphones, 'الدعم والمساعدة', onTap: () => showToast(context, 'تواصل معنا: support@qitaat.app')),
                MenuEntry(LucideIcons.settings, 'الإعدادات', onTap: () => context.push('/settings')),
              ]),
              GestureDetector(
                onTap: () => showAppSheet(
                  context,
                  VCol(gap: 14, [
                    Text('تسجيل كتاجر', style: tx(18, w: w6)),
                    Text('حساب التاجر يكون برقم جوال منفصل عن حساب المشتري. سجّل خروج وأنشئ حساب جديد واختر «تاجر / مورد».', style: tx(14, c: AppColors.ink2)),
                    AppButton('تسجيل خروج وإنشاء حساب تاجر', onTap: () {
                      Navigator.pop(context);
                      logout(context, ref);
                    }),
                  ]),
                ),
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
              logoutBtn,
              version,
            ]),
          ),
        ]),
      );
    }

    // ── التاجر / المورد ──
    final mine = ref.watch(myListingsProvider).valueOrNull ?? const <Listing>[];
    return RefreshIndicator(
      color: AppColors.pri,
      onRefresh: refresh,
      child: ListView(padding: EdgeInsets.zero, children: [
        cover(LucideIcons.store, AppColors.beige, AppColors.thumbIcon),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(p.displayName, style: tx(24, w: w6)),
          if (p.verified) const SizedBox(width: 8),
          if (p.verified) const VerifiedBadge(size: 24),
        ]),
        const SizedBox(height: 8),
        const Center(child: StatusBadge.teal('تاجر / مورد')),
        const SizedBox(height: 8),
        if (p.city != null) Center(child: MetaItem(LucideIcons.mapPin, p.city!)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: VCol(gap: 16, [
            statsCard(
              [
                ['تاجر', p.verified ? 'موثّق ✓' : 'غير موثّق'],
                ['جديد', 'لا تقييمات بعد'],
                ['${stats.$1}', 'متابعوني'],
              ],
              middleTop: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.star, size: 16, color: Color(0xFFB9AB98)),
                const SizedBox(width: 4),
                Text('جديد', style: tx(19, w: w6, h: 1.3)),
              ]),
            ),
            if (!p.verified)
              GestureDetector(
                onTap: () => context.push('/edit-profile'),
                child: InfoBox(p.verifyStatus == 'pending'
                    ? 'طلب توثيق متجرك قيد المراجعة'
                    : p.verifyStatus == 'rejected'
                        ? 'طلب التوثيق مرفوض${p.verifyNote != null ? ' — ${p.verifyNote}' : ''}. أعد رفع السجل التجاري من تعديل الملف'
                        : 'وثّق متجرك برفع صورة السجل التجاري من تعديل الملف — يظهر لك شارة «تاجر موثّق»'),
              ),
            VCol(gap: 10, cross: CrossAxisAlignment.start, [
              Text('تخصص المحل', style: tx(14, w: w5)),
              p.brands.isEmpty
                  ? GestureDetector(onTap: () => context.push('/edit-profile'), child: Text('حدّد الماركات عشان توصلك الطلبات ←', style: tx(13, w: w5, c: AppColors.pri)))
                  : Wrap(spacing: 8, runSpacing: 8, children: [for (final b in p.brands) AppChip(b, bg: const Color(0xFFEBE1D3), noBorder: true, py: 7)]),
            ]),
            quickRow([
              quick(LucideIcons.pencil, 'تعديل الملف', () => context.push('/edit-profile')),
              quick(LucideIcons.car, 'سياراتي', () => context.push('/cars')),
              quick(LucideIcons.fileText, 'فواتيري', () => context.push('/invoices')),
              quick(LucideIcons.users, 'أتابعهم', () => context.push('/favorites')),
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
                  MenuEntry(LucideIcons.headphones, 'الدعم والمساعدة', onTap: () => showToast(context, 'تواصل معنا: support@qitaat.app')),
                  MenuEntry(LucideIcons.settings, 'الإعدادات', onTap: () => context.push('/settings')),
                ]),
              ]),
            ),
            const SizedBox(height: 4),
            Text('إعلاناتي', style: tx(20, w: w6)),
            AppButton('إدارة إعلاناتي (بحث، فلترة، تعديل)', icon: LucideIcons.archive, iconFirst: true, v: BtnV.out2, radius: 999, height: 48, fs: 14, onTap: () => context.push('/m/listings')),
            if (mine.isEmpty) AppButton('أضف أول إعلان', icon: LucideIcons.plus, iconFirst: true, radius: 999, height: 48, fs: 14, onTap: () => context.push('/sell')),
            for (final l in mine.take(2)) ProductCard(l),
            if (mine.length > 2)
              AppButton('إظهار جميع إعلاناتي (${mine.length})', icon: LucideIcons.layoutGrid, iconFirst: true, v: BtnV.out2, radius: 999, height: 48, fs: 14, onTap: () => context.push('/m/listings')),
            const SizedBox(height: 4),
            logoutBtn,
            version,
          ]),
        ),
      ]),
    );
  }
}

// ───────────────── T02 · تعديل الملف ─────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool loaded = false, busy = false, sendingDoc = false;
  late bool receive;
  late Set<String> brands, cats;
  late String name, city, bio, x, snap, tiktok, insta, location, cr, vat;
  String iban = '';
  String? avatar;

  void _init(Profile p) {
    if (loaded) return;
    loaded = true;
    receive = p.receiveRequests;
    brands = {...p.brands};
    cats = {...p.categories};
    name = p.name ?? '';
    city = p.city ?? '';
    bio = p.bio ?? '';
    x = '${p.socials['x'] ?? ''}';
    snap = '${p.socials['snap'] ?? ''}';
    tiktok = '${p.socials['tiktok'] ?? ''}';
    insta = '${p.socials['insta'] ?? ''}';
    location = p.storeLocation ?? '';
    cr = p.storeCr ?? '';
    vat = p.storeVat ?? '';
    avatar = p.avatarUrl;
  }

  Widget _section(String t) => Text(t, style: tx(16, w: w6, c: AppColors.pri));
  String? _nz(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _sendDoc() async {
    if (cr.trim().isEmpty) {
      showToast(context, 'اكتب رقم السجل التجاري أول');
      return;
    }
    final u = await pickAndUpload(context);
    if (u == null || !mounted) return;
    setState(() => sendingDoc = true);
    final ok = await run(context, () async {
      await Api.updateProfile({'store_cr': cr.trim(), 'store_vat': _nz(vat)});
      await Api.requestVerification(u);
    }, success: 'وصل طلب التوثيق للإدارة — بنبلّغك بالنتيجة');
    if (!mounted) return;
    setState(() => sendingDoc = false);
    if (ok) ref.invalidate(myProfileProvider);
  }

  Widget _verifyCard(Profile p) {
    final (label, color, bg) = p.verified
        ? ('متجرك موثّق ✓', AppColors.teal, AppColors.tealBg)
        : switch (p.verifyStatus) {
            'pending' => ('طلبك قيد المراجعة', AppColors.pri, AppColors.pink),
            'rejected' => ('الطلب مرفوض${p.verifyNote != null ? ' — ${p.verifyNote}' : ''}', AppColors.red, const Color(0xFFFBE5E2)),
            _ => ('غير موثّق', AppColors.ink2, AppColors.bg),
          };
    return AppCard(
      child: VCol(gap: 12, [
        Row(children: [
          const IconSquare(LucideIcons.badgeCheck, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('توثيق المتجر', style: tx(16, w: w6)),
              Text('ارفع صورة السجل التجاري وتظهر لك شارة «تاجر موثّق» بعد مراجعة الإدارة', style: tx(12, c: AppColors.mute)),
            ]),
          ),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: tx(13, w: w5, c: color)),
        ),
        if (p.crDocUrl != null) PartThumb(width: double.infinity, height: 140, radius: 14, imageUrl: p.crDocUrl),
        if (!p.verified)
          sendingDoc
              ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
              : AppButton(p.crDocUrl == null ? 'ارفع صورة السجل التجاري' : 'أعد رفع السجل التجاري', icon: LucideIcons.camera, v: BtnV.out2, height: 48, fs: 15, onTap: _sendDoc),
      ]),
    );
  }

  Future<void> _save(Profile p) async {
    if (name.trim().isEmpty) {
      showToast(context, 'اكتب الاسم');
      return;
    }
    if (p.isMerchant && brands.isEmpty) {
      showToast(context, 'اختر ماركة وحدة على الأقل عشان توصلك الطلبات');
      return;
    }
    final ib = iban.replaceAll(' ', '').toUpperCase();
    if (ib.isNotEmpty && !RegExp(r'^SA\d{22}$').hasMatch(ib)) {
      showToast(context, 'الآيبان لازم يبدأ بـ SA ويتكون من 24 خانة');
      return;
    }
    setState(() => busy = true);
    final ok = await run(context, () async {
      await Api.updateProfile({
        'name': name.trim(),
        'city': _nz(city),
        'bio': _nz(bio),
        'avatar_url': avatar,
        'socials': {'x': _nz(x), 'snap': _nz(snap), 'tiktok': _nz(tiktok), 'insta': _nz(insta)},
        if (p.isMerchant) ...{
          'store_location': _nz(location),
          'store_cr': _nz(cr),
          'store_vat': _nz(vat),
          'receive_requests': receive,
          'brands': brands.toList(),
          'categories': cats.toList(),
        },
      });
      if (ib.isNotEmpty) await Api.setIban(ib);
    }, success: 'تم حفظ التعديلات');
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ref.invalidate(myProfileProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(myProfileProvider).valueOrNull;
    if (p == null) return const Scaffold(backgroundColor: AppColors.bg, body: Loading());
    _init(p);
    final merchant = p.isMerchant;
    return AppPage(
      header: const AppHeader(title: 'تعديل الملف'),
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final u = await pickAndUpload(context);
              if (u != null) setState(() => avatar = u);
            },
            child: Column(children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(children: [
                  Container(
                    width: 120,
                    height: 120,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                    child: avatar != null ? Image.network(avatar!, fit: BoxFit.cover) : Icon(merchant ? LucideIcons.store : LucideIcons.user, size: 52, color: AppColors.thumbIcon),
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
        ),
        _section('المعلومات الأساسية'),
        LabeledField('رقم الجوال (تسجيل الدخول)', AppField(value: ltr(p.phone ?? ''), icon: LucideIcons.smartphone, locked: true)),
        LabeledField('الاسم', AppField(value: name, onChanged: (v) => name = v)),
        LabeledField('المدينة', AppField(key: ValueKey(city), value: city.isEmpty ? null : city, hint: 'اختر مدينتك', chevron: true, onTap: () => pickFromSheet(context, 'المدينة', Mock.cities, (v) => setState(() => city = v)))),
        LabeledField('نبذة (اختياري)', AppField(hint: 'وش يميّزك؟', value: bio.isEmpty ? null : bio, area: true, onChanged: (v) => bio = v)),
        _section('حسابات التواصل (اختياري)'),
        LabeledField('تويتر / X', AppField(hint: '@username', value: x.isEmpty ? null : x, icon: LucideIcons.atSign, ltrText: true, onChanged: (v) => x = v)),
        LabeledField('سناب شات', AppField(hint: 'username', value: snap.isEmpty ? null : snap, icon: LucideIcons.camera, ltrText: true, onChanged: (v) => snap = v)),
        LabeledField('تيك توك', AppField(hint: '@username', value: tiktok.isEmpty ? null : tiktok, icon: LucideIcons.music, ltrText: true, onChanged: (v) => tiktok = v)),
        LabeledField('إنستقرام', AppField(hint: '@username', value: insta.isEmpty ? null : insta, icon: LucideIcons.camera, ltrText: true, onChanged: (v) => insta = v)),
        if (merchant) ...[
          LabeledField('موقع المحل (اختياري)', AppField(hint: 'رابط خرائط قوقل للمحل', value: location.isEmpty ? null : location, icon: LucideIcons.mapPin, onChanged: (v) => location = v)),
          _section('بيانات المحل (للتاجر)'),
          LabeledField('السجل التجاري', AppField(hint: 'رقم السجل التجاري', value: cr.isEmpty ? null : cr, ltrText: true, keyboard: TextInputType.number, onChanged: (v) => cr = v)),
          LabeledField('الرقم الضريبي (إن وجد)', AppField(hint: 'الرقم الضريبي', value: vat.isEmpty ? null : vat, ltrText: true, keyboard: TextInputType.number, onChanged: (v) => vat = v)),
          _verifyCard(p),
          LabeledField('الآيبان (لتحويل المبيعات)', AppField(hint: 'SAxx xxxx xxxx xxxx xxxx xxxx', ltrText: true, onChanged: (v) => iban = v),
              help: 'اتركه فارغاً للإبقاء على الآيبان المحفوظ، أو اكتب الجديد (24 خانة تبدأ بـ SA)'),
          ToggleRow(title: 'أستقبل طلبات القطع من العملاء', sub: 'أوقفه لو ما تبي تصلك طلبات القطع الموجّهة لتخصصك', value: receive, onChanged: (v) => setState(() => receive = v)),
          LabeledField('تخصص المحل — الماركات',
              ChipWrap(Mock.allBrands.toSet().toList(), selected: brands, px: 14, py: 8, onTap: (b) => setState(() => brands.contains(b) ? brands.remove(b) : brands.add(b))),
              required: true),
          Text('طلبات هذه الماركات فقط تصلك (أساس المطابقة)', style: tx(12, c: AppColors.mute)),
          LabeledField('أصناف القطع (اختياري)', ChipWrap(Mock.categories, selected: cats, teal: true, px: 14, py: 8, onTap: (c) => setState(() => cats.contains(c) ? cats.remove(c) : cats.add(c)))),
          Text('حدّدها لتضييق الطلبات لصنفك، أو اتركها لاستقبال كل الأصناف', style: tx(12, c: AppColors.mute)),
        ],
        const SizedBox(height: 8),
        busy ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri))) : AppButton('حفظ', onTap: () => _save(p)),
      ],
    );
  }
}

// ───────────────── 22 · سياراتي ─────────────────

final carsProvider = FutureProvider<List<Car>>((ref) => Api.cars());

class MyCarsScreen extends ConsumerStatefulWidget {
  const MyCarsScreen({super.key});
  @override
  ConsumerState<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends ConsumerState<MyCarsScreen> {
  String brand = 'تويوتا', model = 'كامري', year = '2020', vin = '';
  bool adding = false;

  Widget _car(Car c) => AppCard(
        border: c.isDefault ? AppColors.pri : null,
        child: Row(children: [
          IconSquare(LucideIcons.car, size: 56, iconSize: 28, radius: 16, bg: c.isDefault ? AppColors.pink : AppColors.bg, color: c.isDefault ? AppColors.pri : AppColors.mute),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title, style: tx(16, w: w6)),
              if (c.vin != null) Text('رقم الهيكل: ${ltr(c.vin!)}', style: tx(12, c: AppColors.mute)),
              if (c.isDefault) const SizedBox(height: 4),
              if (c.isDefault) const StatusBadge('السيارة الأساسية', icon: LucideIcons.check),
            ]),
          ),
          GestureDetector(
            onTap: () => showAppSheet(
              context,
              VCol(gap: 12, [
                Text(c.title, style: tx(18, w: w6)),
                if (!c.isDefault)
                  AppButton('اجعلها الأساسية', v: BtnV.out, onTap: () async {
                    Navigator.pop(context);
                    await run(context, () => Api.setDefaultCar(c.id));
                    ref.invalidate(carsProvider);
                  }),
                AppButton('حذف السيارة', v: BtnV.red, onTap: () async {
                  Navigator.pop(context);
                  await run(context, () => Api.deleteCar(c.id));
                  ref.invalidate(carsProvider);
                }),
              ]),
            ),
            child: const Icon(LucideIcons.moreVertical, size: 20, color: AppColors.mute),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(carsProvider);
    return AppPage(
      header: const AppHeader(title: 'سياراتي'),
      gap: 14,
      children: [
        const InfoBox('نستخدم سياراتك عشان نوصلك القطع اللي تناسبها بالضبط'),
        AsyncBody<List<Car>>(v, (cars) => VCol(gap: 14, [for (final c in cars) _car(c)])),
        GestureDetector(
          onTap: () => setState(() => adding = !adding),
          child: Container(
            height: 58,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.pri, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(adding ? LucideIcons.x : LucideIcons.plus, size: 20, color: AppColors.pri),
              const SizedBox(width: 8),
              Text(adding ? 'إلغاء' : 'أضف سيارة', style: tx(16, w: w5, c: AppColors.pri)),
            ]),
          ),
        ),
        if (adding) ...[
          const SizedBox(height: 8),
          Text('إضافة سيارة', style: tx(17, w: w6)),
          LabeledField(
              'الماركة',
              AppField(
                  key: ValueKey('b$brand'),
                  value: brand,
                  chevron: true,
                  onTap: () => pickFromSheet(context, 'الماركة', Mock.allBrands, (x) => setState(() {
                        brand = x;
                        model = Mock.modelsOf(x).first;
                      })))),
          LabeledField('الموديل', AppField(key: ValueKey('m$model'), value: model, chevron: true, onTap: () => pickFromSheet(context, 'الموديل', Mock.modelsOf(brand), (x) => setState(() => model = x)))),
          LabeledField('سنة الصنع',
              AppField(key: ValueKey('y$year'), value: year, chevron: true, onTap: () => pickFromSheet(context, 'سنة الصنع', [for (var y = DateTime.now().year + 1; y >= 1990; y--) '$y'], (x) => setState(() => year = x)))),
          LabeledField('رقم الهيكل / VIN (اختياري)', AppField(hint: '17 خانة', ltrText: true, onChanged: (x) => vin = x)),
          AppButton('حفظ السيارة', onTap: () async {
            final ok = await run(context, () => Api.addCar({'brand': brand, 'model': model, 'year': int.tryParse(year), 'vin': vin.trim().isEmpty ? null : vin.trim().toUpperCase()}),
                success: 'تمت إضافة السيارة');
            if (ok) {
              ref.invalidate(carsProvider);
              setState(() => adding = false);
            }
          }),
        ],
      ],
    );
  }
}

// ───────────────── 24 · الإعدادات ─────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final p = ref.watch(myProfileProvider).valueOrNull;
    return AppPage(
      header: const AppHeader(title: 'الإعدادات'),
      children: [
        _group('الحساب', [
          MenuEntry(LucideIcons.user, 'الملف الشخصي', onTap: () => context.push('/edit-profile')),
          MenuEntry(LucideIcons.smartphone, 'رقم الجوال', trailing: _val(ltr(p?.phone ?? ''))),
          MenuEntry(LucideIcons.car, 'سياراتي', onTap: () => context.push('/cars')),
        ]),
        _group('التفضيلات', [
          MenuEntry(LucideIcons.globe, 'اللغة', trailing: _val('العربية')),
          MenuEntry(LucideIcons.bell, 'الإشعارات', trailing: AppToggle(value: notif, onChanged: (v) => setState(() => notif = v))),
          MenuEntry(LucideIcons.messageSquare, 'إشعارات المحادثات', trailing: AppToggle(value: chatNotif, onChanged: (v) => setState(() => chatNotif = v))),
          MenuEntry(LucideIcons.moon, 'الوضع الليلي', trailing: AppToggle(value: dark, onChanged: (v) => setState(() => dark = v))),
        ]),
        _group('الدعم', [
          MenuEntry(LucideIcons.helpCircle, 'مركز المساعدة', onTap: () => showToast(context, 'قريباً')),
          MenuEntry(LucideIcons.headphones, 'تواصل معنا', onTap: () => showToast(context, 'support@qitaat.app')),
          MenuEntry(LucideIcons.fileText, 'الشروط والأحكام', onTap: () => showToast(context, 'قريباً')),
          MenuEntry(LucideIcons.shieldCheck, 'سياسة الخصوصية', onTap: () => showToast(context, 'قريباً')),
        ]),
        _group('', [
          MenuEntry(LucideIcons.logOut, 'تسجيل الخروج', color: AppColors.red, onTap: () => logout(context, ref)),
          MenuEntry(LucideIcons.trash2, 'حذف الحساب', color: AppColors.red, onTap: () => showToast(context, 'لحذف الحساب تواصل مع الدعم: support@qitaat.app')),
        ]),
        Center(child: Text('الإصدار 2.0', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}
