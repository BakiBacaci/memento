import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import 'create_quote_page.dart';
import 'feed_page.dart';
import 'leaderboard_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'swipe_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  /// Misafirken korunan bir işleme dokunulunca giriş sayfasını açar.
  void _openSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(canDismiss: true)),
    );
  }

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      SwipePage(onRequireSignIn: _openSignIn),
      FeedPage(onRequireSignIn: _openSignIn),
      CreateQuotePage(onRequireSignIn: _openSignIn),
      const LeaderboardPage(),
      ProfilePage(onRequireSignIn: _openSignIn),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: ValueListenableBuilder<String>(
          valueListenable: SettingsService.instance.language,
          builder: (context, _, __) => BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(
                  icon: const Icon(Icons.style_outlined),
                  activeIcon: const Icon(Icons.style),
                  label: context.t('discover')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.local_fire_department_outlined),
                  activeIcon: const Icon(Icons.local_fire_department),
                  label: context.t('feed')),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 22),
                ),
                label: context.t('create'),
              ),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events_outlined),
                  activeIcon: const Icon(Icons.emoji_events),
                  label: context.t('leaderboard')),
              BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: context.t('profile')),
            ],
          ),
        ),
      ),
    );
  }
}
