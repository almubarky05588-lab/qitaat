import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── 15 · مشترياتي ─────────────────

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
        Text('مشترياتي', style: tx(24, w: w6)),
        const SizedBox(height: 14),
        SegTabs(items: const ['الحالية', 'المكتملة', 'الملغاة'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        const SizedBox(height: 14),
        if (tab == 0)
          for (final o in Mock.orders) ...[
            _OrderCard(o),
            const SizedBox(height: 14),
          ],
        if (tab != 0)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(child: Text(tab == 1 ? 'ما عندك طلبات مكتملة' : 'ما عندك طلبات ملغاة', style: tx(15, c: AppColors.mute))),
          ),
      ]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order o;
  const _OrderCard(this.o);
  @override
  Widget build(BuildContext context) {
    Widget badge;
    List<Widget> buttons = [];
    switch (o.status) {
      case OrderStatus.shipping:
        badge = const StatusBadge.teal('في الطريق', icon: LucideIcons.truck);
        buttons = [AppButton('تتبّع الشحنة', icon: LucideIcons.truck, v: BtnV.out2, radius: 999, height: 44, fs: 14, onTap: () => context.push('/order/${o.id}'))];
        break;
      case OrderStatus.awaitingPayment:
        badge = const StatusBadge('بانتظار الدفع · 23:41', icon: LucideIcons.clock);
        buttons = [
          AppButton('ادفع الآن', radius: 999, height: 44, fs: 14, onTap: () => context.push('/checkout')),
          AppButton('إلغاء', v: BtnV.out2, radius: 999, height: 44, fs: 14),
        ];
        break;
      case OrderStatus.preparing:
        badge = const StatusBadge.amber('جاري التجهيز', icon: LucideIcons.store);
        break;
      case OrderStatus.delivered:
        badge = const StatusBadge.grey('تم التسليم');
        break;
    }
    return AppCard(
      onTap: () => context.push('/order/${o.id}'),
      child: VCol(gap: 12, [
        Row(children: [
          const PartThumb(width: 76, height: 76, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title, style: tx(15, w: w5)),
              Text(o.no, style: tx(12, c: AppColors.mute)),
              const SizedBox(height: 4),
              badge,
            ]),
          ),
          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
        ]),
        Row(children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i < o.progress ? AppColors.teal : const Color(0xFFE8DDCF), borderRadius: BorderRadius.circular(3)))),
          ],
        ]),
        if (buttons.isNotEmpty)
          Row(children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: buttons[i]),
            ],
          ]),
      ]),
    );
  }
}

// ───────────────── 16 · تفاصيل الطلب والتتبّع ─────────────────

class OrderDetailsScreen extends StatelessWidget {
  final String id;
  const OrderDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ['تم الطلب', '2026/11/08 — 6:20 م', 2],
      ['تم الدفع', '2026/11/08 — 6:21 م', 2],
      ['جهّز البائع الشحنة', '2026/11/08 — 9:05 م', 2],
      ['في الطريق مع سمسا', '2026/11/09 — 8:30 ص', 1],
      ['تم التسليم', '', 0],
    ];

    Widget timelineRow(int i) {
      final s = steps[i];
      final st = s[2] as int;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: st == 2 ? AppColors.teal : (st == 1 ? AppColors.pink : AppColors.progressTodo),
              shape: BoxShape.circle,
              border: st == 1 ? Border.all(color: AppColors.pri, width: 2) : null,
            ),
            child: st == 2
                ? const Icon(LucideIcons.check, size: 12, color: AppColors.white)
                : (st == 1 ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle)) : null),
          ),
          if (i < steps.length - 1) Container(width: 2, height: 30, color: st == 2 ? AppColors.teal : const Color(0xFFE6DACB)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s[0] as String, style: tx(14, w: st > 0 ? w5 : w4, c: st == 1 ? AppColors.pri : (st > 0 ? AppColors.ink : AppColors.ph))),
            if ((s[1] as String).isNotEmpty) Text(s[1] as String, style: tx(12, c: AppColors.mute)),
          ]),
        ),
      ]);
    }

    return AppPage(
      header: AppHeader(title: 'تفاصيل الطلب', actions: [HeaderIcon(LucideIcons.messageSquare, size: 24, onTap: () => context.push('/chat/c1'))]),
      gap: 14,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(LucideIcons.truck, size: 26, color: AppColors.teal),
              const SizedBox(width: 10),
              Text('طلبك في الطريق', style: tx(18, w: w6, c: AppColors.teal)),
            ]),
            const SizedBox(height: 4),
            Text('الوصول المتوقع: الثلاثاء 10 نوفمبر', style: tx(13, c: AppColors.ink2)),
          ]),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('مراحل الطلب', style: tx(16, w: w6)),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++) timelineRow(i),
          ]),
        ),
        // صور القطعة قبل الشحن (4 اتجاهات)
        AppCard(
          child: VCol(gap: 12, [
            Row(children: [
              const Icon(LucideIcons.camera, size: 20, color: AppColors.pri),
              const SizedBox(width: 8),
              Expanded(child: Text('صور القطعة قبل الشحن', style: tx(16, w: w6))),
              const StatusBadge.teal('4/4', icon: LucideIcons.check),
            ]),
            Text('صوّرها البائع من 4 اتجاهات قبل ما يسلّمها لشركة الشحن', style: tx(12, c: AppColors.mute)),
            Row(children: [
              for (final d in const ['أمام', 'خلف', 'يمين', 'يسار']) ...[
                if (d != 'أمام') const SizedBox(width: 8),
                Expanded(
                  child: Column(children: [
                    const AspectRatio(aspectRatio: 1, child: PartThumb(height: 72, radius: 12)),
                    const SizedBox(height: 4),
                    Text(d, style: tx(12, w: w5, c: AppColors.ink2)),
                  ]),
                ),
              ],
            ]),
          ]),
        ),
        AppCard(
          child: VCol(gap: 10, [
            Text('الشحنة', style: tx(16, w: w6)),
            const KV('شركة الشحن', 'سمسا'),
            KV('رقم التتبع', ltr('SMSA 2948 1173 06'), icon: LucideIcons.copy),
            const KV('عنوان التوصيل', 'الرياض — حي النرجس'),
          ]),
        ),
        AppCard(
          child: VCol(gap: 10, [
            Row(children: [
              const PartThumb(width: 72, height: 72, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('صدام أمامي كامري 2020', style: tx(15, w: w5)),
                  Text('جديد أصلي · الكمية 1', style: tx(12, c: AppColors.mute)),
                  Text(sar(450), style: tx(16, w: w6, c: AppColors.teal)),
                ]),
              ),
            ]),
            const HLine(),
            const KV('البائع', 'كار ون'),
            KV('رقم الطلب', ltr('ORD-58213')),
            const KV('الإجمالي المدفوع', '557.75 ر.س', vColor: AppColors.pri),
            GestureDetector(onTap: () => context.push('/invoice'), child: KV('الفاتورة', ltr('INV-2026-001284'), vColor: AppColors.teal)),
          ]),
        ),
        AppButton('تأكيد الاستلام', icon: LucideIcons.check, onTap: () => showToast(context, 'شكراً! تم تأكيد الاستلام')),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.red),
          const SizedBox(width: 6),
          Text('الإبلاغ عن مشكلة في الطلب', style: tx(14, w: w5, c: AppColors.red)),
        ]),
      ],
    );
  }
}
