import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/state.dart';
import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';

String money(num v) => fmtMoney2(v);

// ───────────────── 08 · السلة ─────────────────

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool busy = false;

  Widget _stepBtn(IconData ic, bool filled, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: filled ? AppColors.pri : AppColors.white, shape: BoxShape.circle),
          child: Icon(ic, size: 14, color: filled ? AppColors.white : AppColors.ink2),
        ),
      );

  Future<void> _setQty(String id, int q) async {
    await run(context, () => Api.setCartQty(id, q));
    ref.invalidate(cartProvider);
  }

  Future<void> _checkout() async {
    setState(() => busy = true);
    try {
      final ids = await Api.checkoutCart(null);
      ref.invalidate(cartProvider);
      if (ids.isEmpty) {
        if (mounted) showToast(context, 'القطع في السلة ما عادت متوفرة');
        return;
      }
      ref.read(checkoutOrdersProvider.notifier).state = ids;
      if (mounted) context.push('/checkout');
    } catch (e) {
      if (mounted) showToast(context, errMsg(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cv = ref.watch(cartProvider);
    final items = cv.valueOrNull ?? const <(Listing, int)>[];
    final sub = items.fold<num>(0, (a, e) => a + (e.$1.price ?? 0) * e.$2);
    final count = items.fold<int>(0, (a, e) => a + e.$2);
    final sellers = items.map((e) => e.$1.sellerId).toSet().length;
    final ship = shippingFee * sellers;
    final vat = (sub + ship) * vatRate;
    final total = sub + ship + vat;

    return AppPage(
      header: AppHeader(title: 'السلة', actions: [
        if (items.isNotEmpty)
          GestureDetector(
            onTap: () async {
              await run(context, Api.clearCart);
              ref.invalidate(cartProvider);
            },
            child: Text('حذف الكل', style: tx(13, w: w5, c: AppColors.red)),
          ),
      ]),
      gap: 14,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      bottom: items.isEmpty
          ? null
          : BottomBar(
              child: busy
                  ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
                  : AppButton('إتمام الشراء — ${money(total)}', icon: LucideIcons.arrowLeft, onTap: _checkout),
            ),
      children: [
        if (cv.isLoading && items.isEmpty) const Loading(),
        if (cv.hasError) ErrorBox(cv.error!, onRetry: () => ref.invalidate(cartProvider)),
        if (!cv.isLoading && items.isEmpty && !cv.hasError)
          EmptyBox(LucideIcons.shoppingCart, 'سلتك فاضية',
              action: AppButton('تصفّح القطع', expand: false, radius: 999, height: 46, fs: 15, onTap: () => context.push('/search'))),
        for (final e in items)
          AppCard(
            onTap: () => context.push('/part/${e.$1.id}'),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PartThumb(width: 80, height: 80, radius: 14, imageUrl: e.$1.cover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.$1.title} · ${e.$1.condition}', style: tx(15, w: w5)),
                  Text('البائع: ${e.$1.sellerName}', style: tx(12, c: AppColors.mute)),
                  Text(fmtMoney(e.$1.price ?? 0), style: tx(16, w: w6, c: AppColors.teal)),
                ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                GestureDetector(onTap: () => _setQty(e.$1.id, 0), child: const Icon(LucideIcons.trash2, size: 20, color: AppColors.mute)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _stepBtn(LucideIcons.plus, true, () {
                      if (e.$2 < e.$1.quantity) {
                        _setQty(e.$1.id, e.$2 + 1);
                      } else {
                        showToast(context, 'الكمية المتوفرة ${e.$1.quantity} فقط');
                      }
                    }),
                    const SizedBox(width: 12),
                    Text('${e.$2}', style: tx(15, w: w6)),
                    const SizedBox(width: 12),
                    _stepBtn(LucideIcons.minus, false, () => _setQty(e.$1.id, e.$2 - 1)),
                  ]),
                ),
              ]),
            ]),
          ),
        if (items.isNotEmpty) ...[
          Row(children: [
            const Expanded(child: AppField(hint: 'عندك كود خصم؟', icon: LucideIcons.ticket)),
            const SizedBox(width: 10),
            AppButton('تطبيق', v: BtnV.soft, expand: false, height: 56, onTap: () => showToast(context, 'كود الخصم غير صالح')),
          ]),
          AppCard(
            child: VCol(gap: 10, [
              Text('ملخص الطلب', style: tx(16, w: w6)),
              KV('المجموع ($count قطع)', money(sub)),
              KV('الشحن', money(ship)),
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

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String method = 'mada';
  bool save = true;
  bool busy = false;
  String? address;
  late Future<List<Order>> future = Api.ordersByIds(ref.read(checkoutOrdersProvider));

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

  void _editAddress() {
    String v = address ?? '';
    showAppSheet(
      context,
      VCol(gap: 14, [
        Text('عنوان الشحن', style: tx(18, w: w6)),
        AppField(hint: 'المدينة — الحي، الشارع، رقم المبنى', value: address, area: true, onChanged: (t) => v = t),
        AppButton('حفظ العنوان', onTap: () {
          setState(() => address = v.trim().isEmpty ? null : v.trim());
          Navigator.pop(context);
        }),
      ]),
    );
  }

  Future<void> _pay(List<Order> orders) async {
    if (address == null && orders.any((o) => o.shippingAddress == null)) {
      showToast(context, 'أضف عنوان الشحن أول');
      _editAddress();
      return;
    }
    setState(() => busy = true);
    final ids = orders.map((o) => o.id).toList();
    final label = {'mada': 'مدى', 'apple': 'Apple Pay', 'card': 'بطاقة ائتمانية', 'tabby': 'تابي'}[method]!;
    final ok = await run(context, () async {
      if (address != null) await Api.setOrderAddress(ids, address!);
      await Api.payOrders(ids, label);
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      ref.read(checkoutOrdersProvider.notifier).state = const [];
      context.pushReplacement('/invoice/${ids.first}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: future,
      builder: (c, s) {
        final orders = (s.data ?? const <Order>[]).where((o) => o.status == 'awaiting_payment').toList();
        final sub = orders.fold<num>(0, (a, o) => a + o.subtotal);
        final ship = orders.fold<num>(0, (a, o) => a + o.shipping);
        final vat = orders.fold<num>(0, (a, o) => a + o.vat);
        final total = orders.fold<num>(0, (a, o) => a + o.total);
        final deadline = orders.isEmpty ? null : orders.map((o) => o.payDeadline ?? DateTime.now()).reduce((a, b) => a.isBefore(b) ? a : b);
        final addr = address ?? (orders.isNotEmpty ? orders.first.shippingAddress : null);

        return AppPage(
          header: const AppHeader(title: 'الدفع'),
          children: [
            if (!s.hasData) const Loading(),
            if (s.hasData && orders.isEmpty) const EmptyBox(LucideIcons.checkCircle, 'ما فيه طلبات بانتظار الدفع'),
            if (orders.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Icon(LucideIcons.clock, size: 20, color: AppColors.pri),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(TextSpan(style: tx(13, c: AppColors.ink2), children: [
                      const TextSpan(text: 'أكمل الدفع خلال '),
                      TextSpan(text: fmtLeft(deadline).replaceFirst('باقي ', ''), style: tx(13, w: w6, c: AppColors.pri)),
                      const TextSpan(text: ' قبل انتهاء مهلة العرض'),
                    ])),
                  ),
                ]),
              ),
              for (final o in orders)
                AppCard(
                  child: Row(children: [
                    PartThumb(width: 76, height: 76, radius: 14, imageUrl: o.image),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(o.title, style: tx(16, w: w5)),
                        Text('${o.condition ?? ''} · المورد: ${o.seller?.displayName ?? ''}', style: tx(13, c: AppColors.mute)),
                        Text(fmtMoney(o.subtotal), style: tx(17, w: w6, c: AppColors.teal)),
                      ]),
                    ),
                  ]),
                ),
              AppCard(
                onTap: _editAddress,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const IconSquare(LucideIcons.mapPin, size: 40, iconSize: 20, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('عنوان الشحن', style: tx(15, w: w5)),
                      Text(addr ?? 'اضغط لإضافة عنوان الشحن', style: tx(13, c: addr == null ? AppColors.pri : AppColors.mute)),
                    ]),
                  ),
                  Text(addr == null ? 'إضافة' : 'تغيير', style: tx(14, w: w5, c: AppColors.pri)),
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
                  KV(orders.length > 1 ? 'سعر القطع' : 'سعر القطعة', money(sub)),
                  KV('الشحن', money(ship)),
                  KV('ضريبة القيمة المضافة (15%)', money(vat)),
                  const HLine(),
                  KV('الإجمالي', money(total), bold: true),
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
              busy
                  ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(color: AppColors.pri)))
                  : AppButton('ادفع ${money(total)}', icon: LucideIcons.lock, height: 56, onTap: () => _pay(orders)),
            ],
          ],
        );
      },
    );
  }
}

// ───────────────── 10 · الفاتورة ─────────────────

final orderProvider = FutureProvider.family<Order?, String>((ref, id) => Api.order(id));

class InvoiceScreen extends ConsumerWidget {
  final String id;
  const InvoiceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ov = ref.watch(orderProvider(id));
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
        HeaderIcon(LucideIcons.share2, onTap: () => showToast(context, 'مشاركة الفاتورة تتفعّل مع نشر التطبيق')),
        HeaderIcon(LucideIcons.download, onTap: () => showToast(context, 'تحميل PDF يتفعّل مع نشر التطبيق')),
      ]),
      children: [
        AsyncBody<Order?>(ov, (o) {
          if (o == null) return const EmptyBox(LucideIcons.receipt, 'الفاتورة غير موجودة');
          final paid = o.paidAt != null;
          final pt = o.paidAt ?? o.createdAt ?? DateTime.now();
          return VCol(gap: 16, [
            if (paid)
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
                    paid ? const StatusBadge.teal('مدفوعة', icon: LucideIcons.check) : const StatusBadge('غير مدفوعة'),
                  ]),
                  const SaduPattern(color: AppColors.bg, height: 8, tooth: 12),
                  kv('رقم الفاتورة', ltr(o.invoiceNo ?? '—')),
                  kv('التاريخ', '${fmtDate(pt)} — ${fmtTime(pt)}'),
                  kv('رقم الطلب', ltr(o.orderNo)),
                  const HLine(),
                  Text('البائع', style: tx(14, w: w6)),
                  kv('الاسم', o.seller?.displayName ?? ''),
                  if (o.seller?.storeVat != null) kv('الرقم الضريبي', ltr(o.seller!.storeVat!)),
                  if (o.seller?.storeCr != null) kv('السجل التجاري', ltr(o.seller!.storeCr!)),
                  if (o.seller?.city != null) kv('المدينة', o.seller!.city!),
                  const HLine(),
                  Text('المشتري', style: tx(14, w: w6)),
                  kv('الاسم', o.buyer?.displayName ?? ''),
                  if (o.buyer?.phone != null) kv('الجوال', ltr(o.buyer!.phone!)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      row('الصنف', 'الكمية', 'المبلغ', head: true),
                      const HLine(color: Color(0xFFE6D9C8)),
                      row('${o.title}${o.condition == null ? '' : ' · ${o.condition}'}', '${o.quantity}', o.subtotal.toStringAsFixed(2)),
                      const HLine(color: Color(0xFFE6D9C8)),
                      row('رسوم الشحن', '1', o.shipping.toStringAsFixed(2)),
                    ]),
                  ),
                  kv('المجموع قبل الضريبة', money(o.subtotal + o.shipping)),
                  kv('ضريبة القيمة المضافة 15%', money(o.vat)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(child: Text('الإجمالي', style: tx(16, w: w6))),
                      Text(money(o.total), style: tx(20, w: w7, c: AppColors.pri)),
                    ]),
                  ),
                  if (o.paymentMethod != null) kv('طريقة الدفع', o.paymentMethod!),
                  const HLine(),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('رمز الفاتورة الإلكترونية', style: tx(13, w: w6)),
                        Text('متوافق مع متطلبات هيئة الزكاة والضريبة والجمارك', style: tx(12, c: AppColors.mute)),
                      ]),
                    ),
                    const SizedBox(width: 14),
                    _QrBox(seed: o.orderNo.hashCode),
                  ]),
                ]),
              ),
            ),
            Row(children: [
              Expanded(child: AppButton('تحميل PDF', icon: LucideIcons.download, onTap: () => showToast(context, 'تحميل PDF يتفعّل مع نشر التطبيق'))),
              const SizedBox(width: 12),
              Expanded(child: AppButton('مشاركة', icon: LucideIcons.share2, v: BtnV.out, onTap: () => showToast(context, 'مشاركة الفاتورة تتفعّل مع نشر التطبيق'))),
            ]),
            AppButton('تتبّع الشحنة', icon: LucideIcons.truck, v: BtnV.tealOut, onTap: () => context.push('/order/${o.id}')),
          ]);
        }),
      ],
    );
  }
}

class _QrBox extends StatelessWidget {
  final int seed;
  const _QrBox({required this.seed});
  @override
  Widget build(BuildContext context) => SizedBox(width: 100, height: 100, child: CustomPaint(painter: _QrPainter(seed)));
}

class _QrPainter extends CustomPainter {
  final int seed0;
  _QrPainter(this.seed0);
  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final cs = size.width / n;
    final ink = Paint()..color = AppColors.ink;
    final white = Paint()..color = AppColors.white;
    var seed = seed0.abs() % 233280 + 7;
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

final myOrdersProvider = FutureProvider<List<Order>>((ref) {
  ref.watch(authProvider);
  return Api.myOrders();
});

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});
  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final ov = ref.watch(myOrdersProvider);
    return AppPage(
      header: const AppHeader(title: 'فواتيري'),
      gap: 14,
      children: [
        AsyncBody<List<Order>>(ov, (all) {
          final paid = all.where((o) => o.invoiceNo != null).toList();
          final year = DateTime.now().year;
          final yearTotal = paid.where((o) => o.paidAt?.year == year && o.status != 'cancelled').fold<num>(0, (a, o) => a + o.total);
          final list = paid.where((o) => filter == 0 || (filter == 1 ? o.status != 'cancelled' : o.status == 'cancelled')).toList();
          return VCol(gap: 14, [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.gradient),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('إجمالي مشترياتك في $year', style: tx(13, c: AppColors.white.withOpacity(0.85))),
                  Text(ltr(money(yearTotal)), style: tx(28, w: w7, c: AppColors.white, h: 1.3)),
                  Text('${paid.length} فواتير', style: tx(13, c: AppColors.white.withOpacity(0.85))),
                ]),
              ),
            ),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < 3; i++) AppChip(const ['الكل', 'مدفوعة', 'مستردة'][i], selected: filter == i, px: 14, py: 7, onTap: () => setState(() => filter = i)),
            ]),
            if (list.isEmpty) const EmptyBox(LucideIcons.receipt, 'ما عندك فواتير للحين'),
            for (final o in list)
              AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/invoice/${o.id}'),
                child: Row(children: [
                  const IconSquare(LucideIcons.receipt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ltr(o.invoiceNo!), style: tx(15, w: w6)),
                      Text('${o.title} · ${fmtDate(o.paidAt)}', style: tx(12, c: AppColors.mute)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(money(o.total), style: tx(15, w: w6)),
                    const SizedBox(height: 4),
                    o.status == 'cancelled' ? const StatusBadge.grey('مستردة') : const StatusBadge.teal('مدفوعة'),
                  ]),
                ]),
              ),
          ]);
        }),
      ],
    );
  }
}
