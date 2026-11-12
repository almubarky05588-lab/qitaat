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

/// 04 · الرئيسية
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _statusLabel(Order o) => switch (o.status) {
        'awaiting_payment' => (o.payDeadline != null && o.payDeadline!.isBefore(DateTime.now())) ? 'انتهت مهلة الدفع' : 'بانتظار الدفع',
        'paid' => 'تم الدفع',
        'preparing' => 'جاري التجهيز',
        'shipped' => 'في الطريق',
        _ => '',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final listings = ref.watch(homeListingsProvider);
    final current = ref.watch(currentOrderProvider).valueOrNull;
    final offers = ref.watch(offersCountProvider).valueOrNull ?? 0;
    final unread = (ref.watch(notificationsProvider).valueOrNull ?? const []).where((n) => !n.read).length;
    final merchant = ref.watch(roleProvider) == UserRole.merchant;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.pri,
        onRefresh: () async => refreshAll(ref, [homeListingsProvider, currentOrderProvider, offersCountProvider, favoriteIdsProvider]),
        child: ListView(padding: EdgeInsets.zero, children: [
          // الشريط العلوي
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Row(children: [
              const AppLogo(size: 50),
              const SizedBox(width: 14),
              Expanded(child: Text('قطعة سيارتك', style: tx(24, w: w7, c: AppColors.pri))),
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
              VCol(gap: 10, cross: CrossAxisAlignment.start, [
                Text('وش عندي الآن؟', style: tx(17, w: w6)),
                GestureDetector(
                  onTap: () => context.push(merchant ? '/m/sales' : '/requests'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.sageB)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.checkCircle, size: 20, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('$offers', style: tx(18, w: w7, c: AppColors.teal, h: 1.2)),
                      const SizedBox(width: 8),
                      Text(merchant ? 'عروضك المقبولة' : 'عروض وصلتك', style: tx(14, c: AppColors.ink2, h: 1.2)),
                    ]),
                  ),
                ),
              ]),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: const BoxDecoration(gradient: AppColors.gradient),
                  child: Stack(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text('قطعتك مو موجودة بالسوق؟', style: tx(20, w: w7, c: AppColors.white)),
                        const SizedBox(height: 6),
                        Text('اطلبها ويوصلك عروض من الموردين المتخصصين', style: tx(14, c: AppColors.white.withOpacity(0.85))),
                        const SizedBox(height: 16),
                        AppButton('اطلب قطعتك الآن', icon: LucideIcons.search, v: BtnV.white, radius: 999, height: 52, onTap: () => context.push('/request-part')),
                      ]),
                    ),
                    const Positioned(left: 0, right: 0, bottom: 0, child: SaduPattern(color: AppColors.white, height: 8, tooth: 12, opacity: 0.14)),
                  ]),
                ),
              ),
              if (current != null)
                AppCard(
                  border: const Color(0xFFF0D5C8),
                  child: VCol(gap: 14, [
                    Row(children: [
                      const Icon(LucideIcons.receipt, size: 20, color: AppColors.pri),
                      const SizedBox(width: 8),
                      Expanded(child: Text('طلبك الحالي', style: tx(15, w: w5))),
                      GestureDetector(onTap: () => context.go('/orders'), child: Text('كل مشترياتي ←', style: tx(13, w: w5, c: AppColors.pri))),
                    ]),
                    Row(children: [
                      Expanded(child: Text(current.title, style: tx(18, w: w6))),
                      StatusBadge(_statusLabel(current)),
                    ]),
                    Row(children: [
                      Expanded(child: AppButton('تفاصيل الطلب', v: BtnV.out2, radius: 999, height: 48, fs: 15, onTap: () => context.push('/order/${current.id}'))),
                      const SizedBox(width: 10),
                      Expanded(child: AppButton('تتبّع الشحنة', icon: LucideIcons.truck, v: BtnV.out2, radius: 999, height: 48, fs: 15, onTap: () => context.push('/order/${current.id}'))),
                    ]),
                  ]),
                ),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _tile(LucideIcons.shoppingBag, 'تشتري جاهز', 'قطع معروضة الآن — أضفها للسلة', () => context.push('/search'))),
                  const SizedBox(width: 12),
                  Expanded(child: _tile(LucideIcons.send, 'تطلب من الموردين', 'ما لقيتها؟ توصلك عروض أسعار', () => context.push('/request-part'))),
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

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.sageB)),
          child: Column(children: [
            Icon(icon, size: 24, color: AppColors.teal),
            const SizedBox(height: 6),
            Text(title, style: tx(16, w: w6), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(sub, style: tx(11, c: AppColors.mute), textAlign: TextAlign.center),
          ]),
        ),
      );
}
