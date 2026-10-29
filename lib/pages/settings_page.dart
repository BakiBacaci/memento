import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionTitle(context.t('language')),

          // Dili değiştirmek tüm uygulamayı anında yeniden çiziyor —
          // yeniden başlatmaya gerek yok.
          ValueListenableBuilder<String>(
            valueListenable: SettingsService.instance.language,
            builder: (context, current, _) => RadioGroup<String>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) SettingsService.instance.setLanguage(v);
              },
              child: Column(
                children: [
                  for (final code in L.supported)
                    RadioListTile<String>(
                      value: code,
                      activeColor: AppColors.gold,
                      title: Text(
                        L.languageName(code),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Divider(height: 32),

          if (UserService.instance.isSignedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(context.t('sign_out'),
                  style: const TextStyle(color: Colors.redAccent)),
              onTap: () async {
                // Yönlendirmeyi main.dart'taki oturum dinleyicisi yapar.
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pop(context);
              },
            ),

          const Divider(height: 32),
          _SectionTitle(context.t('about')),
          ListTile(
            title: Text(context.t('version'),
                style: const TextStyle(color: Colors.white)),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          const ListTile(
            title: Text('Memento',
                style: TextStyle(color: Colors.white, fontFamily: kSerif)),
            subtitle: Text('memento-60cce',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
}
