import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'profile_page.dart';

/// Bildirimler: kim beğendi, kim takip etti. Açılınca hepsi okundu olur.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const NotificationsPage()));

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final _stream = NotificationService.instance.watch();

  @override
  void initState() {
    super.initState();
    NotificationService.instance.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('notifications'))),
      body: StreamBuilder<List<AppNotification>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
                message: context.t('load_failed'), icon: Icons.cloud_off);
          }
          if (!snap.hasData) return const ShimmerList(count: 6);
          final items = snap.data!;
          if (items.isEmpty) {
            return EmptyState(
              message: context.t('no_notifications'),
              icon: Icons.notifications_none,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, i) => Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: AppColors.danger,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) =>
                  NotificationService.instance.delete(items[i].id),
              child: _Row(n: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final isLike = n.type == 'like';
    final mood = QuoteMood.of(n.quoteId ?? n.actorUid);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(uid: n.actorUid)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                    photoUrl: n.actorPhotoUrl,
                    initial: n.actorUsername,
                    radius: 22),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isLike ? AppColors.danger : AppColors.textPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    child: Icon(
                      isLike ? Icons.favorite : Icons.person_add_alt_1,
                      size: 11,
                      color: isLike ? Colors.white : AppColors.bg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '@${n.actorUsername} ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                          text: context.t(isLike ? 'notif_like' : 'notif_follow')),
                      TextSpan(
                        text: '  ${_ago(context, n.createdAt)}',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ]),
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 15, height: 1.3),
                  ),
                  if (isLike && (n.quoteText ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      decoration: BoxDecoration(
                        color: mood.top,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        n.quoteText!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mood.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ago(BuildContext context, DateTime? t) {
    if (t == null) return context.t('just_now');
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return context.t('just_now');
    if (d.inHours < 1) return context.tn('ago_min', {'n': '${d.inMinutes}'});
    if (d.inDays < 1) return context.tn('ago_hour', {'n': '${d.inHours}'});
    if (d.inDays < 7) return context.tn('ago_day', {'n': '${d.inDays}'});
    return context.tn('ago_week', {'n': '${d.inDays ~/ 7}'});
  }
}

/// Zil düğmesi + okunmamış rozeti. Akış başlığında duruyor.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final _count = NotificationService.instance.unreadCount();

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: _count,
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return IconButton(
            tooltip: context.t('notifications'),
            onPressed: () => NotificationsPage.open(context),
            icon: Badge(
              isLabelVisible: n > 0,
              backgroundColor: AppColors.danger,
              label: Text(n > 20 ? '20+' : '$n'),
              child: Icon(n > 0 ? Icons.notifications : Icons.notifications_none),
            ),
          );
        },
      );
}
