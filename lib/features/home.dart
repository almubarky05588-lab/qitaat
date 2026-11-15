import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/media.dart';
import '../core/product_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import '../data/mock.dart';
import 'banners.dart';
import 'merchant.dart' show customerRequestsProvider;

final homeListingsProvider = FutureProvider<List<Listing>>((ref) => Api.listings(limit: 3));

final currentOrderProvider = FutureProvider<Order?>((ref) async {
  ref.watch(authProvider);
  if (myId == null) return null;
  final all = await Api.myOrders();
  for (final o in all) {
    if (o.status != 'delivered' && o.status != 'cancelled') return o;
  }
  return null;
});

/// المشتري: عدد العروض اللي وصلته على طلباته المفتوحة — التاجر: عدد عروضه المقبولة
final offersCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authProvider);
  final role = ref.watch(roleProvider);
  if (myId == null) return 0;
  if (role == UserRole.merchant) {
    final r = await sb.from('offers').select('id').eq('supplier_id', myId!).eq('status', 'accepted');
    return r.length;
  }
  final reqs = await Api.myRequests();
  return reqs.where((r) => r.isOpen).fold<int>(0, (a, r) => a + r.liveOffers.where((o) => o.status == 'pending').length);
});

/// رقم التنبيه على تبويب «طلبات»: المشتري = عروض جديدة على طلباته المفتوحة — التاجر = طلبات عملاء جديدة ما قدّم عليها
final requestsBadgeProvider = FutureProvider<int>((ref) async {
  ref.watch(authProvider);
  if (myId == null) return 0;
  if (ref.watch(roleProvider) == UserRole.merchant) {
    final all = await ref.watch(customerRequestsProvider.future);
    return all.where((r) => r.isOpen && !r.offers.any((o) => o.supplierId == myId)).length;
  }
  return ref.watch(offersCountProvider.future);
});

/// 04 · الرئيسية
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final listings = ref.watch(homeListingsProvider);
    final current = ref.watch(currentOrderProvider).valueOrNull;
    final unread = (ref.watch(notificationsProvider).valueOrNull ?? const []).where((n) => !n.read).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.pri,
        onRefresh: () async => refreshAll(ref, [homeListingsProvider, currentOrderProvider, offersCountProvider, requestsBadgeProvider, bannersProvider, favoriteIdsProvider]),
        child: ListView(padding: EdgeInsets.zero, children: [
          // الشريط العلوي
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Row(children: [
              const AppLogo(size: 50),
              const SizedBox(width: 14),
              Expanded(child: Text('قطعة سيارتك', style: tx(24, w: w7, c: AppColors.pri), maxLines: 1, overflow: TextOverflow.ellipsis)),
              HeaderIcon(LucideIcons.shoppingCart, size: 26, color: AppColors.ink2, onTap: () => context.push('/cart')),
              const SizedBox(width: 14),
              HeaderIcon(LucideIcons.messageSquare, size: 26, color: AppColors.ink2, onTap: () => context.push('/chats')),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(clipBehavior: Clip.none, children: [
                  const Icon(LucideIcons.bell, size: 26, color: AppColors.ink2),
                  if (unread > 0)
                    Positioned(
                      left: -9,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.bg, width: 2)),
                        child: Text(ltr(unread > 9 ? '+9' : '$unread'), style: tx(10, w: w6, c: AppColors.white, h: 1.3)),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: AppField(hint: 'ابحث عن قطعة...', icon: LucideIcons.search, onTap: () => context.push('/search')),
          ),
          const SaduPattern(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: VCol(gap: 18, [
              const PromoCarousel(),
              if (current != null) _CurrentOrderCard(current),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _tile(AppIconsDuo.shoppingBag, AppColors.pink, AppColors.pri, 'تشتري جاهز', 'قطع معروضة الآن — أضفها للسلة', () => context.push('/search'))),
                  const SizedBox(width: 12),
                  Expanded(child: _tile(AppIconsDuo.send, AppColors.tealBg, AppColors.teal, 'تطلب من الموردين', 'ما لقيتها؟ توصلك عروض أسعار', () => context.push('/request-part'))),
                ]),
              ),
              Text('تصفّح حسب الماركة', style: tx(18, w: w6)),
            ]),
          ),
          const SizedBox(height: 12),
          ChipScroller(children: [
            for (final b in Mock.brands) AppChip(b, noBorder: true, px: 20, py: 11, fs: 15, onTap: () => context.push('/search?brand=$b')),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: VCol(gap: 14, [
              Text('وصل حديثاً', style: tx(18, w: w6)),
              AsyncBody<List<Listing>>(
                listings,
                (list) => list.isEmpty
                    ? const EmptyBox(LucideIcons.package, 'ما فيه قطع معروضة للحين')
                    : VCol(gap: 14, [for (final p in list) ProductCard(p, fav: favs.contains(p.id))]),
                onRetry: () => ref.invalidate(homeListingsProvider),
              ),
              AppButton('إظهار المزيد من القطع ←', icon: LucideIcons.layoutGrid, iconFirst: true, v: BtnV.out2, radius: 999, height: 50, fs: 15, onTap: () => context.push('/search')),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tile(IconData icon, Color bg, Color fg, String title, String sub, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: PhosphorIcon(icon, size: 28, color: fg, duotoneSecondaryOpacity: 0.25),
            ),
            const SizedBox(height: 8),
            Text(title, style: tx(15, w: w6), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(sub, style: tx(11, c: AppColors.mute), textAlign: TextAlign.center),
          ]),
        ),
      );
}

/// بطاقة «طلبك الحالي»: الحالة جنب العنوان + شريط المراحل + زر واحد
class _CurrentOrderCard extends ConsumerWidget {
  final Order o;
  const _CurrentOrderCard(this.o);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = o.status == 'awaiting_payment' && o.payDeadline != null && o.payDeadline!.isBefore(DateTime.now());
    final Widget badge = switch (o.status) {
      'awaiting_payment' => expired ? const StatusBadge.grey('انتهت مهلة الدفع') : const StatusBadge('بانتظار الدفع'),
      'paid' => const StatusBadge.amber('تم الدفع'),
      'preparing' => const StatusBadge.amber('جاري التجهيز'),
      'shipped' => const StatusBadge.teal('في الطريق'),
      _ => const SizedBox(),
    };
    const steps = ['طلب', 'دفع', 'تجهيز', 'شحن', 'تسليم'];
    final payNow = o.status == 'awaiting_payment' && !expired;
    return AppCard(
      child: VCol(gap: 12, [
        Row(children: [
          const Icon(LucideIcons.receipt, size: 20, color: AppColors.pri),
          const SizedBox(width: 8),
          Expanded(child: Text('طلبك الحالي', style: tx(14, w: w5, c: AppColors.ink2))),
          badge,
        ]),
        Text(o.title, style: tx(17, w: w6), maxLines: 2, overflow: TextOverflow.ellipsis),
        Column(children: [
          Row(children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(child: Container(height: 5, decoration: BoxDecoration(color: i < o.progress ? AppColors.teal : AppColors.progressTodo, borderRadius: BorderRadius.circular(3)))),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(child: Text(steps[i], textAlign: TextAlign.center, style: tx(11, w: i == o.progress - 1 ? w6 : w4, c: i < o.progress ? AppColors.teal : AppColors.mute))),
          ]),
        ]),
        payNow
            ? AppButton('أكمل الدفع', icon: LucideIcons.lock, radius: 999, height: 46, fs: 14, onTap: () {
                ref.read(checkoutOrdersProvider.notifier).state = [o.id];
                context.push('/checkout');
              })
            : AppButton(expired ? 'تفاصيل الطلب' : 'تتبّع الطلب', icon: LucideIcons.truck, v: BtnV.out, radius: 999, height: 46, fs: 14, onTap: () => context.push('/order/${o.id}')),
      ]),
    );
  }
}
