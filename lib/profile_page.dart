import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Quote Modelini burada da tanımlıyoruz ki hata vermesin
class Quote {
  final String text;
  final String author;
  final String? authorPhotoUrl;
  final bool isUserGenerated;
  final String? docId;
  final String? userId;
  final int likes;

  Quote({required this.text, required this.author, this.authorPhotoUrl, this.isUserGenerated = false, this.docId, this.userId, this.likes = 0});

  factory Quote.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Quote(
      text: json['text'] ?? "Bilinmeyen Söz",
      author: json['author'] ?? "Anonim",
      authorPhotoUrl: json['author_photo'],
      isUserGenerated: json['isUserGenerated'] ?? false,
      docId: docId,
      userId: json['user_id'],
      likes: json['likes'] ?? 0
    );
  }
}

// --- PROFİL SAYFASI ---
class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState() => _ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;

  @override Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, title: const Text("PROFİL", style: TextStyle(color: Color(0xFFD4AF37))), actions: [
          // HATA ÇIKARAN KISIM DÜZELDİ: Artık EditProfilePage sadece 'user' istiyor
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user)))),
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async { 
            await _auth.signOut(); 
            // Çıkış yapınca Login sayfasına yönlendirme işlemi Main.dart'ta olduğu için 
            // burada sadece pop yapıyoruz veya basitçe çıkış sağlanıyor.
             if(mounted) Navigator.popUntil(context, (route) => route.isFirst);
          })
        ]),
        body: Column(
          children: [
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot>(future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(), builder: (context, snapshot) {
              String? photoUrl; if(snapshot.hasData) photoUrl = snapshot.data?['photo_url'];
              return CircleAvatar(radius: 40, backgroundColor: const Color(0xFF1E1E1E), backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null, child: (photoUrl == null || photoUrl.isEmpty) ? Text(user?.displayName?[0] ?? "M", style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 30)) : null);
            }),
            const SizedBox(height: 10), Text(user?.displayName ?? "Misafir", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const TabBar(
              labelColor: Color(0xFFD4AF37),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFD4AF37),
              tabs: [Tab(text: "PAYLAŞTIKLARIM"), Tab(text: "KAYDETTİKLERİM")]
            ),
            Expanded(child: TabBarView(children: [
              StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('quotes').where('user_id', isEqualTo: user?.uid).orderBy('created_at', descending: true).snapshots(), builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz paylaşım yok.", style: TextStyle(color: Colors.grey)));
                return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) { var data = snapshot.data!.docs[index].data() as Map<String, dynamic>; return Card(color: const Color(0xFF1E1E1E), margin: const EdgeInsets.all(8), child: ListTile(title: Text(data['text'], style: const TextStyle(color: Colors.white)), subtitle: Text("❤️ ${data['likes']} Beğeni", style: const TextStyle(color: Colors.grey)))); });
              }),
              FutureBuilder<List<String>>(future: SharedPreferences.getInstance().then((p) => p.getStringList('saved_quotes_v2') ?? []), builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Henüz kaydedilen yok.", style: TextStyle(color: Colors.grey)));
                return ListView.builder(itemCount: snapshot.data!.length, itemBuilder: (context, index) { var q = Quote.fromJson(jsonDecode(snapshot.data![index])); return Card(color: const Color(0xFF1E1E1E), margin: const EdgeInsets.all(8), child: ListTile(title: Text(q.text, style: const TextStyle(color: Colors.white)), subtitle: Text(q.author, style: const TextStyle(color: Color(0xFFD4AF37))))); });
              })
            ]))
          ],
        ),
      ),
    );
  }
}

// --- DÜZENLEME SAYFASI ---
class EditProfilePage extends StatefulWidget { final User? user; const EditProfilePage({super.key, required this.user}); @override State<EditProfilePage> createState() => _EditProfilePageState(); }
class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController(); final _bio = TextEditingController(); final _photo = TextEditingController(); bool _loading = false;
  @override void initState() { super.initState(); _load(); }
  void _load() async { var d = await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).get(); _name.text = d.data()?['username'] ?? ""; _bio.text = d.data()?['bio'] ?? ""; _photo.text = d.data()?['photo_url'] ?? ""; }
  void _save() async { setState(() => _loading = true); await widget.user?.updateDisplayName(_name.text); await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).update({'username': _name.text, 'bio': _bio.text, 'photo_url': _photo.text}); if(mounted) Navigator.pop(context); }
  @override Widget build(BuildContext context) { return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, title: const Text("Profili Düzenle")), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [TextField(controller: _name, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "İsim", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 20), TextField(controller: _bio, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Bio", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 20), TextField(controller: _photo, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Profil Fotoğrafı Linki (URL)", hintText: "https://...", filled: true, fillColor: Color(0xFF1E1E1E))), const SizedBox(height: 40), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 50)), onPressed: _loading ? null : _save, child: const Text("KAYDET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))) ]))); }
}