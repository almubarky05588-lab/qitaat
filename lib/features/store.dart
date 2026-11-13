import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/media.dart';
import '../core/product_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';
import 'catalog.dart' show openChat;

// ───────────────── عناصر مشتركة للملف الشخصي ─────────────────

/// غلاف عريض + صورة عرض دائرية متداخلة معه
class ProfileCover extends StatelessWidget {
  final Profile p;
  final VoidCallback? onCover, onAvatar;
  const ProfileCover(this.p, {super.key, this.onCover, this.onAvatar});

  @override
  Widget build(BuildContext context) {
    final merchant = p.isMerchant;
    return SizedBox(
      height: 262,
      child: Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: onCover,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.gradient),
            child: p.coverUrl != null ? Image.network(p.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()) : null,
          ),
        ),
        if (p.coverUrl == null) const Positioned(top: 169, left: 0, right: 0, child: SaduPattern(color: AppColors.bg, height: 12)),
        if (onCover != null)
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 10,
            end: 16,
            child: GestureDetector(
              onTap: onCover,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(LucideIcons.camera, size: 14, color: AppColors.white),
                  const SizedBox(width: 4),
                  Text('الغلاف', style: tx(12, c: AppColors.white)),
                ]),
              ),
            ),
          ),
        Positioned(
          top: 124,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: onAvatar,
              child: Container(
                width: 140,
                height: 140,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: merchant ? AppColors.beige : AppColors.tealBg, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 6)),
                child: p.avatarUrl != null
                    ? Image.network(p.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                    : Icon(merchant ? LucideIcons.store : LucideIcons.user, size: 56, color: merchant ? AppColors.thumbIcon : AppColors.teal),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// النبذة + أيقونات حسابات التواصل المعبأة فقط
class BioAndSocials extends StatelessWidget {
  final Profile p;
  const BioAndSocials(this.p, {super.key});

  IconData _icon(String k) => switch (k) { 'x' => LucideIcons.atSign, 'tiktok' => LucideIcons.music, _ => LucideIcons.camera };

  @override
  Widget build(BuildContext context) {
    final links = p.socialLinks;
    final bio = (p.bio ?? '').trim();
    if (bio.isEmpty && links.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
      child: Column(children: [
        if (bio.isNotEmpty) Text(bio, textAlign: TextAlign.center, style: tx(14, c: AppColors.ink2, h: 1.6)),
        if (links.isNotEmpty) const SizedBox(height: 10),
        if (links.isNotEmpty)
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
            for (final l in links)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(l.$3), mode: LaunchMode.externalApplication),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.chipB)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_icon(l.$1), size: 15, color: AppColors.pri),
                    const SizedBox(width: 6),
                    Text(l.$2, style: tx(12, w: w5, c: AppColors.ink2)),
                  ]),
                ),
              ),
          ]),
      ]),
    );
  }
}

/// قائمة شرائح تظهر بصفين، و«إظهار المزيد / أقل» لو أطول
class ExpandableChips extends StatefulWidget {
  final List<String> items;
  const ExpandableChips(this.items, {super.key});
  @override
  State<ExpandableChips> createState() => _ExpandableChipsState();
}

class _ExpandableChipsState extends State<ExpandableChips> {
  static const twoRows = 84.0;
  final key = GlobalKey();
  bool open = false, overflow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant ExpandableChips old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final h = (key.currentContext?.findRenderObject() as RenderBox?)?.size.height ?? 0;
    final o = h > twoRows + 2;
    if (mounted && o != overflow) setState(() => overflow = o);
  }

  @override
  Widget build(BuildContext context) {
    final wrap = Wrap(key: key, spacing: 8, runSpacing: 8, children: [
      for (final b in widget.items) AppChip(b, bg: const Color(0xFFEBE1D3), noBorder: true, py: 7),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: ClipRect(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: open ? double.infinity : twoRows),
            child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: wrap),
          ),
        ),
      ),
      if (overflow)
        GestureDetector(
          onTap: () => setState(() => open = !open),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(open ? 'إظهار أقل' : 'إظهار المزيد (${widget.items.length})', style: tx(13, w: w5, c: AppColors.pri)),
              Icon(open ? LucideIcons.chevronDown : LucideIcons.chevronLeft, size: 16, color: AppColors.pri),
            ]),
          ),
        ),
    ]);
  }
}

// ───────────────── صفحة المتجر / الملف العام (للزوار) ─────────────────

final storeProfileProvider = FutureProvider.family<Profile?, String>((ref, id) => Api.profile(id));
final storeListingsProvider = FutureProvider.family<List<Listing>, String>((ref, id) => Api.listings(sellerId: id, limit: 60));

class StoreScreen extends ConsumerStatefulWidget {
  final String id;
  const StoreScreen({super.key, required this.id});
  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  bool? following;
  int followers = 0;

  @override
  void initState() {
    super.initState();
    _loadSocial();
  }

  Future<void> _loadSocial() async {
    try {
      final f = await Api.isFollowing(widget.id);
      final n = await Api.followersCount(widget.id);
      if (!mounted) return;
      setState(() {
        following = f;
        followers = n;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pv = ref.watch(storeProfileProvider(widget.id));
    final lv = ref.watch(storeListingsProvider(widget.id));
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? {};
    final mine = widget.id == myId;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: pv.when(
        loading: () => const Loading(),
        error: (e, _) => SafeArea(child: ErrorBox(e)),
        data: (p) {
          if (p == null) return const SafeArea(child: EmptyBox(LucideIcons.user, 'الحساب غير موجود'));
          final listings = lv.valueOrNull ?? const <Listing>[];
          return Stack(children: [
            ListView(padding: EdgeInsets.zero, children: [
              ProfileCover(p),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(child: Text(p.displayName, style: tx(24, w: w6), textAlign: TextAlign.center)),
                if (p.verified) const SizedBox(width: 8),
                if (p.verified) const VerifiedBadge(size: 22),
              ]),
              const SizedBox(height: 8),
              Center(child: p.isMerchant ? const StatusBadge.teal('تاجر / مورد') : const StatusBadge('مشتري')),
              if (p.city != null) const SizedBox(height: 8),
              if (p.city != null) Center(child: MetaItem(LucideIcons.mapPin, p.city!)),
              BioAndSocials(p),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                child: VCol(gap: 16, [
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(children: [
                      Expanded(child: Column(children: [Text('${listings.length}', style: tx(19, w: w6, h: 1.3)), Text('إعلان', style: tx(12, c: AppColors.mute))])),
                      Container(width: 1, height: 40, color: AppColors.line),
                      Expanded(child: Column(children: [Text('$followers', style: tx(19, w: w6, h: 1.3)), Text('متابع', style: tx(12, c: AppColors.mute))])),
                    ]),
                  ),
                  if (!mine)
                    Row(children: [
                      Expanded(
                        child: AppButton(following == true ? 'تتابعه' : 'متابعة', v: following == true ? BtnV.soft : BtnV.pri, height: 46, fs: 15, onTap: () async {
                          final on = following != true;
                          if (await run(context, () => Api.setFollow(p.id, on))) {
                            setState(() {
                              following = on;
                              followers += on ? 1 : -1;
                            });
                          }
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: AppButton('مراسلة', icon: LucideIcons.messageSquare, v: BtnV.tealOut, height: 46, fs: 15, onTap: () => openChat(context, p.id))),
                    ]),
                  if (p.isMerchant && p.brands.isNotEmpty) ...[
                    Text('تخصص المحل', style: tx(14, w: w5)),
                    ExpandableChips(p.brands),
                  ],
                  if (listings.isNotEmpty) Text('الإعلانات', style: tx(18, w: w6)),
                  if (lv.isLoading) const Loading(pad: 20),
                  if (listings.isNotEmpty) TwoColGrid([for (final l in listings) ProductTile(l, fav: favs.contains(l.id))]),
                ]),
              ),
            ]),
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 8,
              start: 16,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.arrowRight, size: 20, color: AppColors.white),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
