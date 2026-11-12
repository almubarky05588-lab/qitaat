import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../data/api.dart';
import 'theme.dart';
import 'widgets.dart';

export 'package:flutter/services.dart' show Clipboard, ClipboardData;

// ───────────────── التحميل والأخطاء ─────────────────

class Loading extends StatelessWidget {
  final double pad;
  const Loading({super.key, this.pad = 60});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: pad),
        child: const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pri))),
      );
}

class ErrorBox extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorBox(this.error, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.mute),
          const SizedBox(height: 10),
          Text(errMsg(error), textAlign: TextAlign.center, style: tx(14, c: AppColors.mute)),
          if (onRetry != null) const SizedBox(height: 12),
          if (onRetry != null) AppButton('حاول مرة ثانية', v: BtnV.out2, expand: false, height: 44, fs: 14, radius: 999, onTap: onRetry),
        ]),
      );
}

class EmptyBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyBox(this.icon, this.text, {super.key, this.action});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Column(children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
            child: Icon(icon, size: 42, color: AppColors.thumbIcon),
          ),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center, style: tx(15, w: w5, c: AppColors.ink2)),
          if (action != null) const SizedBox(height: 14),
          if (action != null) action!,
        ]),
      );
}

/// يعرض حالة مزوّد غير متزامن (تحميل / خطأ / بيانات)
class AsyncBody<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  const AsyncBody(this.value, this.builder, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const Loading(),
        error: (e, _) => ErrorBox(e, onRetry: onRetry),
      );
}

/// تنفيذ عملية مع رسالة خطأ واضحة
Future<bool> run(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) showToast(context, success);
    return true;
  } catch (e) {
    if (context.mounted) showToast(context, errMsg(e));
    return false;
  }
}

// ───────────────── الصور ─────────────────

/// اختيار صورة (كاميرا أو معرض) ورفعها — يرجع الرابط
Future<String?> pickAndUpload(BuildContext context, {bool cameraOnly = false}) async {
  bool? camera = cameraOnly ? true : null;
  if (camera == null) {
    camera = await showAppSheet<bool>(
      context,
      VCol(gap: 12, [
        Text('أضف صورة', style: tx(18, w: w6)),
        _sheetOption(context, LucideIcons.camera, 'التقط صورة', true),
        _sheetOption(context, LucideIcons.layoutGrid, 'اختر من الصور', false),
      ]),
    );
    if (camera == null) return null;
  }
  try {
    final f = await Api.pickImage(camera: camera);
    if (f == null) return null;
    if (context.mounted) showToast(context, 'جاري رفع الصورة...');
    return await Api.uploadImage(f);
  } catch (e) {
    if (context.mounted) showToast(context, errMsg(e));
    return null;
  }
}

Widget _sheetOption(BuildContext context, IconData icon, String label, bool value) => GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.chipB)),
        child: Row(children: [
          IconSquare(icon, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: tx(16, w: w5))),
          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
        ]),
      ),
    );

/// مربع رفع الصور (إطار متقطع)
class UploadBox extends StatelessWidget {
  final double size;
  final String label;
  final VoidCallback? onTap;
  const UploadBox({super.key, this.size = 96, this.label = 'أضف صور', this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRRect(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: AppColors.uploadBg, borderRadius: BorderRadius.circular(18)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.camera, size: size * 0.27, color: AppColors.pri),
              const SizedBox(height: 4),
              Text(label, style: tx(12, w: w5, c: AppColors.pri)),
            ]),
          ),
        ),
      );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pri
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// صف صور قابل للإضافة والحذف (يرفع مباشرة إلى التخزين)
class PhotoStrip extends StatelessWidget {
  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final double size;
  const PhotoStrip({super.key, required this.urls, required this.onChanged, this.max = 8, this.size = 96});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final u in urls) ...[
          Stack(children: [
            PartThumb(width: size, height: size, radius: 18, imageUrl: u),
            Positioned(
              left: 6,
              top: 6,
              child: GestureDetector(
                onTap: () => onChanged([...urls]..remove(u)),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 14, color: AppColors.ink2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 10),
        ],
        if (urls.length < max)
          UploadBox(
            size: size,
            onTap: () async {
              final u = await pickAndUpload(context);
              if (u != null) onChanged([...urls, u]);
            },
          ),
      ]),
    );
  }
}

/// لإعادة تحميل مزوّد عند السحب للأسفل
Future<void> refreshAll(WidgetRef ref, List<ProviderOrFamily> providers) async {
  for (final p in providers) {
    ref.invalidate(p);
  }
}
