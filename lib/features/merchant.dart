import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';
import 'requests.dart' show UploadBox;

Widget _gradientCard({required List<Widget> children}) => ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: Stack(children: [
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
          const Positioned(left: 0, right: 0, bottom: 0, child: SaduPattern(color: AppColors.white, height: 8, tooth: 12, opacity: 0.14)),
        ]),
      ),
    );

Widget _glass(Widget child, {EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8), double radius = 12}) => Container(
      padding: padding,
      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(radius)),
      child: child,
    );

// ───────────────── T03 · لوحة المتجر ─────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int period = 1;

  Widget _stat(IconData ic, String v, String t, bool teal) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconSquare(ic, size: 38, iconSize: 20, radius: 12, bg: teal ? AppColors.tealBg : AppColors.pink, color: teal ? AppColors.teal : AppColors.pri),
            const SizedBox(height: 6),
            Text(v, style: tx(22, w: w7, h: 1.3)),
            Text(t, style: tx(12, c: AppColors.mute)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const bars = [40.0, 65.0, 30.0, 90.0, 55.0, 120.0, 75.0];
    const days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    return AppPage(
      header: const AppHeader(title: 'لوحة المتجر'),
      children: [
        SegTabs(items: const ['اليوم', 'الأسبوع', 'الشهر'], selected: period, onChanged: (i) => setState(() => period = i)),
        _gradientCard(children: [
          Text('أرباح هذا الأسبوع', style: tx(13, c: AppColors.white.withOpacity(0.85))),
          Text(ltr('4,820 ر.س'), style: tx(32, w: w7, c: AppColors.white, h: 1.3)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _glass(
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.trendingUp, size: 14, color: AppColors.white),
                const SizedBox(width: 4),
                Text('+18% عن الأسبوع الماضي', style: tx(12, w: w5, c: AppColors.white)),
              ]),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              radius: 999,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('قابل للتحويل', style: tx(12, c: AppColors.white.withOpacity(0.8))),
                Text(ltr('3,150 ر.س'), style: tx(17, w: w6, c: AppColors.white)),
              ]),
            ),
            AppButton('تحويل للآيبان', v: BtnV.white, radius: 999, height: 42, fs: 14, expand: false, onTap: () => context.push('/m/earnings')),
          ]),
          const SizedBox(height: 6),
        ]),
        Row(children: [_stat(LucideIcons.inbox, '12', 'طلبات جديدة تناسبك', false), const SizedBox(width: 12), _stat(LucideIcons.tag, '34', 'عرض سعر أرسلته', true)]),
        Row(children: [_stat(LucideIcons.percent, '41%', 'نسبة قبول عروضك', true), const SizedBox(width: 12), _stat(LucideIcons.eye, '1.2K', 'مشاهدة لإعلاناتك', false)]),
        AppCard(
          child: VCol(gap: 14, [
            Row(children: [
              Expanded(child: Text('المبيعات اليومية', style: tx(16, w: w6))),
              Text('هذا الأسبوع', style: tx(13, c: AppColors.mute)),
            ]),
            SizedBox(
              height: 150,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < bars.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(height: bars[i], decoration: BoxDecoration(color: i == 5 ? AppColors.pri : const Color(0xFFEBCFC2), borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 6),
                      Text(days[i], style: tx(10, c: AppColors.mute), maxLines: 1),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
        AppCard(
          child: VCol(gap: 10, [
            Row(children: [
              const Icon(LucideIcons.package, size: 22, color: AppColors.ink2),
              const SizedBox(width: 10),
              Expanded(child: Text('المخزون', style: tx(16, w: w6))),
              GestureDetector(onTap: () => context.push('/m/listings'), child: Text('إدارة ←', style: tx(13, w: w5, c: AppColors.pri))),
            ]),
            Row(children: [
              for (final s in const [
                ['6', 'إعلان نشط', 0],
                ['2', 'قاربت تنفد', 1],
                ['1', 'مباعة', 2],
              ]) ...[
                if (s[2] != 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                    child: Column(children: [
                      Text(s[0] as String, style: tx(18, w: w7, c: s[2] == 1 ? AppColors.pri : (s[2] == 2 ? AppColors.teal : AppColors.ink), h: 1.3)),
                      Text(s[1] as String, style: tx(11, c: AppColors.mute)),
                    ]),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ],
    );
  }
}

// ───────────────── T04 · طلبات العملاء ─────────────────

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});
  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'طلبات العملاء وعروضي'),
      gap: 14,
      children: [
        SegTabs(items: const ['جديدة (5)', 'عروضي (12)', 'مقبولة (4)'], selected: tab, onChanged: (i) => setState(() => tab = i)),
        const InfoBox('هذي الطلبات تطابق تخصصك: تويوتا · لكزس · نيسان'),
        for (final r in Mock.customerRequests)
          AppCard(
            child: VCol(gap: 12, [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const IconSquare(LucideIcons.car, size: 48, iconSize: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.title, style: tx(15, w: w6)),
                    Text(r.sub, style: tx(12, c: AppColors.mute)),
                  ]),
                ),
              ]),
              if (r.image) const Align(alignment: AlignmentDirectional.centerStart, child: PartThumb(width: 96, height: 80, radius: 12)),
              Row(children: [
                MetaItem(LucideIcons.mapPin, r.city),
                const SizedBox(width: 12),
                MetaItem(LucideIcons.users, r.offers),
                const Spacer(),
                StatusBadge.amber(r.left, icon: LucideIcons.clock),
              ]),
              Row(children: [
                Expanded(child: AppButton('قدّم عرض سعر', icon: LucideIcons.tag, height: 46, fs: 15, onTap: () => context.push('/m/offer/${r.id}'))),
                const SizedBox(width: 10),
                AppButton('تجاهل', v: BtnV.out2, height: 46, fs: 14, expand: false),
              ]),
            ]),
          ),
      ],
    );
  }
}

// ───────────────── T05 · تقديم عرض سعر ─────────────────

class SubmitOfferScreen extends StatefulWidget {
  final String id;
  const SubmitOfferScreen({super.key, required this.id});
  @override
  State<SubmitOfferScreen> createState() => _SubmitOfferScreenState();
}

class _SubmitOfferScreenState extends State<SubmitOfferScreen> {
  bool inclShipping = true;
  String condition = 'جديد أصلي';

  @override
  Widget build(BuildContext context) {
    final r = Mock.customerRequests.firstWhere((e) => e.id == widget.id, orElse: () => Mock.customerRequests.first);
    return AppPage(
      header: const AppHeader(title: 'تقديم عرض سعر'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
          child: VCol(gap: 6, [
            Row(children: [
              Expanded(child: Text('طلب العميل', style: tx(13, c: AppColors.mute))),
              StatusBadge.amber(r.left, icon: LucideIcons.clock),
            ]),
            Text('${r.title} · جديد أصلي', style: tx(16, w: w5)),
            Text('ملاحظة العميل: «أبيه أصلي وكالة، ويفضّل اللون أبيض»', style: tx(13, c: AppColors.ink2)),
          ]),
        ),
        LabeledField(
          'سعرك',
          AppField(value: '380', ltrText: true, focus: true, keyboard: TextInputType.number, trailing: Text('ر.س', style: tx(15, w: w5, c: AppColors.mute))),
        ),
        ToggleRow(title: 'السعر شامل الشحن', sub: 'العميل يشوف السعر النهائي بدون مفاجآت', value: inclShipping, onChanged: (v) => setState(() => inclShipping = v)),
        LabeledField(
          'حالة القطعة (أصلية / مستعملة)',
          SelectGrid(options: const ['جديد أصلي', 'جديد درجة أولى', 'مستعمل', 'مجدد'], selected: condition, onChanged: (v) => setState(() => condition = v)),
          required: true,
        ),
        Row(children: [
          const Expanded(child: LabeledField('مدة التوصيل', AppField(value: '2-3 أيام', chevron: true))),
          const SizedBox(width: 10),
          const Expanded(child: LabeledField('الضمان', AppField(value: '6 أشهر', chevron: true))),
        ]),
        LabeledField(
          'صور القطعة',
          Row(children: const [PartThumb(width: 96, height: 96, radius: 18), SizedBox(width: 10), UploadBox()]),
        ),
        const LabeledField('رسالة للعميل (اختياري)', AppField(value: 'متوفر أصلي وكالة، نشحن اليوم', area: true)),
        const InfoBox('العميل يقارن عرضك مع باقي الموردين — السعر والتقييم وسرعة التوصيل يفرقون'),
        AppButton('أرسل العرض', icon: LucideIcons.send, onTap: () {
          showToast(context, 'وصل عرضك للعميل');
          context.pop();
        }),
      ],
    );
  }
}

// ───────────────── T06 · أبيع قطعة ─────────────────

class SellPartScreen extends StatefulWidget {
  const SellPartScreen({super.key});
  @override
  State<SellPartScreen> createState() => _SellPartScreenState();
}

class _SellPartScreenState extends State<SellPartScreen> {
  final cats = <String>{'بودي'};
  String condition = 'جديد أصلي';
  String method = 'على السوم';
  String duration = '3 أيام';
  final delivery = <String>{'شحن لكل المدن', 'استلام من المحل'};

  @override
  Widget build(BuildContext context) {
    final auction = method == 'على السوم';
    return AppPage(
      header: const AppHeader(title: 'أبيع قطعة'),
      children: [
        LabeledField(
          'صور القطعة',
          Row(children: const [PartThumb(width: 96, height: 96, radius: 18), SizedBox(width: 10), PartThumb(width: 96, height: 96, radius: 18), SizedBox(width: 10), UploadBox()]),
          help: 'أضف حتى 8 صور — الصورة الأولى تكون الغلاف',
        ),
        const LabeledField('اسم القطعة', AppField(value: 'صدام أمامي')),
        Row(children: [
          const Expanded(child: LabeledField('الماركة', AppField(value: 'تويوتا', chevron: true))),
          const SizedBox(width: 10),
          const Expanded(child: LabeledField('الموديل', AppField(value: 'كامري', chevron: true))),
        ]),
        Row(children: [
          const Expanded(child: LabeledField('من سنة', AppField(value: '2020', chevron: true))),
          const SizedBox(width: 10),
          const Expanded(child: LabeledField('إلى سنة', AppField(value: '2023', chevron: true))),
        ]),
        LabeledField('التصنيف', ChipWrap(Mock.categories, selected: cats, onTap: (c) => setState(() => cats.contains(c) ? cats.remove(c) : cats.add(c)))),
        LabeledField(
          'حالة القطعة (أصلية / مستعملة)',
          SelectGrid(options: const ['جديد أصلي', 'جديد درجة أولى', 'مستعمل', 'مجدد'], selected: condition, onChanged: (v) => setState(() => condition = v)),
          required: true,
        ),
        LabeledField(
          'طريقة البيع',
          SelectGrid(
            options: const ['سعر محدد', 'على السوم'],
            subs: const {'سعر محدد': 'المشتري يشتري مباشرة', 'على السوم': 'المشترين يسومون وأنت تختار'},
            selected: method,
            onChanged: (v) => setState(() => method = v),
          ),
          required: true,
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: LabeledField(
              auction ? 'سعر مبدئي (اختياري)' : 'السعر',
              AppField(value: '450', ltrText: true, keyboard: TextInputType.number, trailing: Text('ر.س', style: tx(15, w: w5, c: AppColors.mute))),
              help: auction ? 'السومات تبدأ من هذا السعر — اتركه فاضي لو تبي السوم مفتوح' : null,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: LabeledField('الكمية', AppField(value: '1', ltrText: true, keyboard: TextInputType.number))),
        ]),
        if (auction)
          LabeledField(
            'مدة السوم',
            Wrap(spacing: 8, children: [
              for (final d in const ['يوم', '3 أيام', 'أسبوع']) AppChip(d, selected: duration == d, px: 18, onTap: () => setState(() => duration = d)),
            ]),
          ),
        LabeledField(
          'طريقة التسليم',
          Row(children: [
            for (final d in const ['شحن لكل المدن', 'استلام من المحل']) ...[
              if (d != 'شحن لكل المدن') const SizedBox(width: 10),
              Expanded(child: SelectCell(d, selected: delivery.contains(d), onTap: () => setState(() => delivery.contains(d) ? delivery.remove(d) : delivery.add(d)))),
            ],
          ]),
        ),
        const LabeledField('الوصف', AppField(hint: 'اكتب تفاصيل القطعة، حالتها، وأي ملاحظات...', area: true)),
        AppButton('انشر الإعلان', icon: LucideIcons.check, onTap: () {
          showToast(context, 'تم نشر إعلانك');
          context.pop();
        }),
        Center(child: Text('حفظ كمسودة', style: tx(14, w: w5, c: AppColors.teal))),
      ],
    );
  }
}

// ───────────────── T07 · إدارة إعلاناتي ─────────────────

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});
  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  int filter = 0;

  Widget _item(String t, String price, String views, String favs, Widget status, String stock) => AppCard(
        child: VCol(gap: 12, [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PartThumb(width: 84, height: 84, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: tx(15, w: w5)),
                Text(price, style: tx(16, w: w6, c: AppColors.teal)),
                const SizedBox(height: 4),
                Wrap(spacing: 12, children: [
                  MetaItem(LucideIcons.eye, views),
                  MetaItem(LucideIcons.heart, favs),
                  MetaItem(LucideIcons.package, stock),
                ]),
                const SizedBox(height: 4),
                status,
              ]),
            ),
          ]),
          Row(children: [
            Expanded(child: AppButton('تعديل', icon: LucideIcons.pencil, iconFirst: true, v: BtnV.out2, height: 40, fs: 13, radius: 12, onTap: () => context.push('/sell'))),
            const SizedBox(width: 8),
            Expanded(child: AppButton('إيقاف', icon: LucideIcons.pause, iconFirst: true, v: BtnV.ink, height: 40, fs: 13, radius: 12)),
            const SizedBox(width: 8),
            Expanded(child: AppButton('حذف', icon: LucideIcons.trash2, iconFirst: true, v: BtnV.red, height: 40, fs: 13, radius: 12)),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(title: 'إعلاناتي', actions: [HeaderIcon(LucideIcons.plus, size: 26, color: AppColors.pri, onTap: () => context.push('/sell'))]),
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: AppField(hint: 'ابحث في إعلاناتك...', icon: LucideIcons.search)),
          ChipScroller(children: [
            for (var i = 0; i < 4; i++)
              AppChip(const ['الكل (8)', 'نشطة (6)', 'موقوفة (1)', 'مباعة (1)'][i], selected: filter == i, px: 14, py: 7, onTap: () => setState(() => filter = i)),
          ]),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 40), children: [
              _item('جهاز فحص كامري 2020', sar(100), '230', '12', const StatusBadge.teal('نشط'), '3'),
              const SizedBox(height: 14),
              _item('صدام أمامي كامري 2020', 'على السوم', '184', '9', const StatusBadge('نشط · قاربت تنفد', icon: LucideIcons.alertCircle), '1'),
              const SizedBox(height: 14),
              _item('شمعات لكزس LX 2020', sar(620), '96', '4', const StatusBadge.grey('موقوف'), '2'),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── T07ب · السومات على إعلاناتي (مساوماتي) ─────────────────

class ListingBidsScreen extends StatelessWidget {
  const ListingBidsScreen({super.key});

  Widget _bid(BuildContext context, Bid b) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: b.top ? AppColors.pink : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: b.top ? Border.all(color: AppColors.pinkB) : null,
        ),
        child: VCol(gap: 10, [
          Row(children: [
            Avatar(size: 36, letter: b.name.substring(0, 1), bg: AppColors.white, color: b.top ? AppColors.pri : AppColors.mute),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(b.name.replaceAll('***', '').trim(), style: tx(14, w: w5)),
                  if (b.top) const SizedBox(width: 6),
                  if (b.top) const StatusBadge('الأعلى', icon: LucideIcons.star),
                ]),
                Text(b.time, style: tx(11, c: AppColors.mute)),
              ]),
            ),
            Text(sar(b.amount), style: tx(17, w: w7, c: b.top ? AppColors.pri : AppColors.ink)),
          ]),
          Row(children: [
            Expanded(child: AppButton('قبول السومة', icon: LucideIcons.check, height: 40, fs: 13, radius: 12, onTap: () => showToast(context, 'تم قبول السومة — بلّغنا المشتري يكمل الدفع'))),
            const SizedBox(width: 8),
            Expanded(child: AppButton('رفض', v: BtnV.out2, height: 40, fs: 13, radius: 12)),
            const SizedBox(width: 8),
            AppButton('', icon: LucideIcons.messageSquare, v: BtnV.tealOut, height: 40, radius: 12, expand: false, onTap: () => context.push('/chat/c4')),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'مساوماتي'),
      gap: 14,
      children: [
        AppCard(
          child: VCol(gap: 12, [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PartThumb(width: 72, height: 72, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('صدام أمامي كامري 2020', style: tx(15, w: w5)),
                  const SizedBox(height: 3),
                  const StatusBadge('على السوم · باقي 2 يوم', icon: LucideIcons.gavel),
                  const SizedBox(height: 3),
                  Text('سعر مبدئي 300 ر.س', style: tx(12, c: AppColors.mute)),
                ]),
              ),
            ]),
            const HLine(),
            for (final b in Mock.bids.take(3)) _bid(context, b),
          ]),
        ),
        AppCard(
          onTap: () {},
          child: Row(children: [
            const PartThumb(width: 72, height: 72, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('شمعات لكزس LX 2020', style: tx(15, w: w5)),
                const SizedBox(height: 3),
                const StatusBadge('على السوم · باقي 5 ساعات', icon: LucideIcons.gavel),
                const SizedBox(height: 3),
                Text('أعلى سومة: 540 ر.س · 7 سومات', style: tx(12, w: w6, c: AppColors.pri)),
              ]),
            ),
            const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.mute),
          ]),
        ),
      ],
    );
  }
}

// ───────────────── T08 · طلبات البيع ─────────────────

class SalesOrdersScreen extends StatefulWidget {
  const SalesOrdersScreen({super.key});
  @override
  State<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends State<SalesOrdersScreen> {
  int tab = 1;

  Widget _order(String t, String buyer, String no, String price, Widget status, List<Widget> buttons) => AppCard(
        child: VCol(gap: 12, [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PartThumb(width: 72, height: 72, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: tx(15, w: w5)),
                Text(buyer, style: tx(12, c: AppColors.mute)),
                Text(no, style: tx(12, c: AppColors.mute)),
              ]),
            ),
            Text(price, style: tx(16, w: w6, c: AppColors.teal)),
          ]),
          Align(alignment: AlignmentDirectional.centerStart, child: status),
          Row(children: [
            for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: buttons[i])],
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(title: 'طلبات البيع'),
          ChipScroller(children: [
            for (var i = 0; i < 4; i++)
              AppChip(const ['جديدة (2)', 'قيد التجهيز (1)', 'تم الشحن (3)', 'مكتملة'][i], selected: tab == i, px: 14, py: 7, onTap: () => setState(() => tab = i)),
          ]),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 40), children: [
              _order('صدام أمامي كامري 2020', 'المشتري: عبدالله · الرياض', 'ORD-58213 · مدفوع', sar(450),
                  const StatusBadge.amber('قيد التجهيز · سلّمه قبل 24 ساعة', icon: LucideIcons.clock), [
                AppButton('صوّر القطعة وجهّز', icon: LucideIcons.camera, height: 44, fs: 14, onTap: () => context.push('/m/document/o1')),
                AppButton('بوليصة الشحن', icon: LucideIcons.printer, iconFirst: true, v: BtnV.out2, height: 44, fs: 14),
              ]),
              const SizedBox(height: 14),
              _order('فلتر زيت أصلي تويوتا', 'المشتري: فهد · جدة', 'ORD-58240 · مدفوع', sar(50), const StatusBadge('طلب جديد', icon: LucideIcons.bell), [
                AppButton('قبول الطلب', height: 44, fs: 14),
                AppButton('رفض', v: BtnV.red, height: 44, fs: 14),
              ]),
              const SizedBox(height: 14),
              _order('شمعات لكزس LX 2020', 'المشتري: سعد · الدمام', 'ORD-58102 · سمسا', sar(620), const StatusBadge.teal('تم الشحن', icon: LucideIcons.truck), [
                AppButton('تتبّع الشحنة', icon: LucideIcons.truck, iconFirst: true, v: BtnV.out2, height: 44, fs: 14),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── T08ب · توثيق القطعة قبل الشحن (4 اتجاهات) ─────────────────

class DocumentPhotosScreen extends StatefulWidget {
  final String id;
  const DocumentPhotosScreen({super.key, required this.id});
  @override
  State<DocumentPhotosScreen> createState() => _DocumentPhotosScreenState();
}

class _DocumentPhotosScreenState extends State<DocumentPhotosScreen> {
  static const sides = ['الأمام', 'الخلف', 'الجانب الأيمن', 'الجانب الأيسر'];
  final done = <String>{'الأمام', 'الخلف', 'الجانب الأيمن'};

  Widget _slot(String side) {
    final ok = done.contains(side);
    return GestureDetector(
      onTap: () => setState(() => ok ? done.remove(side) : done.add(side)),
      child: Column(children: [
        SizedBox(
          height: 140,
          child: ok
              ? Stack(children: [
                  const PartThumb(width: double.infinity, height: 140, radius: 18),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                      child: const Icon(LucideIcons.check, size: 14, color: AppColors.white),
                    ),
                  ),
                ])
              : LayoutBuilder(builder: (c, cons) => UploadBox(size: cons.maxWidth < 140 ? cons.maxWidth : 140, label: 'صوّر الآن')),
        ),
        const SizedBox(height: 8),
        Text(side, style: tx(14, w: w5, c: ok ? AppColors.ink : AppColors.pri)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = done.length;
    return AppPage(
      header: const AppHeader(title: 'توثيق القطعة قبل الشحن'),
      children: [
        const InfoBox('لازم تصوّر القطعة من 4 اتجاهات قبل الشحن — الصور توصل للمشتري وتحميك وتحميه'),
        AppCard(
          child: Row(children: [
            const PartThumb(width: 64, height: 64, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('صدام أمامي كامري 2020', style: tx(15, w: w5)),
                Text('ORD-58213 · المشتري: عبدالله', style: tx(12, c: AppColors.mute)),
                const SizedBox(height: 4),
                const ConditionBadge('جديد أصلي'),
              ]),
            ),
          ]),
        ),
        Row(children: [
          Expanded(child: Text('صور القطعة', style: tx(16, w: w6))),
          Text('$count من 4', style: tx(14, w: w6, c: AppColors.pri)),
        ]),
        Row(children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: Container(height: 6, decoration: BoxDecoration(color: i < count ? AppColors.teal : const Color(0xFFE8DDCF), borderRadius: BorderRadius.circular(3)))),
          ],
        ]),
        Row(children: [Expanded(child: _slot(sides[0])), const SizedBox(width: 12), Expanded(child: _slot(sides[1]))]),
        Row(children: [Expanded(child: _slot(sides[2])), const SizedBox(width: 12), Expanded(child: _slot(sides[3]))]),
        AppCard(
          child: VCol(gap: 8, [
            Text('نصائح للتصوير', style: tx(14, w: w6)),
            for (final t in const ['صوّر في مكان فيه إضاءة واضحة', 'خل القطعة كاملة داخل الصورة', 'وضّح أي رقم قطعة أو ملصق وكالة'])
              Row(children: [
                const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: tx(13, c: AppColors.ink2))),
              ]),
          ]),
        ),
        AppButton('أكّد التجهيز وسلّم للشحن', icon: LucideIcons.check, disabled: count < 4, onTap: () {
          showToast(context, 'تم التوثيق — بلّغنا المشتري وشركة الشحن');
          context.pop();
        }),
        if (count < 4) Center(child: Text('يتفعّل الزر بعد رفع الصور الأربع', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}

// ───────────────── T09 · الأرباح والتحويل ─────────────────

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  Widget _tx(String t, String d, String amt, bool pos, String st) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          IconSquare(pos ? LucideIcons.arrowDown : LucideIcons.arrowUp, size: 42, iconSize: 20, radius: 12, bg: pos ? AppColors.tealBg : AppColors.pink, color: pos ? AppColors.teal : AppColors.pri),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: tx(14, w: w5)),
              Text(d, style: tx(12, c: AppColors.mute)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(ltr(amt), style: tx(15, w: w6, c: pos ? AppColors.teal : AppColors.ink)),
            Text(st, style: tx(11, c: AppColors.mute)),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'الأرباح والتحويل'),
      children: [
        _gradientCard(children: [
          Text('الرصيد المتاح للتحويل', style: tx(13, c: AppColors.white.withOpacity(0.85))),
          Text(ltr('3,150.00 ر.س'), style: tx(32, w: w7, c: AppColors.white, h: 1.3)),
          const SizedBox(height: 6),
          _glass(Row(children: [
            const Icon(LucideIcons.clock, size: 16, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('معلّق 1,670 ر.س — يُتاح بعد تأكيد المشتري للاستلام', style: tx(12, c: AppColors.white))),
          ])),
          const SizedBox(height: 6),
        ]),
        AppCard(
          child: Row(children: [
            const IconSquare(LucideIcons.landmark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الحساب البنكي', style: tx(15, w: w5)),
                Text(ltr('SA44 •••• •••• •••• 7781'), style: tx(13, c: AppColors.mute)),
              ]),
            ),
            GestureDetector(onTap: () => context.push('/edit-profile'), child: Text('تغيير', style: tx(14, w: w5, c: AppColors.pri))),
          ]),
        ),
        LabeledField(
          'مبلغ التحويل',
          VCol(gap: 8, cross: CrossAxisAlignment.start, [
            AppField(value: '3,150.00', ltrText: true, keyboard: TextInputType.number, trailing: Text('ر.س', style: tx(15, w: w5, c: AppColors.mute))),
            Wrap(spacing: 8, children: [
              const AppChip('كامل الرصيد', selected: true, px: 14, py: 6, fs: 13),
              AppChip(ltr('1,000'), px: 14, py: 6, fs: 13),
              AppChip(ltr('2,000'), px: 14, py: 6, fs: 13),
            ]),
          ]),
        ),
        AppButton('اطلب التحويل', icon: LucideIcons.landmark, onTap: () => showToast(context, 'تم إرسال طلب التحويل')),
        Center(child: Text('يوصلك التحويل خلال 1-3 أيام عمل · بدون رسوم', style: tx(12, c: AppColors.mute))),
        const SizedBox(height: 4),
        Text('سجل العمليات', style: tx(17, w: w6)),
        _tx('مبيعات طلب ORD-58213', '2026/11/08', '+450.00', true, 'معلّق'),
        _tx('تحويل للآيبان', '2026/11/01', '-2,000.00', false, 'مكتمل'),
        _tx('مبيعات طلب ORD-58102', '2026/10/28', '+620.00', true, 'متاح'),
        _tx('رسوم باقة لولو', '2026/10/01', '-49.00', false, 'مكتمل'),
      ],
    );
  }
}

// ───────────────── T10 · باقة لولو ─────────────────

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  Widget _plan(BuildContext context, String name, String price, List<String> feats, {bool hl = false, bool current = false, required String cta}) {
    final fg = hl ? AppColors.white : AppColors.ink;
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: VCol(gap: 10, [
        Row(children: [
          Icon(hl ? LucideIcons.crown : LucideIcons.award, size: 24, color: hl ? const Color(0xFFFFD98A) : AppColors.pri),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: tx(19, w: w7, c: fg))),
          if (hl) const StatusBadge('الأكثر طلباً', bg: AppColors.white),
        ]),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: tx(30, w: w7, c: fg, h: 1.2)),
          const SizedBox(width: 6),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('ر.س / شهرياً', style: tx(13, c: hl ? const Color(0xFFF6D9CD) : AppColors.mute))),
        ]),
        for (final f in feats)
          Row(children: [
            Icon(LucideIcons.checkCircle, size: 18, color: hl ? AppColors.white : AppColors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(f, style: tx(14, c: hl ? AppColors.white : AppColors.ink2))),
          ]),
        const SizedBox(height: 4),
        AppButton(cta, v: hl ? BtnV.white : (current ? BtnV.ink : BtnV.out), height: 48, radius: 999, fs: 15, onTap: current ? null : () => context.push('/checkout')),
      ]),
    );
    return Container(
      decoration: BoxDecoration(
        gradient: hl ? AppColors.gradient : null,
        color: hl ? null : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: hl ? null : Border.all(color: AppColors.chipB),
      ),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      header: const AppHeader(title: 'باقة لولو'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            const Icon(LucideIcons.award, size: 28, color: AppColors.pri),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('باقتك الحالية', style: tx(12, c: AppColors.mute)),
                Text('المجانية', style: tx(17, w: w6)),
              ]),
            ),
            Text('3 من 5 إعلانات', style: tx(13, w: w5, c: AppColors.ink2)),
          ]),
        ),
        _plan(context, 'المجانية', '0', const ['حتى 5 إعلانات', 'استقبال 10 طلبات قطع شهرياً', 'عمولة 8% على المبيعات'], current: true, cta: 'باقتك الحالية'),
        _plan(context, 'لولو', '49', const ['إعلانات بلا حدود', 'طلبات القطع بلا حدود', 'عمولة 5% فقط', 'شارة «تاجر موثّق»'], hl: true, cta: 'اشترك الآن'),
        _plan(context, 'لولو برو', '149', const ['كل مزايا لولو', 'ظهور مميز في نتائج البحث', 'عمولة 3%', 'تقارير أداء متقدمة'], cta: 'اشترك في برو'),
        Center(child: Text('تقدر تلغي اشتراكك بأي وقت من الإعدادات', style: tx(12, c: AppColors.mute))),
      ],
    );
  }
}
