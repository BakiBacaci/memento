import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';
import 'profile_page.dart';

/// Zirve: ilk üç kişi renkli bloklarda, gerisi sade satırlar.
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<({int rank, int karma})> _rankFuture;

  // Kürsü renkleri: söz paletinden.
  static const _podium = [
    (Color(0xFFD7F75B), Color(0xFF24400A)),
    (Color(0xFF9AD1FF), Color(0xFF0A2A4A)),
    (Color(0xFFFF9F80), Color(0xFF4A1406)),
  ];

  @override
  void initState() {
    super.initState();
    _rankFuture = UserService.instance.myRank();
  }

  void _open(AppUser u) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(uid: u.uid)),
      );

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
                      icon: Icons.leaderboard_outlined);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final isMe = u.uid == myUid;
                    return i < 3
                        ? _PodiumTile(
                            rank: i + 1,
                            user: u,
                            bg: _podium[i].$1,
                            ink: _podium[i].$2,
                            onTap: () => _open(u),
                          )
                        : _RowTile(
                            rank: i + 1,
                            user: u,
                            highlighted: isMe,
                            onTap: () => _open(u),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: ShapeDecoration(
          color: AppColors.textPrimary,
          shape: StadiumBorder(),
        ),
        child: FutureBuilder<({int rank, int karma})>(
          future: _rankFuture,
          builder: (context, snap) {
            final style = TextStyle(
                color: AppColors.bg, fontSize: 15, fontWeight: FontWeight.w600);
            if (snap.hasError) {
              return Text(context.t('rank_unknown'), style: style);
            }
            if (!snap.hasData) {
              return LinearProgressIndicator(color: AppColors.bg);
            }
            final data = snap.data!;
            return Row(
              children: [
                Text(context.t('your_rank'), style: style),
                const SizedBox(width: 10),
                Text(
                  data.rank > 0 ? '${data.rank}.' : '—',
                  style: TextStyle(
                    color: AppColors.bg,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text('${data.karma} ${context.t('points')}', style: style),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.rank,
    required this.user,
    required this.bg,
    required this.ink,
    required this.onTap,
  });

  final int rank;
  final AppUser user;
  final Color bg;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Text('$rank',
                      style: TextStyle(
                          color: ink,
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2)),
                  const SizedBox(width: 16),
                  UserAvatar(
                      photoUrl: user.photoUrl, initial: user.username, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${user.karma}',
                          style: TextStyle(
                              color: ink,
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w800)),
                      Text(context.t('points'),
                          style: TextStyle(
                              color: ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.rank,
    required this.user,
    required this.highlighted,
    required this.onTap,
  });

  final int rank;
  final AppUser user;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: highlighted
              ? BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(18),
                )
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text('$rank',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              UserAvatar(
                  photoUrl: user.photoUrl, initial: user.username, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(user.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              Text('${user.karma}',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}
