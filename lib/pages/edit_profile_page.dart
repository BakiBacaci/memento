import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/chunky_button.dart';
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

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.user?.photoUrl;
    _username.addListener(_validateUsername);
  }

  @override
  void dispose() {
    _name.dispose();
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
    if (err != _usernameError) setState(() => _usernameError = err);
  }

  Future<void> _pickPhoto() async {
    final uid = UserService.instance.uid;
    if (uid == null) return;

    final XFile? file = await StorageService.instance.pickImage();
    if (file == null) return;

    setState(() => _uploading = true);
    final url = await StorageService.instance.uploadProfilePhoto(uid, file);
    if (!mounted) return;

    if (url == null) {
      setState(() => _uploading = false);
      _toast(context.t('photo_failed'));
      return;
    }
    await UserService.instance.updatePhotoUrl(uid, url);
    if (!mounted) return;
    setState(() {
      _photoUrl = url;
      _uploading = false;
    });
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
      final changed =
          username.toLowerCase() != (widget.user?.username ?? '').toLowerCase();
      if (changed &&
          !await UserService.instance.isUsernameAvailable(username)) {
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
                      radius: 46,
                      onTap: _uploading ? null : _pickPhoto,
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2.5),
                      ),
                      child: _uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 15, color: Colors.black),
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
            error: _usernameError,
            helper: context.t('username_helper'),
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
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
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

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: formatters,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefix,
                prefixStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 15),
                errorText: error,
                helperText: helper,
                helperStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
}
