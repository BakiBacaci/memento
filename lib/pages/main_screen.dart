import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
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
  late final _unread = NotificationService.instance.unreadCount();

  /// Misafirken korunan bir işleme dokunulunca giriş sayfasını açar.
  void _openSignIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(canDismiss: true)),
    );
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
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
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        extendBody: false,
        // Sekmeler arası geçiş: seçilen sekme yana kayarak ve belirerek gelir.
        // Hepsi bellekte kalır (kaydırma yeri, yazılan metin kaybolmaz).
        body: Stack(
          children: [
            for (var i = 0; i < pages.length; i++)
              _TabLayer(
                active: i == _index,
                offset: i == _index ? 0 : (i < _index ? -0.06 : 0.06),
                child: pages[i],
              ),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<String>(
          valueListenable: SettingsService.instance.language,
          builder: (context, _, __) => StreamBuilder<int>(
            stream: _unread,
            builder: (context, snap) => _FloatingNav(
              index: _index,
              onSelect: _select,
              dotOn: (snap.data ?? 0) > 0 ? 1 : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Alt menü: düz zemin, seçili sekme siyah bir yuvarlakta.
/// Ortadaki siyah kare "söz yaz".
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onSelect, this.dotOn});

  final int index;
  final ValueChanged<int> onSelect;

  /// Bu sekmenin simgesinde küçük kırmızı nokta (okunmamış bildirim).
  final int? dotOn;

  static const _icons = [
    (Icons.style_outlined, Icons.style),
    (Icons.whatshot_outlined, Icons.whatshot),
    (Icons.add, Icons.add),
    (Icons.leaderboard_outlined, Icons.leaderboard),
    (Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 6, 18, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _icons.length; i++)
              i == 2 ? _createButton() : _item(i),
          ],
        ),
      ),
    );
  }

  Widget _item(int i) {
    final active = i == index;
    return GestureDetector(
      onTap: () => onSelect(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? AppColors.textPrimary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Badge(
          isLabelVisible: dotOn == i,
          smallSize: 9,
          backgroundColor: AppColors.danger,
          child: Icon(
            active ? _icons[i].$2 : _icons[i].$1,
            color: active ? AppColors.bg : AppColors.textPrimary,
            size: 25,
          ),
        ),
      ),
    );
  }

  Widget _createButton() => GestureDetector(
        onTap: () => onSelect(2),
        child: Container(
          width: 64,
          height: 52,
          decoration: BoxDecoration(
            color: index == 2 ? AppColors.gold : AppColors.textPrimary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.add, color: AppColors.bg, size: 28),
        ),
      );
}

class _TabLayer extends StatelessWidget {
  const _TabLayer({required this.active, required this.offset, required this.child});
  final bool active;
  final double offset;
  final Widget child;

  @override
  // Not: TickerMode yalnızca sayfanın içini durdurur. Geçiş animasyonunun
  // kendisini sarmamalı; yoksa çıkılan sekmenin solması yarıda donar ve o
  // sayfa (özellikle en üstteki Profil) ekranda asılı kalır.
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !active,
        child: AnimatedSlide(
          offset: Offset(offset, 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      );
}
