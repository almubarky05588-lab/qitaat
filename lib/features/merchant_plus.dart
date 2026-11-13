import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import 'account.dart' show myListingsProvider;
import 'catalog.dart' show openChat;
import 'merchant.dart' show customerRequestsProvider, SellPartScreen;

// تحديثات ملاحظات العميل: طلبات العملاء، إدارة الإعلانات والتمييز، الباقات الجديدة، شرط الحساب البنكي قبل البيع

// ───────────────── شرط الحساب البنكي قبل نشر قطعة للبيع ─────────────────

class SellGate extends StatefulWidget {
  const SellGate({super.key});
  @override
  State<SellGate> createState() => _SellGateState();
}

class _SellGateState extends State<SellGate> {
  bool? ok;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    var complete = false;
    try {
      complete = (await Api.payout()).complete;
    } catch (_) {}
    if (mounted) setState(() => ok = complete);
  }

  @override
  Widget build(BuildContext context) {
    if (ok == null) return const Scaffold(backgroundColor: AppColors.bg, body: Loading());
    if (ok == true) return const SellPartScreen();
    return AppPage(
      header: const AppHeader(title: 'أبيع قطعة'),
      children: [
        const SizedBox(height: 30),
        const Center(child: IconSquare(LucideIcons.landmark, size: 84, iconSize: 40, radius: 26)),
        Text('أضف حسابك البنكي أول', textAlign: TextAlign.center, style: tx(22, w: w7)),
        Text('عشان نحوّل لك مبلغ البيع، نحتاج اسم صاحب الحساب والبنك والآيبان. بياناتك خاصة وما تظهر لأي أحد — والشراء ما يحتاجها.',
            textAlign: TextAlign.center, style: tx(14, c: AppColors.ink2, h: 1.7)),
        AppButton('أضف الحساب البنكي', icon: LucideIcons.arrowLeft, onTap: () async {
          await context.push('/edit-profile');
          if (!mounted) return;
          setState(() => ok = null);
          _check();
        }),
      ],
    );
  }
}

// ───────────────── طلبات العملاء (حسب التخصص) ─────────────────

class CustomerRequestsPage extends ConsumerStatefulWidget {
  final bool inTab;
  const CustomerRequestsPage({super.key, this.inTab = false});
  @override
  ConsumerState<CustomerRequestsPage> createState() => _CustomerRequestsPageState();
}

class _CustomerRequestsPageState extends ConsumerState<CustomerRequestsPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final v = ref.watch(customerRequestsProvider);
    final me = ref.watch(myProfileProvider).valueOrNull;
    final all = v.valueOrNull ?? const <PartRequest>[];
    Offer? mine(PartRequest r) {
      for (final o in r.offers) {
        if (o.supplierId == myId) return o;
      }
      return null;
    }

    final fresh = all.where((r) => r.isOpen && mine(r) == null).toList();
    final offered = all.where((r) => mine(r) != null && mine(r)!.status != 'accepted').toList();
    final accepted = all.where((r) => mine(r)?.status == 'accepted').toList();
    final list = [fresh, offered, accepted][tab];

    return AppPage(
      header: AppHeader(title: widget.inTab ? 'طلبات العملاء' : 'طلبات العملاء وعروضي', back: !widget.inTab),
      gap: 14,
      children: [
        SegTabs(items: ['جديدة (${fresh.length})', 'عروضي (${offered.length})', 'مقبولة (${accepted.length})'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        InfoBox(me == null || me.brands.isEmpty ? 'حدّد تخصصك (الماركات) من تعديل الملف عشان توصلك الطلبات' : 'هذي الطلبات تطابق تخصصك: ${me.brands.join(' · ')}'),
        if (v.isLoading) const Loading(),
        if (v.hasError) ErrorBox(v.error!, onRetry: () => ref.invalidate(customerRequestsProvider)),
        if (!v.isLoading && list.isEmpty) EmptyBox(LucideIcons.inbox, ['ما فيه طلبات جديدة حالياً — بنعلمك أول ما يوصل طلب', 'ما قدّمت عروض للحين', 'ما فيه عروض مقبولة للحين'][tab]),
        for (final r in list)
          AppCard(
            child: VCol(gap: 12, [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const IconSquare(LucideIcons.car, size: 48, iconSize: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.partsLabel} · ${r.car}', style: tx(15, w: w6)),
                    Text([r.condition, if (r.categoriesLabel.isNotEmpty) r.categoriesLabel, if (r.notes != null) '«${r.notes}»'].join(' · '), style: tx(12, c: AppColors.mute)),
                    Text('${r.buyer?.displayName ?? 'عميل'} · ${fmtAgo(r.createdAt)}', style: tx(11, c: AppColors.mute)),
                  ]),
                ),
              ]),
              if (r.images.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final u in r.images) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: PartThumb(width: 96, height: 80, radius: 12, imageUrl: u)),
                  ]),
                ),
              Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (r.city != null) MetaItem(LucideIcons.mapPin, r.city!),
                MetaItem(LucideIcons.users, r.liveOffers.isEmpty ? 'لا عروض بعد' : '${r.liveOffers.length} عروض'),
                if (tab == 0) StatusBadge.amber(fmtLeft(r.expiresAt), icon: LucideIcons.clock),
                if (tab == 1) StatusBadge(mine(r)!.status == 'rejected' ? 'لم يُقبل' : 'عرضك ${fmtMoney(mine(r)!.price)}'),
                if (tab == 2) const StatusBadge.teal('مقبول', icon: LucideIcons.check),
              ]),
              if (tab == 0)
                Row(children: [
                  Expanded(child: AppButton('قدّم عرض سعر', icon: LucideIcons.tag, height: 46, fs: 15, onTap: () async {
                    await context.push('/m/offer/${r.id}');
                    ref.invalidate(customerRequestsProvider);
                  })),
                  const SizedBox(width: 10),
                  AppButton('مراسلة', v: BtnV.out2, height: 46, fs: 14, expand: false, onTap: () => openChat(context, r.buyerId)),
                ]),
              if (tab == 2) AppButton('طلبات البيع', icon: LucideIcons.arrowLeft, v: BtnV.out2, height: 46, fs: 14, onTap: () => context.push('/m/sales')),
            ]),
          ),
      ],
    );
  }
}

// ───────────────── إعلاناتي ─────────────────

class ListingsManagerScreen extends ConsumerStatefulWidget {
  const ListingsManagerScreen({super.key});
  @override
  ConsumerState<ListingsManagerScreen> createState() => _ListingsManagerScreenState();
}

class _ListingsManagerScreenState extends ConsumerState<ListingsManagerScreen> {
  int filter = 0;
  String q = '';

  /// تمييز الإعلان في أعلى القائمة لمدة ساعتين (من رصيد الباقة)
  Future<void> _boost(Listing l) async {
    Map<String, dynamic> qv;
    try {
      qv = await Api.boostQuota();
    } catch (e) {
      if (mounted) showToast(context, errMsg(e));
      return;
    }
    if (!mounted) return;
    final quota = (qv['quota'] ?? 0) as int, left = (qv['left'] ?? 0) as int, hours = (qv['hours'] ?? 2) as num;
    showAppSheet(
      context,
      VCol(gap: 12, [
        Text('تمييز «${l.title}»', style: tx(18, w: w6)),
        if (quota == 0) ...[
          Text('تمييز الإعلانات في أعلى القائمة متاح في باقة لولو برو (5 إعلانات) ولولو برو ماكس (10 إعلانات).', style: tx(14, c: AppColors.ink2)),
          AppButton('شوف الباقات', onTap: () {
            Navigator.pop(context);
            context.push('/m/subscription');
          }),
        ] else ...[
          Text('يظهر إعلانك أعلى القائمة لمدة ${hours.toInt()} ساعة، وبعدها يرجع لترتيبه العادي.', style: tx(14, c: AppColors.ink2)),
          InfoBox('رصيدك: $left من $quota'),
          AppButton(left > 0 ? 'ميّز الإعلان الآن' : 'خلص رصيد التمييز', icon: LucideIcons.star, disabled: left <= 0, onTap: () async {
            Navigator.pop(context);
            if (await run(context, () => Api.boostListing(l.id), success: 'صار إعلانك مميز لمدة ${hours.toInt()} ساعة')) ref.invalidate(myListingsProvider);
          }),
        ],
      ]),
    );
  }

  Widget _status(Listing l) => switch (l.status) {
        'active' => l.boosted
            ? StatusBadge('مميز${l.featuredUntil != null ? ' حتى ${fmtTime(l.featuredUntil!)}' : ''}', icon: LucideIcons.star)
            : (l.quantity <= 1 ? const StatusBadge('نشط · قاربت تنفد', icon: LucideIcons.alertCircle) : const StatusBadge.teal('نشط')),
        'paused' => const StatusBadge.grey('موقوف'),
        'sold' => const StatusBadge.teal('مباع', icon: LucideIcons.check),
        _ => const StatusBadge.grey('مسودة'),
      };

  Widget _item(Listing l) => AppCard(
        onTap: () => context.push('/part/${l.id}'),
        child: VCol(gap: 12, [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PartThumb(width: 84, height: 84, radius: 14, imageUrl: l.cover),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.title, style: tx(15, w: w5)),
                Text(l.auction ? 'على السوم${l.topBid != null ? ' · أعلى ${fmtMoney(l.topBid!)}' : ''}' : fmtMoney(l.price ?? 0), style: tx(16, w: w6, c: l.auction ? AppColors.pri : AppColors.teal)),
                const SizedBox(height: 4),
                Wrap(spacing: 12, children: [
                  MetaItem(LucideIcons.eye, '${l.views}'),
                  MetaItem(LucideIcons.package, fmtQty(l.quantity)),
                  if (l.auction) MetaItem(LucideIcons.gavel, '${l.bidsCount}'),
                ]),
                const SizedBox(height: 4),
                _status(l),
              ]),
            ),
          ]),
          Row(children: [
            Expanded(child: AppButton('تعديل', icon: LucideIcons.pencil, iconFirst: true, v: BtnV.out2, height: 40, fs: 13, radius: 12, onTap: () async {
              await context.push('/sell?edit=${l.id}');
              ref.invalidate(myListingsProvider);
            })),
            const SizedBox(width: 8),
            Expanded(
                child: AppButton(l.status == 'paused' || l.status == 'draft' ? 'تفعيل' : 'إيقاف',
                    icon: LucideIcons.pause, iconFirst: true, v: BtnV.ink, height: 40, fs: 13, radius: 12, disabled: l.status == 'sold', onTap: () async {
              await run(context, () => Api.updateListing(l.id, {'status': l.status == 'active' ? 'paused' : 'active'}));
              ref.invalidate(myListingsProvider);
            })),
            if (l.status == 'active' && !l.boosted) ...[
              const SizedBox(width: 8),
              Expanded(child: AppButton('تمييز', icon: LucideIcons.star, iconFirst: true, v: BtnV.out, height: 40, fs: 13, radius: 12, onTap: () => _boost(l))),
            ],
            const SizedBox(width: 8),
            Expanded(child: AppButton('حذف', icon: LucideIcons.trash2, iconFirst: true, v: BtnV.red, height: 40, fs: 13, radius: 12, onTap: () async {
              final yes = await showAppSheet<bool>(
                context,
                VCol(gap: 12, [
                  Text('حذف «${l.title}»؟', style: tx(18, w: w6)),
                  AppButton('حذف نهائي', v: BtnV.red, onTap: () => Navigator.pop(context, true)),
                  AppButton('إلغاء', v: BtnV.out2, onTap: () => Navigator.pop(context, false)),
                ]),
              );
              if (yes != true || !mounted) return;
              await run(context, () => Api.deleteListing(l.id), success: 'تم حذف الإعلان');
              ref.invalidate(myListingsProvider);
            })),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(myListingsProvider);
    final all = (v.valueOrNull ?? const <Listing>[]).where((l) => q.isEmpty || l.title.contains(q)).toList();
    final groups = [
      all,
      all.where((l) => l.status == 'active').toList(),
      all.where((l) => l.status == 'paused' || l.status == 'draft').toList(),
      all.where((l) => l.status == 'sold').toList(),
    ];
    final labels = ['الكل', 'نشطة', 'موقوفة', 'مباعة'];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(title: 'إعلاناتي', actions: [
            HeaderIcon(LucideIcons.plus, size: 26, color: AppColors.pri, onTap: () async {
              await context.push('/sell');
              ref.invalidate(myListingsProvider);
            }),
          ]),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: AppField(hint: 'ابحث في إعلاناتك...', icon: LucideIcons.search, onChanged: (t) => setState(() => q = t.trim()))),
          ChipScroller(children: [
            for (var i = 0; i < 4; i++) AppChip('${labels[i]} (${groups[i].length})', selected: filter == i, px: 14, py: 7, onTap: () => setState(() => filter = i)),
          ]),
          Expanded(
            child: v.isLoading
                ? const Loading()
                : ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 40), children: [
                    if (groups[filter].isEmpty)
                      EmptyBox(LucideIcons.package, 'ما فيه إعلانات هنا',
                          action: AppButton('أضف إعلان', icon: LucideIcons.plus, iconFirst: true, expand: false, radius: 999, height: 46, fs: 15, onTap: () => context.push('/sell'))),
                    for (final l in groups[filter]) ...[_item(l), const SizedBox(height: 14)],
                  ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── باقة لولو ─────────────────

final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) => Api.settings());

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  Widget _plan(BuildContext context, String name, String price, List<String> feats, {bool hl = false, bool current = false, required String cta}) {
    final fg = hl ? AppColors.white : AppColors.ink;
    return Container(
      decoration: BoxDecoration(
        gradient: hl ? AppColors.gradient : null,
        color: hl ? null : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: hl ? null : Border.all(color: current ? AppColors.pri : AppColors.chipB, width: current ? 1.5 : 1),
      ),
      padding: const EdgeInsets.all(20),
      child: VCol(gap: 10, [
        Row(children: [
          Icon(hl ? LucideIcons.crown : LucideIcons.award, size: 24, color: hl ? const Color(0xFFFFD98A) : AppColors.pri),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: tx(19, w: w7, c: fg))),
          if (hl) const StatusBadge('الأكثر طلباً', bg: AppColors.white),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: tx(30, w: w7, c: fg, h: 1.2)),
          const SizedBox(width: 6),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(price == '0' ? 'مجاناً' : 'ر.س / شهرياً', style: tx(13, c: hl ? const Color(0xFFF6D9CD) : AppColors.mute))),
        ]),
        for (final f in feats)
          Row(children: [
            Icon(LucideIcons.checkCircle, size: 18, color: hl ? AppColors.white : AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: tx(14, c: hl ? AppColors.white : AppColors.ink2))),
          ]),
        const SizedBox(height: 4),
        AppButton(cta, v: hl ? BtnV.white : (current ? BtnV.ink : BtnV.out), height: 48, radius: 999, fs: 15,
            onTap: current ? null : () => showToast(context, 'الاشتراك يتفعّل مع ربط بوابة الدفع')),
      ]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(myProfileProvider).valueOrNull;
    final st = ref.watch(settingsProvider).valueOrNull ?? const {};
    String n(String k, String d) {
      final v = st[k];
      if (v == null) return d;
      final x = num.tryParse('$v');
      return x == null ? d : (x % 1 == 0 ? '${x.toInt()}' : '$x');
    }

    final prices = st['plan_prices'] is Map ? Map<String, dynamic>.from(st['plan_prices']) : const <String, dynamic>{};
    String price(String k, String d) => prices[k] == null ? d : '${prices[k]}';
    final today = ref.watch(myListingsProvider).valueOrNull?.where((l) {
          final c = l.createdAt;
          final now = DateTime.now();
          return c != null && c.year == now.year && c.month == now.month && c.day == now.day;
        }).length ??
        0;
    final plan = p?.plan ?? 'free';
    final hours = n('boost_hours', '2');
    return AppPage(
      header: const AppHeader(title: 'باقة لولو'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            const Icon(LucideIcons.award, size: 28, color: AppColors.pri),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('باقتك الحالية', style: tx(12, c: AppColors.mute)),
                Text(p?.planLabel ?? 'لولو المجانية', style: tx(17, w: w6)),
              ]),
            ),
            if (plan == 'free') Text('اليوم: $today من ${n('free_listings_per_day', '5')}', style: tx(13, w: w5, c: AppColors.ink2)),
          ]),
        ),
        _plan(
            context,
            'لولو المجانية',
            '0',
            [
              '${n('free_listings_per_day', '5')} إعلانات قطع يومياً',
              'استقبال ${n('free_requests_per_month', '50')} طلب من العملاء شهرياً',
              'عمولة ${n('commission_free', '6')}% على المبيعات',
            ],
            current: plan == 'free',
            cta: plan == 'free' ? 'باقتك الحالية' : 'الرجوع للمجانية'),
        _plan(
            context,
            'لولو برو',
            price('pro', '99'),
            [
              'إعلانات قطع بلا حدود',
              'طلبات العملاء بلا حدود (حسب تخصصك)',
              'عمولة ${n('commission_pro', '4')}% فقط',
              'شارة «تاجر موثّق» بعد اعتماد المستندات',
              'تمييز ${n('boost_quota_pro', '5')} إعلانات في أعلى القائمة ($hours ساعة لكل إعلان)',
            ],
            hl: true,
            current: plan == 'pro',
            cta: plan == 'pro' ? 'باقتك الحالية' : 'اشترك في برو'),
        _plan(
            context,
            'لولو برو ماكس',
            price('pro_max', '199'),
            [
              'كل مزايا لولو برو',
              'رفع حتى ${n('pro_max_items', '500')} صنف قطع',
              'أولوية في طلبات العملاء (حسب تخصصك)',
              'عمولة ${n('commission_pro_max', '4')}%',
              'تمييز ${n('boost_quota_pro_max', '10')} إعلانات في أعلى القائمة ($hours ساعة لكل إعلان)',
            ],
            current: plan == 'pro_max',
            cta: plan == 'pro_max' ? 'باقتك الحالية' : 'اشترك في برو ماكس'),
        Center(child: Text('تقدر تلغي اشتراكك بأي وقت', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}
