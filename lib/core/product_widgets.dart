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
            if (p.status == 'draft') const Padding(padding: EdgeInsets.only(bottom: 4), child: StatusBadge.grey('مسودة · غير منشورة', icon: LucideIcons.pencil)),
            if (p.status == 'paused') const Padding(padding: EdgeInsets.only(bottom: 4), child: StatusBadge.grey('موقوف · غير ظاهر للعامة', icon: LucideIcons.pause)),
            if (p.boosted && p.status == 'active') const Padding(padding: EdgeInsets.only(bottom: 4), child: StatusBadge('مميز', icon: LucideIcons.star)),
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

/// جدول بنود العرض: كل قطعة بسعرها ونوعها وحالتها، وغير المتوفرة واضحة وغير مشمولة
class OfferItemsTable extends StatelessWidget {
  final List<OfferItem> items;
  final bool showNote;
  const OfferItemsTable(this.items, {super.key, this.showNote = true});
  @override
  Widget build(BuildContext context) {
    final av = items.where((e) => e.available).toList();
    final missing = items.where((e) => !e.available).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.sec, borderRadius: BorderRadius.circular(14)),
      child: VCol(gap: 8, [
        for (final e in items)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(e.available ? LucideIcons.checkCircle : LucideIcons.x, size: 16, color: e.available ? AppColors.teal : AppColors.mute),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.qty > 1 ? '${e.name} × ${e.qty}' : e.name,
                    style: tx(14, w: w5, c: e.available ? AppColors.ink : AppColors.mute).copyWith(decoration: e.available ? null : TextDecoration.lineThrough)),
                Text(e.available ? '${e.type} · ${e.condition}${e.qty > 1 ? ' · ${fmtMoney(e.unitPrice ?? 0)} للحبة' : ''}' : 'غير متوفرة — غير مشمولة', style: tx(12, c: AppColors.mute)),
              ]),
            ),
            if (e.available) Text(ltr(fmtMoney(e.total)), style: tx(14, w: w6, c: AppColors.teal)),
          ]),
        if (showNote && missing.isNotEmpty && av.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(10)),
            child: Text('يشمل العرض ${av.map((e) => e.name).join(' و')} فقط؛ ${missing.map((e) => e.name).join(' و')} غير متوفر وغير مشمول',
                style: tx(12, c: AppColors.amber, h: 1.5)),
          ),
      ]),
    );
  }
}
