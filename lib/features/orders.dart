import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import 'catalog.dart' show openChat;
import 'checkout.dart' show myOrdersProvider, orderProvider;

Widget orderBadge(Order o) => switch (o.status) {
      'awaiting_payment' => StatusBadge('بانتظار الدفع · ${fmtLeft(o.payDeadline).replaceFirst('باقي ', '')}', icon: LucideIcons.clock),
      'paid' => const StatusBadge.amber('تم الدفع · بانتظار التجهيز', icon: LucideIcons.store),
      'preparing' => const StatusBadge.amber('جاري التجهيز', icon: LucideIcons.store),
      'shipped' => const StatusBadge.teal('في الطريق', icon: LucideIcons.truck),
      'delivered' => const StatusBadge.grey('تم التسليم', icon: LucideIcons.check),
      _ => const StatusBadge.grey('ملغي'),
    };

// ───────────────── 15 · مشترياتي ─────────────────

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});
  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(myOrdersProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.pri,
        onRefresh: () async => ref.invalidate(myOrdersProvider),
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          Text('مشترياتي', style: tx(24, w: w6)),
          const SizedBox(height: 14),
          SegTabs(items: const ['الحالية', 'المكتملة', 'الملغاة'], selected: tab, onChanged: (i) => setState(() => tab = i)),
          const SizedBox(height: 14),
          AsyncBody<List<Order>>(v, (all) {
            final list = all.where((o) => switch (tab) {
                  0 => !['delivered', 'cancelled'].contains(o.status),
                  1 => o.status == 'delivered',
                  _ => o.status == 'cancelled',
                }).toList();
            if (list.isEmpty) {
              return EmptyBox(LucideIcons.shoppingBag, ['ما عندك طلبات حالية', 'ما عندك طلبات مكتملة', 'ما عندك طلبات ملغاة'][tab]);
            }
            return VCol(gap: 14, [for (final o in list) _OrderCard(o)]);
          }, onRetry: () => ref.invalidate(myOrdersProvider)),
        ]),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order o;
  const _OrderCard(this.o);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = <Widget>[];
    if (o.status == 'awaiting_payment') {
      buttons.add(AppButton('ادفع الآن', radius: 999, height: 44, fs: 14, onTap: () {
        ref.read(checkoutOrdersProvider.notifier).state = [o.id];
        context.push('/checkout');
      }));
    }
    if (o.status == 'shipped') {
      buttons.add(AppButton('تتبّع الشحنة', icon: LucideIcons.truck, v: BtnV.out2, radius: 999, height: 44, fs: 14, onTap: () => context.push('/order/${o.id}')));
    }
    if (o.invoiceNo != null) {
      buttons.add(AppButton('الفاتورة', icon: LucideIcons.receipt, v: BtnV.out2, radius: 999, height: 44, fs: 14, onTap: () => context.push('/invoice/${o.id}')));
    }
    return AppCard(
      onTap: () => context.push('/order/${o.id}'),
      child: VCol(gap: 12, [
        Row(children: [
          PartThumb(width: 76, height: 76, radius: 14, imageUrl: o.image ?? o.photo('front')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title, style: tx(15, w: w5)),
              Text('رقم الطلب ${ltr(o.orderNo)} · ${fmtMoney2(o.total)}', style: tx(12, c: AppColors.mute)),
              const SizedBox(height: 4),
              orderBadge(o),
            ]),
          ),
          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
        ]),
        if (o.status != 'cancelled')
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

class OrderDetailsScreen extends ConsumerWidget {
  final String id;
  const OrderDetailsScreen({super.key, required this.id});

  Widget _timelineRow(String t, DateTime? d, int st, bool last) {
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
        if (!last) Container(width: 2, height: 30, color: st == 2 ? AppColors.teal : const Color(0xFFE6DACB)),
      ]),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: tx(14, w: st > 0 ? w5 : w4, c: st == 1 ? AppColors.pri : (st > 0 ? AppColors.ink : AppColors.ph))),
          if (d != null) Text('${fmtDate(d)} — ${fmtTime(d)}', style: tx(12, c: AppColors.mute)),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(orderProvider(id));
    return AppPage(
      header: AppHeader(title: 'تفاصيل الطلب', actions: [
        HeaderIcon(LucideIcons.messageSquare, size: 24, onTap: () {
          final o = v.valueOrNull;
          if (o != null) openChat(context, o.buyerId == myId ? o.sellerId : o.buyerId, listingId: o.listingId);
        }),
      ]),
      gap: 14,
      children: [
        AsyncBody<Order?>(v, (o) {
          if (o == null) return const EmptyBox(LucideIcons.package, 'الطلب غير موجود');
          final p = o.progress;
          final steps = [
            ('تم الطلب', o.createdAt),
            ('تم الدفع', o.paidAt),
            ('جهّز البائع الشحنة', o.status == 'preparing' || p >= 4 ? (o.shippedAt ?? o.paidAt) : null),
            ('في الطريق${o.carrier != null ? ' مع ${o.carrier}' : ''}', o.shippedAt),
            ('تم التسليم', o.deliveredAt),
          ];
          final head = switch (o.status) {
            'awaiting_payment' => ('بانتظار الدفع', 'أكمل الدفع ${fmtLeft(o.payDeadline)}', LucideIcons.clock),
            'paid' => ('تم الدفع', 'البائع بيجهّز طلبك ويصوّره قبل الشحن', LucideIcons.store),
            'preparing' => ('جاري التجهيز', 'البائع يجهّز الشحنة', LucideIcons.store),
            'shipped' => ('طلبك في الطريق', 'شُحن ${fmtAgo(o.shippedAt)}', LucideIcons.truck),
            'delivered' => ('تم التسليم', 'استلمت طلبك ${fmtDate(o.deliveredAt)}', LucideIcons.checkCircle),
            _ => ('الطلب ملغي', '', LucideIcons.x),
          };
          final sides = [('front', 'أمام'), ('back', 'خلف'), ('right', 'يمين'), ('left', 'يسار')];
          final photoCount = sides.where((s) => o.photo(s.$1) != null).length;
          return VCol(gap: 14, [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(head.$3, size: 26, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Text(head.$1, style: tx(18, w: w6, c: AppColors.teal)),
                ]),
                if (head.$2.isNotEmpty) const SizedBox(height: 4),
                if (head.$2.isNotEmpty) Text(head.$2, style: tx(13, c: AppColors.ink2)),
              ]),
            ),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('مراحل الطلب', style: tx(16, w: w6)),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++) _timelineRow(steps[i].$1, steps[i].$2, i < p ? 2 : (i == p ? 1 : 0), i == steps.length - 1),
              ]),
            ),
            if (photoCount > 0)
              AppCard(
                child: VCol(gap: 12, [
                  Row(children: [
                    const Icon(LucideIcons.camera, size: 20, color: AppColors.pri),
                    const SizedBox(width: 8),
                    Expanded(child: Text('صور القطعة قبل الشحن', style: tx(16, w: w6))),
                    StatusBadge.teal('$photoCount/4', icon: LucideIcons.check),
                  ]),
                  Text('صوّرها البائع من 4 اتجاهات قبل ما يسلّمها لشركة الشحن', style: tx(12, c: AppColors.mute)),
                  Row(children: [
                    for (var i = 0; i < sides.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: o.photo(sides[i].$1) == null
                              ? null
                              : () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(o.photo(sides[i].$1)!))),
                          child: Column(children: [
                            AspectRatio(aspectRatio: 1, child: PartThumb(height: 72, radius: 12, imageUrl: o.photo(sides[i].$1))),
                            const SizedBox(height: 4),
                            Text(sides[i].$2, style: tx(12, w: w5, c: AppColors.ink2)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ]),
              ),
            // للبائع: بيانات المستلم بعد الدفع (ما تظهر في الإعلان العام)
            if (o.sellerId == myId && o.paidAt != null)
              AppCard(
                color: AppColors.sage,
                border: AppColors.sageB,
                child: VCol(gap: 10, [
                  Text('بيانات المستلم', style: tx(16, w: w6, c: AppColors.teal)),
                  KV('الاسم', o.buyer?.displayName ?? ''),
                  if (o.buyer?.phone != null) KV('الجوال', ltr(o.buyer!.phone!)),
                  if (o.buyer?.city != null) KV('المدينة', o.buyer!.city!),
                  KV('عنوان التسليم', o.shippingAddress ?? 'ما حدده المشتري — راسله من زر المحادثة'),
                ]),
              ),
            if (o.carrier != null || o.shippingAddress != null)
              AppCard(
                child: VCol(gap: 10, [
                  Text('الشحنة', style: tx(16, w: w6)),
                  if (o.carrier != null) KV('شركة الشحن', o.carrier!),
                  if (o.trackingNo != null)
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: o.trackingNo!));
                        if (context.mounted) showToast(context, 'تم نسخ رقم التتبع');
                      },
                      child: KV('رقم التتبع', ltr(o.trackingNo!), icon: LucideIcons.copy),
                    ),
                  if (o.shippingAddress != null) KV('عنوان التوصيل', o.shippingAddress!),
                ]),
              ),
            AppCard(
              child: VCol(gap: 10, [
                Row(children: [
                  PartThumb(width: 72, height: 72, radius: 14, imageUrl: o.image ?? o.photo('front')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.title, style: tx(15, w: w5)),
                      Text('${o.condition ?? ''} · الكمية ${o.quantity}', style: tx(12, c: AppColors.mute)),
                      Text(fmtMoney(o.subtotal), style: tx(16, w: w6, c: AppColors.teal)),
                    ]),
                  ),
                ]),
                const HLine(),
                KV(o.buyerId == myId ? 'البائع' : 'المشتري', (o.buyerId == myId ? o.seller : o.buyer)?.displayName ?? ''),
                KV('رقم الطلب', ltr(o.orderNo)),
                KV(o.paidAt != null ? 'الإجمالي المدفوع' : 'الإجمالي', fmtMoney2(o.total), vColor: AppColors.pri),
                if (o.invoiceNo != null) GestureDetector(onTap: () => context.push('/invoice/${o.id}'), child: KV('الفاتورة', ltr(o.invoiceNo!), vColor: AppColors.teal)),
              ]),
            ),
            if (o.sellerId == myId && (o.status == 'paid' || o.status == 'preparing'))
              AppButton('صوّر القطعة واشحنها', icon: LucideIcons.camera, onTap: () => context.push('/m/document/${o.id}')),
            if (o.buyerId == myId && o.status == 'awaiting_payment')
              AppButton('ادفع الآن', icon: LucideIcons.lock, onTap: () {
                ref.read(checkoutOrdersProvider.notifier).state = [o.id];
                context.push('/checkout');
              }),
            if (o.buyerId == myId && o.status == 'shipped')
              AppButton('تأكيد الاستلام', icon: LucideIcons.check, onTap: () async {
                if (await run(context, () => Api.confirmReceived(o.id), success: 'شكراً! تم تأكيد الاستلام')) {
                  ref.invalidate(orderProvider(id));
                  ref.invalidate(myOrdersProvider);
                }
              }),
            GestureDetector(
              onTap: () => openChat(context, o.buyerId == myId ? o.sellerId : o.buyerId, listingId: o.listingId),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.red),
                const SizedBox(width: 6),
                Text('الإبلاغ عن مشكلة في الطلب', style: tx(14, w: w5, c: AppColors.red)),
              ]),
            ),
          ]);
        }, onRetry: () => ref.invalidate(orderProvider(id))),
      ],
    );
  }
}
