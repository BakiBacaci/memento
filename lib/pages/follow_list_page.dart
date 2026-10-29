import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'profile_page.dart';

/// Takipçiler / Takip edilenler listesi.
///
/// Profildeki sayılara dokununca açılıyor — sayıyı görüp kimler olduğunu
/// görememek eksik kalıyordu.
class FollowListPage extends StatelessWidget {
  const FollowListPage({
    super.key,
    required this.uid,
    required this.showFollowers,
  });

  final String uid;

  /// true = takipçiler, false = takip edilenler
  final bool showFollowers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(showFollowers ? 'followers' : 'following')),
      ),
      body: FutureBuilder<List<String>>(
        future: showFollowers
            ? FollowService.instance.followerIds(uid)
            : FollowService.instance.followingIdsOf(uid),
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
                  .t(showFollowers ? 'no_followers' : 'no_following'),
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            itemCount: ids.length,
            itemBuilder: (context, i) => _UserRow(uid: ids[i]),
          );
        },
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserService.instance.get(uid),
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
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: u == null
              ? null
              : Text('@${u.username}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
          trailing: Text(
            '${u?.karma ?? 0} ${context.t('points')}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfilePage(uid: uid)),
          ),
        );
      },
    );
  }
}
