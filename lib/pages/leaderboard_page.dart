import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<({int rank, int karma})> _rankFuture;

  @override
  void initState() {
    super.initState();
    _rankFuture = UserService.instance.myRank();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = UserService.instance.uid;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('leaderboard'))),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: UserService.instance.topUsers(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return EmptyState(
                      message: context.t('rank_failed'), icon: Icons.cloud_off);
                }
                if (!snap.hasData) return const ShimmerList();

                final users = snap.data!;
                if (users.isEmpty) {
                  return EmptyState(
                      message: context.t('no_one_yet'),
                      icon: Icons.emoji_events_outlined);
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final isMe = u.uid == myUid;
                    final color = switch (i) {
                      0 => AppColors.gold1,
                      1 => AppColors.silver,
                      2 => AppColors.bronze,
                      _ => Colors.white,
                    };
                    final badge = switch (i) {
                      0 => ' 👑',
                      1 => ' 🥈',
                      2 => ' 🥉',
                      _ => '',
                    };
                    return ListTile(
                      tileColor:
                          isMe ? AppColors.gold.withValues(alpha: 0.08) : null,
                      leading: SizedBox(
                        width: 56,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            UserAvatar(
                              photoUrl: u.photoUrl,
                              initial: u.username,
                              radius: 14,
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        '${u.username}$badge',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${u.karma} ${context.t('points')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfilePage(uid: u.uid)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (UserService.instance.isSignedIn) _buildMyRankBar(),
        ],
      ),
    );
  }

  Widget _buildMyRankBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.gold.withValues(alpha: 0.4))),
      ),
      child: FutureBuilder<({int rank, int karma})>(
        future: _rankFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(context.t('rank_unknown'),
                style: const TextStyle(color: Colors.grey));
          }
          if (!snap.hasData) return const LinearProgressIndicator();

          final data = snap.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.t('your_rank'),
                  style: TextStyle(color: Colors.grey[400])),
              Text(
                data.rank > 0 ? '#${data.rank}' : '—',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('${data.karma} ${context.t('points')}',
                  style: const TextStyle(color: Colors.white)),
            ],
          );
        },
      ),
    );
  }
}
