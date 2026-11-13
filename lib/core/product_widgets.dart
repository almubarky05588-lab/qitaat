import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/api.dart';
import 'theme.dart';
import 'widgets.dart';

/// بطاقة القطعة الأفقية (وصل حديثاً / إعلاناتي)
class ProductCard extends StatelessWidget {
  final Listing p;
  final bool fav;
  const ProductCard(this.p, {super.key, this.fav = false});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      border: p.boosted ? AppColors.pinkB : null,
      onTap: () => context.push('/part/${p.id}'),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (p.boosted) const Padding(padding: EdgeInsets.only(bottom: 4), child: StatusBadge('مميز', icon: LucideIcons.star)),
            Text(p.title, style: tx(17, w: w5, c: AppColors.teal)),
            Text(p.priceLabel, style: tx(19, w: w6, c: p.auction ? AppColors.pri : AppColors.teal)),
            const SizedBox(height: 4),
            Wrap(spacing: 10, runSpacing: 4, children: [
              MetaItem(LucideIcons.user, p.sellerName),
              MetaItem(LucideIcons.clock, fmtAgo(p.createdAt)),
              if (p.city != null) MetaItem(LucideIcons.mapPin, p.city!),
            ]),
          ]),
        ),
        const SizedBox(width: 14),
        PartThumb(width: 104, height: 104, heart: true, fav: fav, imageUrl: p.cover),
      ]),
    );
  }
}

/// بطاقة القطعة في الشبكة (نتائج البحث / المفضلة)
class ProductTile extends StatelessWidget {
  final Listing p;
  final bool fav;
  const ProductTile(this.p, {super.key, this.fav = false});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      border: p.boosted ? AppColors.pinkB : null,
      onTap: () => context.push('/part/${p.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PartThumb(width: double.infinity, height: 120, radius: 14, heart: true, fav: fav, imageUrl: p.cover),
        const SizedBox(height: 6),
        Text(p.title, style: tx(14, w: w5), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text(p.priceLabel, style: tx(16, w: w6, c: p.auction ? AppColors.pri : AppColors.teal)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          MetaItem(LucideIcons.clock, fmtAgo(p.createdAt)),
          if (p.city != null) MetaItem(LucideIcons.mapPin, p.city!),
        ]),
      ]),
    );
  }
}

/// شبكة عمودين
class TwoColGrid extends StatelessWidget {
  final List<Widget> children;
  const TwoColGrid(this.children, {super.key});
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: children[i]),
          const SizedBox(width: 12),
          Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
        ]),
      ));
    }
    return Column(children: rows);
  }
}
