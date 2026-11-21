import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'profile_page.dart';

/// Takipçiler / Takip edilenler listesi. Canlı.
///
/// Kendi takipçi listende her satırda "Çıkar" var: o kişi engellenmeden
/// takipçilerinden çıkar (Instagram'daki gibi, karşı tarafa bildirim gitmez).
class FollowListPage extends StatefulWidget {
  const FollowListPage({
    super.key,
    required this.uid,
    required this.showFollowers,
  });

  final String uid;

  /// true = takipçiler, false = takip edilenler
  final bool showFollowers;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  late final _ids =
      FollowService.instance.watchIds(widget.uid, followers: widget.showFollowers);

  bool get _canRemove =>
      widget.showFollowers && widget.uid == UserService.instance.uid;

  Future<void> _remove(AppUser? u, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('remove_follower_q')),
        content: Text(ctx.tn('remove_follower_body', {'u': '@${u?.username ?? ''}'})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('remove'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t('err_generic');
    try {
      await FollowService.instance.removeFollower(uid);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$failed $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(widget.showFollowers ? 'followers' : 'following')),
      ),
      body: StreamBuilder<List<String>>(
        stream: _ids,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
                message: context.t('load_failed'), icon: Icons.cloud_off);
          }
          if (!snap.hasData) return const ShimmerList(count: 5);

          final ids = snap.data!;
          if (ids.isEmpty) {
            return EmptyState(
              message: context
                  .t(widget.showFollowers ? 'no_followers' : 'no_following'),
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            itemCount: ids.length,
            itemBuilder: (context, i) => _UserRow(
              key: ValueKey(ids[i]),
              uid: ids[i],
              onRemove: _canRemove ? (u) => _remove(u, ids[i]) : null,
            ),
          );
        },
      ),
    );
  }
}

class _UserRow extends StatefulWidget {
  const _UserRow({super.key, required this.uid, this.onRemove});
  final String uid;
  final ValueChanged<AppUser?>? onRemove;

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  late final _user = UserService.instance.get(widget.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _user,
      builder: (context, snap) {
        final u = snap.data;
        return ListTile(
          leading: UserAvatar(
            photoUrl: u?.photoUrl,
            initial: u?.name,
            radius: 22,
          ),
          title: Text(
            u?.name ?? '...',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          subtitle: u == null
              ? null
              : Text('@${u.username}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          trailing: widget.onRemove != null
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => widget.onRemove!(u),
                  child: Text(context.t('remove')),
                )
              : Text(
                  '${u?.karma ?? 0} ${context.t('points')}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePage(uid: widget.uid)),
          ),
        );
      },
    );
  }
}
