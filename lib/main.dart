import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/main_screen.dart';
import 'services/settings_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  await SettingsService.instance.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MementoApp());
}

class MementoApp extends StatelessWidget {
  const MementoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dil değişince tüm ağaç yeniden çiziliyor — ayarlardan Türkçe/İngilizce
    // arasında geçiş anında uygulanıyor, yeniden başlatma gerekmiyor.
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.language,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: 'Memento',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Geniş ekranlarda (web/tablet) içeriği telefon genişliğinde tut.
        builder: (context, child) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: child,
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Oturum durumunu tek yerden dinler.
///
/// Giriş yapılmamışsa VE kullanıcı daha önce "hesapsız devam et" dememişse
/// giriş ekranı gösterilir. Misafir modundaysa uygulama normal açılır;
/// hesap gerektiren işlemlerde giriş ekranı ayrıca sunulur.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (snapshot.data != null) return const MainScreen();

        return ValueListenableBuilder<bool>(
          valueListenable: SettingsService.instance.guestMode,
          builder: (context, isGuest, _) =>
              isGuest ? const MainScreen() : const LoginPage(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, color: AppColors.gold, size: 44),
              SizedBox(height: 20),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      );
}
