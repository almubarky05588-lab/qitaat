import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';

/// بنر إعلاني — يتحكم فيه المدير من صفحة «البنرات» في لوحة الإدارة
class PromoBanner {
  final String id, title;
  final String? subtitle, cta, imageUrl, link;
  final Color color;
  PromoBanner.fromJson(Map<String, dynamic> j)
      : id = '${j['id']}',
        title = j['title'] ?? '',
        subtitle = j['subtitle'],
        cta = j['cta'],
        imageUrl = (j['image_url'] ?? '').toString().isEmpty ? null : j['image_url'],
        link = j['link'],
        color = _hex(j['color']);
  const PromoBanner.fallback()
      : id = 'default',
        title = 'قطعتك ما لقيتها؟',
        subtitle = 'اطلبها وتوصلك عروض من الموردين المتخصصين',
        cta = 'اطلب قطعتك',
        imageUrl = null,
        link = '/request-part',
        color = AppColors.pri;

  static Color _hex(dynamic v) {
    final s = '${v ?? ''}'.replaceAll('#', '').trim();
    final n = int.tryParse(s.length == 6 ? 'FF$s' : s, radix: 16);
    return n == null ? AppColors.pri : Color(n);
  }

  IconData get icon {
    final l = link ?? '';
    if (l.startsWith('/request')) return AppIconsDuo.search;
    if (l.startsWith('/sell')) return AppIconsDuo.tag;
    if (l.contains('subscription')) return AppIconsDuo.crown;
    if (l.startsWith('/orders')) return AppIconsDuo.truck;
    return AppIconsDuo.sparkle;
  }
}

/// البنرات الفعّالة فقط (مفعّلة وضمن مدة العرض) — لو ما فيه ولا واحد يختفي القسم كامل
final bannersProvider = FutureProvider<List<PromoBanner>>((ref) async {
  final r = await sb.from('banners').select().eq('active', true).order('sort', ascending: true);
  final now = DateTime.now();
  bool live(Map j) {
    final s = DateTime.tryParse('${j['starts_at'] ?? ''}'), e = DateTime.tryParse('${j['ends_at'] ?? ''}');
    return (s == null || !now.isBefore(s)) && (e == null || now.isBefore(e));
  }

  return r.where(live).map<PromoBanner>((e) => PromoBanner.fromJson(Map<String, dynamic>.from(e))).toList();
});

const _tabRoutes = {'/home', '/orders', '/requests', '/account'};

Future<void> openBannerLink(BuildContext context, String? link) async {
  final l = (link ?? '').trim();
  if (l.isEmpty) return;
  if (l.startsWith('http')) {
    await launchUrl(Uri.parse(l), mode: LaunchMode.externalApplication);
  } else if (_tabRoutes.contains(l)) {
    context.go(l);
  } else if (l.startsWith('/')) {
    context.push(l);
  }
}

/// البنرات المتقلبة تحت البحث (تتقلب كل 4 ثواني)
class PromoCarousel extends ConsumerStatefulWidget {
  const PromoCarousel({super.key});
  @override
  ConsumerState<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<PromoCarousel> {
  final ctrl = PageController();
  Timer? timer;
  int page = 0, count = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || count < 2 || !ctrl.hasClients) return;
      ctrl.animateToPage((page + 1) % count, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Widget _slide(PromoBanner b) {
    final body = b.imageUrl != null
        ? Image.network(b.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) => Container(color: b.color))
        : Container(
            color: b.color,
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: tx(18, w: w7, c: AppColors.onPri, h: 1.35), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if ((b.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(b.subtitle!, style: tx(13, c: AppColors.onPri.withOpacity(0.85), h: 1.45), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      if ((b.cta ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.onPri, borderRadius: BorderRadius.circular(999)),
                          child: Text(b.cta!, style: tx(13, w: w6, c: b.color, h: 1.3)),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: AppColors.onPri.withOpacity(0.16), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: PhosphorIcon(b.icon, size: 44, color: AppColors.onPri, duotoneSecondaryOpacity: 0.3),
                  ),
                ]),
              ),
              const Positioned(left: 0, right: 0, bottom: 0, child: SaduPattern(color: AppColors.onPri, height: 9, tooth: 12, opacity: 0.3)),
            ]),
          );
    return GestureDetector(
      onTap: () => openBannerLink(context, b.link),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bannersProvider).valueOrNull ?? const <PromoBanner>[];
    if (list.isEmpty) return const SizedBox.shrink();
    count = list.length;
    if (page >= count) page = 0;
    return Column(children: [
      SizedBox(
        height: 132,
        child: PageView.builder(
          controller: ctrl,
          itemCount: list.length,
          onPageChanged: (i) => setState(() => page = i),
          itemBuilder: (c, i) => _slide(list[i]),
        ),
      ),
      if (list.length > 1) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < list.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == page ? AppColors.pri : AppColors.chipB, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
      ],
    ]);
  }
}
