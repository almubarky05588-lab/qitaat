import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/mock.dart';

// ───────────────── 17 · الإشعارات ─────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int filter = 0;
  bool allRead = false;
  static const filters = ['الكل', 'غير المقروء', 'العروض', 'الطلبات والشحن', 'الإعلانات'];

  IconData _icon(String k) => switch (k) {
        'offer' => LucideIcons.tag,
        'order' => LucideIcons.truck,
        'accepted' => LucideIcons.checkCircle,
        'invoice' => LucideIcons.receipt,
        _ => LucideIcons.tag,
      };

  @override
  Widget build(BuildContext context) {
    var list = Mock.notifications.toList();
    if (filter == 1) list = list.where((n) => n.unread && !allRead).toList();
    if (filter == 2) list = list.where((n) => n.kind == 'offer' || n.kind == 'accepted').toList();
    if (filter == 3) list = list.where((n) => n.kind == 'order' || n.kind == 'invoice').toList();
    if (filter == 4) list = list.where((n) => n.kind == 'request').toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(title: 'الإشعارات', actions: [
            GestureDetector(onTap: () => setState(() => allRead = true), child: Text('تحديد الكل كمقروء', style: tx(13, w: w5, c: AppColors.pri))),
          ]),
          ChipScroller(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), children: [
            for (var i = 0; i < filters.length; i++)
              AppChip(filters[i], selected: filter == i, icon: filter == i && i == 0 ? LucideIcons.check : null, onTap: () => setState(() => filter = i)),
          ]),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 30),
              itemCount: list.length,
              separatorBuilder: (_, __) => const HLine(color: Color(0xFFE9DCCB)),
              itemBuilder: (_, i) {
                final n = list[i];
                final unread = n.unread && !allRead;
                final teal = n.kind == 'offer' || n.kind == 'accepted';
                return InkWell(
                  onTap: () {
                    if (n.kind == 'offer') context.push('/offers/r1');
                    if (n.kind == 'request') context.push('/m/requests');
                    if (n.kind == 'invoice') context.push('/invoice');
                    if (n.kind == 'order') context.push('/m/sales');
                  },
                  child: Container(
                    color: unread ? AppColors.unread : AppColors.bg,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      IconSquare(_icon(n.kind), size: 52, iconSize: 24, radius: 16, bg: teal ? AppColors.tealBg : AppColors.pink, color: teal ? AppColors.teal : AppColors.pri),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.title, style: tx(15, w: unread ? w6 : w5)),
                          const SizedBox(height: 3),
                          Text(n.body, style: tx(13, c: AppColors.ink2)),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(n.date, style: tx(12, c: AppColors.mute)),
                        const SizedBox(height: 10),
                        if (unread) Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle)),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 18 · المحادثات ─────────────────

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(title: 'المحادثات'),
          const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 14), child: AppField(hint: 'ابحث في المحادثات...', icon: LucideIcons.search)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 30),
              itemCount: Mock.chats.length,
              separatorBuilder: (_, __) => const Padding(padding: EdgeInsetsDirectional.only(start: 84, end: 20), child: HLine(color: Color(0xFFE9DCCB))),
              itemBuilder: (_, i) {
                final c = Mock.chats[i];
                final unread = c.unread > 0;
                return InkWell(
                  onTap: () => context.push('/chat/${c.id}'),
                  child: Container(
                    color: unread ? AppColors.unread : null,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(children: [
                      c.store ? const Avatar(size: 52) : Avatar(size: 52, letter: c.name.substring(0, 1), bg: AppColors.tealBg, color: AppColors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(c.name, style: tx(15, w: unread ? w6 : w5))),
                            Text(c.time, style: tx(12, c: unread ? AppColors.pri : AppColors.mute)),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            Expanded(child: Text(c.last, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, c: unread ? AppColors.ink2 : AppColors.mute))),
                            if (unread)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(999)),
                                child: Text('${c.unread}', style: tx(11, w: w6, c: AppColors.white, h: 1.4)),
                              ),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ───────────────── 19 · محادثة ─────────────────

class _Msg {
  final String text;
  final bool me;
  final String time;
  final bool photos;
  const _Msg(this.text, this.me, this.time, {this.photos = false});
}

class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen({super.key, required this.id});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final msgs = <_Msg>[
    const _Msg('السلام عليكم، القطعة متوفرة؟', true, '6:02 م'),
    const _Msg('وعليكم السلام، إيه متوفرة أصلية وجاهزة للاستلام', false, '6:03 م'),
    const _Msg('ممكن صور من كل الجهات؟', true, '6:04 م'),
    const _Msg('', false, '6:05 م', photos: true),
    const _Msg('تمام، أرسلت لك صور القطعة من كل الجهات', false, '6:06 م'),
  ];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _send() {
    if (ctrl.text.trim().isEmpty) return;
    setState(() {
      msgs.add(_Msg(ctrl.text.trim(), true, 'الآن'));
      ctrl.clear();
    });
  }

  Widget _bubble(_Msg m) {
    if (m.photos) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          PartThumb(width: 110, height: 90, radius: 14),
          SizedBox(width: 6),
          PartThumb(width: 110, height: 90, radius: 14),
        ]),
      );
    }
    return Align(
      alignment: m.me ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 268),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.me ? AppColors.pri : AppColors.white,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(m.me ? 6 : 18),
              topEnd: Radius.circular(m.me ? 18 : 6),
              bottomStart: const Radius.circular(18),
              bottomEnd: const Radius.circular(18),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(m.text, style: tx(14, c: m.me ? AppColors.white : AppColors.ink)),
            const SizedBox(height: 2),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(m.time, style: tx(10, c: m.me ? const Color(0xFFF6D9CD) : AppColors.mute)),
              if (m.me) const SizedBox(width: 4),
              if (m.me) const Icon(LucideIcons.checkCheck, size: 14, color: Color(0xFFF6D9CD)),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Mock.chats.firstWhere((e) => e.id == widget.id, orElse: () => Mock.chats.first);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(children: [
              GestureDetector(onTap: () => context.pop(), child: const Icon(LucideIcons.arrowRight, size: 24, color: AppColors.ink)),
              const SizedBox(width: 12),
              const Avatar(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(c.name, style: tx(17, w: w6))),
                    const SizedBox(width: 4),
                    const VerifiedBadge(size: 16),
                  ]),
                  Text('متصل الآن', style: tx(12, c: AppColors.teal)),
                ]),
              ),
              const Icon(LucideIcons.phone, size: 22, color: AppColors.ink),
            ]),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const PartThumb(width: 48, height: 48, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('جهاز فحص كامري 2020', style: tx(14, w: w5)),
                  Text(sar(100), style: tx(14, w: w6, c: AppColors.teal)),
                ]),
              ),
              GestureDetector(onTap: () => context.push('/part/p1'), child: Text('شوف القطعة', style: tx(13, w: w5, c: AppColors.pri))),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.segBg, borderRadius: BorderRadius.circular(999)),
                  child: Text('اليوم', style: tx(12, c: AppColors.mute)),
                ),
              ),
              for (final m in msgs) ...[const SizedBox(height: 10), _bubble(m)],
            ]),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(children: [
              const Icon(LucideIcons.camera, size: 24, color: AppColors.mute),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: ctrl,
                    onSubmitted: (_) => _send(),
                    style: tx(14),
                    decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: 'اكتب رسالتك...', hintStyle: tx(14, c: AppColors.ph)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.send, size: 20, color: AppColors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
