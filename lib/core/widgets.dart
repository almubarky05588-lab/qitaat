import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'theme.dart';

// ───────────────── الشعار والنقشة ─────────────────

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/logo/symbol.svg', width: size, height: size);
}

/// نقشة المثلثات (السدو) — مثلثات للأعلى قاعدتها في الأسفل
class SaduPattern extends StatelessWidget {
  final Color color;
  final double height;
  final double tooth;
  final double opacity;
  const SaduPattern({super.key, this.color = AppColors.tan, this.height = 10, this.tooth = 14, this.opacity = 1});
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _SaduPainter(color, tooth)),
        ),
      );
}

class _SaduPainter extends CustomPainter {
  final Color color;
  final double tooth;
  _SaduPainter(this.color, this.tooth);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path();
    for (double x = 0; x < size.width; x += tooth) {
      path.moveTo(x, size.height);
      path.lineTo(x + tooth / 2, 0);
      path.lineTo(x + tooth, size.height);
      path.close();
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────── الهيكل العام للشاشة ─────────────────

class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool back;
  const AppHeader({super.key, required this.title, this.actions = const [], this.back = true});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(children: [
        if (back)
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : null,
            child: const Icon(LucideIcons.arrowRight, size: 24, color: AppColors.ink),
          ),
        if (back) const SizedBox(width: 16),
        Expanded(child: Text(title, style: tx(22, w: w5), overflow: TextOverflow.ellipsis)),
        for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(start: 16), child: a),
      ]),
    );
  }
}

class HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  const HeaderIcon(this.icon, {super.key, this.onTap, this.size = 22, this.color = AppColors.ink});
  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: onTap, child: Icon(icon, size: size, color: color));
}

/// شاشة بقائمة قابلة للتمرير + هيدر اختياري + شريط سفلي اختياري
class AppPage extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  final double gap;
  const AppPage({super.key, this.header, required this.children, this.bottom, this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 40), this.gap = 16});
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(height: gap));
      items.add(children[i]);
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (header != null) header!,
          Expanded(child: ListView(padding: padding, children: items)),
        ]),
      ),
      bottomNavigationBar: bottom,
    );
  }
}

/// شريط أبيض سفلي بحواف علوية مدوّرة يحمل زر/أزرار
class BottomBar extends StatelessWidget {
  final Widget child;
  const BottomBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: const Color(0xFF6B4D33).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: child,
    );
  }
}

// ───────────────── الأزرار ─────────────────

enum BtnV { pri, out, tealOut, white, red, soft, ink, out2 }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BtnV v;
  final double height;
  final double radius;
  final double fs;
  final bool iconFirst;
  final bool expand;
  final bool disabled;
  final VoidCallback? onTap;
  const AppButton(this.label,
      {super.key, this.icon, this.v = BtnV.pri, this.height = 54, this.radius = 16, this.fs = 16, this.iconFirst = false, this.expand = true, this.disabled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color? border;
    Color fg;
    switch (v) {
      case BtnV.pri:
        bg = AppColors.pri;
        fg = AppColors.white;
        break;
      case BtnV.out:
        border = AppColors.pri;
        fg = AppColors.pri;
        break;
      case BtnV.tealOut:
        border = AppColors.teal;
        fg = AppColors.teal;
        break;
      case BtnV.white:
        bg = AppColors.white;
        fg = AppColors.pri;
        break;
      case BtnV.red:
        border = AppColors.red;
        fg = AppColors.red;
        break;
      case BtnV.soft:
        bg = AppColors.pink;
        fg = AppColors.pri;
        break;
      case BtnV.ink:
        border = AppColors.ink2;
        fg = AppColors.ink2;
        break;
      case BtnV.out2:
        border = AppColors.outline2;
        fg = AppColors.pri;
        break;
    }
    final text = label.isEmpty ? null : Text(label, style: tx(fs, w: w5, c: fg, h: 1.2), textAlign: TextAlign.center);
    final ic = icon == null ? null : Icon(icon, size: fs + 2, color: fg);
    final kids = <Widget>[];
    final ordered = iconFirst ? [ic, text] : [text, ic];
    for (final k in ordered) {
      if (k == null) continue;
      if (kids.isNotEmpty) kids.add(const SizedBox(width: 8));
      kids.add(k);
    }
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: disabled ? null : (onTap ?? () {}),
          child: SizedBox(
            height: height,
            width: expand ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: kids),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────── الحقول ─────────────────

class AppField extends StatelessWidget {
  final String hint;
  final String? value;
  final IconData? icon;
  final bool chevron;
  final bool locked;
  final bool area;
  final bool ltrText;
  final bool focus;
  final Widget? trailing;
  final TextInputType? keyboard;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  const AppField(
      {super.key, this.hint = '', this.value, this.icon, this.chevron = false, this.locked = false, this.area = false, this.ltrText = false, this.focus = false, this.trailing, this.keyboard, this.onTap, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final readOnly = locked || chevron || onTap != null;
    return Container(
      height: area ? 110 : 56,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: area ? 6 : 0),
      decoration: BoxDecoration(
        color: locked ? AppColors.beige : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: locked
            ? Border.all(color: AppColors.lockedB)
            : (focus ? Border.all(color: AppColors.pri, width: 1.5) : null),
      ),
      child: Row(crossAxisAlignment: area ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        if (icon != null) Padding(padding: EdgeInsets.only(top: area ? 10 : 0), child: Icon(icon, size: 20, color: AppColors.mute)),
        if (icon != null) const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            initialValue: value,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            keyboardType: keyboard,
            maxLines: area ? 4 : 1,
            textDirection: ltrText ? TextDirection.ltr : null,
            textAlign: ltrText ? TextAlign.left : TextAlign.start,
            style: tx(15),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: tx(15, c: AppColors.ph),
              hintTextDirection: ltrText ? TextDirection.ltr : null,
            ),
          ),
        ),
        if (trailing != null) const SizedBox(width: 10),
        if (trailing != null) trailing!,
        if (chevron) const SizedBox(width: 10),
        if (chevron) const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.mute),
        if (locked) const SizedBox(width: 10),
        if (locked) const Icon(LucideIcons.lock, size: 16, color: AppColors.mute),
      ]),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  final bool required;
  const Label(this.text, {super.key, this.required = false});
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: text, style: tx(14, w: w5)),
        if (required) TextSpan(text: ' *', style: tx(14, w: w5, c: AppColors.pri)),
      ]));
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget field;
  final String? help;
  final bool required;
  const LabeledField(this.label, this.field, {super.key, this.help, this.required = false});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Label(label, required: required),
        const SizedBox(height: 8),
        field,
        if (help != null) const SizedBox(height: 8),
        if (help != null) Text(help!, style: tx(12, c: AppColors.mute)),
      ]);
}

// ───────────────── الشرائح والشارات ─────────────────

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final bool teal;
  final Color? bg;
  final bool noBorder;
  final double fs;
  final double px;
  final double py;
  final Color? color;
  final Color? iconColor;
  final VoidCallback? onTap;
  const AppChip(this.label,
      {super.key, this.selected = false, this.icon, this.teal = false, this.bg, this.noBorder = false, this.fs = 14, this.px = 16, this.py = 9, this.color, this.iconColor, this.onTap});
  @override
  Widget build(BuildContext context) {
    final col = teal ? AppColors.teal : AppColors.pri;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
        decoration: BoxDecoration(
          color: selected ? (teal ? AppColors.tealBg : AppColors.pink) : (bg ?? AppColors.white),
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? Border.all(color: col, width: 1.5)
              : (noBorder ? null : Border.all(color: AppColors.chipB)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, size: 16, color: selected ? col : (iconColor ?? AppColors.mute)),
          if (icon != null) const SizedBox(width: 6),
          Text(label, style: tx(fs, w: selected ? w5 : w4, c: selected ? col : (color ?? AppColors.ink), h: 1.3)),
        ]),
      ),
    );
  }
}

/// مجموعة شرائح قابلة للاختيار (تلتف تلقائياً من اليمين)
class ChipWrap extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final bool teal;
  final double px;
  final double py;
  final ValueChanged<String>? onTap;
  const ChipWrap(this.items, {super.key, this.selected = const {}, this.teal = false, this.px = 16, this.py = 9, this.onTap});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 10, children: [
        for (final s in items)
          AppChip(s, selected: selected.contains(s), teal: teal, px: px, py: py, onTap: onTap == null ? null : () => onTap!(s)),
      ]);
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  final IconData? icon;
  const StatusBadge(this.label, {super.key, this.bg = AppColors.pink, this.color = AppColors.pri, this.icon});
  const StatusBadge.teal(this.label, {super.key, this.icon})
      : bg = AppColors.tealBg,
        color = AppColors.teal;
  const StatusBadge.grey(this.label, {super.key, this.icon})
      : bg = AppColors.greyBg,
        color = AppColors.mute;
  const StatusBadge.amber(this.label, {super.key, this.icon})
      : bg = AppColors.amberBg,
        color = AppColors.amber;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, size: 13, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(label, style: tx(12, w: w5, c: color, h: 1.4)),
        ]),
      );
}

/// شارة حالة القطعة (أصلية / مستعملة) — تظهر بشكل بارز
class ConditionBadge extends StatelessWidget {
  final String condition;
  const ConditionBadge(this.condition, {super.key});
  @override
  Widget build(BuildContext context) => StatusBadge.teal('الحالة: $condition', icon: LucideIcons.badgeCheck);
}

// ───────────────── الاختيار من خيارات (شبكة 2×2) ─────────────────

class SelectCell extends StatelessWidget {
  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback? onTap;
  final double height;
  const SelectCell(this.label, {super.key, this.sub, this.selected = false, this.onTap, this.height = 50});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.pink : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.pri : AppColors.chipB, width: selected ? 1.5 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, textAlign: TextAlign.center, style: tx(15, w: selected ? w6 : w4, c: selected ? AppColors.pri : AppColors.ink, h: 1.3)),
            if (sub != null) Text(sub!, textAlign: TextAlign.center, style: tx(11, c: AppColors.mute)),
          ]),
        ),
      );
}

class SelectGrid extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, String> subs;
  const SelectGrid({super.key, required this.options, required this.selected, required this.onChanged, this.subs = const {}});
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(Row(children: [
        Expanded(child: SelectCell(options[i], sub: subs[options[i]], selected: selected == options[i], onTap: () => onChanged(options[i]))),
        const SizedBox(width: 10),
        Expanded(
            child: i + 1 < options.length
                ? SelectCell(options[i + 1], sub: subs[options[i + 1]], selected: selected == options[i + 1], onTap: () => onChanged(options[i + 1]))
                : const SizedBox()),
      ]));
    }
    return Column(children: rows);
  }
}

// ───────────────── البطاقات ─────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final Color? border;
  final double borderWidth;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20, this.color = AppColors.white, this.border, this.borderWidth = 1, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border!, width: borderWidth),
          ),
          child: child,
        ),
      );
}

/// صورة القطعة (مكان مؤقت بأيقونة سيارة إلى أن تُرفع الصور)
class PartThumb extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool heart;
  final bool fav;
  final String? imageUrl;
  const PartThumb({super.key, this.width, required this.height, this.radius = 16, this.heart = false, this.fav = false, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    final base = width ?? height;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(radius)),
            alignment: Alignment.center,
            child: imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: Image.network(imageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                : Icon(LucideIcons.car, size: (base < height ? base : height) * 0.28, color: AppColors.thumbIcon),
          ),
        ),
        if (heart)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: Icon(LucideIcons.heart, size: 17, color: fav ? AppColors.pri : AppColors.mute),
            ),
          ),
      ]),
    );
  }
}

class MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const MetaItem(this.icon, this.text, {super.key, this.color = AppColors.mute});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text, style: tx(13, c: color, h: 1.3)),
      ]);
}

class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoBox(this.text, {super.key, this.icon = LucideIcons.info});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: tx(12, c: AppColors.teal))),
        ]),
      );
}

class KV extends StatelessWidget {
  final String k;
  final String v;
  final Color? vColor;
  final IconData? icon;
  final bool bold;
  const KV(this.k, this.v, {super.key, this.vColor, this.icon, this.bold = false});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(k, style: tx(bold ? 16 : 14, w: bold ? w6 : w4, c: bold ? AppColors.ink : AppColors.mute))),
        Text(v, style: tx(bold ? 18 : 14, w: bold ? w7 : w5, c: vColor ?? (bold ? AppColors.pri : AppColors.ink))),
        if (icon != null) const SizedBox(width: 6),
        if (icon != null) Icon(icon, size: 16, color: AppColors.pri),
      ]);
}

class HLine extends StatelessWidget {
  final Color color;
  const HLine({super.key, this.color = AppColors.line});
  @override
  Widget build(BuildContext context) => Container(height: 1, color: color);
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const AppToggle({super.key, required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? AppColors.pri : AppColors.toggleOff, borderRadius: BorderRadius.circular(15)),
          alignment: value ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle)),
        ),
      );
}

class ToggleRow extends StatelessWidget {
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const ToggleRow({super.key, required this.title, this.sub, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => AppCard(
        radius: 18,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(15, w: w5)),
              if (sub != null) Text(sub!, style: tx(12, c: AppColors.mute)),
            ]),
          ),
          const SizedBox(width: 12),
          AppToggle(value: value, onChanged: onChanged),
        ]),
      );
}

class SegTabs extends StatelessWidget {
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;
  const SegTabs({super.key, required this.items, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.segBg, borderRadius: BorderRadius.circular(999)),
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == selected ? AppColors.white : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                  child: Text(items[i], style: tx(14, w: i == selected ? w6 : w4, c: i == selected ? AppColors.pri : AppColors.mute, h: 1.2)),
                ),
              ),
            ),
          ],
        ]),
      );
}

/// صف شرائح أفقي قابل للتمرير يبدأ من اليمين
class ChipScroller extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const ChipScroller({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 20)});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ]),
      );
}

class IconSquare extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color bg;
  final Color color;
  final double radius;
  const IconSquare(this.icon, {super.key, this.size = 48, this.iconSize = 22, this.bg = AppColors.pink, this.color = AppColors.pri, this.radius = 14});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, size: iconSize, color: color),
      );
}

class Avatar extends StatelessWidget {
  final double size;
  final IconData? icon;
  final String? letter;
  final Color bg;
  final Color color;
  const Avatar({super.key, this.size = 52, this.icon, this.letter, this.bg = AppColors.pink, this.color = AppColors.pri});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: letter != null
            ? Text(letter!, style: tx(size * 0.38, w: w6, c: color, h: 1.2))
            : Icon(icon ?? LucideIcons.store, size: size * 0.46, color: color),
      );
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Icon(LucideIcons.badgeCheck, size: size, color: AppColors.teal);
}

class Stars extends StatelessWidget {
  final String text;
  const Stars(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(LucideIcons.star, size: 14, color: AppColors.star),
        const SizedBox(width: 4),
        Text(text, style: tx(12, c: AppColors.teal, h: 1.3)),
      ]);
}

class SectionTitle extends StatelessWidget {
  final String text;
  final double size;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.size = 18, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, style: tx(size, w: w6))),
        if (trailing != null) trailing!,
      ]);
}

// ───────────────── القوائم (حسابي / الإعدادات) ─────────────────

class MenuEntry {
  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  MenuEntry(this.icon, this.title, {this.sub, this.onTap, this.trailing, this.color});
}

class MenuGroup extends StatelessWidget {
  final String? title;
  final List<MenuEntry> items;
  final bool headerInside;
  const MenuGroup({super.key, this.title, required this.items, this.headerInside = true});
  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    if (title != null && headerInside) {
      kids.add(Container(
        color: AppColors.sec,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(title!, style: tx(13, c: AppColors.mute)),
      ));
    }
    for (var i = 0; i < items.length; i++) {
      final e = items[i];
      kids.add(InkWell(
        onTap: e.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(children: [
            Icon(e.icon, size: 24, color: e.color ?? AppColors.ink2),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: tx(16, c: e.color ?? AppColors.ink)),
                if (e.sub != null) Text(e.sub!, style: tx(12, c: AppColors.mute)),
              ]),
            ),
            e.trailing ?? (e.color == null ? const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute) : const SizedBox()),
          ]),
        ),
      ));
      if (i < items.length - 1) {
        kids.add(Padding(padding: const EdgeInsetsDirectional.only(start: 58, end: 20), child: const HLine()));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids),
    );
  }
}

// ───────────────── أدوات مساعدة ─────────────────

class Gap extends StatelessWidget {
  final double size;
  const Gap(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// صف بفواصل ثابتة بين العناصر
class HRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;
  final MainAxisAlignment main;
  const HRow(this.children, {super.key, this.gap = 10, this.cross = CrossAxisAlignment.center, this.main = MainAxisAlignment.start});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: cross, mainAxisAlignment: main, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          children[i],
        ],
      ]);
}

class VCol extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;
  const VCol(this.children, {super.key, this.gap = 12, this.cross = CrossAxisAlignment.stretch});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: cross, mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ]);
}

void showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: tx(14, c: AppColors.white)),
    backgroundColor: AppColors.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
}

/// نافذة سفلية بنفس شكل التصميم (حواف 28 + مقبض)
Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    barrierColor: const Color(0xFF1A1209).withOpacity(0.45),
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 36 + MediaQuery.of(ctx).viewInsets.bottom),
      decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.chipB, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 16),
        child,
      ]),
    ),
  );
}
