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

Future<void> toggleFav(BuildContext context, WidgetRef ref, String listingId) async {
  final favs = ref.read(favoriteIdsProvider).valueOrNull ?? {};
  final on = !favs.contains(listingId);
  await run(context, () => Api.toggleFavorite(listingId, on), success: on ? 'أُضيفت للمفضلة' : 'أُزيلت من المفضلة');
  ref.invalidate(favoriteIdsProvider);
}

// ───────────────── 06 · نتائج البحث ─────────────────

class SearchScreen extends ConsumerStatefulWidget {
  final String query;
  final String? brand;
  const SearchScreen({super.key, required this.query, this.brand});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late String q = widget.query;
  late String? brand = widget.brand;
  String? condition;
  int sort = 0; // 0 الأحدث، 1 الأقل سعر
  late Future<List<Listing>> future = _load();

  Future<List<Listing>> _load() => Api.listings(q: q, brand: brand);

  void _reload() => setState(() => future = _load());

  void _pick(String title, List<String> opts, String? current, ValueChanged<String?> onPick) {
    showAppSheet(
      context,
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: tx(18, w: w6)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: SingleChildScrollView(
            child: Wrap(spacing: 8, runSpacing: 10, children: [
              AppChip('الكل', selected: current == null, onTap: () {
                onPick(null);
                Navigator.pop(context);
              }),
              for (final o in opts)
                AppChip(o, selected: o == current, onTap: () {
                  onPick(o);
                  Navigator.pop(context);
                }),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _filter(String label, {bool sel = false, VoidCallback? onTap}) =>
      AppChip(label, selected: sel, px: 14, icon: LucideIcons.chevronDown, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
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
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(LucideIcons.search, size: 20, color: AppColors.mute),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: q,
                        autofocus: q.isEmpty && brand == null,
                        textInputAction: TextInputAction.search,
                        style: tx(15),
                        decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'ابحث عن قطعة...', hintStyle: tx(15, c: AppColors.ph)),
                        onFieldSubmitted: (v) {
                          q = v;
                          _reload();
                        },
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => sort = sort == 0 ? 1 : 0),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(LucideIcons.slidersHorizontal, size: 22, color: AppColors.white),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              ChipScroller(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), children: [
                _filter(brand ?? 'الماركة', sel: brand != null, onTap: () => _pick('الماركة', Mock.allBrands, brand, (v) {
                      brand = v;
                      _reload();
                    })),
                _filter(condition ?? 'الحالة', sel: condition != null, onTap: () => _pick('الحالة', Mock.sellConditions, condition, (v) => setState(() => condition = v))),
                _filter(sort == 0 ? 'الأحدث' : 'الأقل سعر', sel: sort == 1, onTap: () => setState(() => sort = sort == 0 ? 1 : 0)),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: FutureBuilder<List<Listing>>(
                  future: future,
                  builder: (c, s) {
                    if (s.hasError) return ErrorBox(s.error!, onRetry: _reload);
                    if (!s.hasData) return const Loading();
                    var list = s.data!.where((p) => condition == null || p.condition == condition).toList();
                    if (sort == 1) list.sort((a, b) => (a.price ?? a.topBid ?? a.startPrice ?? 0).compareTo(b.price ?? b.topBid ?? b.startPrice ?? 0));
                    return VCol(gap: 12, [
                      Row(children: [
                        Text('${list.length} نتيجة', style: tx(14, w: w5, c: AppColors.ink2)),
                        const Spacer(),
                        Text(sort == 0 ? 'الأحدث' : 'الأقل سعر', style: tx(14, w: w5, c: AppColors.pri)),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.pri),
                      ]),
                      if (list.isEmpty)
                        EmptyBox(LucideIcons.search, 'ما لقينا قطع مطابقة — اطلبها من الموردين وتوصلك عروضهم',
                            action: AppButton('اطلب القطعة', icon: LucideIcons.send, expand: false, radius: 999, height: 46, fs: 15, onTap: () => context.push('/request-part'))),
                      TwoColGrid([for (final p in list) ProductTile(p, fav: favs.contains(p.id))]),
                    ]);
                  },
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 07 · تفاصيل القطعة (سعر محدد) / 07ب (على السوم) ─────────────────

final listingProvider = FutureProvider.family<Listing?, String>((ref, id) => Api.listing(id));
final bidsProvider = FutureProvider.family<List<Bid>, String>((ref, id) => Api.bids(id));
final commentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) => Api.comments(id));
final similarProvider = FutureProvider.family<List<Listing>, String>((ref, brand) => Api.listings(brand: brand, limit: 8));

class PartDetailsScreen extends ConsumerWidget {
  final String id;
  const PartDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lv = ref.watch(listingProvider(id));
    final l = lv.valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: lv.when(
          loading: () => Column(children: const [AppHeader(title: 'تفاصيل القطعة'), Expanded(child: Loading())]),
          error: (e, _) => Column(children: [const AppHeader(title: 'تفاصيل القطعة'), ErrorBox(e, onRetry: () => ref.invalidate(listingProvider(id)))]),
          data: (p) => p == null
              ? Column(children: const [AppHeader(title: 'تفاصيل القطعة'), EmptyBox(LucideIcons.package, 'الإعلان غير متوفر')])
              : _Details(p),
        ),
      ),
      bottomNavigationBar: l != null && l.auction && l.sellerId != myId && l.status == 'active'
          ? BottomBar(
              child: Row(children: [
                Expanded(child: AppButton('اعرض سومتك', icon: LucideIcons.gavel, onTap: () => showBidSheet(context, ref, l))),
                const SizedBox(width: 10),
                AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, expand: false, onTap: () => openChat(context, l.sellerId, listingId: id)),
              ]),
            )
          : null,
    );
  }
}

Future<void> openChat(BuildContext context, String otherId, {String? listingId}) async {
  try {
    final cid = await Api.startChat(otherId, listingId: listingId);
    if (context.mounted) context.push('/chat/$cid');
  } catch (e) {
    if (context.mounted) showToast(context, errMsg(e));
  }
}

class _Details extends ConsumerStatefulWidget {
  final Listing p;
  const _Details(this.p);
  @override
  ConsumerState<_Details> createState() => _DetailsState();
}

class _DetailsState extends ConsumerState<_Details> {
  int page = 0;
  final commentCtrl = TextEditingController();
  bool? following;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    try {
      final v = await Api.isFollowing(widget.p.sellerId);
      if (mounted) setState(() => following = v);
    } catch (_) {}
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  Widget _fit(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.fitBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.fitB)),
        child: Row(children: [
          const Icon(LucideIcons.car, size: 22, color: AppColors.ink2),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: tx(15, w: w5))),
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

  Widget _bidRow(Bid b, bool top) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Avatar(size: 36, letter: b.maskedName.substring(0, 1), bg: top ? AppColors.pink : AppColors.bg, color: top ? AppColors.pri : AppColors.mute),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(b.maskedName, style: tx(14, w: w5)),
                if (top) const SizedBox(width: 6),
                if (top) const StatusBadge('الأعلى', icon: LucideIcons.star),
              ]),
              Text(fmtAgo(b.createdAt), style: tx(11, c: AppColors.mute)),
            ]),
          ),
          Text(fmtMoney(b.amount), style: tx(16, w: top ? w7 : w6, c: top ? AppColors.pri : AppColors.ink)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final fav = favs.contains(p.id);
    final isOwner = p.sellerId == myId;
    final seller = p.seller;
    final available = p.status == 'active' && p.quantity > 0;
    final bids = p.auction ? ref.watch(bidsProvider(p.id)).valueOrNull ?? const <Bid>[] : const <Bid>[];
    final comments = ref.watch(commentsProvider(p.id)).valueOrNull ?? const [];
    final similar = (ref.watch(similarProvider(p.brand ?? '')).valueOrNull ?? const <Listing>[]).where((e) => e.id != p.id).toList();

    final header = AppHeader(title: 'تفاصيل القطعة', actions: [
      if (!p.auction) HeaderIcon(LucideIcons.home, size: 24, onTap: () => context.go('/home')),
      HeaderIcon(LucideIcons.share2, onTap: () => showToast(context, 'رابط المشاركة يتفعّل مع نشر التطبيق')),
      HeaderIcon(LucideIcons.flag, onTap: () => showToast(context, 'وصلنا بلاغك وبنراجعه')),
      HeaderIcon(LucideIcons.heart, size: 24, color: fav ? AppColors.pri : AppColors.ink, onTap: () => toggleFav(context, ref, p.id)),
    ]);

    final gallery = Container(
      height: p.auction ? 300 : 330,
      color: AppColors.white,
      child: Stack(children: [
        if (p.images.isEmpty)
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.car, size: 90, color: Color(0xFFC9BBA8)),
              const SizedBox(height: 8),
              Text('صورة القطعة', style: tx(13, c: AppColors.ph)),
            ]),
          )
        else
          PageView(
            onPageChanged: (i) => setState(() => page = i),
            children: [for (final u in p.images) Image.network(u, fit: BoxFit.cover, width: double.infinity)],
          ),
        if (!p.auction && p.images.length > 1)
          Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < p.images.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(color: i == page ? AppColors.pri : const Color(0xFFE1D4C3), borderRadius: BorderRadius.circular(4)),
                ),
            ]),
          ),
        if (p.auction) const PositionedDirectional(top: 16, start: 20, child: StatusBadge('على السوم', icon: LucideIcons.gavel)),
        if (!available) PositionedDirectional(top: 16, end: 20, child: StatusBadge.grey(p.status == 'sold' || p.quantity <= 0 ? 'مباعة' : 'غير متاحة')),
      ]),
    );

    Widget pill(IconData ic, String t) => AppChip(t, icon: ic, bg: AppColors.pillBg, noBorder: true, iconColor: AppColors.ink2, px: 14, py: 8);

    final sellerCard = AppCard(
      onTap: () => context.push('/store/${p.sellerId}'),
      child: Row(children: [
        Avatar(size: p.auction ? 52 : 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(p.sellerName, style: tx(p.auction ? 16 : 18, w: w6))),
              const SizedBox(width: 6),
              seller?.verified == true ? const VerifiedBadge(size: 18) : const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.mute),
            ]),
            Stars(seller?.city ?? ''),
          ]),
        ),
        if (!isOwner)
          AppButton(following == true ? 'تتابعه' : 'متابعة', v: following == true ? BtnV.soft : BtnV.pri, expand: false, height: 38, radius: 12, fs: 14, onTap: () async {
            final on = following != true;
            if (await run(context, () => Api.setFollow(p.sellerId, on))) setState(() => following = on);
          }),
      ]),
    );

    final kids = <Widget>[
      Text(p.title, style: tx(24, w: w6)),
    ];
    if (!p.auction) {
      kids.addAll([
        Text(p.priceLabel, style: tx(28, w: w7, c: AppColors.teal)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          pill(LucideIcons.badgeCheck, p.condition),
          pill(LucideIcons.package, fmtQty(available ? p.quantity : 0)),
          if (p.city != null) pill(LucideIcons.mapPin, p.city!),
          pill(LucideIcons.clock, fmtAgo(p.createdAt)),
          if (p.category != null) pill(LucideIcons.shapes, p.category!),
          if (!p.delivery.contains('shipping')) pill(LucideIcons.store, 'استلام بدون شحن'),
        ]),
        if (p.fits.isNotEmpty) _fit('يناسب: ${p.fits}'),
        sellerCard,
        const HLine(),
        _info(LucideIcons.phone, 'رقم التواصل:', 'راسل البائع عبر المحادثة'),
        const HLine(),
        _info(LucideIcons.mapPin, 'الموقع:', p.city ?? seller?.city ?? '—'),
        const HLine(),
        Text('ملاحظات', style: tx(16, w: w6)),
        Text((p.description ?? '').isEmpty ? '—' : p.description!, style: tx(15, c: AppColors.ink2)),
        if (isOwner) AppButton('إدارة إعلاني', icon: LucideIcons.slidersHorizontal, onTap: () => context.push('/m/listings')),
        if (!isOwner && available)
          AppButton('أضف للسلة', icon: LucideIcons.shoppingCart, onTap: () async {
            final cart = ref.read(cartProvider).valueOrNull ?? const [];
            final cur = cart.where((e) => e.$1.id == p.id).map((e) => e.$2).fold<int>(0, (a, b) => a + b);
            if (cur + 1 > p.quantity) {
              showToast(context, 'الكمية المتوفرة ${p.quantity} فقط');
              return;
            }
            if (await run(context, () => Api.setCartQty(p.id, cur + 1), success: 'أُضيفت للسلة')) ref.invalidate(cartProvider);
          }),
        if (!isOwner && !available) const Center(child: StatusBadge.grey('مباعة — غير متاحة للشراء')),
        if (!isOwner)
          Row(children: [
            Expanded(child: AppButton('ملف البائع', icon: LucideIcons.store, onTap: () => context.push('/store/${p.sellerId}'))),
            const SizedBox(width: 12),
            Expanded(child: AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, onTap: () => openChat(context, p.sellerId, listingId: p.id))),
          ]),
        const HLine(),
        if (similar.isNotEmpty) Text('قطع مشابهة', style: tx(18, w: w6)),
      ]);
    } else {
      final top = bids.isEmpty ? null : bids.first.amount;
      kids.addAll([
        Row(children: [
          Text('على السوم', style: tx(26, w: w7, c: AppColors.pri)),
          const Spacer(),
          if (p.startPrice != null) AppChip('سعر مبدئي ${fmtMoney(p.startPrice!)}', bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
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
                Text(top == null ? 'ما فيه سومات' : fmtMoney(top), style: tx(top == null ? 18 : 24, w: w7, c: AppColors.pri, h: 1.3)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${bids.length} سومات', style: tx(14, w: w6)),
              if (bids.isNotEmpty) Text('آخر سومة ${fmtAgo(bids.map((b) => b.createdAt ?? DateTime(2000)).reduce((a, b) => a.isAfter(b) ? a : b))}', style: tx(12, c: AppColors.mute)),
            ]),
          ]),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ConditionBadge(p.condition),
          AppChip(fmtQty(available ? p.quantity : 0), icon: LucideIcons.package, bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
          if (p.city != null) AppChip(p.city!, icon: LucideIcons.mapPin, bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
          if (p.category != null) AppChip(p.category!, icon: LucideIcons.shapes, bg: AppColors.pillBg, noBorder: true, fs: 13, px: 12, py: 6),
        ]),
        if (p.fits.isNotEmpty) _fit('يناسب: ${p.fits}'),
        sellerCard,
        if ((p.description ?? '').isNotEmpty) Text(p.description!, style: tx(15, c: AppColors.ink2)),
        AppCard(
          child: VCol(gap: 4, [
            Row(children: [
              Expanded(child: Text('السومات', style: tx(17, w: w6))),
              if (p.auctionEndsAt != null) Text(fmtLeft(p.auctionEndsAt).replaceFirst('باقي', 'تنتهي بعد'), style: tx(12, c: AppColors.mute)),
            ]),
            const SizedBox(height: 6),
            if (bids.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('كن أول من يسوم', style: tx(14, c: AppColors.mute))),
            for (var i = 0; i < bids.length; i++) ...[
              _bidRow(bids[i], i == 0),
              if (i < bids.length - 1) const HLine(),
            ],
          ]),
        ),
        if (isOwner) AppButton('إدارة السومات', icon: LucideIcons.gavel, onTap: () => context.push('/m/bids')),
      ]);
    }

    return Column(children: [
      header,
      Expanded(
        child: RefreshIndicator(
          color: AppColors.pri,
          onRefresh: () async => refreshAll(ref, [listingProvider(p.id), bidsProvider(p.id), commentsProvider(p.id)]),
          child: ListView(padding: EdgeInsets.zero, children: [
            gallery,
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: VCol(gap: 14, kids)),
            if (!p.auction) ...[
              if (similar.isNotEmpty) const SizedBox(height: 12),
              if (similar.isNotEmpty)
                SizedBox(
                  height: 210,
                  child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                    for (final s in similar)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 12),
                        child: SizedBox(
                          width: 160,
                          child: AppCard(
                            padding: const EdgeInsets.all(12),
                            onTap: () => context.push('/part/${s.id}'),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              PartThumb(width: 136, height: 96, radius: 14, imageUrl: s.cover),
                              const SizedBox(height: 8),
                              Text(s.title, style: tx(14, w: w5), maxLines: 2),
                              const Spacer(),
                              Text(s.priceLabel, style: tx(15, w: w6, c: AppColors.pri)),
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
                    Expanded(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: commentCtrl,
                          style: tx(15),
                          decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'اكتب تعليقك...', hintStyle: tx(15, c: AppColors.ph)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final t = commentCtrl.text.trim();
                        if (t.isEmpty) return;
                        if (await run(context, () => Api.addComment(p.id, t))) {
                          commentCtrl.clear();
                          ref.invalidate(commentsProvider(p.id));
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(LucideIcons.send, size: 22, color: AppColors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (comments.isEmpty) Center(child: Text('لا توجد تعليقات بعد — كن أول من يعلّق', style: tx(13, c: AppColors.ph))),
                  for (final c in comments)
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${(c['user'] as Map?)?['name'] ?? 'مستخدم'}', style: tx(13, w: w6)),
                        Text('${c['body']}', style: tx(14, c: AppColors.ink2)),
                      ]),
                    ),
                ]),
              ),
            ],
            if (p.auction) const SizedBox(height: 16),
          ]),
        ),
      ),
    ]);
  }
}

// ───────────────── 07ج · اعرض سومتك ─────────────────

void showBidSheet(BuildContext context, WidgetRef ref, Listing p) {
  final bids = ref.read(bidsProvider(p.id)).valueOrNull ?? const <Bid>[];
  final hi = bids.isEmpty ? (p.startPrice ?? 0) : bids.first.amount;
  showAppSheet(context, _BidSheet(p, hi, bids.isEmpty && p.startPrice != null, onDone: () {
    ref.invalidate(bidsProvider(p.id));
    ref.invalidate(listingProvider(p.id));
  }));
}

class _BidSheet extends StatefulWidget {
  final Listing p;
  final num hi;
  final bool firstBid;
  final VoidCallback onDone;
  const _BidSheet(this.p, this.hi, this.firstBid, {required this.onDone});
  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late num amount = widget.firstBid ? widget.hi : widget.hi + 25;
  int quick = 25;
  bool busy = false;

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
    final hi = widget.hi;
    final minAllowed = widget.firstBid ? hi : hi + 1;
    return VCol(gap: 16, [
      Row(children: [
        Expanded(child: Text('اعرض سومتك', style: tx(20, w: w7))),
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(LucideIcons.x, size: 22, color: AppColors.mute)),
      ]),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          PartThumb(width: 52, height: 52, radius: 12, imageUrl: widget.p.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.p.title, style: tx(14, w: w5)),
              Text(widget.firstBid ? 'أقل سومة: ${fmtMoney(hi)}' : 'أعلى سومة حالياً: ${fmtMoney(hi)}', style: tx(13, w: w6, c: AppColors.pri)),
            ]),
          ),
        ]),
      ),
      Row(children: [
        _step(LucideIcons.plus, true, () => setState(() => amount += 10)),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${amount % 1 == 0 ? amount.toInt() : amount}', style: tx(44, w: w7, h: 1.1)),
            const SizedBox(width: 6),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('ر.س', style: tx(18, w: w5, c: AppColors.mute))),
          ]),
        ),
        _step(LucideIcons.minus, false, () => setState(() => amount = amount - 10 >= minAllowed ? amount - 10 : minAllowed)),
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
      InfoBox(widget.firstBid
          ? 'أقل سومة ${fmtMoney(hi)}. لو قبلها البائع تتحول لطلب شراء وتكمل الدفع.'
          : 'لازم تكون سومتك أعلى من ${fmtMoney(hi)}. لو قبلها البائع تتحول لطلب شراء وتكمل الدفع.'),
      busy
          ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
          : AppButton('أرسل السومة — ${fmtMoney(amount)}', icon: LucideIcons.gavel, onTap: () async {
              setState(() => busy = true);
              final ok = await run(context, () => Api.placeBid(widget.p.id, amount), success: 'وصلت سومتك للبائع');
              if (!mounted) return;
              setState(() => busy = false);
              if (ok) {
                widget.onDone();
                Navigator.pop(context);
              }
            }),
    ]);
  }
}

// ───────────────── 21 · المفضلة ─────────────────

final favoritesListProvider = FutureProvider<List<Listing>>((ref) {
  ref.watch(favoriteIdsProvider);
  return Api.favorites();
});

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int tab = 0;
  late Future<List<Profile>> stores = _stores();

  Future<List<Profile>> _stores() async {
    final r = await sb.from('follows').select('store:profiles!follows_store_id_fkey(*)').eq('follower_id', myId!);
    return r.where((e) => e['store'] != null).map<Profile>((e) => Profile.fromJson(Map<String, dynamic>.from(e['store']))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(favoritesListProvider);
    final n = list.valueOrNull?.length ?? 0;
    return AppPage(
      header: const AppHeader(title: 'المفضلة'),
      gap: 14,
      children: [
        SegTabs(items: ['القطع ($n)', 'المتاجر'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        if (tab == 0)
          AsyncBody<List<Listing>>(
            list,
            (items) => items.isEmpty ? const EmptyBox(LucideIcons.heart, 'ما أضفت قطع للمفضلة للحين') : TwoColGrid([for (final p in items) ProductTile(p, fav: true)]),
          ),
        if (tab == 1)
          FutureBuilder<List<Profile>>(
            future: stores,
            builder: (c, s) {
              if (!s.hasData) return const Loading();
              if (s.data!.isEmpty) return const EmptyBox(LucideIcons.store, 'ما تتابع أي متجر للحين');
              return VCol(gap: 12, [
                for (final st in s.data!)
                  AppCard(
                    onTap: () => context.push('/store/${st.id}'),
                    child: Row(children: [
                      const Avatar(size: 48),
                      const SizedBox(width: 12),
                      Expanded(child: Text(st.displayName, style: tx(16, w: w6))),
                      if (st.verified) const VerifiedBadge(size: 20),
                    ]),
                  ),
              ]);
            },
          ),
      ],
    );
  }
}
