import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _humanErrorKey(FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'err_email_in_use',
        'invalid-email' => 'err_invalid_email',
        'weak-password' => 'err_weak_password',
        'network-request-failed' => 'err_network',
        _ => 'err_generic',
      };

  void _toast(String key) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(key))));
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    if (!UserService.isValidUsername(name)) {
      _toast('err_username_invalid');
      return;
    }
    if (password.length < 6) {
      _toast('err_weak_password');
      return;
    }

    setState(() => _loading = true);
    try {
      if (!await UserService.instance.isUsernameAvailable(name)) {
        if (!mounted) return;
        setState(() => _loading = false);
        _toast('err_username_taken');
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);

      if (!mounted) return;
      await UserService.instance.createProfile(
        uid: user.uid,
        username: name,
        email: email,
        defaultBio: context.t('bio_default'),
      );
      await SettingsService.instance.setGuestMode(false);
      // Oturum dinleyicisi ana ekrana götürür.
    } on UsernameTakenException {
      if (mounted) _toast('err_username_taken');
    } on FirebaseAuthException catch (e) {
      if (mounted) _toast(_humanErrorKey(e));
    } catch (_) {
      if (mounted) _toast('err_generic');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              context.t('register'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _name,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: context.t('username'),
                prefixText: '@',
                prefixStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: context.t('email')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: context.t('password')),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : Text(context.t('sign_up')),
            ),
          ],
        ),
      ),
    );
  }
}
