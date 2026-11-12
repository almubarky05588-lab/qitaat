import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/mock.dart';
import 'account.dart' show myListingsProvider;
import 'catalog.dart' show openChat;
import 'checkout.dart' show orderProvider;
import 'orders.dart' show orderBadge;
import 'requests.dart' show pickFromSheet;

Widget _gradientCard({required List<Widget> children}) => ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: Stack(children: [
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
          const Positioned(left: 0, right: 0, bottom: 0, child: SaduPattern(color: AppColors.white, height: 8, tooth: 12, opacity: 0.14)),
        ]),
      ),
    );

Widget _glass(Widget child, {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8), double radius = 12}) => Container(
      padding: padding,
      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(radius)),
      child: child,
    );

// ───────────────── T03 · لوحة المتجر ─────────────────

final statsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, days) => Api.merchantStats(days));

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int period = 1;

  Widget _stat(IconData ic, String v, String t, bool teal) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconSquare(ic, size: 38, iconSize: 20, radius: 12, bg: teal ? AppColors.tealBg : AppColors.pink, color: teal ? AppColors.teal : AppColors.pri),
            const SizedBox(height: 6),
            Text(v, style: tx(22, w: w7, h: 1.3)),
            Text(t, style: tx(12, c: AppColors.mute)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final days = const [1, 7, 30][period];
    final v = ref.watch(statsProvider(days));
    final label = const ['اليوم', 'هذا الأسبوع', 'هذا الشهر'][period];
    return AppPage(
      header: const AppHeader(title: 'لوحة المتجر'),
      children: [
        SegTabs(items: const ['اليوم', 'الأسبوع', 'الشهر'], selected: period, onChanged: (i) => setState(() => period = i)),
        AsyncBody<Map<String, dynamic>>(v, (s) {
          num n(String k) => num.tryParse('${s[k] ?? 0}') ?? 0;
          final sent = n('offers_sent'), acc = n('offers_accepted');
          final rate = sent == 0 ? 0 : (acc * 100 / sent).round();
          final daily = (s['daily'] as List? ?? const []).map((e) => double.tryParse('$e') ?? 0.0).toList();
          final double maxD = daily.isEmpty ? 1.0 : daily.reduce((a, b) => a > b ? a : b);
          final today = DateTime.now();
          const dayNames = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
          return VCol(gap: 16, [
            _gradientCard(children: [
              Text('أرباح $label', style: tx(13, c: AppColors.white.withOpacity(0.85))),
              Text(ltr(fmtMoney(n('earnings'))), style: tx(32, w: w7, c: AppColors.white, h: 1.3)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _glass(
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.clock, size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text('معلّق ${fmtMoney(n('pending'))} لين يستلم المشترين', style: tx(12, w: w5, c: AppColors.white)),
                  ]),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  radius: 999,
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('قابل للتحويل', style: tx(12, c: AppColors.white.withOpacity(0.8))),
                    Text(ltr(fmtMoney(n('available'))), style: tx(17, w: w6, c: AppColors.white)),
                  ]),
                ),
                AppButton('تحويل للآيبان', v: BtnV.white, radius: 999, height: 42, fs: 14, expand: false, onTap: () => context.push('/m/earnings')),
              ]),
              const SizedBox(height: 6),
            ]),
            Row(children: [
              _stat(LucideIcons.inbox, '${n('new_requests')}', 'طلبات جديدة تناسبك', false),
              const SizedBox(width: 12),
              _stat(LucideIcons.tag, '$sent', 'عرض سعر أرسلته', true),
            ]),
            Row(children: [
              _stat(LucideIcons.percent, '$rate%', 'نسبة قبول عروضك', true),
              const SizedBox(width: 12),
              _stat(LucideIcons.eye, '${n('views')}', 'مشاهدة لإعلاناتك', false),
            ]),
            AppCard(
              child: VCol(gap: 14, [
                Row(children: [
                  Expanded(child: Text('المبيعات اليومية', style: tx(16, w: w6))),
                  Text('آخر 7 أيام', style: tx(13, c: AppColors.mute)),
                ]),
                SizedBox(
                  height: 150,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (var i = 0; i < daily.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Container(
                            height: 6.0 + 114.0 * (maxD == 0 ? 0.0 : daily[i] / maxD),
                            decoration: BoxDecoration(color: i == daily.length - 1 ? AppColors.pri : const Color(0xFFEBCFC2), borderRadius: BorderRadius.circular(8)),
                          ),
                          const SizedBox(height: 6),
                          Text(dayNames[today.subtract(Duration(days: daily.length - 1 - i)).weekday - 1], style: tx(10, c: AppColors.mute), maxLines: 1),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
            AppCard(
              child: VCol(gap: 10, [
                Row(children: [
                  const Icon(LucideIcons.package, size: 22, color: AppColors.ink2),
                  const SizedBox(width: 10),
                  Expanded(child: Text('المخزون', style: tx(16, w: w6))),
                  GestureDetector(onTap: () => context.push('/m/listings'), child: Text('إدارة ←', style: tx(13, w: w5, c: AppColors.pri))),
                ]),
                Row(children: [
                  for (final it in [('${n('active')}', 'إعلان نشط', AppColors.ink), ('${n('low_stock')}', 'قاربت تنفد', AppColors.pri), ('${n('sold')}', 'مباعة', AppColors.teal)]) ...[
                    if (it.$2 != 'إعلان نشط') const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                        child: Column(children: [
                          Text(it.$1, style: tx(18, w: w7, c: it.$3, h: 1.3)),
                          Text(it.$2, style: tx(11, c: AppColors.mute)),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
          ]);
        }, onRetry: () => ref.invalidate(statsProvider(days))),
      ],
    );
  }
}

// ───────────────── T04 · طلبات العملاء ─────────────────

final customerRequestsProvider = FutureProvider<List<PartRequest>>((ref) => Api.customerRequests());

class CustomerRequestsScreen extends ConsumerStatefulWidget {
  const CustomerRequestsScreen({super.key});
  @override
  ConsumerState<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends ConsumerState<CustomerRequestsScreen> {
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
      header: const AppHeader(title: 'طلبات العملاء وعروضي'),
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
                    Text([r.condition, if (r.category != null) r.category!, if (r.notes != null) '«${r.notes}»'].join(' · '), style: tx(12, c: AppColors.mute)),
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
              Row(children: [
                if (r.city != null) MetaItem(LucideIcons.mapPin, r.city!),
                if (r.city != null) const SizedBox(width: 12),
                MetaItem(LucideIcons.users, r.liveOffers.isEmpty ? 'لا عروض بعد' : '${r.liveOffers.length} عروض'),
                const Spacer(),
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

// ───────────────── T05 · تقديم عرض سعر ─────────────────

class SubmitOfferScreen extends ConsumerStatefulWidget {
  final String id;
  const SubmitOfferScreen({super.key, required this.id});
  @override
  ConsumerState<SubmitOfferScreen> createState() => _SubmitOfferScreenState();
}

class _SubmitOfferScreenState extends ConsumerState<SubmitOfferScreen> {
  bool inclShipping = true, busy = false;
  String condition = 'جديد أصلي', price = '', delivery = '2-3 أيام', warranty = 'بدون ضمان', note = '';
  List<String> images = [];
  late Future<PartRequest?> future = Api.request(widget.id);

  Future<void> _send() async {
    final p = num.tryParse(price.replaceAll(',', '').trim());
    if (p == null || p <= 0) {
      showToast(context, 'اكتب سعرك');
      return;
    }
    setState(() => busy = true);
    final ok = await run(context, () => Api.submitOffer({
          'request_id': widget.id,
          'price': p,
          'includes_shipping': inclShipping,
          'condition': condition,
          'delivery_time': delivery,
          'warranty': warranty == 'بدون ضمان' ? null : warranty,
          'note': note.trim().isEmpty ? null : note.trim(),
          'images': images,
        }), success: 'وصل عرضك للعميل');
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PartRequest?>(
      future: future,
      builder: (c, s) {
        final r = s.data;
        return AppPage(
          header: const AppHeader(title: 'تقديم عرض سعر'),
          children: [
            if (!s.hasData && !s.hasError) const Loading(),
            if (s.hasError) ErrorBox(s.error!),
            if (s.hasData && r == null) const EmptyBox(LucideIcons.inbox, 'الطلب غير متاح'),
            if (r != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
                child: VCol(gap: 6, [
                  Row(children: [
                    Expanded(child: Text('طلب العميل', style: tx(13, c: AppColors.mute))),
                    StatusBadge.amber(fmtLeft(r.expiresAt), icon: LucideIcons.clock),
                  ]),
                  Text(r.title, style: tx(16, w: w5)),
                  if (r.notes != null) Text('ملاحظة العميل: «${r.notes}»', style: tx(13, c: AppColors.ink2)),
                  if (r.images.isNotEmpty)
                    SizedBox(
                      height: 64,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        for (final u in r.images) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: PartThumb(width: 64, height: 64, radius: 10, imageUrl: u)),
                      ]),
                    ),
                ]),
              ),
              LabeledField(
                'سعرك',
                AppField(hint: '0', ltrText: true, focus: true, keyboard: TextInputType.number, onChanged: (v) => price = v, trailing: Text('ر.س', style: tx(15, w: w5, c: AppColors.mute))),
              ),
              ToggleRow(title: 'السعر شامل الشحن', sub: 'العميل يشوف السعر النهائي بدون مفاجآت', value: inclShipping, onChanged: (v) => setState(() => inclShipping = v)),
              LabeledField('حالة القطعة (أصلية / مستعملة)', SelectGrid(options: Mock.sellConditions, selected: condition, onChanged: (v) => setState(() => condition = v)), required: true),
              Row(children: [
                Expanded(
                    child: LabeledField(
                        'مدة التوصيل',
                        AppField(
                            key: ValueKey('d$delivery'),
                            value: delivery,
                            chevron: true,
                            onTap: () => pickFromSheet(context, 'مدة التوصيل', const ['نفس اليوم', 'يوم واحد', '2-3 أيام', '3-5 أيام', 'أسبوع'], (v) => setState(() => delivery = v))))),
                const SizedBox(width: 10),
                Expanded(
                    child: LabeledField(
                        'الضمان',
                        AppField(
                            key: ValueKey('w$warranty'),
                            value: warranty,
                            chevron: true,
                            onTap: () => pickFromSheet(context, 'الضمان', const ['بدون ضمان', '3 أشهر', '6 أشهر', 'سنة', 'ضمان الوكالة'], (v) => setState(() => warranty = v))))),
              ]),
              LabeledField('صور القطعة', PhotoStrip(urls: images, max: 6, onChanged: (v) => setState(() => images = v))),
              LabeledField('رسالة للعميل (اختياري)', AppField(hint: 'مثال: متوفر أصلي وكالة، نشحن اليوم', area: true, onChanged: (v) => note = v)),
              const InfoBox('العميل يقارن عرضك مع باقي الموردين — السعر والتقييم وسرعة التوصيل يفرقون'),
              busy ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri))) : AppButton('أرسل العرض', icon: LucideIcons.send, onTap: _send),
            ],
          ],
        );
      },
    );
  }
}

// ───────────────── T06 · أبيع قطعة ─────────────────

class SellPartScreen extends ConsumerStatefulWidget {
  final String? editId;
  const SellPartScreen({super.key, this.editId});
  @override
  ConsumerState<SellPartScreen> createState() => _SellPartScreenState();
}

class _SellPartScreenState extends ConsumerState<SellPartScreen> {
  String title = '', brand = 'تويوتا', model = 'كامري', yFrom = '2020', yTo = '2023', price = '', qty = '1', desc = '';
  String? cat = 'بودي';
  String condition = 'جديد أصلي', method = 'سعر محدد', duration = '3 أيام';
  final delivery = <String>{'شحن لكل المدن', 'استلام من المحل'};
  List<String> images = [];
  bool busy = false, loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      Api.listing(widget.editId!).then((l) {
        if (l == null || !mounted) return;
        setState(() {
          title = l.title;
          brand = l.brand ?? brand;
          model = l.model ?? model;
          yFrom = '${l.yearFrom ?? yFrom}';
          yTo = '${l.yearTo ?? yTo}';
          cat = l.category;
          condition = l.condition;
          method = l.auction ? 'على السوم' : 'سعر محدد';
          price = '${l.auction ? (l.startPrice ?? '') : (l.price ?? '')}';
          qty = '${l.quantity}';
          desc = l.description ?? '';
          images = [...l.images];
          delivery
            ..clear()
            ..addAll([if (l.delivery.contains('shipping')) 'شحن لكل المدن', if (l.delivery.contains('pickup')) 'استلام من المحل']);
          loaded = true;
        });
      });
    } else {
      loaded = true;
    }
  }

  Future<void> _publish({bool draft = false}) async {
    final auction = method == 'على السوم';
    final p = num.tryParse(price.trim());
    if (title.trim().isEmpty) {
      showToast(context, 'اكتب اسم القطعة');
      return;
    }
    if (!auction && (p == null || p <= 0)) {
      showToast(context, 'اكتب السعر');
      return;
    }
    if (delivery.isEmpty) {
      showToast(context, 'اختر طريقة التسليم');
      return;
    }
    setState(() => busy = true);
    final days = {'يوم': 1, '3 أيام': 3, 'أسبوع': 7}[duration]!;
    final data = {
      'title': title.trim(),
      'brand': brand,
      'model': model,
      'year_from': int.tryParse(yFrom),
      'year_to': int.tryParse(yTo),
      'category': cat,
      'condition': condition,
      'sale_type': auction ? 'auction' : 'fixed',
      'price': auction ? null : p,
      'start_price': auction ? p : null,
      'auction_ends_at': auction ? DateTime.now().add(Duration(days: days)).toUtc().toIso8601String() : null,
      'quantity': int.tryParse(qty) ?? 1,
      'delivery': [if (delivery.contains('شحن لكل المدن')) 'shipping', if (delivery.contains('استلام من المحل')) 'pickup'],
      'city': ref.read(myProfileProvider).valueOrNull?.city,
      'description': desc.trim().isEmpty ? null : desc.trim(),
      'images': images,
      'status': draft ? 'draft' : 'active',
    };
    final ok = await run(context, () async {
      if (widget.editId != null) {
        await Api.updateListing(widget.editId!, data);
      } else {
        await Api.createListing(data);
      }
    }, success: draft ? 'انحفظ كمسودة' : (widget.editId != null ? 'تم حفظ التعديلات' : 'تم نشر إعلانك'));
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ref.invalidate(myListingsProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = method == 'على السوم';
    if (!loaded) return const Scaffold(backgroundColor: AppColors.bg, body: Loading());
    final years = [for (var y = DateTime.now().year + 1; y >= 1990; y--) '$y'];
    return AppPage(
      header: AppHeader(title: widget.editId != null ? 'تعديل الإعلان' : 'أبيع قطعة'),
      children: [
        LabeledField('صور القطعة', PhotoStrip(urls: images, onChanged: (v) => setState(() => images = v)), help: 'أضف حتى 8 صور — الصورة الأولى تكون الغلاف'),
        LabeledField('اسم القطعة', AppField(hint: 'مثال: صدام أمامي', value: title.isEmpty ? null : title, onChanged: (v) => title = v)),
        Row(children: [
          Expanded(
              child: LabeledField(
                  'الماركة',
                  AppField(
                      key: ValueKey('b$brand'),
                      value: brand,
                      chevron: true,
                      onTap: () => pickFromSheet(context, 'الماركة', Mock.allBrands, (v) => setState(() {
                            brand = v;
                            model = Mock.modelsOf(v).first;
                          }))))),
          const SizedBox(width: 10),
          Expanded(child: LabeledField('الموديل', AppField(key: ValueKey('m$model'), value: model, chevron: true, onTap: () => pickFromSheet(context, 'الموديل', Mock.modelsOf(brand), (v) => setState(() => model = v))))),
        ]),
        Row(children: [
          Expanded(child: LabeledField('من سنة', AppField(key: ValueKey('f$yFrom'), value: yFrom, chevron: true, onTap: () => pickFromSheet(context, 'من سنة', years, (v) => setState(() => yFrom = v))))),
          const SizedBox(width: 10),
          Expanded(child: LabeledField('إلى سنة', AppField(key: ValueKey('t$yTo'), value: yTo, chevron: true, onTap: () => pickFromSheet(context, 'إلى سنة', years, (v) => setState(() => yTo = v))))),
        ]),
        LabeledField('التصنيف', ChipWrap(Mock.categories, selected: {if (cat != null) cat!}, onTap: (c) => setState(() => cat = cat == c ? null : c))),
        LabeledField('حالة القطعة (أصلية / مستعملة)', SelectGrid(options: Mock.sellConditions, selected: condition, onChanged: (v) => setState(() => condition = v)), required: true),
        LabeledField(
          'طريقة البيع',
          SelectGrid(
            options: const ['سعر محدد', 'على السوم'],
            subs: const {'سعر محدد': 'المشتري يشتري مباشرة', 'على السوم': 'المشترين يسومون وأنت تختار'},
            selected: method,
            onChanged: (v) => setState(() => method = v),
          ),
          required: true,
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: LabeledField(
              auction ? 'سعر مبدئي (اختياري)' : 'السعر',
              AppField(
                  key: ValueKey('p$method'),
                  hint: '0',
                  value: price.isEmpty ? null : price,
                  ltrText: true,
                  keyboard: TextInputType.number,
                  onChanged: (v) => price = v,
                  trailing: Text('ر.س', style: tx(15, w: w5, c: AppColors.mute))),
              help: auction ? 'السومات تبدأ من هذا السعر — اتركه فاضي لو تبي السوم مفتوح' : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: LabeledField('الكمية', AppField(value: qty, ltrText: true, keyboard: TextInputType.number, onChanged: (v) => qty = v))),
        ]),
        if (auction)
          LabeledField(
            'مدة السوم',
            Wrap(spacing: 8, children: [
              for (final d in const ['يوم', '3 أيام', 'أسبوع']) AppChip(d, selected: duration == d, px: 18, onTap: () => setState(() => duration = d)),
            ]),
          ),
        LabeledField(
          'طريقة التسليم',
          Row(children: [
            for (final d in const ['شحن لكل المدن', 'استلام من المحل']) ...[
              if (d != 'شحن لكل المدن') const SizedBox(width: 10),
              Expanded(child: SelectCell(d, selected: delivery.contains(d), onTap: () => setState(() => delivery.contains(d) ? delivery.remove(d) : delivery.add(d)))),
            ],
          ]),
        ),
        LabeledField('الوصف', AppField(hint: 'اكتب تفاصيل القطعة، حالتها، وأي ملاحظات...', value: desc.isEmpty ? null : desc, area: true, onChanged: (v) => desc = v)),
        busy
            ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
            : AppButton(widget.editId != null ? 'حفظ التعديلات' : 'انشر الإعلان', icon: LucideIcons.check, onTap: _publish),
        if (widget.editId == null) Center(child: GestureDetector(onTap: () => _publish(draft: true), child: Text('حفظ كمسودة', style: tx(14, w: w5, c: AppColors.teal)))),
      ],
    );
  }
}

// ───────────────── T07 · إدارة إعلاناتي ─────────────────

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});
  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  int filter = 0;
  String q = '';

  Widget _status(Listing l) => switch (l.status) {
        'active' => l.quantity <= 1 ? const StatusBadge('نشط · قاربت تنفد', icon: LucideIcons.alertCircle) : const StatusBadge.teal('نشط'),
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
                  MetaItem(LucideIcons.package, '${l.quantity}'),
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

// ───────────────── T07ب · السومات على إعلاناتي (مساوماتي) ─────────────────

final myAuctionsProvider = FutureProvider<List<(Listing, List<Bid>)>>((ref) async {
  final ls = await Api.myAuctions();
  final out = <(Listing, List<Bid>)>[];
  for (final l in ls) {
    out.add((l, await Api.bids(l.id)));
  }
  return out;
});

class ListingBidsScreen extends ConsumerWidget {
  const ListingBidsScreen({super.key});

  Widget _bid(BuildContext context, WidgetRef ref, Listing l, Bid b, bool top) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: top ? AppColors.pink : AppColors.bg, borderRadius: BorderRadius.circular(16), border: top ? Border.all(color: AppColors.pinkB) : null),
        child: VCol(gap: 10, [
          Row(children: [
            Avatar(size: 36, letter: b.bidder?.initial ?? '؟', bg: AppColors.white, color: top ? AppColors.pri : AppColors.mute),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(b.bidder?.displayName ?? 'مستخدم', style: tx(14, w: w5)),
                  if (top) const SizedBox(width: 6),
                  if (top) const StatusBadge('الأعلى', icon: LucideIcons.star),
                ]),
                Text(fmtAgo(b.createdAt), style: tx(11, c: AppColors.mute)),
              ]),
            ),
            Text(fmtMoney(b.amount), style: tx(17, w: w7, c: top ? AppColors.pri : AppColors.ink)),
          ]),
          if (l.status == 'active')
            Row(children: [
              Expanded(child: AppButton('قبول السومة', icon: LucideIcons.check, height: 40, fs: 13, radius: 12, onTap: () async {
                if (await run(context, () => Api.acceptBid(b.id).then((_) {}), success: 'تم قبول السومة — بلّغنا المشتري يكمل الدفع')) {
                  ref.invalidate(myAuctionsProvider);
                  ref.invalidate(myListingsProvider);
                }
              })),
              const SizedBox(width: 8),
              Expanded(child: AppButton('رفض', v: BtnV.out2, height: 40, fs: 13, radius: 12, onTap: () async {
                await run(context, () => Api.rejectBid(b.id));
                ref.invalidate(myAuctionsProvider);
              })),
              const SizedBox(width: 8),
              AppButton('', icon: LucideIcons.messageSquare, v: BtnV.tealOut, height: 40, radius: 12, expand: false, onTap: () => openChat(context, b.bidderId, listingId: l.id)),
            ]),
          if (b.status == 'accepted') const StatusBadge.teal('مقبولة', icon: LucideIcons.check),
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(myAuctionsProvider);
    return AppPage(
      header: const AppHeader(title: 'مساوماتي'),
      gap: 14,
      children: [
        AsyncBody<List<(Listing, List<Bid>)>>(v, (items) {
          if (items.isEmpty) {
            return EmptyBox(LucideIcons.gavel, 'ما عندك إعلانات على السوم',
                action: AppButton('أضف قطعة على السوم', icon: LucideIcons.plus, iconFirst: true, expand: false, radius: 999, height: 46, fs: 15, onTap: () => context.push('/sell')));
          }
          return VCol(gap: 14, [
            for (final it in items)
              AppCard(
                child: VCol(gap: 12, [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    PartThumb(width: 72, height: 72, radius: 14, imageUrl: it.$1.cover),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(it.$1.title, style: tx(15, w: w5)),
                        const SizedBox(height: 3),
                        StatusBadge(it.$1.status == 'sold' ? 'تم البيع' : 'على السوم · ${fmtLeft(it.$1.auctionEndsAt)}', icon: LucideIcons.gavel),
                        const SizedBox(height: 3),
                        Text(it.$1.startPrice != null ? 'سعر مبدئي ${fmtMoney(it.$1.startPrice!)} · ${it.$2.length} سومات' : '${it.$2.length} سومات',
                            style: tx(12, c: AppColors.mute)),
                      ]),
                    ),
                  ]),
                  if (it.$2.isNotEmpty) const HLine(),
                  if (it.$2.isEmpty) Text('ما وصلت سومات للحين', style: tx(13, c: AppColors.mute)),
                  for (var i = 0; i < it.$2.length; i++) _bid(context, ref, it.$1, it.$2[i], i == 0),
                ]),
              ),
          ]);
        }, onRetry: () => ref.invalidate(myAuctionsProvider)),
      ],
    );
  }
}

// ───────────────── T08 · طلبات البيع ─────────────────

final salesProvider = FutureProvider<List<Order>>((ref) => Api.myOrders(asSeller: true));

class SalesOrdersScreen extends ConsumerStatefulWidget {
  const SalesOrdersScreen({super.key});
  @override
  ConsumerState<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends ConsumerState<SalesOrdersScreen> {
  int tab = 1;

  Widget _order(Order o) {
    final buttons = <Widget>[];
    if (o.status == 'paid' || o.status == 'preparing') {
      buttons.add(AppButton('صوّر القطعة وجهّز', icon: LucideIcons.camera, height: 44, fs: 14, onTap: () async {
        if (o.status == 'paid') await Api.sellerSetStatus(o.id, 'preparing').catchError((_) {});
        if (!mounted) return;
        await context.push('/m/document/${o.id}');
        ref.invalidate(salesProvider);
      }));
      buttons.add(AppButton('مراسلة المشتري', icon: LucideIcons.messageSquare, iconFirst: true, v: BtnV.out2, height: 44, fs: 14, onTap: () => openChat(context, o.buyerId, listingId: o.listingId)));
    } else if (o.status == 'awaiting_payment') {
      buttons.add(AppButton('مراسلة المشتري', icon: LucideIcons.messageSquare, iconFirst: true, v: BtnV.out2, height: 44, fs: 14, onTap: () => openChat(context, o.buyerId, listingId: o.listingId)));
      buttons.add(AppButton('إلغاء', v: BtnV.red, height: 44, fs: 14, onTap: () async {
        await run(context, () => Api.sellerSetStatus(o.id, 'cancelled'));
        ref.invalidate(salesProvider);
      }));
    } else if (o.status == 'shipped' || o.status == 'delivered') {
      buttons.add(AppButton('تفاصيل الطلب', icon: LucideIcons.truck, iconFirst: true, v: BtnV.out2, height: 44, fs: 14, onTap: () => context.push('/order/${o.id}')));
    }
    return AppCard(
      onTap: () => context.push('/order/${o.id}'),
      child: VCol(gap: 12, [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PartThumb(width: 72, height: 72, radius: 14, imageUrl: o.image ?? o.photo('front')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title, style: tx(15, w: w5)),
              Text('المشتري: ${o.buyer?.displayName ?? ''}${o.buyer?.city != null ? ' · ${o.buyer!.city}' : ''}', style: tx(12, c: AppColors.mute)),
              Text('${ltr(o.orderNo)}${o.paidAt != null ? ' · مدفوع' : ''}${o.carrier != null ? ' · ${o.carrier}' : ''}', style: tx(12, c: AppColors.mute)),
            ]),
          ),
          Text(fmtMoney(o.subtotal), style: tx(16, w: w6, c: AppColors.teal)),
        ]),
        Align(alignment: AlignmentDirectional.centerStart, child: orderBadge(o)),
        if (buttons.isNotEmpty)
          Row(children: [
            for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: buttons[i])],
          ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(salesProvider);
    final all = v.valueOrNull ?? const <Order>[];
    final groups = [
      all.where((o) => o.status == 'awaiting_payment').toList(),
      all.where((o) => o.status == 'paid' || o.status == 'preparing').toList(),
      all.where((o) => o.status == 'shipped').toList(),
      all.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList(),
    ];
    final labels = ['جديدة', 'قيد التجهيز', 'تم الشحن', 'مكتملة'];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(title: 'طلبات البيع'),
          ChipScroller(children: [
            for (var i = 0; i < 4; i++) AppChip('${labels[i]} (${groups[i].length})', selected: tab == i, px: 14, py: 7, onTap: () => setState(() => tab = i)),
          ]),
          Expanded(
            child: v.isLoading
                ? const Loading()
                : RefreshIndicator(
                    color: AppColors.pri,
                    onRefresh: () async => ref.invalidate(salesProvider),
                    child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 40), children: [
                      if (v.hasError) ErrorBox(v.error!, onRetry: () => ref.invalidate(salesProvider)),
                      if (groups[tab].isEmpty) const EmptyBox(LucideIcons.tag, 'ما فيه طلبات هنا'),
                      for (final o in groups[tab]) ...[_order(o), const SizedBox(height: 14)],
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── T08ب · توثيق القطعة قبل الشحن (4 اتجاهات) ─────────────────

class DocumentPhotosScreen extends ConsumerStatefulWidget {
  final String id;
  const DocumentPhotosScreen({super.key, required this.id});
  @override
  ConsumerState<DocumentPhotosScreen> createState() => _DocumentPhotosScreenState();
}

class _DocumentPhotosScreenState extends ConsumerState<DocumentPhotosScreen> {
  static const sides = [('front', 'الأمام'), ('back', 'الخلف'), ('right', 'الجانب الأيمن'), ('left', 'الجانب الأيسر')];
  final urls = <String, String>{};
  String carrier = 'سمسا', tracking = '';
  bool busy = false, init = false;

  Future<void> _shoot(String side) async {
    final u = await pickAndUpload(context);
    if (u == null) return;
    final ok = await run(context, () => Api.setOrderPhoto(widget.id, side, u));
    if (ok && mounted) setState(() => urls[side] = u);
  }

  Widget _slot((String, String) s) {
    final u = urls[s.$1];
    return GestureDetector(
      onTap: () => _shoot(s.$1),
      child: Column(children: [
        SizedBox(
          height: 140,
          child: u != null
              ? Stack(children: [
                  PartThumb(width: double.infinity, height: 140, radius: 18, imageUrl: u),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                      child: const Icon(LucideIcons.check, size: 14, color: AppColors.white),
                    ),
                  ),
                ])
              : LayoutBuilder(builder: (c, cons) => UploadBox(size: cons.maxWidth < 140 ? cons.maxWidth : 140, label: 'صوّر الآن', onTap: () => _shoot(s.$1))),
        ),
        const SizedBox(height: 8),
        Text(s.$2, style: tx(14, w: w5, c: u != null ? AppColors.ink : AppColors.pri)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ov = ref.watch(orderProvider(widget.id));
    final o = ov.valueOrNull;
    if (o != null && !init) {
      init = true;
      for (final p in o.photos) {
        urls[p.side] = p.url;
      }
    }
    final count = urls.length;
    return AppPage(
      header: const AppHeader(title: 'توثيق القطعة قبل الشحن'),
      children: [
        const InfoBox('لازم تصوّر القطعة من 4 اتجاهات قبل الشحن — الصور توصل للمشتري وتحميك وتحميه'),
        if (o == null) const Loading(),
        if (o != null) ...[
          AppCard(
            child: Row(children: [
              PartThumb(width: 64, height: 64, radius: 12, imageUrl: o.image ?? urls['front']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.title, style: tx(15, w: w5)),
                  Text('${ltr(o.orderNo)} · المشتري: ${o.buyer?.displayName ?? ''}', style: tx(12, c: AppColors.mute)),
                  const SizedBox(height: 4),
                  if (o.condition != null) ConditionBadge(o.condition!),
                ]),
              ),
            ]),
          ),
          Row(children: [
            Expanded(child: Text('صور القطعة', style: tx(16, w: w6))),
            Text('$count من 4', style: tx(14, w: w6, c: AppColors.pri)),
          ]),
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: i < count ? AppColors.teal : const Color(0xFFE8DDCF), borderRadius: BorderRadius.circular(3)))),
            ],
          ]),
          Row(children: [Expanded(child: _slot(sides[0])), const SizedBox(width: 12), Expanded(child: _slot(sides[1]))]),
          Row(children: [Expanded(child: _slot(sides[2])), const SizedBox(width: 12), Expanded(child: _slot(sides[3]))]),
          AppCard(
            child: VCol(gap: 8, [
              Text('نصائح للتصوير', style: tx(14, w: w6)),
              for (final t in const ['صوّر في مكان فيه إضاءة واضحة', 'خل القطعة كاملة داخل الصورة', 'وضّح أي رقم قطعة أو ملصق وكالة'])
                Row(children: [
                  const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: tx(13, c: AppColors.ink2))),
                ]),
            ]),
          ),
          if (o.status == 'paid' || o.status == 'preparing') ...[
            LabeledField('شركة الشحن', AppField(key: ValueKey(carrier), value: carrier, chevron: true, onTap: () => pickFromSheet(context, 'شركة الشحن', Mock.carriers, (v) => setState(() => carrier = v)))),
            LabeledField('رقم التتبع', AppField(hint: 'رقم بوليصة الشحن', ltrText: true, onChanged: (v) => tracking = v)),
            busy
                ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
                : AppButton('أكّد التجهيز وسلّم للشحن', icon: LucideIcons.check, disabled: count < 4, onTap: () async {
                    setState(() => busy = true);
                    final ok = await run(context, () => Api.markShipped(o.id, carrier, tracking.trim()), success: 'تم التوثيق — بلّغنا المشتري');
                    if (!mounted) return;
                    setState(() => busy = false);
                    if (ok) {
                      ref.invalidate(orderProvider(widget.id));
                      context.pop();
                    }
                  }),
            if (count < 4) Center(child: Text('يتفعّل الزر بعد رفع الصور الأربع', style: tx(12, c: AppColors.mute))),
          ] else
            Center(child: orderBadge(o)),
        ],
      ],
    );
  }
}

// ───────────────── T09 · الأرباح والتحويل ─────────────────

final ibanProvider = FutureProvider<String?>((ref) => Api.iban());

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  Widget _tx(String t, String d, String amt, bool pos, String st) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          IconSquare(pos ? LucideIcons.arrowDown : LucideIcons.arrowUp, size: 42, iconSize: 20, radius: 12, bg: pos ? AppColors.tealBg : AppColors.pink, color: pos ? AppColors.teal : AppColors.pri),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: tx(14, w: w5)),
              Text(d, style: tx(12, c: AppColors.mute)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(ltr(amt), style: tx(15, w: w6, c: pos ? AppColors.teal : AppColors.ink)),
            Text(st, style: tx(11, c: AppColors.mute)),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(statsProvider(3650)).valueOrNull ?? const <String, dynamic>{};
    final sales = ref.watch(salesProvider).valueOrNull ?? const <Order>[];
    final iban = ref.watch(ibanProvider).valueOrNull;
    num n(String k) => num.tryParse('${s[k] ?? 0}') ?? 0;
    final masked = iban == null || iban.length < 8 ? null : '${iban.substring(0, 4)} •••• •••• •••• ${iban.substring(iban.length - 4)}';
    final paidOrders = sales.where((o) => o.paidAt != null && o.status != 'cancelled').toList();
    return AppPage(
      header: const AppHeader(title: 'الأرباح والتحويل'),
      children: [
        _gradientCard(children: [
          Text('الرصيد المتاح للتحويل', style: tx(13, c: AppColors.white.withOpacity(0.85))),
          Text(ltr(fmtMoney2(n('available'))), style: tx(32, w: w7, c: AppColors.white, h: 1.3)),
          const SizedBox(height: 6),
          _glass(Row(children: [
            const Icon(LucideIcons.clock, size: 16, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('معلّق ${fmtMoney(n('pending'))} — يُتاح بعد تأكيد المشتري للاستلام', style: tx(12, c: AppColors.white))),
          ])),
          const SizedBox(height: 6),
        ]),
        AppCard(
          onTap: () => context.push('/edit-profile'),
          child: Row(children: [
            const IconSquare(LucideIcons.landmark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الحساب البنكي', style: tx(15, w: w5)),
                Text(masked == null ? 'أضف الآيبان من تعديل الملف' : ltr(masked), style: tx(13, c: masked == null ? AppColors.pri : AppColors.mute)),
              ]),
            ),
            Text(masked == null ? 'إضافة' : 'تغيير', style: tx(14, w: w5, c: AppColors.pri)),
          ]),
        ),
        AppButton('اطلب التحويل', icon: LucideIcons.landmark, disabled: n('available') <= 0 || masked == null, onTap: () => showToast(context, 'تم إرسال طلب التحويل — يوصلك خلال 1-3 أيام عمل')),
        Center(child: Text('يوصلك التحويل خلال 1-3 أيام عمل · بدون رسوم', style: tx(12, c: AppColors.mute))),
        const SizedBox(height: 4),
        Text('سجل العمليات', style: tx(17, w: w6)),
        if (paidOrders.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('ما فيه عمليات للحين', style: tx(14, c: AppColors.mute)))),
        for (final o in paidOrders)
          _tx('مبيعات طلب ${o.orderNo}', fmtDate(o.paidAt), '+${o.subtotal.toStringAsFixed(2)}', true, o.status == 'delivered' ? 'متاح' : 'معلّق'),
      ],
    );
  }
}

// ───────────────── T10 · باقة لولو ─────────────────

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  Widget _plan(BuildContext context, String name, String price, List<String> feats, {bool hl = false, bool current = false, required String cta}) {
    final fg = hl ? AppColors.white : AppColors.ink;
    return Container(
      decoration: BoxDecoration(
        gradient: hl ? AppColors.gradient : null,
        color: hl ? null : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: hl ? null : Border.all(color: AppColors.chipB),
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
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('ر.س / شهرياً', style: tx(13, c: hl ? const Color(0xFFF6D9CD) : AppColors.mute))),
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
    final active = ref.watch(myListingsProvider).valueOrNull?.where((l) => l.status == 'active').length ?? 0;
    final plan = p?.plan ?? 'free';
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
                Text(plan == 'free' ? 'المجانية' : (plan == 'pro' ? 'لولو برو' : 'لولو'), style: tx(17, w: w6)),
              ]),
            ),
            if (plan == 'free') Text('$active من 5 إعلانات', style: tx(13, w: w5, c: AppColors.ink2)),
          ]),
        ),
        _plan(context, 'المجانية', '0', const ['حتى 5 إعلانات', 'استقبال 10 طلبات قطع شهرياً', 'عمولة 8% على المبيعات'], current: plan == 'free', cta: plan == 'free' ? 'باقتك الحالية' : 'الرجوع للمجانية'),
        _plan(context, 'لولو', '49', const ['إعلانات بلا حدود', 'طلبات القطع بلا حدود', 'عمولة 5% فقط', 'شارة «تاجر موثّق»'], hl: true, current: plan == 'lulu', cta: plan == 'lulu' ? 'باقتك الحالية' : 'اشترك الآن'),
        _plan(context, 'لولو برو', '149', const ['كل مزايا لولو', 'ظهور مميز في نتائج البحث', 'عمولة 3%', 'تقارير أداء متقدمة'], current: plan == 'pro', cta: plan == 'pro' ? 'باقتك الحالية' : 'اشترك في برو'),
        Center(child: Text('تقدر تلغي اشتراكك بأي وقت من الإعدادات', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}
