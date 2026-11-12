import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/media.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/api.dart';

// ───────────────── 17 · الإشعارات ─────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int filter = 0;
  static const filters = ['الكل', 'غير المقروء', 'العروض', 'الطلبات والشحن', 'الإعلانات'];

  IconData _icon(String k) => switch (k) {
        'offer' => LucideIcons.tag,
        'order' => LucideIcons.truck,
        'accepted' => LucideIcons.checkCircle,
        'bid' => LucideIcons.gavel,
        'message' => LucideIcons.messageSquare,
        'invoice' => LucideIcons.receipt,
        _ => LucideIcons.tag,
      };

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          AppHeader(title: 'الإشعارات', actions: [
            GestureDetector(onTap: () => run(context, Api.markAllNotifsRead), child: Text('تحديد الكل كمقروء', style: tx(13, w: w5, c: AppColors.pri))),
          ]),
          ChipScroller(padding: const EdgeInsets.fromLTRB(20, 0, 20, 14), children: [
            for (var i = 0; i < filters.length; i++)
              AppChip(filters[i], selected: filter == i, icon: filter == i && i == 0 ? LucideIcons.check : null, onTap: () => setState(() => filter = i)),
          ]),
          Expanded(
            child: v.when(
              loading: () => const Loading(),
              error: (e, _) => ErrorBox(e),
              data: (all) {
                var list = all;
                if (filter == 1) list = list.where((n) => !n.read).toList();
                if (filter == 2) list = list.where((n) => ['offer', 'accepted', 'bid'].contains(n.kind)).toList();
                if (filter == 3) list = list.where((n) => ['order', 'invoice'].contains(n.kind)).toList();
                if (filter == 4) list = list.where((n) => n.kind == 'request').toList();
                if (list.isEmpty) return const SingleChildScrollView(child: EmptyBox(LucideIcons.bell, 'ما عندك إشعارات هنا'));
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 30),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const HLine(color: Color(0xFFE9DCCB)),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    final unread = !n.read;
                    final teal = ['offer', 'accepted'].contains(n.kind);
                    return InkWell(
                      onTap: () {
                        if (unread) Api.markNotifRead(n.id).catchError((_) {});
                        if (n.link != null && n.link!.isNotEmpty) context.push(n.link!);
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
                              if (n.body != null) Text(n.body!, style: tx(13, c: AppColors.ink2)),
                            ]),
                          ),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(fmtAgo(n.createdAt), style: tx(12, c: AppColors.mute)),
                            const SizedBox(height: 10),
                            if (unread) Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle)),
                          ]),
                        ]),
                      ),
                    );
                  },
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

final conversationsProvider = FutureProvider<(List<Conversation>, Map<String, int>)>((ref) async {
  ref.watch(notificationsProvider);
  final c = await Api.conversations();
  final u = await Api.unreadByConversation();
  return (c, u);
});

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});
  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final v = ref.watch(conversationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(title: 'المحادثات'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: AppField(hint: 'ابحث في المحادثات...', icon: LucideIcons.search, onChanged: (t) => setState(() => q = t.trim())),
          ),
          Expanded(
            child: v.when(
              loading: () => const Loading(),
              error: (e, _) => ErrorBox(e, onRetry: () => ref.invalidate(conversationsProvider)),
              data: (d) {
                final list = d.$1.where((c) => q.isEmpty || (c.other?.displayName ?? '').contains(q) || (c.lastMessage ?? '').contains(q)).toList();
                if (list.isEmpty) return const SingleChildScrollView(child: EmptyBox(LucideIcons.messageSquare, 'ما عندك محادثات للحين'));
                return RefreshIndicator(
                  color: AppColors.pri,
                  onRefresh: () async => ref.invalidate(conversationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 30),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Padding(padding: EdgeInsetsDirectional.only(start: 84, end: 20), child: HLine(color: Color(0xFFE9DCCB))),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final o = c.other;
                      final unread = d.$2[c.id] ?? 0;
                      final store = o?.isMerchant == true;
                      return InkWell(
                        onTap: () async {
                          await context.push('/chat/${c.id}');
                          ref.invalidate(conversationsProvider);
                        },
                        child: Container(
                          color: unread > 0 ? AppColors.unread : null,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            store ? const Avatar(size: 52) : Avatar(size: 52, letter: o?.initial ?? '؟', bg: AppColors.tealBg, color: AppColors.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(o?.displayName ?? 'مستخدم', style: tx(15, w: unread > 0 ? w6 : w5))),
                                  Text(fmtAgo(c.lastAt), style: tx(12, c: unread > 0 ? AppColors.pri : AppColors.mute)),
                                ]),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Expanded(
                                    child: Text(c.lastMessage ?? (c.listing?['title'] != null ? 'بخصوص: ${c.listing!['title']}' : 'ابدأ المحادثة'),
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(13, c: unread > 0 ? AppColors.ink2 : AppColors.mute)),
                                  ),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                      decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(999)),
                                      child: Text('$unread', style: tx(11, w: w6, c: AppColors.white, h: 1.4)),
                                    ),
                                ]),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
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

final conversationProvider = FutureProvider.family<Conversation?, String>((ref, id) => Api.conversation(id));

class ChatScreen extends ConsumerStatefulWidget {
  final String id;
  const ChatScreen({super.key, required this.id});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  late final Stream<List<Message>> stream = Api.messages(widget.id);
  bool sending = false;

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _send({List<String> images = const []}) async {
    final t = ctrl.text.trim();
    if (t.isEmpty && images.isEmpty) return;
    setState(() => sending = true);
    final ok = await run(context, () => Api.sendMessage(widget.id, body: t.isEmpty ? null : t, images: images));
    if (!mounted) return;
    setState(() => sending = false);
    if (ok) ctrl.clear();
  }

  Widget _bubble(Message m) {
    final me = m.mine;
    return Align(
      alignment: me ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 268),
        child: Column(crossAxisAlignment: me ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
          if (m.images.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final u in m.images)
                GestureDetector(
                  onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(u))),
                  child: PartThumb(width: 110, height: 90, radius: 14, imageUrl: u),
                ),
            ]),
          if ((m.body ?? '').isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: m.images.isNotEmpty ? 6 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: me ? AppColors.pri : AppColors.white,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(me ? 6 : 18),
                  topEnd: Radius.circular(me ? 18 : 6),
                  bottomStart: const Radius.circular(18),
                  bottomEnd: const Radius.circular(18),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(m.body!, style: tx(14, c: me ? AppColors.white : AppColors.ink)),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(fmtTime(m.createdAt), style: tx(10, c: me ? const Color(0xFFF6D9CD) : AppColors.mute)),
                  if (me) const SizedBox(width: 4),
                  if (me) Icon(m.readAt != null ? LucideIcons.checkCheck : LucideIcons.check, size: 14, color: const Color(0xFFF6D9CD)),
                ]),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(conversationProvider(widget.id)).valueOrNull;
    final other = c?.other;
    final listing = c?.listing;
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
              other?.isMerchant == false ? Avatar(size: 42, letter: other!.initial, bg: AppColors.tealBg, color: AppColors.teal) : const Avatar(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(other?.displayName ?? '...', style: tx(17, w: w6))),
                    if (other?.verified == true) const SizedBox(width: 4),
                    if (other?.verified == true) const VerifiedBadge(size: 16),
                  ]),
                  if (other?.city != null) Text(other!.city!, style: tx(12, c: AppColors.teal)),
                ]),
              ),
              GestureDetector(onTap: () => showToast(context, 'التواصل عبر المحادثة داخل التطبيق'), child: const Icon(LucideIcons.phone, size: 22, color: AppColors.ink)),
            ]),
          ),
          if (listing != null)
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                PartThumb(width: 48, height: 48, radius: 10, imageUrl: (listing['images'] as List?)?.isNotEmpty == true ? '${listing['images'][0]}' : null),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${listing['title']}', style: tx(14, w: w5)),
                    Text(listing['sale_type'] == 'auction' ? 'على السوم' : fmtMoney(num.tryParse('${listing['price']}') ?? 0), style: tx(14, w: w6, c: AppColors.teal)),
                  ]),
                ),
                GestureDetector(onTap: () => context.push('/part/${listing['id']}'), child: Text('شوف القطعة', style: tx(13, w: w5, c: AppColors.pri))),
              ]),
            ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: stream,
              builder: (ctx, s) {
                if (s.hasError) return ErrorBox(s.error!);
                if (!s.hasData) return const Loading();
                final msgs = s.data!;
                if (msgs.any((m) => !m.mine && m.readAt == null)) {
                  Api.markChatRead(widget.id).catchError((_) {});
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
                });
                return ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.segBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(msgs.isEmpty ? 'ابدأ المحادثة' : fmtDate(msgs.first.createdAt), style: tx(12, c: AppColors.mute)),
                    ),
                  ),
                  for (final m in msgs) ...[const SizedBox(height: 10), _bubble(m)],
                ]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(children: [
              GestureDetector(
                onTap: () async {
                  final u = await pickAndUpload(context);
                  if (u != null) await _send(images: [u]);
                },
                child: const Icon(LucideIcons.camera, size: 24, color: AppColors.mute),
              ),
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
                onTap: sending ? null : () => _send(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.pri, shape: BoxShape.circle),
                  child: sending
                      ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Icon(LucideIcons.send, size: 20, color: AppColors.white),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
