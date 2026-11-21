import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/main_screen.dart';
import 'services/account_service.dart';
import 'services/block_service.dart';
import 'services/daily_service.dart';
import 'services/journal_service.dart';
import 'services/settings_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SettingsService.instance.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check: Firebase'e sadece gerçek Memento uygulamasından gelen
  // istekler ulaşsın. Konsolda "zorunlu" yapılana kadar sadece izler.
  if (!kIsWeb) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
      );
    } catch (e) {
      debugPrint('App Check başlatılamadı: $e');
    }
  }

  // Oturum açılınca engellenenler yüklenir, kapanınca temizlenir.
  FirebaseAuth.instance.authStateChanges().listen((user) {
    DailyService.instance.onAuthChanged();
    JournalService.instance.bind();
    if (user == null) {
      BlockService.instance.clear();
    } else {
      BlockService.instance.load();
      AccountService.instance.scrubLegacyEmail();
    }
  });

  runApp(const MementoApp());

  // Widget verisi + günlük bildirimler. Açılışı bekletmesin diye sonra.
  DailyService.instance.init();
}

class MementoApp extends StatefulWidget {
  const MementoApp({super.key});

  @override
  State<MementoApp> createState() => _MementoAppState();
}

class _MementoAppState extends State<MementoApp> with WidgetsBindingObserver {
  final _settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.themeMode.addListener(_applyTheme);
    _applyTheme(rebuild: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.themeMode.removeListener(_applyTheme);
    super.dispose();
  }

  /// Telefonun açık/koyu modu değişince ("Sistem" seçiliyse) uygula.
  @override
  void didChangePlatformBrightness() => _applyTheme();

  Brightness get _brightness => switch (_settings.themeMode.value) {
        'light' => Brightness.light,
        'dark' => Brightness.dark,
        _ => WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };

  void _applyTheme({bool rebuild = true}) {
    final b = _brightness;
    final changed = AppColors.isDark != (b == Brightness.dark);
    AppColors.apply(b);
    SystemChrome.setSystemUIOverlayStyle(
        b == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    if (!rebuild || !changed || !mounted) return;
    setState(() {});
    // Renkler build sırasında okunuyor: açık sayfalar dahil her şeyi yeniden
    // çizdir (gezinme geçmişi korunur, kullanıcı olduğu yerde kalır).
    void rebuildAll(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuildAll);
    }
    (context as Element).visitChildren(rebuildAll);
  }

  @override
  Widget build(BuildContext context) {
    // Dil değişince tüm ağaç yeniden çiziliyor — ayarlardan Türkçe/İngilizce
    // arasında geçiş anında uygulanıyor, yeniden başlatma gerekmiyor.
    return ValueListenableBuilder<String>(
      valueListenable: _settings.language,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: 'Memento',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Geniş ekranlarda (web/tablet) içeriği telefon genişliğinde tut.
        builder: (context, child) => ColoredBox(
          color: AppColors.bg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
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
        // Anahtar oturuma bağlı: giriş/çıkışta bütün sekmeler sıfırdan kurulur,
        // misafirken açılmış "giriş yap" ekranları takılı kalmaz.
        if (snapshot.data != null) {
          return MainScreen(key: ValueKey(snapshot.data!.uid));
        }

        return ValueListenableBuilder<bool>(
          valueListenable: SettingsService.instance.guestMode,
          builder: (context, isGuest, _) =>
              isGuest ? const MainScreen(key: ValueKey('guest')) : const LoginPage(),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
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
