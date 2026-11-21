import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/chunky_button.dart';
import '../widgets/photo_sheet.dart';
import '../widgets/user_avatar.dart';

/// Profil düzenleme — Instagram/Twitter'ın kullandığı düzen.
///
/// Eski hâlinde sadece iki kutu vardı (isim, bio) ve kaydet butonu.
/// Profesyonel uygulamalarda bu ekran gruplara ayrılmış satırlardan oluşur:
/// önce fotoğraf, sonra kimlik alanları, sonra bağlantılar. Her alanın
/// kendi sayacı ve doğrulaması olur, hata alanın altında görünür.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});
  final AppUser? user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name =
      TextEditingController(text: widget.user?.displayName ?? '');
  late final _username =
      TextEditingController(text: widget.user?.username ?? '');
  late final _bio = TextEditingController(text: widget.user?.bio ?? '');
  late final _link = TextEditingController(text: widget.user?.link ?? '');

  String? _photoUrl;
  bool _saving = false;
  bool _uploading = false;
  String? _usernameError;
  UsernameStatus? _status;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.user?.photoUrl;
    _username.addListener(_validateUsername);
  }

  @override
  void dispose() {
    _name.dispose();
    _debounce?.cancel();
    _username.dispose();
    _bio.dispose();
    _link.dispose();
    super.dispose();
  }

  void _validateUsername() {
    final v = _username.text.trim();
    final err = v.isEmpty || UserService.isValidUsername(v)
        ? null
        : context.t('err_username_invalid');
    setState(() {
      _usernameError = err;
      _status = null;
    });
    _debounce?.cancel();
    if (err != null || v.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final st = await UserService.instance.usernameStatus(v);
      if (mounted && _username.text.trim() == v) setState(() => _status = st);
    });
  }

  Future<void> _pickPhoto() async {
    final url = await changeProfilePhoto(
      context,
      hasPhoto: (_photoUrl ?? '').isNotEmpty,
      onBusy: (v) {
        if (mounted) setState(() => _uploading = v);
      },
    );
    if (url == null || !mounted) return;
    setState(() => _photoUrl = url.isEmpty ? null : url);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final uid = UserService.instance.uid;
    final username = _username.text.trim();
    if (uid == null) return;

    if (!UserService.isValidUsername(username)) {
      _toast(context.t('err_username_invalid'));
      return;
    }

    setState(() => _saving = true);
    try {
      if (await UserService.instance.usernameStatus(username) ==
          UsernameStatus.taken) {
        if (!mounted) return;
        setState(() => _saving = false);
        _toast(context.t('err_username_taken'));
        return;
      }

      await UserService.instance.updateProfile(
        uid: uid,
        username: username,
        displayName: _name.text.trim(),
        bio: _bio.text.trim(),
        link: _link.text.trim(),
        previousUsername: widget.user?.username,
      );
      await UserService.instance.currentUser
          ?.updateDisplayName(_name.text.trim().isEmpty
              ? username
              : _name.text.trim());

      if (!mounted) return;
      Navigator.pop(context);
    } on UsernameTakenException {
      if (mounted) _toast(context.t('err_username_taken'));
    } catch (e) {
      if (mounted) _toast('${context.t('err_generic')} $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('edit_profile')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(context.t('done')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SizedBox(height: 20),

          // --- Fotoğraf ---
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAvatar(
                      photoUrl: _photoUrl,
                      initial: _name.text.isEmpty
                          ? _username.text
                          : _name.text,
                      radius: 52,
                      onTap: _uploading ? null : _pickPhoto,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 3),
                      ),
                      child: _uploading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.bg),
                            )
                          : Icon(Icons.camera_alt,
                              size: 16, color: AppColors.bg),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _uploading ? null : _pickPhoto,
                  child: Text(context.t('change_photo')),
                ),
              ],
            ),
          ),

          _SectionHeader(context.t('section_identity')),
          _Field(
            label: context.t('display_name'),
            controller: _name,
            maxLength: 40,
            hint: context.t('display_name_hint'),
          ),
          _Field(
            label: context.t('username'),
            controller: _username,
            maxLength: 20,
            prefix: '@',
            error: _usernameError ??
                (_status == UsernameStatus.taken
                    ? context.t('err_username_taken')
                    : null),
            helper: switch (_status) {
              UsernameStatus.free => context.t('username_free'),
              UsernameStatus.mine => context.t('username_mine'),
              _ => context.t('username_helper'),
            },
            suffix: switch (_status) {
              UsernameStatus.free || UsernameStatus.mine =>
                const Icon(Icons.check_circle, color: Color(0xFF2E9E5B)),
              UsernameStatus.taken =>
                const Icon(Icons.cancel, color: Color(0xFFE5482F)),
              _ => null,
            },
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            ],
          ),
          _Field(
            label: context.t('bio'),
            controller: _bio,
            maxLength: 160,
            maxLines: 3,
            hint: context.t('bio_hint'),
          ),

          _SectionHeader(context.t('section_links')),
          _Field(
            label: context.t('link'),
            controller: _link,
            maxLength: 100,
            hint: 'instagram.com/...',
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ChunkyButton(
              label: context.t('save'),
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.hint,
    this.prefix,
    this.error,
    this.helper,
    this.keyboardType,
    this.formatters,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final int maxLines;
  final String? hint;
  final String? prefix;
  final String? error;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: formatters,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefix,
                prefixStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 15),
                errorText: error,
                suffixIcon: suffix,
                helperText: helper,
                helperStyle: TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
}
