import 'firebase_options.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const PhiloDailyApp());
  
}

class PhiloDailyApp extends StatelessWidget {
  const PhiloDailyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), 
            child: child,
          ),
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'Memento',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFFD4AF37),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0, iconTheme: IconThemeData(color: Color(0xFFD4AF37))),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.black, selectedItemColor: Color(0xFFD4AF37), unselectedItemColor: Colors.grey),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), secondary: Colors.white),
        // TabBar hatası için burayı temizledik, sayfa içinde tanımlayacağız.
        
      ),
      home: const LoginPage(),
    );
  }
}

// --- MODEL ---
class Quote {
  final String text;
  final String author;
  final bool isUserGenerated;
  final String? docId;  
  final String? userId; 
  final int likes;      

  Quote({required this.text, required this.author, this.isUserGenerated = false, this.docId, this.userId, this.likes = 0});
  
  factory Quote.fromJson(Map<String, dynamic> json, {String? docId}) { 
    return Quote(
      text: json['text'] ?? "Bilinmeyen Söz", 
      author: json['author'] ?? "Anonim", 
      isUserGenerated: json['isUserGenerated'] ?? false,
      docId: docId,
      userId: json['user_id'], 
      likes: json['likes'] ?? 0
    ); 
  }
  Map<String, dynamic> toJson() => {'text': text, 'author': author, 'isUserGenerated': isUserGenerated, 'likes': likes, 'user_id': userId, 'docId': docId};
}

// --- GİRİŞ EKRANI ---
class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _fadeAnimation; bool _isLoading = false;
  final _emailController = TextEditingController(); final _passwordController = TextEditingController();
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2)); _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller); _controller.forward(); checkUser(); }
  void checkUser() { if (FirebaseAuth.instance.currentUser != null) { WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()))); } }
  void _signIn() async { if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return; setState(() => _isLoading = true); try { await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim()); if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen())); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)); } finally { if(mounted) setState(() => _isLoading = false); } }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, body: Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.3, colors: [Color(0xFF1F1F1F), Colors.black])), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 30.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Spacer(flex: 2), FadeTransition(opacity: _fadeAnimation, child: Column(children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 40, spreadRadius: 1)]), child: const Icon(Icons.hourglass_empty, size: 50, color: Color(0xFFD4AF37))), const SizedBox(height: 25), const Text("M E M E N T O", style: TextStyle(fontFamily: 'Georgia', color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 6)), const SizedBox(height: 8), Text("Kendi gerçeğini keşfet.", style: TextStyle(fontFamily: 'Georgia', color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1))])), const SizedBox(height: 50), TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "E-posta", prefixIcon: Icon(Icons.email, color: Color(0xFFD4AF37)), filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 15), TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Şifre", prefixIcon: Icon(Icons.lock, color: Color(0xFFD4AF37)), filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 25), SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), onPressed: _isLoading ? null : _signIn, child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))), const Spacer(flex: 2), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Hesabın yok mu? ", style: TextStyle(color: Colors.grey)), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text("Kayıt Ol", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)))]), const SizedBox(height: 40)])))); }
}

// --- KAYIT SAYFASI ---
class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState() => _RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController(); final _email = TextEditingController(); final _pass = TextEditingController(); bool _loading = false;
  Future<void> _reg() async { if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) return; setState(() => _loading = true); try { UserCredential uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim()); await uc.user?.updateDisplayName(_name.text.trim()); await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({'username': _name.text.trim(), 'email': _email.text.trim(), 'bio': "Yeni bir zihin.", 'created_at': FieldValue.serverTimestamp(), 'uid': uc.user!.uid, 'karma': 0}); if(mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt Başarılı!"), backgroundColor: Color(0xFFD4AF37))); } } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"))); } finally { if(mounted) setState(() => _loading = false); } }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [const Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)), const SizedBox(height: 30), TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Kullanıcı Adı", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 15), TextField(controller: _email, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "E-posta", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 15), TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Şifre", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)), onPressed: _loading ? null : _reg, child: const Text("KAYDOL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))))]))); }
}

// --- 🏠 ANA EKRAN ---
class MainScreen extends StatefulWidget { const MainScreen({super.key}); @override State<MainScreen> createState() => _MainScreenState(); }
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const SwipePage(), const LeaderboardPage(), const CreateQuotePage(), const ProfilePage()];
  @override Widget build(BuildContext context) { return Scaffold(body: IndexedStack(index: _currentIndex, children: _pages), bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i), type: BottomNavigationBarType.fixed, backgroundColor: Colors.black, showSelectedLabels: false, showUnselectedLabels: false, items: [const BottomNavigationBarItem(icon: Icon(Icons.style), label: "Keşfet"), const BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Zirve"), BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(12))), child: const Icon(Icons.add, color: Colors.black)), label: "Oluştur"), const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil")])); }
}

// --- 🏆 ZİRVE (LİDERLİK) SAYFASI (CANLI + SENİN SIRAN) ---
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});
  Future<Map<String, dynamic>> _getMyRank() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'rank': '-', 'karma': 0};
    var myDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    int myKarma = myDoc.data()?['karma'] ?? 0;
    // Basit sıralama mantığı (Gelişmiş sorgu için 'Count' kullanılır ama şimdilik bu yeterli)
    var higherDocs = await FirebaseFirestore.instance.collection('users').where('karma', isGreaterThan: myKarma).get();
    int rank = higherDocs.docs.length + 1;
    return {'rank': rank, 'karma': myKarma};
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("ZİRVE", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)), centerTitle: true, backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('users').orderBy('karma', descending: true).limit(50).snapshots(), builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
            var docs = snapshot.data!.docs;
            return ListView.builder(itemCount: docs.length, itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool isMe = data['uid'] == FirebaseAuth.instance.currentUser?.uid;
              Color color = index == 0 ? Colors.amber : (index == 1 ? Colors.grey[300]! : (index == 2 ? Colors.brown[300]! : Colors.white));
              return ListTile(
                tileColor: isMe ? const Color(0xFFD4AF37).withOpacity(0.1) : null, 
                leading: Text("${index + 1}", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)), 
                title: Text(data['username'] ?? "Anonim", style: TextStyle(color: color, fontWeight: FontWeight.bold)), 
                trailing: Text("${data['karma']} Puan", style: const TextStyle(color: Colors.grey))
              );
            });
          })),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), border: Border(top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)))), child: FutureBuilder<Map<String, dynamic>>(future: _getMyRank(), builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: LinearProgressIndicator(color: Color(0xFFD4AF37)));
            return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Senin Sıran:", style: TextStyle(color: Colors.grey[400])), Text("#${snapshot.data!['rank']}", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)), Text("${snapshot.data!['karma']} Puan", style: const TextStyle(color: Colors.white))]);
          }))
        ],
      ),
    );
  }
}

// --- ✍️ OLUŞTURMA SAYFASI ---
class CreateQuotePage extends StatefulWidget { const CreateQuotePage({super.key}); @override State<CreateQuotePage> createState() => _CreateQuotePageState(); }
class _CreateQuotePageState extends State<CreateQuotePage> {
  final _tController = TextEditingController(); final _aController = TextEditingController(); 
  String privacy = "Herkese Açık"; bool _isSending = false;
  @override void initState() { super.initState(); _loadUser(); }
  void _loadUser() async { 
    final user = FirebaseAuth.instance.currentUser; 
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if(mounted) { setState(() { _aController.text = user.displayName ?? (doc.data()?['username'] ?? ""); }); }
    }
  }
  @override Widget build(BuildContext context) { 
    return Scaffold(backgroundColor: Colors.black, body: Padding(padding: const EdgeInsets.all(20.0), child: SingleChildScrollView(child: Column(children: [
      const SizedBox(height: 20), const Text("BİLGELİĞİNİ PAYLAŞ", style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 20), 
      TextField(controller: _tController, maxLines: 5, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Sözü buraya yaz...", filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20), 
      TextField(controller: _aController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Senin Adın", filled: true, fillColor: const Color(0xFF1E1E1E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))), const SizedBox(height: 20), 
      DropdownButton<String>(value: privacy, dropdownColor: const Color(0xFF1E1E1E), style: const TextStyle(color: Colors.white), items: ["Herkese Açık", "Takipçilerim", "Yalnızca Ben"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => privacy = v!)), const SizedBox(height: 40), 
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 50)), onPressed: _isSending ? null : () async { 
        if (_tController.text.isNotEmpty) { 
          setState(() => _isSending = true); 
          try { 
            await FirebaseFirestore.instance.collection('quotes').add({
              'text': _tController.text, 'author': _aController.text.isEmpty ? "Anonim" : _aController.text, 'privacy': privacy, 'created_at': FieldValue.serverTimestamp(), 'likes': 0, 'user_id': FirebaseAuth.instance.currentUser?.uid
            }); 
            if (mounted) { _tController.clear(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paylaşıldı!"), backgroundColor: Color(0xFFD4AF37))); } 
          } finally { if(mounted) setState(() => _isSending = false); } 
        } 
      }, child: _isSending ? const CircularProgressIndicator(color: Colors.black) : const Text("PAYLAŞ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) 
    ])))); 
  }
}

// --- 🔥 SWIPE SAYFASI (GÜNCELLENDİ: BUTONSUZ BEĞENİ & KAYDETME DÜZELDİ) ---
// --- 🔥 SWIPE SAYFASI (GÜNCELLENDİ: BUTONSUZ BEĞENİ & KAYDETME DÜZELDİ) ---
class SwipePage extends StatefulWidget { const SwipePage({super.key}); @override State<SwipePage> createState() => _SwipePageState(); }
class _SwipePageState extends State<SwipePage> {
  final CardSwiperController controller = CardSwiperController();
  List<Quote> _quotes = []; List<String> _savedIds = []; bool _isLoading = true; Set<String> _likedSessionIds = {};
  @override void initState() { super.initState(); _init(); }
  void _init() async { await _loadQuotes(); await _loadSaved(); }
  Future<void> _loadQuotes() async {Future<void> _loadQuotes() async {
    // 1. Yerel JSON dosyasını yükle (Hali hazırda var olanları kaybetme)
    List<Quote> localLoaded = [];
    try { 
      final r = await rootBundle.loadString('assets/quotes.json'); 
      for(var i in jsonDecode(r)) localLoaded.add(Quote.fromJson(i)); 
    } catch (_) {}
    
    // 2. Firebase Canlı Yayınını Başlat
    // Bu yapı uygulamanın diğer sayfalarıyla ASLA çakışmaz.
    FirebaseFirestore.instance.collection('quotes')
        .where('privacy', isEqualTo: 'Herkese Açık')
        .orderBy('created_at', descending: true)
        .limit(30)
        .snapshots() // Canlı bağlantı kurar
        .listen((snapshot) {
      
      if (_isLoading) {
        // Uygulama ilk açıldığında listeyi doldurur
        List<Quote> firebaseLoaded = [];
        for (var d in snapshot.docs) {
          firebaseLoaded.add(Quote.fromJson(d.data(), docId: d.id));
        }
        if (mounted) {
          setState(() { 
            _quotes = [...localLoaded, ...firebaseLoaded]..shuffle(); 
            _isLoading = false; 
          });
        }
      } else {
        // Paylaşım yapıldığında listeye sessizce yeni dökümanı ekler
        bool isChanged = false;
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
           var newQuote = Quote.fromJson(change.doc.data()!, docId: change.doc.id);
            // Zaten listede yoksa ekle (Çift kayıt olmasın diye)
            if (!_quotes.any((q) => q.docId == newQuote.docId)) {
              _quotes.insert(0, newQuote); // En başa ekle
              isChanged = true;
            }
          }
        }
        if (isChanged && mounted) setState(() {}); 
      }
    });
  }
   
  }
  Future<void> _loadSaved() async { final p = await SharedPreferences.getInstance(); setState(() => _savedIds = p.getStringList('saved_quotes_v2') ?? []); }
  
  void _like(Quote q) {
    HapticFeedback.mediumImpact();
    if(q.docId != null) {
      setState(() => _likedSessionIds.add(q.docId!));
      FirebaseFirestore.instance.collection('quotes').doc(q.docId).update({'likes': FieldValue.increment(1)});
      if(q.userId != null) FirebaseFirestore.instance.collection('users').doc(q.userId).update({'karma': FieldValue.increment(1)});
    }
  }

  // 🔥 YENİ GÜVENLİ KAYDETME FONKSİYONU
  void _save(Quote q) async {
    final p = await SharedPreferences.getInstance(); 
    List<String> list = p.getStringList('saved_quotes_v2') ?? []; 
    
    bool exists = false;
    for (var e in list) {
      try { if (jsonDecode(e)['text'] == q.text) exists = true; } catch (_) {}
    }

    if (exists) { 
      list.removeWhere((e) {
        try { return jsonDecode(e)['text'] == q.text; } catch (_) { return false; }
      }); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaldırıldı"))); 
    } else { 
      list.add(jsonEncode(q.toJson())); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedildi 🔖"), backgroundColor: Color(0xFFD4AF37))); 
    }
    await p.setStringList('saved_quotes_v2', list); 
    _loadSaved();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: Column(children: [const SizedBox(height: 20), Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))) : CardSwiper(controller: controller, cardsCount: _quotes.length, numberOfCardsDisplayed: _quotes.length < 3 ? _quotes.length : 3, padding: const EdgeInsets.all(24.0), onSwipe: (p, c, d) { if(d == CardSwiperDirection.right) _like(_quotes[p]); return true; }, cardBuilder: (c, i, x, y) => _buildCard(_quotes[i]))) ])));
  }

  // 🔥 YENİ ANINDA TEPKİ VEREN KART (StatefulBuilder eklendi)
  Widget _buildCard(Quote q) {
    bool isLiked = (q.docId != null && _likedSessionIds.contains(q.docId));
    
    return StatefulBuilder(
      builder: (context, setStateCard) {
        bool isSaved = false;
        for (var e in _savedIds) {
          try { if (jsonDecode(e)['text'] == q.text) isSaved = true; } catch (_) {}
        }

        return Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF333333))),
          child: Stack(
            fit: StackFit.expand, // KART BÜZÜŞMESİNİ ENGELLEYEN KOD BURADA
            children: [
              Positioned(top: 20, left: 20, child: Row(children: [
                const CircleAvatar(radius: 16, backgroundColor: Color(0xFF333333), child: Icon(Icons.person, color: Colors.white, size: 20)),
                const SizedBox(width: 8), Text(q.author, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if(isLiked) const Icon(Icons.favorite, color: Colors.redAccent, size: 60), 
                const SizedBox(height: 20),
                Text("\"${q.text}\"", textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Georgia', color: Color(0xFFE0E0E0), fontSize: 24, fontStyle: FontStyle.italic)),
              ])),
              // KAYDETME BUTONU
              Positioned(
                bottom: 20, right: 20, 
                child: IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFFD4AF37) : Colors.white54, size: 30), 
                  onPressed: () {
                    _save(q); 
                    setStateCard(() {}); // Butonu anında sarıya boyar!
                  }
                )
              ),
            ],
          ),
        );
      }
    );
  }
}
// --- 👤 PROFİL SAYFASI (DÜZELDİ: SEKME STİLİ VE LİSTE) ---
class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  // --- BOT BASMA (Gizli Özellik) ---
  void _addBots() async {
    final names = ["Baki", "Seda", "Can", "Elif", "Mert", "Ece", "Ozan", "Gizem"];
    final batch = FirebaseFirestore.instance.batch();
    for(int i=0; i<50; i++) {
      String id = FirebaseFirestore.instance.collection('users').doc().id;
      batch.set(FirebaseFirestore.instance.collection('users').doc(id), {
        'username': "${names[Random().nextInt(names.length)]}_${Random().nextInt(99)}",
        'karma': Random().nextInt(500), 'uid': id, 'bio': "Bot", 'created_at': FieldValue.serverTimestamp()
      });
    }
    await batch.commit();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("50 Bot Eklendi!"), backgroundColor: Colors.green));
  }

  void _settings() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1E1E1E), builder: (c) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit, color: Colors.white), title: const Text("Düzenle", style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: _auth.currentUser))); }),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Çıkış", style: TextStyle(color: Colors.red)), onTap: () async { await _auth.signOut(); Navigator.pop(c); if(mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())); }),
      const Divider(),
      TextButton(onPressed: _addBots, child: const Text("TEST: Bot Ekle (Gizli)", style: TextStyle(color: Colors.grey)))
    ]));
  }

  @override Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return DefaultTabController(length: 2, child: Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, title: const Text("PROFİL", style: TextStyle(color: Color(0xFFD4AF37))), actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _settings)]), body: Column(children: [
      const SizedBox(height: 20),
      const CircleAvatar(radius: 40, backgroundColor: Color(0xFF1E1E1E), child: Icon(Icons.person, color: Color(0xFFD4AF37), size: 40)),
      const SizedBox(height: 10), Text(user?.displayName ?? "Misafir", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20), const TabBar(labelColor: Color(0xFFD4AF37), unselectedLabelColor: Colors.grey, indicatorColor: Color(0xFFD4AF37), tabs: [Tab(text: "PAYLAŞTIKLARIM"), Tab(text: "KAYDETTİKLERİM")]),
      Expanded(child: TabBarView(children: [
        // PAYLAŞTIKLARIM
        StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('quotes').where('user_id', isEqualTo: user?.uid).orderBy('created_at', descending: true).snapshots(), builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz yok.", style: TextStyle(color: Colors.grey)));
          return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) { var data = snapshot.data!.docs[index].data() as Map<String, dynamic>; return Card(color: const Color(0xFF1E1E1E), margin: const EdgeInsets.all(8), child: ListTile(title: Text(data['text'], style: const TextStyle(color: Colors.white)), subtitle: Text("❤️ ${data['likes']} Beğeni", style: const TextStyle(color: Colors.grey)))); });
        }),
        // KAYDETTİKLERİM (DÜZELTİLDİ)
        FutureBuilder<List<String>>(future: SharedPreferences.getInstance().then((p) => p.getStringList('saved_quotes_v2') ?? []), builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Henüz yok.", style: TextStyle(color: Colors.grey)));
          return ListView.builder(itemCount: snapshot.data!.length, itemBuilder: (context, index) { 
             try { var q = Quote.fromJson(jsonDecode(snapshot.data![index])); return Card(color: const Color(0xFF1E1E1E), margin: const EdgeInsets.all(8), child: ListTile(title: Text(q.text, style: const TextStyle(color: Colors.white)), subtitle: Text(q.author, style: const TextStyle(color: Color(0xFFD4AF37))))); } catch (e) { return const SizedBox(); }
          });
        })
      ]))
    ])));
  }
}

// --- DÜZENLEME SAYFASI ---
class EditProfilePage extends StatefulWidget { final User? user; const EditProfilePage({super.key, required this.user}); @override State<EditProfilePage> createState() => _EditProfilePageState(); }
class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController(); final _bio = TextEditingController(); bool _loading = false;
  @override void initState() { super.initState(); _load(); }
  void _load() async { var d = await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).get(); _name.text = d.data()?['username'] ?? ""; _bio.text = d.data()?['bio'] ?? ""; }
  void _save() async { setState(() => _loading = true); await widget.user?.updateDisplayName(_name.text); await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({'username': _name.text, 'bio': _bio.text}); if(mounted) Navigator.pop(context); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, title: const Text("Profili Düzenle")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "İsim", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 20), TextField(controller: _bio, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Bio", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 40), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 50)), onPressed: _loading ? null : _save, child: const Text("KAYDET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ]))); }
}