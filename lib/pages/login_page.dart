import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/account_service.dart';
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

  /// Şifre sıfırlama bağlantısı gönderir. E-posta kutusu doluysa onu kullanır.
  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ctx.t('reset_password'),
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: ctx.t('email')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(ctx.t('send'))),
        ],
      ),
    );
    ctrl.dispose();
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await AccountService.instance.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      // 'user-not-found' bilgisini açık etmiyoruz: kayıtlı e-postaları
      // tahmin etmeye yarar. Her durumda aynı mesaj.
      if (e.code == 'invalid-email' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t('err_invalid_email'))));
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('reset_sent'))));
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await AccountService.instance
          .signInWithGoogle(defaultBio: context.t('bio_default'));
      if (mounted && widget.canDismiss) Navigator.maybePop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.t('google_failed')}\n$e')));
      }
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
        color: AppColors.bg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: Column(
              children: [
                if (widget.canDismiss)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'memento',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 52,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        decoration: BoxDecoration(
                          color: QuoteMood.all.first.top,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t('app_tagline'),
                              style: quoteStyle(context.t('app_tagline'),
                                  scale: 0.9,
                                  color: QuoteMood.all.first.accent),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.t('login_sub'),
                              style: TextStyle(
                                  color: QuoteMood.all.first.accent,
                                  fontSize: 15,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.t('email'),
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.t('password'),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.textPrimary),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(context.t('forgot_password'),
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.onAccent, strokeWidth: 2),
                        )
                      : Text(context.t('sign_in')),
                ),
                const SizedBox(height: 12),
                _GoogleButton(onPressed: _loading ? null : _google),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.t('no_account'),
                        style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage()),
                      ),
                      child: Text(
                        context.t('register'),
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!widget.canDismiss) ...[
                  const SizedBox(height: 28),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 8),
                  // Giriş duvarını kaldıran kapı: uygulamayı ilk açan kimse
                  // tek bir söz bile görmeden kayıt olmak zorunda değil.
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      context.t('continue_as_guest'),
                      style: TextStyle(color: AppColors.textMuted),
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

/// "Google ile devam et" — beyaz hap, Google'ın marka kurallarına uygun düz yazı.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.surface,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('G',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Text(context.t('continue_with_google'),
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
