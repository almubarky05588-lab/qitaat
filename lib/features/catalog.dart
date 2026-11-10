import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/product_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── 06 · نتائج البحث ─────────────────

class SearchScreen extends ConsumerWidget {
  final String query;
  const SearchScreen({super.key, required this.query});

  Widget _filter(String label, {bool sel = false}) => AppChip(label, selected: sel, px: 14, icon: LucideIcons.chevronDown);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(children: [
              GestureDetector(onTap: () => context.pop(), child: const Icon(LucideIcons.arrowRight, size: 24, color: AppColors.ink)),
              const SizedBox(width: 10),
              Expanded(child: AppField(value: query, icon: LucideIcons.search)),
              const SizedBox(width: 10),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.slidersHorizontal, size: 22, color: AppColors.white),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              ChipScroller(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), children: [
                _filter('تويوتا', sel: true),
                _filter('كامري', sel: true),
                _filter('السنة'),
                _filter('الحالة'),
                _filter('السعر'),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: VCol(gap: 12, [
                  Row(children: [
                    Text('${Mock.searchResults.length * 4} نتيجة', style: tx(14, w: w5, c: AppColors.ink2)),
                    const Spacer(),
                    Text('الأحدث', style: tx(14, w: w5, c: AppColors.pri)),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.pri),
                  ]),
                  TwoColGrid([for (final p in Mock.searchResults) ProductTile(p, fav: favs.contains(p.id))]),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 07 · تفاصيل القطعة (سعر محدد) / 07ب (على السوم) ─────────────────

class PartDetailsScreen extends ConsumerWidget {
  final String id;
  const PartDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = Mock.product(id);
    final favs = ref.watch(favoritesProvider);
    final fav = favs.contains(p.id);
    final isOwner = ref.watch(roleProvider) == UserRole.merchant && p.seller == 'كار ون';

    void toggleFav() {
      final s = {...favs};
      fav ? s.remove(p.id) : s.add(p.id);
      ref.read(favoritesProvider.notifier).state = s;
    }

    final header = AppHeader(title: 'تفاصيل القطعة', actions: [
      if (!p.auction) HeaderIcon(LucideIcons.home, size: 24, onTap: () => context.go('/home')),
      const HeaderIcon(LucideIcons.share2),
      const HeaderIcon(LucideIcons.flag),
      HeaderIcon(LucideIcons.heart, size: 24, color: fav ? AppColors.pri : AppColors.ink, onTap: toggleFav),
    ]);

    final gallery = Container(
      height: p.auction ? 300 : 330,
      color: AppColors.white,
      child: Stack(children: [
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.car, size: 90, color: Color(0xFFC9BBA8)),
            const SizedBox(height: 8),
            Text('صورة القطعة', style: tx(13, c: AppColors.ph)),
          ]),
        ),
        if (!p.auction)
          Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == 0 ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(color: i == 0 ? AppColors.pri : const Color(0xFFE1D4C3), borderRadius: BorderRadius.circular(4)),
                ),
            ]),
          ),
        if (p.auction) const PositionedDirectional(top: 16, start: 20, child: StatusBadge('على السوم', icon: LucideIcons.gavel)),
      ]),
    );

    final pill = (IconData ic, String t) => AppChip(t, icon: ic, bg: AppColors.pillBg, noBorder: true, iconColor: AppColors.ink2, px: 14, py: 8);

    final seller = AppCard(
      child: Row(children: [
        Avatar(size: p.auction ? 52 : 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(p.seller, style: tx(p.auction ? 16 : 18, w: w6))),
              const SizedBox(width: 6),
              p.auction ? const VerifiedBadge(size: 18) : const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.mute),
            ]),
            Stars(p.auction ? '4.8 · 120 تقييم' : '0.0 · 0 تقييم'),
          ]),
        ),
        AppButton('متابعة', expand: false, height: 38, radius: 12, fs: 14),
      ]),
    );

    final children = <Widget>[];
    if (!p.auction) {
      children.addAll([
        Text(p.title, style: tx(24, w: w6)),
        Text(p.priceLabel, style: tx(28, w: w7, c: AppColors.teal)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          pill(LucideIcons.badgeCheck, p.condition),
          pill(LucideIcons.mapPin, p.city),
          pill(LucideIcons.clock, p.date),
          pill(LucideIcons.shapes, p.category),
          if (p.pickupOnly) pill(LucideIcons.store, 'استلام بدون شحن'),
        ]),
        _fit(p.fits),
        seller,
        const HLine(),
        _info(LucideIcons.phone, 'رقم التواصل:', 'لم يضف البائع رقم تواصل — راسله عبر المحادثة'),
        const HLine(),
        _info(LucideIcons.mapPin, 'الموقع:', p.city),
        const HLine(),
        Text('ملاحظات', style: tx(16, w: w6)),
        Text(p.notes.isEmpty ? '—' : p.notes, style: tx(15, c: AppColors.ink2)),
        if (isOwner) AppButton('إدارة إعلاني', icon: LucideIcons.slidersHorizontal, onTap: () => context.push('/m/listings')),
        if (!isOwner)
          AppButton('أضف للسلة', icon: LucideIcons.shoppingCart, onTap: () {
            ref.read(cartProvider.notifier).add(p);
            showToast(context, 'أُضيفت للسلة');
          }),
        Row(children: [
          Expanded(child: AppButton('اتصال', icon: LucideIcons.phone)),
          const SizedBox(width: 12),
          Expanded(child: AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, onTap: () => context.push('/chat/c1'))),
        ]),
        const HLine(),
        Text('قطع مشابهة', style: tx(18, w: w6)),
      ]);
    } else {
      children.addAll([
        Text(p.title, style: tx(24, w: w6)),
        Row(children: [
          Text('على السوم', style: tx(26, w: w7, c: AppColors.pri)),
          const Spacer(),
          AppChip('سعر مبدئي ${p.startPrice} ر.س', bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
        ]),
        AppCard(
          color: AppColors.pink,
          border: AppColors.pinkB,
          child: Row(children: [
            const IconSquare(LucideIcons.gavel, bg: AppColors.white, size: 48, iconSize: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('أعلى سومة حالياً', style: tx(13, c: AppColors.ink2)),
                Text(sar(p.highestBid ?? 0), style: tx(24, w: w7, c: AppColors.pri, h: 1.3)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${p.bidsCount} سومات', style: tx(14, w: w6)),
              Text('آخر سومة قبل 12 د', style: tx(12, c: AppColors.mute)),
            ]),
          ]),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ConditionBadge(p.condition),
          AppChip(p.city, icon: LucideIcons.mapPin, bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
          AppChip(p.category, icon: LucideIcons.shapes, bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
        ]),
        _fit('يناسب: ${p.fits}', raw: true),
        seller,
        AppCard(
          child: VCol(gap: 4, [
            Row(children: [
              Expanded(child: Text('السومات', style: tx(17, w: w6))),
              Text('تنتهي بعد 2 يوم', style: tx(12, c: AppColors.mute)),
            ]),
            const SizedBox(height: 6),
            for (var i = 0; i < Mock.bids.length; i++) ...[
              _bidRow(Mock.bids[i]),
              if (i < Mock.bids.length - 1) const HLine(),
            ],
          ]),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          header,
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              gallery,
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: VCol(gap: 14, children)),
              if (!p.auction) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    for (final s in const [233, 23, 222])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: SizedBox(
                          width: 160,
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => context.push('/part/p2'),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const PartThumb(width: 136, height: 96, radius: 14),
                              const SizedBox(height: 8),
                              Text('صدام أمامي كامري 2020', style: tx(14, w: w5), maxLines: 2),
                              const Spacer(),
                              Text(sar(s), style: tx(15, w: w6, c: AppColors.pri)),
                            ]),
                          ),
                        ),
                      ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: VCol(gap: 12, [
                    Text('التعليقات', style: tx(18, w: w6)),
                    Row(children: [
                      const Expanded(child: AppField(hint: 'اكتب تعليقك...')),
                      const SizedBox(width: 10),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(LucideIcons.send, size: 22, color: AppColors.white),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Center(child: Text('لا توجد تعليقات بعد — كن أول من يعلّق', style: tx(13, c: AppColors.ph))),
                  ]),
                ),
              ],
              if (p.auction) const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: p.auction
          ? BottomBar(
              child: Row(children: [
                Expanded(child: AppButton('اعرض سومتك', icon: LucideIcons.gavel, onTap: () => showBidSheet(context, p))),
                const SizedBox(width: 10),
                AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, expand: false, onTap: () => context.push('/chat/c2')),
              ]),
            )
          : null,
    );
  }

  Widget _fit(String fits, {bool raw = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.fitBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.fitB)),
        child: Row(children: [
          const Icon(LucideIcons.car, size: 22, color: AppColors.ink2),
          const SizedBox(width: 10),
          Expanded(child: Text(raw ? fits : 'يناسب: $fits', style: tx(15, w: w5))),
        ]),
      );

  Widget _info(IconData icon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColors.mute),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$k ', style: tx(14, c: AppColors.mute)),
              TextSpan(text: v, style: tx(14, w: w5)),
            ])),
          ),
        ]),
      );

  Widget _bidRow(Bid b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Avatar(size: 36, letter: b.name.substring(0, 1), bg: b.top ? AppColors.pink : AppColors.bg, color: b.top ? AppColors.pri : AppColors.mute),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(b.name, style: tx(14, w: w5)),
                if (b.top) const SizedBox(width: 6),
                if (b.top) const StatusBadge('الأعلى', icon: LucideIcons.star),
              ]),
              Text(b.time, style: tx(11, c: AppColors.mute)),
            ]),
          ),
          Text(sar(b.amount), style: tx(16, w: b.top ? w7 : w6, c: b.top ? AppColors.pri : AppColors.ink)),
        ]),
      );
}

// ───────────────── 07ج · اعرض سومتك ─────────────────

void showBidSheet(BuildContext context, Product p) {
  showAppSheet(context, _BidSheet(p));
}

class _BidSheet extends StatefulWidget {
  final Product p;
  const _BidSheet(this.p);
  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late int amount = (widget.p.highestBid ?? 0) + 30;
  int quick = 25;

  Widget _step(IconData ic, bool filled, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: filled ? AppColors.pri : AppColors.bg, shape: BoxShape.circle),
          child: Icon(ic, size: 22, color: filled ? AppColors.white : AppColors.ink2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hi = widget.p.highestBid ?? 0;
    return VCol(gap: 16, [
      Row(children: [
        Expanded(child: Text('اعرض سومتك', style: tx(20, w: w7))),
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(LucideIcons.x, size: 22, color: AppColors.mute)),
      ]),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const PartThumb(width: 52, height: 52, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.p.title, style: tx(14, w: w5)),
              Text('أعلى سومة حالياً: ${sar(hi)}', style: tx(13, w: w6, c: AppColors.pri)),
            ]),
          ),
        ]),
      ),
      Row(children: [
        _step(LucideIcons.plus, true, () => setState(() => amount += 10)),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$amount', style: tx(44, w: w7, h: 1.1)),
            const SizedBox(width: 6),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('ر.س', style: tx(18, w: w5, c: AppColors.mute))),
          ]),
        ),
        _step(LucideIcons.minus, false, () => setState(() => amount = amount - 10 > hi ? amount - 10 : hi + 1)),
      ]),
      Center(
        child: Wrap(spacing: 8, children: [
          for (final q in const [10, 25, 50, 100])
            AppChip(ltr('+$q'), selected: quick == q, px: 18, onTap: () => setState(() {
                  quick = q;
                  amount = hi + q;
                })),
        ]),
      ),
      InfoBox('لازم تكون سومتك أعلى من ${sar(hi)}. لو قبلها البائع تتحول لطلب شراء وتكمل الدفع.'),
      AppButton('أرسل السومة — ${sar(amount)}', icon: LucideIcons.gavel, onTap: () {
        Navigator.pop(context);
        showToast(context, 'وصلت سومتك للبائع');
      }),
    ]);
  }
}

// ───────────────── 21 · المفضلة ─────────────────

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider);
    final items = [...Mock.products].where((p) => favs.contains(p.id)).toList();
    return AppPage(
      header: const AppHeader(title: 'المفضلة'),
      gap: 14,
      children: [
        SegTabs(items: ['القطع (${items.length})', 'المتاجر (2)'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        if (tab == 0) TwoColGrid([for (final p in items) ProductTile(p, fav: true)]),
        if (tab == 1)
          for (final s in const ['الصقر لقطع الغيار', 'مؤسسة النخبة'])
            AppCard(
              child: Row(children: [
                const Avatar(size: 48),
                const SizedBox(width: 12),
                Expanded(child: Text(s, style: tx(16, w: w6))),
                const VerifiedBadge(size: 20),
              ]),
            ),
      ],
    );
  }
}
