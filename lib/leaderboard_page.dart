import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ZİRVE", style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      // CANLI VERİ AKIŞI
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('karma', descending: true) // En yüksek puanlı en üstte
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Henüz kimse puan kazanmadı.", style: TextStyle(color: Colors.grey)));
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var data = users[index].data() as Map<String, dynamic>;
              String name = data['username'] ?? "Gizli Filozof";
              int score = data['karma'] ?? 0;
              
              // İlk 3 kişiye özel renkler
              Color rankColor = Colors.white;
              double scale = 1.0;
              String badge = "";
              
              if (index == 0) { rankColor = const Color(0xFFFFD700); scale = 1.2; badge = "👑"; } // Altın
              else if (index == 1) { rankColor = const Color(0xFFC0C0C0); scale = 1.1; badge = "🥈"; } // Gümüş
              else if (index == 2) { rankColor = const Color(0xFFCD7F32); scale = 1.05; badge = "🥉"; } // Bronz

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Text("${index + 1}", style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    "$name $badge",
                    style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 16 * scale),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5))
                    ),
                    child: Text(
                      "$score Puan",
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}