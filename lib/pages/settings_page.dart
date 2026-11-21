import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/account_service.dart';
import '../services/block_service.dart';
import '../services/daily_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../utils/links.dart';
import '../widgets/user_avatar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = UserService.instance.isSignedIn;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _SectionTitle(context.t('daily_quote')),
          const _DailyReminderTile(),

          _SectionTitle(context.t('appearance')),
          ValueListenableBuilder<String>(
            valueListenable: SettingsService.instance.themeMode,
            builder: (context, mode, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  for (final (key, icon) in [
                    ('system', Icons.brightness_auto_outlined),
                    ('light', Icons.light_mode_outlined),
                    ('dark', Icons.dark_mode_outlined),
                  ]) ...[
                    Expanded(
                      child: _ThemeChoice(
                        label: context.t('theme_$key'),
                        icon: icon,
                        selected: mode == key,
                        onTap: () => SettingsService.instance.setThemeMode(key),
                      ),
                    ),
                    if (key != 'dark') const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),

          _SectionTitle(context.t('language')),
          ValueListenableBuilder<String>(
            valueListenable: SettingsService.instance.language,
            builder: (context, current, _) => Column(
              children: [
                for (final code in L.supported)
                  _Tile(
                    icon: current == code
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    iconColor: AppColors.textPrimary,
                    title: L.languageName(code),
                    onTap: () {
                      SettingsService.instance.setLanguage(code);
                      DailyService.instance.refresh();
                    },
                  ),
              ],
            ),
          ),

          if (signedIn) ...[
            _SectionTitle(context.t('privacy')),
            _Tile(
              icon: Icons.block,
              title: context.t('blocked_users'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersPage())),
            ),
          ],

          _SectionTitle(context.t('about')),
          _Tile(
            icon: Icons.shield_outlined,
            title: context.t('privacy_policy'),
            trailing: Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
            onTap: () => AppLinks.open(AppLinks.privacy(context.lang)),
          ),
          _Tile(
            icon: Icons.description_outlined,
            title: context.t('terms_of_use'),
            trailing: Icon(Icons.open_in_new, size: 16, color: AppColors.textMuted),
            onTap: () => AppLinks.open(AppLinks.terms(context.lang)),
          ),
          _Tile(
            icon: Icons.chat_bubble_outline,
            title: context.t('send_feedback'),
            onTap: () => AppLinks.open('mailto:bakibacaci05@gmail.com?subject=Memento'),
          ),
          _Tile(
            icon: Icons.info_outline,
            title: context.t('version'),
            trailing: Text('1.0.0', style: TextStyle(color: AppColors.textMuted)),
          ),

          if (signedIn) ...[
            _SectionTitle(context.t('account')),
            _Tile(
              icon: Icons.mail_outline,
              title: context.t('change_password'),
              onTap: () async {
                final email = UserService.instance.currentUser?.email;
                if (email == null) return;
                await AccountService.instance.sendPasswordReset(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tn('reset_sent_to', {'email': email}))));
                }
              },
            ),
            _Tile(
              icon: Icons.logout,
              title: context.t('sign_out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            _Tile(
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.redAccent,
              title: context.t('delete_account'),
              titleColor: Colors.redAccent,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final google = AccountService.instance.hasNoPassword;
    final pass = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ctx.t('delete_account'),
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.t('delete_account_warning'),
                style: TextStyle(color: AppColors.textMuted, height: 1.4)),
            if (!google) const SizedBox(height: 16),
            if (!google) TextField(
              controller: pass,
              obscureText: true,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: ctx.t('password')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, pass.text),
            child: Text(ctx.t('delete_forever'),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    pass.dispose();
    if (password == null || (!google && password.isEmpty) || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    String? errorKey;
    try {
      await AccountService.instance.deleteAccount(password);
    } on FirebaseAuthException catch (e) {
      errorKey = (e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? 'err_bad_credentials'
          : 'err_generic';
    } catch (_) {
      errorKey = 'err_generic';
    }
    if (!context.mounted) return;
    Navigator.of(context).pop(); // yükleniyor
    if (errorKey != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t(errorKey))));
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

/// Günlük söz bildirimi: aç/kapat ve saat seçimi.
class _DailyReminderTile extends StatelessWidget {
  const _DailyReminderTile();

  @override
  Widget build(BuildContext context) {
    final d = DailyService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: d.enabled,
      builder: (context, on, _) => Column(
        children: [
          SwitchListTile(
            value: on,
            
            secondary: Icon(Icons.notifications_none, color: AppColors.textPrimary),
            title: Text(context.t('daily_reminder'),
                style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(context.t('daily_reminder_sub'),
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            onChanged: (v) async {
              final ok = await d.setEnabled(v);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('notif_denied'))));
              }
            },
          ),
          if (on)
            ValueListenableBuilder<TimeOfDay>(
              valueListenable: d.time,
              builder: (context, t, _) => _Tile(
                icon: Icons.schedule,
                title: context.t('reminder_time'),
                trailing: Text(t.format(context),
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                onTap: () async {
                  final picked =
                      await showTimePicker(context: context, initialTime: t);
                  if (picked != null) await d.setTime(picked);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Engellenen kullanıcılar ve engeli kaldırma.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('blocked_users'))),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: BlockService.instance.blocked,
        builder: (context, ids, _) {
          if (ids.isEmpty) {
            return Center(
              child: Text(context.t('no_blocked'),
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView(
            children: [
              for (final id in ids)
                FutureBuilder<AppUser?>(
                  future: UserService.instance.get(id),
                  builder: (context, snap) {
                    final u = snap.data;
                    return ListTile(
                      leading: UserAvatar(photoUrl: u?.photoUrl, initial: u?.initial),
                      title: Text(u == null ? '…' : '@${u.username}',
                          style: TextStyle(color: AppColors.textPrimary)),
                      trailing: TextButton(
                        onPressed: () => BlockService.instance.unblock(id),
                        child: Text(context.t('unblock')),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(color: titleColor ?? AppColors.textPrimary)),
        trailing: trailing ??
            (onTap == null
                ? null
                : Icon(Icons.chevron_right, color: AppColors.textMuted)),
        onTap: onTap,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      );
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? AppColors.textPrimary : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: selected ? AppColors.bg : AppColors.textPrimary),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        color: selected ? AppColors.bg : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}
