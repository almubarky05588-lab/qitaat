import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

String money(double v) => '${v.toStringAsFixed(2)} ر.س';

// ───────────────── 08 · السلة ─────────────────

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final sub = items.fold<double>(0, (a, e) => a + (e.product.price ?? 0) * e.qty);
    final count = items.fold<int>(0, (a, e) => a + e.qty);
    final vat = (sub + shippingFee) * vatRate;
    final total = sub + shippingFee + vat;

    Widget stepBtn(IconData ic, bool filled, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: filled ? AppColors.pri : AppColors.white, shape: BoxShape.circle),
            child: Icon(ic, size: 14, color: filled ? AppColors.white : AppColors.ink2),
          ),
        );

    return AppPage(
      header: AppHeader(title: 'السلة', actions: [
        GestureDetector(onTap: cart.clear, child: Text('حذف الكل', style: tx(13, w: w5, c: AppColors.red))),
      ]),
      gap: 14,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      bottom: items.isEmpty
          ? null
          : BottomBar(child: AppButton('إتمام الشراء — ${money(total)}', icon: LucideIcons.arrowLeft, onTap: () => context.push('/checkout'))),
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(children: [
              const Icon(LucideIcons.shoppingCart, size: 56, color: AppColors.thumbIcon),
              const SizedBox(height: 12),
              Text('سلتك فاضية', style: tx(18, w: w6)),
            ]),
          ),
        for (final e in items)
          AppCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PartThumb(width: 80, height: 80, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.product.title} · ${e.product.condition}', style: tx(15, w: w5)),
                  Text('البائع: ${e.product.seller}', style: tx(12, c: AppColors.mute)),
                  Text(sar(e.product.price ?? 0), style: tx(16, w: w6, c: AppColors.teal)),
                ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                GestureDetector(onTap: () => cart.remove(e.product.id), child: const Icon(LucideIcons.trash2, size: 20, color: AppColors.mute)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    stepBtn(LucideIcons.plus, true, () => cart.setQty(e.product.id, e.qty + 1)),
                    const SizedBox(width: 12),
                    Text('${e.qty}', style: tx(15, w: w6)),
                    const SizedBox(width: 12),
                    stepBtn(LucideIcons.minus, false, () => cart.setQty(e.product.id, e.qty - 1)),
                  ]),
                ),
              ]),
            ]),
          ),
        if (items.isNotEmpty) ...[
          Row(children: [
            const Expanded(child: AppField(hint: 'عندك كود خصم؟', icon: LucideIcons.ticket)),
            const SizedBox(width: 10),
            AppButton('تطبيق', v: BtnV.soft, expand: false, height: 56),
          ]),
          AppCard(
            child: VCol(gap: 10, [
              Text('ملخص الطلب', style: tx(16, w: w6)),
              KV('المجموع ($count قطع)', money(sub)),
              KV('الشحن', money(shippingFee)),
              KV('ضريبة القيمة المضافة (15%)', money(vat)),
              const HLine(),
              KV('الإجمالي', money(total), bold: true),
            ]),
          ),
        ],
      ],
    );
  }
}

// ───────────────── 09 · بوابة الدفع ─────────────────

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String method = 'mada';
  bool save = true;

  Widget _logo(String t, Color bg, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: tx(12, w: w7, c: c, h: 1.2)),
      );

  Widget _radio(bool on) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: on ? AppColors.pri : const Color(0xFFCDBFAF), width: on ? 2 : 1.5)),
        child: on ? Container(width: 11, height: 11, decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle)) : null,
      );

  Widget _method(String key, String title, String? sub, List<Widget> logos, {Widget? expanded}) {
    final on = method == key;
    return AppCard(
      radius: 18,
      border: on ? AppColors.pri : null,
      borderWidth: 1.5,
      onTap: () => setState(() => method = key),
      child: VCol(gap: 14, [
        Row(children: [
          _radio(on),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: tx(15, w: w5)),
              if (sub != null) Text(sub, style: tx(12, c: AppColors.mute)),
            ]),
          ),
          ...logos.expand((w) => [w, const SizedBox(width: 6)]),
        ]),
        if (on && expanded != null) expanded,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'الدفع'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(LucideIcons.clock, size: 20, color: AppColors.pri),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(TextSpan(style: tx(13, c: AppColors.ink2), children: [
                const TextSpan(text: 'أكمل الدفع خلال '),
                TextSpan(text: '23:41', style: tx(13, w: w6, c: AppColors.pri)),
                const TextSpan(text: ' قبل انتهاء مهلة العرض'),
              ])),
            ),
          ]),
        ),
        AppCard(
          child: Row(children: [
            const PartThumb(width: 76, height: 76, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('صدام أمامي كامري 2020', style: tx(16, w: w5)),
                Text('جديد أصلي · المورد: كار ون', style: tx(13, c: AppColors.mute)),
                Text(sar(450), style: tx(17, w: w6, c: AppColors.teal)),
              ]),
            ),
          ]),
        ),
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconSquare(LucideIcons.mapPin, size: 40, iconSize: 20, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('عنوان الشحن', style: tx(15, w: w5)),
                Text('الرياض — حي النرجس، شارع الأمير محمد بن سلمان', style: tx(13, c: AppColors.mute)),
              ]),
            ),
            Text('تغيير', style: tx(14, w: w5, c: AppColors.pri)),
          ]),
        ),
        Text('طريقة الدفع', style: tx(17, w: w6)),
        _method('mada', 'بطاقة مدى', null, [_logo('mada', const Color(0xFFEAF3FB), const Color(0xFF1E5AA8))],
            expanded: VCol(gap: 14, [
              const HLine(),
              const LabeledField('رقم البطاقة', AppField(hint: '0000 0000 0000 0000', icon: LucideIcons.creditCard, ltrText: true, keyboard: TextInputType.number)),
              Row(children: [
                const Expanded(child: LabeledField('تاريخ الانتهاء', AppField(hint: 'MM / YY', ltrText: true))),
                const SizedBox(width: 10),
                const Expanded(child: LabeledField('CVV', AppField(hint: '•••', icon: LucideIcons.lock, ltrText: true))),
              ]),
              const LabeledField('اسم حامل البطاقة', AppField(hint: 'كما هو مكتوب على البطاقة')),
              GestureDetector(
                onTap: () => setState(() => save = !save),
                child: Row(children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: save ? AppColors.pri : AppColors.white, borderRadius: BorderRadius.circular(6), border: save ? null : Border.all(color: AppColors.chipB)),
                    child: save ? const Icon(LucideIcons.check, size: 12, color: AppColors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Text('احفظ البطاقة للمرات الجاية', style: tx(13, c: AppColors.ink2)),
                ]),
              ),
            ])),
        _method('apple', 'Apple Pay', 'ادفع بلمسة', [_logo(' Pay', const Color(0xFF111111), AppColors.white)]),
        _method('card', 'بطاقة ائتمانية', 'Visa · Mastercard', [_logo('VISA', const Color(0xFFEEF1FA), const Color(0xFF1A1F71)), _logo('MC', const Color(0xFFFDF0E6), const Color(0xFFEB001B))]),
        _method('tabby', 'تابي', 'قسّمها على 4 دفعات بدون فوائد', [_logo('tabby', const Color(0xFF3BFFC1), const Color(0xFF111111))]),
        AppCard(
          child: VCol(gap: 10, [
            Text('ملخص المبلغ', style: tx(16, w: w6)),
            KV('سعر القطعة', money(450)),
            KV('الشحن', money(35)),
            KV('ضريبة القيمة المضافة (15%)', money(72.75)),
            const HLine(),
            KV('الإجمالي', money(557.75), bold: true),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.tealBg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(LucideIcons.shieldCheck, size: 22, color: AppColors.teal),
            const SizedBox(width: 10),
            Expanded(child: Text('دفع آمن ومشفّر — المبلغ محفوظ عند المنصة لين تستلم قطعتك', style: tx(13, c: AppColors.teal))),
          ]),
        ),
        AppButton('ادفع ${money(557.75)}', icon: LucideIcons.lock, height: 56, onTap: () => context.pushReplacement('/invoice')),
      ],
    );
  }
}

// ───────────────── 10 · الفاتورة ─────────────────

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget kv(String k, String v) => Row(children: [
          Expanded(child: Text(k, style: tx(13, c: AppColors.mute))),
          Text(v, style: tx(13, w: w5)),
        ]);
    Widget row(String a, String q, String p, {bool head = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Expanded(child: Text(a, style: tx(13, w: head ? w5 : w4, c: head ? AppColors.mute : AppColors.ink))),
            SizedBox(width: 40, child: Text(q, textAlign: TextAlign.center, style: tx(13, w: head ? w5 : w4, c: head ? AppColors.mute : AppColors.ink))),
            SizedBox(width: 70, child: Text(p, textAlign: TextAlign.left, style: tx(13, w: head ? w5 : w6, c: head ? AppColors.mute : AppColors.ink))),
          ]),
        );

    return AppPage(
      header: AppHeader(title: 'الفاتورة', actions: [
        HeaderIcon(LucideIcons.share2, onTap: () => showToast(context, 'مشاركة الفاتورة')),
        HeaderIcon(LucideIcons.download, onTap: () => showToast(context, 'جاري التحميل')),
      ]),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.sageB)),
          child: Row(children: [
            const Icon(LucideIcons.checkCircle, size: 28, color: AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تم الدفع بنجاح', style: tx(16, w: w6, c: AppColors.teal)),
                Text('وصلت فاتورتك على الجوال، وبيبدأ المورد يجهّز الشحنة', style: tx(12, c: AppColors.ink2)),
              ]),
            ),
          ]),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
            child: VCol(gap: 14, [
              Row(children: [
                const AppLogo(size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('قطعة سيارتك', style: tx(17, w: w7, c: AppColors.pri)),
                    Text('فاتورة ضريبية مبسّطة', style: tx(12, c: AppColors.mute)),
                  ]),
                ),
                const StatusBadge.teal('مدفوعة', icon: LucideIcons.check),
              ]),
              const SaduPattern(color: AppColors.bg, height: 8, tooth: 12),
              kv('رقم الفاتورة', ltr('INV-2026-001284')),
              kv('التاريخ', '2026/11/08 — 6:20 م'),
              kv('رقم الطلب', ltr('ORD-58213')),
              const HLine(),
              Text('البائع', style: tx(14, w: w6)),
              kv('الاسم', 'كار ون'),
              kv('الرقم الضريبي', ltr('310XXXXXXXX0003')),
              kv('السجل التجاري', ltr('7001XXXXXX')),
              kv('المدينة', 'حفر الباطن'),
              const HLine(),
              Text('المشتري', style: tx(14, w: w6)),
              kv('الاسم', 'عبدالله'),
              kv('الجوال', ltr('+966 55 123 4567')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  row('الصنف', 'الكمية', 'المبلغ', head: true),
                  const HLine(color: Color(0xFFE6D9C8)),
                  row('صدام أمامي كامري 2020 · جديد أصلي', '1', '450.00'),
                  const HLine(color: Color(0xFFE6D9C8)),
                  row('رسوم الشحن', '1', '35.00'),
                ]),
              ),
              kv('المجموع قبل الضريبة', money(485)),
              kv('ضريبة القيمة المضافة 15%', money(72.75)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Expanded(child: Text('الإجمالي', style: tx(16, w: w6))),
                  Text(money(557.75), style: tx(20, w: w7, c: AppColors.pri)),
                ]),
              ),
              kv('طريقة الدفع', 'مدى •••• 9010'),
              const HLine(),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('رمز الفاتورة الإلكترونية', style: tx(13, w: w6)),
                    Text('متوافق مع متطلبات هيئة الزكاة والضريبة والجمارك', style: tx(12, c: AppColors.mute)),
                  ]),
                ),
                const SizedBox(width: 14),
                const _QrBox(),
              ]),
            ]),
          ),
        ),
        Row(children: [
          Expanded(child: AppButton('تحميل PDF', icon: LucideIcons.download)),
          const SizedBox(width: 12),
          Expanded(child: AppButton('مشاركة', icon: LucideIcons.share2, v: BtnV.out)),
        ]),
        AppButton('تتبّع الشحنة', icon: LucideIcons.truck, v: BtnV.tealOut, onTap: () => context.push('/order/o1')),
      ],
    );
  }
}

/// رمز QR شكلي (يُولّد فعلياً من بيانات الفاتورة عند الربط)
class _QrBox extends StatelessWidget {
  const _QrBox();
  @override
  Widget build(BuildContext context) => SizedBox(width: 100, height: 100, child: CustomPaint(painter: _QrPainter()));
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final cs = size.width / n;
    final ink = Paint()..color = AppColors.ink;
    final white = Paint()..color = AppColors.white;
    var seed = 7;
    double rnd() {
      seed = (seed * 9301 + 49297) % 233280;
      return seed / 233280;
    }

    bool finder(int x, int y) => (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (finder(x, y)) continue;
        if (rnd() > 0.52) canvas.drawRect(Rect.fromLTWH(x * cs, y * cs, cs, cs), ink);
      }
    }
    void fp(int x, int y) {
      canvas.drawRect(Rect.fromLTWH(x * cs, y * cs, cs * 7, cs * 7), ink);
      canvas.drawRect(Rect.fromLTWH((x + 1) * cs, (y + 1) * cs, cs * 5, cs * 5), white);
      canvas.drawRect(Rect.fromLTWH((x + 2) * cs, (y + 2) * cs, cs * 3, cs * 3), ink);
    }

    fp(0, 0);
    fp(n - 7, 0);
    fp(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────── 23 · فواتيري ─────────────────

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final list = Mock.invoices.where((i) => filter == 0 || (filter == 1 ? !i.refunded : i.refunded)).toList();
    return AppPage(
      header: const AppHeader(title: 'فواتيري'),
      gap: 14,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.gradient),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('إجمالي مشترياتك في 2026', style: tx(13, c: AppColors.white.withOpacity(0.85))),
              Text(ltr('1,240.50 ر.س'), style: tx(28, w: w7, c: AppColors.white, h: 1.3)),
              Text('7 فواتير', style: tx(13, c: AppColors.white.withOpacity(0.85))),
            ]),
          ),
        ),
        Wrap(spacing: 8, children: [
          for (var i = 0; i < 3; i++) AppChip(const ['الكل', 'مدفوعة', 'مستردة'][i], selected: filter == i, px: 14, py: 7, onTap: () => setState(() => filter = i)),
        ]),
        for (final inv in list)
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => context.push('/invoice'),
            child: Row(children: [
              const IconSquare(LucideIcons.receipt),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ltr(inv.no), style: tx(15, w: w6)),
                  Text(inv.desc, style: tx(12, c: AppColors.mute)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${inv.amount} ر.س', style: tx(15, w: w6)),
                const SizedBox(height: 4),
                inv.refunded ? const StatusBadge.grey('مستردة') : const StatusBadge.teal('مدفوعة'),
              ]),
            ]),
          ),
      ],
    );
  }
}
