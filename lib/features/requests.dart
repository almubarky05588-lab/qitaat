import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/mock.dart';

/// اختيار من قائمة في نافذة سفلية
void pickFromSheet(BuildContext context, String title, List<String> options, ValueChanged<String> onPick) {
  showAppSheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: tx(18, w: w6)),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: SingleChildScrollView(
          child: Wrap(spacing: 8, runSpacing: 10, children: [
            for (final o in options)
              AppChip(o, onTap: () {
                onPick(o);
                Navigator.pop(context);
              }),
          ]),
        ),
      ),
    ]),
  );
}

// ───────────────── 11 · اطلب قطعة ─────────────────

class RequestPartScreen extends ConsumerStatefulWidget {
  const RequestPartScreen({super.key});
  @override
  ConsumerState<RequestPartScreen> createState() => _RequestPartScreenState();
}

class _RequestPartScreenState extends ConsumerState<RequestPartScreen> {
  String brand = 'تويوتا';
  String model = 'كامري';
  String year = '2020';
  String vin = '';
  String notes = '';
  final parts = <String>[''];
  String? cat;
  String condition = 'جديد أصلي';
  List<String> images = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    Api.cars().then((cars) {
      if (cars.isEmpty || !mounted) return;
      final c = cars.firstWhere((e) => e.isDefault, orElse: () => cars.first);
      setState(() {
        brand = c.brand;
        model = c.model ?? model;
        year = c.year?.toString() ?? year;
        vin = c.vin ?? '';
      });
    }).catchError((_) {});
  }

  Future<void> _send() async {
    final ps = parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (ps.isEmpty) {
      showToast(context, 'اكتب القطعة المطلوبة');
      return;
    }
    setState(() => busy = true);
    try {
      final city = ref.read(myProfileProvider).valueOrNull?.city;
      final id = await Api.createRequest({
        'brand': brand,
        'model': model,
        'year': int.tryParse(year),
        'vin': vin.trim().isEmpty ? null : vin.trim(),
        'parts': ps,
        'category': cat,
        'condition': condition,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'images': images,
        'city': city,
      });
      if (mounted) context.pushReplacement('/request-sent/$id');
    } catch (e) {
      if (mounted) showToast(context, errMsg(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'اطلب قطعة'),
      gap: 18,
      children: [
        Text('طلبك يوصل للموردين المتخصصين بماركة سيارتك فقط، وكل واحد يرد بسعره — وأنت تختار الأنسب', style: tx(14, c: AppColors.mute)),
        LabeledField(
            'نوع السيارة',
            AppField(
                key: ValueKey('b$brand'),
                value: brand,
                chevron: true,
                onTap: () => pickFromSheet(context, 'نوع السيارة', Mock.allBrands, (v) => setState(() {
                      brand = v;
                      model = Mock.modelsOf(v).first;
                    })))),
        LabeledField('الموديل', AppField(key: ValueKey('m$model'), value: model, chevron: true, onTap: () => pickFromSheet(context, 'الموديل', Mock.modelsOf(brand), (v) => setState(() => model = v)))),
        LabeledField(
            'سنة الصنع', AppField(key: ValueKey('y$year'), value: year, chevron: true, onTap: () => pickFromSheet(context, 'سنة الصنع', [for (var y = DateTime.now().year + 1; y >= 1990; y--) '$y'], (v) => setState(() => year = v)))),
        LabeledField('رقم الهيكل / VIN (اختياري)', AppField(key: ValueKey('v$vin'), hint: 'مثال: JTDKB20U...', value: vin.isEmpty ? null : vin, ltrText: true, onChanged: (v) => vin = v)),
        LabeledField(
          'القطع المطلوبة',
          VCol(gap: 10, [
            for (var i = 0; i < parts.length; i++) AppField(key: ValueKey('p$i'), hint: 'مثال: صدام أمامي', value: parts[i].isEmpty ? null : parts[i], onChanged: (v) => parts[i] = v),
            GestureDetector(
              onTap: () => setState(() => parts.add('')),
              child: Row(children: [
                const Icon(LucideIcons.plus, size: 18, color: AppColors.teal),
                const SizedBox(width: 6),
                Text('إضافة قطعة', style: tx(14, w: w5, c: AppColors.teal)),
              ]),
            ),
          ]),
        ),
        LabeledField('تصنيف القطعة (اختياري)', ChipWrap(Mock.categories, selected: {if (cat != null) cat!}, onTap: (c) => setState(() => cat = cat == c ? null : c))),
        LabeledField('حالة القطعة (أصلية / مستعملة)', SelectGrid(options: Mock.conditions, selected: condition, onChanged: (v) => setState(() => condition = v)), required: true),
        LabeledField('صور (اختياري)', PhotoStrip(urls: images, size: 120, max: 4, onChanged: (v) => setState(() => images = v)), help: 'صورة القطعة أو العطل تساعد الموردين يجاوبونك أدق'),
        LabeledField('ملاحظات (اختياري)', AppField(hint: 'أي تفاصيل إضافية...', area: true, onChanged: (v) => notes = v)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.sageB)),
          child: Row(children: [
            const IconSquare(LucideIcons.users, size: 44, bg: AppColors.white, color: AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('طلبك بيوصل لأكثر من 1000 مورد', style: tx(15, w: w6, c: AppColors.teal)),
                Text('بس الموردين المتخصصين في $brand — كل واحد يرد بسعره وحالة القطعة', style: tx(12, c: AppColors.ink2)),
              ]),
            ),
          ]),
        ),
        busy
            ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
            : AppButton('أرسل الطلب للموردين المتخصصين', icon: LucideIcons.send, onTap: _send),
      ],
    );
  }
}

// ───────────────── 11ب · تم إرسال الطلب ─────────────────

final requestProvider = FutureProvider.family<PartRequest?, String>((ref, id) => Api.request(id));

class RequestSentScreen extends ConsumerWidget {
  final String id;
  const RequestSentScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(requestProvider(id)).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          AppHeader(title: '', actions: [HeaderIcon(LucideIcons.home, size: 24, onTap: () => context.go('/home'))]),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                const SizedBox(height: 20),
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.send, size: 44, color: AppColors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text('طلبك انتشر!', style: tx(28, w: w7)),
                const SizedBox(height: 14),
                Text('أرسلنا طلبك لكل الموردين المتخصصين في ${r?.brand ?? 'ماركتك'}. أول العروض توصلك عادةً خلال ساعتين، وبنعلمك بإشعار.',
                    textAlign: TextAlign.center, style: tx(15, c: AppColors.mute, h: 1.7)),
                const SizedBox(height: 14),
                if (r != null)
                  FutureBuilder<int>(
                    future: Api.matchingSuppliers(r.brand),
                    builder: (c, s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.users, size: 18, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Text(s.hasData ? 'وصل لـ ${s.data} مورد متخصص' : 'جاري الإرسال للموردين...', style: tx(14, w: w6, c: AppColors.teal)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 20),
                if (r != null)
                  AppCard(
                    child: VCol(gap: 8, [
                      KV('القطعة', r.partsLabel),
                      KV('السيارة', r.car),
                      KV('الحالة المطلوبة', r.condition),
                      const KV('مدة استقبال العروض', '48 ساعة'),
                    ]),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: VCol(gap: 10, [
              AppButton('تابع العروض', icon: LucideIcons.arrowLeft, onTap: () => context.pushReplacement('/offers/$id')),
              AppButton('الرجوع للرئيسية', v: BtnV.out2, onTap: () => context.go('/home')),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 12 · طلبات القطع ─────────────────

final myRequestsProvider = FutureProvider<List<PartRequest>>((ref) {
  ref.watch(authProvider);
  return Api.myRequests();
});

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(myRequestsProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.pri,
        onRefresh: () async => ref.invalidate(myRequestsProvider),
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          Text('طلبات القطع', style: tx(24, w: w6)),
          const SizedBox(height: 16),
          AsyncBody<List<PartRequest>>(
            v,
            (list) => list.isEmpty
                ? EmptyBox(LucideIcons.archive, 'ما عندك طلبات قطع للحين',
                    action: AppButton('اطلب قطعتك الآن', icon: LucideIcons.search, expand: false, radius: 999, height: 46, fs: 15, onTap: () => context.push('/request-part')))
                : VCol(gap: 14, [for (final r in list) _RequestCard(r)]),
            onRetry: () => ref.invalidate(myRequestsProvider),
          ),
        ]),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final PartRequest r;
  const _RequestCard(this.r);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = r.liveOffers;
    final badges = <Widget>[];
    if (r.isOpen) {
      badges.addAll([StatusBadge.teal(fmtLeft(r.expiresAt), icon: LucideIcons.clock), if (offers.isNotEmpty) StatusBadge('${offers.length} عروض')]);
    } else if (r.status == 'closed') {
      badges.add(const StatusBadge.teal('تم قبول عرض', icon: LucideIcons.check));
    } else if (offers.isEmpty) {
      badges.add(const StatusBadge.grey('منتهي بدون عروض'));
    } else {
      badges.addAll([const StatusBadge.grey('انتهى بدون شراء'), StatusBadge('${offers.length} عرض')]);
    }
    return AppCard(
      onTap: () => context.push('/offers/${r.id}'),
      child: VCol(gap: 12, [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: tx(16, w: w5)),
              if (r.category != null || r.notes != null) Text([if (r.category != null) 'تصنيف: ${r.category}', if (r.notes != null) r.notes!].join(' · '), style: tx(14, c: AppColors.ink2)),
            ]),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
        ]),
        if (r.images.isNotEmpty) Align(alignment: AlignmentDirectional.centerStart, child: PartThumb(width: 96, height: 96, radius: 14, imageUrl: r.images.first)),
        Row(children: [
          ...badges.expand((b) => [b, const SizedBox(width: 8)]),
          const Spacer(),
          if (r.bestPrice != null) Text('الأفضل: ${fmtMoney(r.bestPrice!)}', style: tx(15, w: w6, c: AppColors.teal)),
        ]),
        if (r.isOpen)
          AppButton('شوف العروض', icon: LucideIcons.arrowLeft, radius: 999, height: 46, fs: 15, onTap: () => context.push('/offers/${r.id}'))
        else if (r.status != 'closed')
          AppButton('أعد نشر الطلب (48 ساعة)', icon: LucideIcons.rotateCw, iconFirst: true, v: BtnV.out2, radius: 999, height: 46, fs: 14, onTap: () async {
            if (await run(context, () => Api.republish(r.id), success: 'تم إعادة نشر الطلب')) ref.invalidate(myRequestsProvider);
          }),
      ]),
    );
  }
}

// ───────────────── 13/14 · عروض الموردين ─────────────────

class OffersScreen extends ConsumerStatefulWidget {
  final String id;
  const OffersScreen({super.key, required this.id});
  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  int sort = 0;

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(requestProvider(widget.id));
    final header = AppHeader(title: 'عروض الموردين', actions: [HeaderIcon(LucideIcons.home, size: 24, onTap: () => context.go('/home'))]);
    return v.when(
      loading: () => Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: Column(children: [header, const Loading()]))),
      error: (e, _) => Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: Column(children: [header, ErrorBox(e, onRetry: () => ref.invalidate(requestProvider(widget.id)))]))),
      data: (r) {
        if (r == null) return Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: Column(children: [header, const EmptyBox(LucideIcons.inbox, 'الطلب غير موجود')])));
        final offers = r.liveOffers;
        final summary = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('طلبك', style: tx(13, c: AppColors.mute)),
            Text(r.title, style: tx(16, w: w5)),
          ]),
        );

        if (offers.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: SafeArea(
              child: Column(children: [
                header,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: VCol(gap: 14, [
                    summary,
                    const OrderStepper(current: 2),
                    if (!r.isOpen)
                      Row(children: [
                        const StatusBadge('منتهي بدون عروض'),
                        const SizedBox(width: 8),
                        Expanded(child: Text('انتهت مهلة استقبال العروض', style: tx(13, c: AppColors.mute))),
                      ])
                    else
                      Row(children: [
                        StatusBadge.teal(fmtLeft(r.expiresAt), icon: LucideIcons.clock),
                        const SizedBox(width: 8),
                        Expanded(child: Text('بانتظار عروض الموردين', style: tx(13, c: AppColors.mute))),
                      ]),
                  ]),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.inbox, size: 50, color: AppColors.thumbIcon),
                      ),
                      const SizedBox(height: 16),
                      Text(r.isOpen ? 'العروض في الطريق' : 'ما وصلتك عروض هالمرة', style: tx(19, w: w6)),
                      const SizedBox(height: 12),
                      Text(
                          r.isOpen
                              ? 'طلبك وصل للموردين المتخصصين، وبنعلمك أول ما يوصلك عرض'
                              : 'يمكن القطعة ما كانت متوفرة عند الموردين خلال المهلة. أعد نشر طلبك ويوصل لموردين أكثر',
                          textAlign: TextAlign.center,
                          style: tx(14, c: AppColors.mute)),
                      const SizedBox(height: 18),
                      if (!r.isOpen)
                        AppButton('أعد نشر الطلب (48 ساعة)', icon: LucideIcons.rotateCw, iconFirst: true, radius: 999, onTap: () async {
                          if (await run(context, () => Api.republish(r.id), success: 'تم إعادة نشر الطلب')) {
                            ref.invalidate(myRequestsProvider);
                            if (context.mounted) context.go('/requests');
                          }
                        }),
                      if (!r.isOpen) const SizedBox(height: 12),
                      GestureDetector(onTap: () => context.push('/request-part'), child: Text('عدّل الطلب', style: tx(14, w: w5, c: AppColors.teal))),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        }

        final sorted = [...offers];
        if (sort == 0) sorted.sort((a, b) => a.price.compareTo(b.price));
        if (sort == 1) sorted.sort((a, b) => (b.supplier?.verified == true ? 1 : 0).compareTo(a.supplier?.verified == true ? 1 : 0));
        final best = offers.map((o) => o.price).reduce((a, b) => a < b ? a : b);
        return AppPage(
          header: header,
          gap: 14,
          children: [
            summary,
            Row(children: [
              StatusBadge.teal('${offers.length} عروض'),
              const SizedBox(width: 8),
              Expanded(child: Text(r.isOpen ? '${fmtLeft(r.expiresAt)} على انتهاء المهلة' : (r.status == 'closed' ? 'تم قبول عرض' : 'انتهت المهلة'), style: tx(13, c: AppColors.mute))),
            ]),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < 3; i++) AppChip(const ['الأقل سعر', 'الأعلى تقييم', 'الأسرع توصيل'][i], selected: sort == i, px: 14, py: 7, onTap: () => setState(() => sort = i)),
            ]),
            for (final o in sorted) _OfferCard(o, best: o.price == best, canAccept: r.status == 'open' && o.status == 'pending', requestId: r.id),
          ],
        );
      },
    );
  }
}

class _OfferCard extends ConsumerWidget {
  final Offer o;
  final bool best;
  final bool canAccept;
  final String requestId;
  const _OfferCard(this.o, {required this.best, required this.canAccept, required this.requestId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = o.supplier;
    return AppCard(
      border: best ? AppColors.pri : null,
      child: VCol(gap: 12, [
        if (best) const Align(alignment: AlignmentDirectional.centerStart, child: StatusBadge('الأفضل سعراً', icon: LucideIcons.star)),
        Row(children: [
          const Avatar(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(s?.displayName ?? 'مورد', style: tx(16, w: w6))),
                if (s?.verified == true) const SizedBox(width: 6),
                if (s?.verified == true) const VerifiedBadge(size: 18),
              ]),
              Row(children: [
                const Icon(LucideIcons.mapPin, size: 14, color: AppColors.mute),
                const SizedBox(width: 4),
                Text(s?.city ?? '', style: tx(12, c: AppColors.mute)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtMoney(o.price), style: tx(20, w: w7, c: AppColors.teal, h: 1.3)),
            Text(o.includesShipping ? 'شامل الشحن' : 'غير شامل الشحن', style: tx(11, c: AppColors.mute)),
          ]),
        ]),
        Wrap(spacing: 6, runSpacing: 6, children: [
          AppChip('الحالة: ${o.condition}', selected: true, teal: true, fs: 12, px: 10, py: 5),
          if (o.warranty != null) AppChip('ضمان ${o.warranty}', bg: const Color(0xFFF3ECE2), noBorder: true, fs: 12, px: 10, py: 5),
          if (o.deliveryTime != null) AppChip(o.deliveryTime!, bg: const Color(0xFFF3ECE2), noBorder: true, fs: 12, px: 10, py: 5),
        ]),
        if (o.note != null && o.note!.isNotEmpty) Text('«${o.note}»', style: tx(13, c: AppColors.ink2)),
        if (o.images.isNotEmpty)
          SizedBox(
            height: 72,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final u in o.images) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: PartThumb(width: 72, height: 72, radius: 12, imageUrl: u)),
            ]),
          ),
        if (o.status == 'accepted') const Center(child: StatusBadge.teal('تم قبول هذا العرض', icon: LucideIcons.check)),
        Row(children: [
          if (canAccept)
            Expanded(
              child: AppButton('قبول العرض', icon: LucideIcons.check, height: 46, fs: 15, onTap: () async {
                try {
                  final oid = await Api.acceptOffer(o.id);
                  ref.invalidate(requestProvider(requestId));
                  ref.invalidate(myRequestsProvider);
                  ref.read(checkoutOrdersProvider.notifier).state = [oid];
                  if (context.mounted) context.push('/checkout');
                } catch (e) {
                  if (context.mounted) showToast(context, errMsg(e));
                }
              }),
            ),
          if (canAccept) const SizedBox(width: 10),
          Expanded(
            child: AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, height: 46, fs: 15, onTap: () async {
              try {
                final cid = await Api.startChat(o.supplierId);
                if (context.mounted) context.push('/chat/$cid');
              } catch (e) {
                if (context.mounted) showToast(context, errMsg(e));
              }
            }),
          ),
        ]),
      ]),
    );
  }
}

/// مراحل الطلب: أرسل ← وصل للموردين ← العروض ← القبول ← الدفع ← الشحن ← الاستلام
class OrderStepper extends StatelessWidget {
  final int current;
  const OrderStepper({super.key, required this.current});
  static const steps = ['أرسل', 'وصل للموردين', 'العروض', 'القبول', 'الدفع', 'الشحن', 'الاستلام'];
  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i < current, cur = i == current;
      kids.add(Column(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.progressDone : (cur ? AppColors.pink : AppColors.progressTodo),
            shape: BoxShape.circle,
            border: cur ? Border.all(color: AppColors.pri, width: 2) : null,
          ),
          child: done
              ? const Icon(LucideIcons.check, size: 14, color: AppColors.white)
              : (cur ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle)) : null),
        ),
        const SizedBox(height: 6),
        Text(steps[i], style: tx(10, w: cur ? w6 : w4, c: cur ? AppColors.pri : (done ? AppColors.ink2 : const Color(0xFFB5A898)), h: 1.3)),
      ]));
      if (i < steps.length - 1) {
        kids.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(height: 2, color: i < current ? AppColors.progressDone : const Color(0xFFE6DACB)),
          ),
        ));
      }
    }
    return Padding(padding: const EdgeInsets.only(top: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: kids));
  }
}
