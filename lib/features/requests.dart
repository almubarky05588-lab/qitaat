import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── 11 · اطلب قطعة ─────────────────

class RequestPartScreen extends StatefulWidget {
  const RequestPartScreen({super.key});
  @override
  State<RequestPartScreen> createState() => _RequestPartScreenState();
}

class _RequestPartScreenState extends State<RequestPartScreen> {
  String brand = 'تويوتا';
  String model = 'كامري';
  String year = '2020';
  final Set<String> cats = {'بودي'};
  String condition = 'جديد أصلي';
  int parts = 1;

  void _pick(String title, List<String> options, ValueChanged<String> onPick) {
    showAppSheet(
      context,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: tx(18, w: w6)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
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

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'اطلب قطعة'),
      gap: 18,
      children: [
        Text('طلبك يوصل للموردين المتخصصين بماركة سيارتك فقط، وكل واحد يرد بسعره — وأنت تختار الأنسب', style: tx(14, c: AppColors.mute)),
        LabeledField('نوع السيارة', AppField(key: ValueKey(brand), value: brand, chevron: true, onTap: () => _pick('نوع السيارة', Mock.allBrands, (v) => setState(() => brand = v)))),
        LabeledField('الموديل', AppField(key: ValueKey(model), value: model, chevron: true, onTap: () => _pick('الموديل', const ['كامري', 'كورولا', 'يارس', 'لاندكروزر', 'هايلكس', 'أفالون', 'راف فور'], (v) => setState(() => model = v)))),
        LabeledField('سنة الصنع', AppField(key: ValueKey(year), value: year, chevron: true, onTap: () => _pick('سنة الصنع', [for (var y = 2026; y >= 2000; y--) '$y'], (v) => setState(() => year = v)))),
        const LabeledField('رقم الهيكل / VIN (اختياري)', AppField(hint: 'مثال: JTDKB20U...')),
        LabeledField(
          'القطع المطلوبة',
          VCol(gap: 10, [
            for (var i = 0; i < parts; i++) const AppField(hint: 'مثال: صدام أمامي'),
            GestureDetector(
              onTap: () => setState(() => parts++),
              child: Row(children: [
                const Icon(LucideIcons.plus, size: 18, color: AppColors.teal),
                const SizedBox(width: 6),
                Text('إضافة قطعة', style: tx(14, w: w5, c: AppColors.teal)),
              ]),
            ),
          ]),
        ),
        LabeledField(
          'تصنيف القطعة (اختياري)',
          ChipWrap(Mock.categories, selected: cats, onTap: (c) => setState(() => cats.contains(c) ? cats.remove(c) : cats.add(c))),
        ),
        LabeledField(
          'حالة القطعة (أصلية / مستعملة)',
          SelectGrid(options: Mock.conditions, selected: condition, onChanged: (v) => setState(() => condition = v)),
          required: true,
        ),
        LabeledField(
          'صور (اختياري)',
          Align(alignment: AlignmentDirectional.centerStart, child: const UploadBox(size: 120)),
          help: null,
        ),
        const LabeledField('ملاحظات (اختياري)', AppField(hint: 'أي تفاصيل إضافية...', area: true)),
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
        AppButton('أرسل الطلب للموردين المتخصصين', icon: LucideIcons.send, onTap: () => context.pushReplacement('/request-sent')),
      ],
    );
  }
}

/// مربع رفع الصور (إطار متقطع)
class UploadBox extends StatelessWidget {
  final double size;
  final String label;
  const UploadBox({super.key, this.size = 96, this.label = 'أضف صور'});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedRRect(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.uploadBg, borderRadius: BorderRadius.circular(18)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.camera, size: size * 0.27, color: AppColors.pri),
            const SizedBox(height: 4),
            Text(label, style: tx(12, w: w5, c: AppColors.pri)),
          ]),
        ),
      );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pri
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────── 11ب · تم إرسال الطلب ─────────────────

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
                Text('أرسلنا طلبك لكل الموردين المتخصصين في تويوتا. أول العروض توصلك عادةً خلال ساعتين، وبنعلمك بإشعار.',
                    textAlign: TextAlign.center, style: tx(15, c: AppColors.mute, h: 1.7)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.users, size: 18, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Text('وصل لـ 1,240 مورد متخصص', style: tx(14, w: w6, c: AppColors.teal)),
                  ]),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: VCol(gap: 8, [
                    const KV('القطعة', 'صدام أمامي'),
                    const KV('السيارة', 'تويوتا كامري 2020'),
                    const KV('الحالة المطلوبة', 'جديد أصلي'),
                    const KV('مدة استقبال العروض', '48 ساعة'),
                  ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: VCol(gap: 10, [
              AppButton('تابع العروض', icon: LucideIcons.arrowLeft, onTap: () => context.pushReplacement('/offers/r1')),
              AppButton('الرجوع للرئيسية', v: BtnV.out2, onTap: () => context.go('/home')),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 12 · طلبات القطع ─────────────────

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Text('طلبات القطع', style: tx(24, w: w6)),
        const SizedBox(height: 16),
        for (final r in Mock.requests) ...[
          _RequestCard(r),
          const SizedBox(height: 14),
        ],
      ]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PartRequest r;
  const _RequestCard(this.r);
  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    switch (r.status) {
      case ReqStatus.active:
        badges.addAll([StatusBadge.teal(r.left, icon: LucideIcons.clock), StatusBadge('${r.offers} عروض')]);
        break;
      case ReqStatus.expiredNoOffers:
        badges.add(const StatusBadge.grey('منتهي بدون عروض'));
        break;
      case ReqStatus.endedNoPurchase:
        badges.addAll([const StatusBadge.grey('انتهى بدون شراء'), StatusBadge('${r.offers} عرض')]);
        break;
    }
    return AppCard(
      onTap: () => context.push('/offers/${r.id}'),
      child: VCol(gap: 12, [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: tx(16, w: w5)),
              if (r.sub != null) Text(r.sub!, style: tx(14, c: AppColors.ink2)),
            ]),
          ),
          const SizedBox(width: 10),
          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
        ]),
        if (r.image) const Align(alignment: AlignmentDirectional.centerStart, child: PartThumb(width: 96, height: 96, radius: 14)),
        Row(children: [
          ...badges.expand((b) => [b, const SizedBox(width: 8)]),
          const Spacer(),
          if (r.best != null) Text('الأفضل: ${sar(r.best!)}', style: tx(15, w: w6, c: AppColors.teal)),
        ]),
        r.status == ReqStatus.active
            ? AppButton('شوف العروض', icon: LucideIcons.arrowLeft, radius: 999, height: 46, fs: 15, onTap: () => context.push('/offers/${r.id}'))
            : AppButton('أعد نشر الطلب (48 ساعة)', icon: LucideIcons.rotateCw, iconFirst: true, v: BtnV.out2, radius: 999, height: 46, fs: 14, onTap: () => showToast(context, 'تم إعادة نشر الطلب')),
      ]),
    );
  }
}

// ───────────────── 13/14 · عروض الموردين ─────────────────

class OffersScreen extends StatefulWidget {
  final String id;
  const OffersScreen({super.key, required this.id});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  int sort = 0;

  @override
  Widget build(BuildContext context) {
    final r = Mock.requests.firstWhere((e) => e.id == widget.id, orElse: () => Mock.requests.first);
    final hasOffers = r.status == ReqStatus.active;
    final title = hasOffers ? 'صدام أمامي · تويوتا كامري 2020 · جديد أصلي' : r.title;

    final header = AppHeader(title: 'عروض الموردين', actions: [HeaderIcon(LucideIcons.home, size: 24, onTap: () => context.go('/home'))]);
    final summary = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('طلبك', style: tx(13, c: AppColors.mute)),
        Text(title, style: tx(16, w: w5)),
      ]),
    );

    if (!hasOffers) {
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
                Row(children: [
                  const StatusBadge('منتهي بدون عروض'),
                  const SizedBox(width: 8),
                  Expanded(child: Text('وصل طلبك لـ 1 مورد متخصص — انتهت المهلة', style: tx(13, c: AppColors.mute))),
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
                  Text('ما وصلتك عروض هالمرة', style: tx(19, w: w6)),
                  const SizedBox(height: 12),
                  Text('يمكن القطعة ما كانت متوفرة عند الموردين خلال المهلة. أعد نشر طلبك ويوصل لموردين أكثر', textAlign: TextAlign.center, style: tx(14, c: AppColors.mute)),
                  const SizedBox(height: 18),
                  AppButton('أعد نشر الطلب (48 ساعة)', icon: LucideIcons.rotateCw, iconFirst: true, radius: 999, onTap: () => showToast(context, 'تم إعادة نشر الطلب')),
                  const SizedBox(height: 12),
                  GestureDetector(onTap: () => context.push('/request-part'), child: Text('عدّل الطلب', style: tx(14, w: w5, c: AppColors.teal))),
                ]),
              ),
            ),
          ]),
        ),
      );
    }

    final offers = [...Mock.offers];
    if (sort == 1) offers.sort((a, b) => b.rating.compareTo(a.rating));
    return AppPage(
      header: header,
      gap: 14,
      children: [
        summary,
        Row(children: [
          StatusBadge.teal('${offers.length} عروض'),
          const SizedBox(width: 8),
          Expanded(child: Text('باقي 31 ساعة على انتهاء المهلة', style: tx(13, c: AppColors.mute))),
        ]),
        Wrap(spacing: 8, children: [
          for (var i = 0; i < 3; i++) AppChip(const ['الأقل سعر', 'الأعلى تقييم', 'الأسرع توصيل'][i], selected: sort == i, px: 14, py: 7, onTap: () => setState(() => sort = i)),
        ]),
        for (final o in offers) _OfferCard(o),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer o;
  const _OfferCard(this.o);
  @override
  Widget build(BuildContext context) {
    return AppCard(
      border: o.best ? AppColors.pri : null,
      child: VCol(gap: 12, [
        if (o.best) const Align(alignment: AlignmentDirectional.centerStart, child: StatusBadge('الأفضل سعراً', icon: LucideIcons.star)),
        Row(children: [
          const Avatar(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(o.store, style: tx(16, w: w6))),
                const SizedBox(width: 6),
                const VerifiedBadge(size: 18),
              ]),
              Row(children: [
                const Icon(LucideIcons.star, size: 14, color: AppColors.star),
                const SizedBox(width: 4),
                Text(o.rating, style: tx(12, c: AppColors.mute)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(sar(o.price), style: tx(20, w: w7, c: AppColors.teal, h: 1.3)),
            Text('شامل الشحن', style: tx(11, c: AppColors.mute)),
          ]),
        ]),
        Wrap(spacing: 6, runSpacing: 6, children: [
          AppChip('الحالة: ${o.condition}', selected: true, teal: true, fs: 12, px: 10, py: 5),
          for (final t in o.tags) AppChip(t, bg: const Color(0xFFF3ECE2), noBorder: true, fs: 12, px: 10, py: 5),
        ]),
        Text('«${o.note}»', style: tx(13, c: AppColors.ink2)),
        Row(children: [
          Expanded(child: AppButton('قبول العرض', icon: LucideIcons.check, height: 46, fs: 15, onTap: () => context.push('/checkout'))),
          const SizedBox(width: 10),
          Expanded(child: AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, height: 46, fs: 15, onTap: () => context.push('/chat/c2'))),
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
