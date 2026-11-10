import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// الهيكل الرئيسي: الشريط السفلي + زر الإضافة العائم
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: shell,
      bottomNavigationBar: SizedBox(
        height: 72 + bottomInset + 28,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 72 + bottomInset,
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? bottomInset : 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: const Color(0xFF6B4D33).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _tab(0, LucideIcons.home, 'الرئيسية'),
                _tab(1, LucideIcons.shoppingBag, 'مشترياتي'),
                const SizedBox(width: 64),
                _tab(2, LucideIcons.archive, 'طلبات القطع'),
                _tab(3, LucideIcons.user, 'حسابي'),
              ]),
            ),
          ),
          Positioned(
            bottom: 72 + bottomInset - 34,
            child: GestureDetector(
              onTap: () => showAddSheet(context),
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.pri,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.pri.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(LucideIcons.plus, size: 28, color: AppColors.white),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final on = shell.currentIndex == i;
    final c = on ? AppColors.pri : AppColors.mute;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      child: SizedBox(
        width: 66,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24, color: c),
          const SizedBox(height: 4),
          Text(label, style: tx(12, w: on ? w5 : w4, c: c, h: 1.2), maxLines: 1),
        ]),
      ),
    );
  }
}

/// 05 · نافذة الإضافة (+)
void showAddSheet(BuildContext context) {
  Widget option(IconData icon, String title, String sub, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.chipB)),
          child: Row(children: [
            IconSquare(icon, size: 56, iconSize: 26, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tx(18, w: w6)),
                Text(sub, style: tx(14, c: AppColors.mute)),
              ]),
            ),
            const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
          ]),
        ),
      );

  showAppSheet(
    context,
    VCol(gap: 14, [
      Text('وش تبي تسوي؟', style: tx(18, w: w6)),
      option(LucideIcons.tag, 'أبيع قطعة', 'اعرض قطعتك في السوق', () {
        Navigator.pop(context);
        context.push('/sell');
      }),
      option(LucideIcons.search, 'أبحث عن قطعة', 'طلبك ينتشر لكل الموردين', () {
        Navigator.pop(context);
        context.push('/request-part');
      }),
    ]),
  );
}
