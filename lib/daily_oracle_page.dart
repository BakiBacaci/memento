import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart'; // ^6.1.0 sürümü gerekli
import 'package:shared_preferences/shared_preferences.dart';

class DailyOraclePage extends StatefulWidget {
  const DailyOraclePage({super.key});

  @override
  State<DailyOraclePage> createState() => _DailyOraclePageState();
}

class _DailyOraclePageState extends State<DailyOraclePage> with SingleTickerProviderStateMixin {
  bool _isUnlocked = false;
  bool _isShaking = false;
  double _shakeProgress = 0.0;
  final double _shakeThreshold = 15.0; // Sallama hassasiyeti
  
  String _dailyQuote = "Yükleniyor...";
  String _dailyAuthor = "";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkDailyStatus();
    _startListeningSensor();
    
    _fadeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  // --- SENSÖR DİNLEME (Versiyon Sorunu Çözüldü) ---
  void _startListeningSensor() {
    // sensors_plus 6.0.0+ için doğru kullanım budur:
    accelerometerEventStream().listen((AccelerometerEvent event) {
      if (_isUnlocked) return; 

      double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (gForce > _shakeThreshold) {
        if (mounted) {
          setState(() {
            _shakeProgress += 0.02; // Biraz daha zor dolsun
            _isShaking = true;
          });
          HapticFeedback.mediumImpact();
        }

        if (_shakeProgress >= 1.0) {
          _unlockDestiny();
        }
      } else {
        if (mounted) setState(() => _isShaking = false);
      }
    });
  }

  Future<void> _checkDailyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpenDate = prefs.getString('last_oracle_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastOpenDate == today) {
      _selectNewQuote();
      _unlockDestiny(skipAnimation: true);
    } else {
      _selectNewQuote();
    }
  }

  void _selectNewQuote() {
    final List<Map<String, String>> quotes = [
      {"text": "Yolunu bulamıyorsan, belki de yol sensindir.", "author": "Rumi"},
      {"text": "Cesaret, korkuya rağmen hareket etmektir.", "author": "Seneca"},
      {"text": "Yarın, bugünden hazırlanır.", "author": "Atatürk"},
      {"text": "Memento Mori: Ölümlü olduğunu hatırla.", "author": "Stoacı"},
      {"text": "Kendini bilmek, tüm bilgeliğin başlangıcıdır.", "author": "Aristoteles"},
    ];
    final random = Random();
    final selection = quotes[random.nextInt(quotes.length)];
    
    if (mounted) {
      setState(() {
        _dailyQuote = selection['text']!;
        _dailyAuthor = selection['author']!;
      });
    }
  }

  Future<void> _unlockDestiny({bool skipAnimation = false}) async {
    if (_isUnlocked && !skipAnimation) return;

    if (mounted) setState(() => _isUnlocked = true);
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_oracle_date', today);

    if (!skipAnimation) {
      HapticFeedback.heavyImpact();
    }
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // --- 1. KİLİTLİ DURUM ---
          if (!_isUnlocked)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: _isShaking ? (Random().nextDouble() - 0.5) * 0.2 : 0, 
                  child: const Icon(Icons.lock_outline, size: 120, color: Color(0xFFD4AF37)), 
                ),
                const SizedBox(height: 40),
                Text("KADERİNİN KİLİDİNİ AÇ", style: TextStyle(color: const Color(0xFFD4AF37).withOpacity(0.9), fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Telefonu Salla 📳", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _shakeProgress,
                    backgroundColor: Colors.grey[900],
                    color: const Color(0xFFD4AF37),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

          // --- 2. AÇILMIŞ DURUM ---
          if (_isUnlocked)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 60, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 20),
                    const Text("BUGÜNÜN REHBERLİĞİ", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 3)),
                    const SizedBox(height: 30),
                    Text("\"$_dailyQuote\"", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, color: Colors.white, fontStyle: FontStyle.italic, height: 1.4, shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 15)])),
                    const SizedBox(height: 20),
                    Text("- $_dailyAuthor", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 50),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Kabul Ettim", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}