import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'merchant_plus.dart' show CustomerRequestsPage;
import 'requests.dart' show MyRequestsScreen;

/// الهيكل الرئيسي: الشريط السفلي + زر الإضافة العائم
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barH = 66.0;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: shell,
      bottomNavigationBar: SizedBox(
        height: barH + bottomInset + 30,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barH + bottomInset,
              padding: EdgeInsets.only(left: 8, right: 8, top: 10, bottom: bottomInset),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: const Color(0xFF6B4D33).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              // كل تبويب يأخذ نفس العرض، والنص يتوسّط تحت أيقونته بالضبط
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _tab(0, LucideIcons.home, 'الرئيسية')),
                Expanded(child: _tab(1, LucideIcons.shoppingBag, 'مشترياتي')),
                const SizedBox(width: 76),
                Expanded(child: _tab(2, LucideIcons.archive, 'طلبات')),
                Expanded(child: _tab(3, LucideIcons.user, 'حسابي')),
              ]),
            ),
          ),
          Positioned(
            bottom: barH + bottomInset - 34,
            child: GestureDetector(
              onTap: () => showAddSheet(context),
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 60,
                  height: 60,
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
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, size: 24, color: c),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: Text(label, textAlign: TextAlign.center, style: tx(12, w: on ? w5 : w4, c: c, h: 1.2), maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
        ),
      ]),
    );
  }
}

/// تبويب «طلبات»: المشتري يشوف طلباته وعروضها — التاجر يشوف طلبات العملاء المطابقة لتخصصه
class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(roleProvider) == UserRole.merchant;
    return merchant ? const CustomerRequestsPage(inTab: true) : const MyRequestsScreen();
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
      option(LucideIcons.search, 'أبحث عن قطعة', 'طلبك يوصل للموردين المتخصصين', () {
        Navigator.pop(context);
        context.push('/request-part');
      }),
    ]),
  );
}
