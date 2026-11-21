import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter/gestures.dart';

import '../l10n/strings.dart';
import '../theme.dart';
import '../utils/links.dart';
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
  bool _acceptedTerms = false;

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
    if (!_acceptedTerms) {
      _toast('err_accept_terms');
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
      final defaultBio = mounted ? context.t('bio_default') : '';
      try {
        await user.updateDisplayName(name);
        await UserService.instance.createProfile(
          uid: user.uid,
          username: name,
          defaultBio: defaultBio,
        );
      } catch (_) {
        // Profil oluşmadıysa (ör. ad son anda kapıldı) oturum hesabını da
        // geri al — yoksa profili olmayan yarım bir hesap kalıyor.
        await user.delete();
        rethrow;
      }
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
      appBar: AppBar(iconTheme: IconThemeData(color: AppColors.textPrimary)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              context.t('register'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                height: 1,
                letterSpacing: -1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _name,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: context.t('username'),
                prefixText: '@',
                prefixStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: context.t('email')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: context.t('password')),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppColors.gold,
                  checkColor: AppColors.onAccent,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                        children: [
                          TextSpan(text: context.t('terms_prefix')),
                          TextSpan(
                            text: context.t('terms_of_use'),
                            style: TextStyle(color: AppColors.textPrimary),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => AppLinks.open(AppLinks.terms(context.lang)),
                          ),
                          TextSpan(text: context.t('terms_and')),
                          TextSpan(
                            text: context.t('privacy_policy'),
                            style: TextStyle(color: AppColors.textPrimary),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => AppLinks.open(AppLinks.privacy(context.lang)),
                          ),
                          TextSpan(text: context.t('terms_suffix')),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.onAccent, strokeWidth: 2),
                    )
                  : Text(context.t('sign_up')),
            ),
          ],
        ),
      ),
    );
  }
}
