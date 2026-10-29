import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.canDismiss = false});

  /// Misafir modundan gelindiyse geri dönülebilsin.
  final bool canDismiss;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _humanErrorKey(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'err_invalid_email',
        'user-disabled' => 'err_user_disabled',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'err_bad_credentials',
        'too-many-requests' => 'err_too_many',
        'network-request-failed' => 'err_network',
        _ => 'err_generic',
      };

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await SettingsService.instance.setGuestMode(false);
      // Yönlendirmeyi main.dart'taki oturum dinleyicisi yapar.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t(_humanErrorKey(e))),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await SettingsService.instance.setGuestMode(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.3,
            colors: [AppColors.surfaceAlt, AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: Column(
              children: [
                if (widget.canDismiss)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.gold, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.hourglass_empty,
                            size: 48, color: AppColors.gold),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'M E M E N T O',
                        style: TextStyle(
                          fontFamily: kSerif,
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('app_tagline'),
                        style: TextStyle(
                          fontFamily: kSerif,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: context.t('email'),
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: context.t('password'),
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        )
                      : Text(context.t('sign_in')),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.t('no_account'),
                        style: const TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage()),
                      ),
                      child: Text(
                        context.t('register'),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!widget.canDismiss) ...[
                  const SizedBox(height: 28),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  // Giriş duvarını kaldıran kapı: uygulamayı ilk açan kimse
                  // tek bir söz bile görmeden kayıt olmak zorunda değil.
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      context.t('continue_as_guest'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
