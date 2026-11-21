import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../services/journal_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'celebration.dart';
import 'common.dart';

/// "Deftere işle": sözü bugünün sayfası yapar, isteğe bağlı kısa bir notla.
Future<void> showJournalSheet(BuildContext context, Quote q) async {
  if (!UserService.instance.isSignedIn) {
    await requireSignIn(context);
    return;
  }
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _JournalSheet(quote: q),
  );
  if (saved == true && context.mounted) {
    await CelebrationSheet.show(
      context,
      title: context.t('journal_done_title'),
      subtitle: context.tn('journal_done_sub', {'n': '${JournalService.instance.streak.value}'}),
      buttonLabel: context.t('celebrate_button'),
      icon: Icons.menu_book_rounded,
    );
  }
}

class _JournalSheet extends StatefulWidget {
  const _JournalSheet({required this.quote});
  final Quote quote;

  @override
  State<_JournalSheet> createState() => _JournalSheetState();
}

class _JournalSheetState extends State<_JournalSheet> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final t = JournalService.instance.today;
    if (t != null && t.quote.id == widget.quote.id) _note.text = t.note;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final isNew = await JournalService.instance.writeToday(widget.quote, _note.text);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, isNew);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${context.t('err_generic')} $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final lang = context.lang;
    final mood = QuoteMood.forQuote(q);
    final today = JournalService.instance.today;
    final replacing = today != null && today.quote.id != q.id;
    final text = q.textFor(lang);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('journal_write_title'),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 4),
          Text(context.t(replacing ? 'journal_replace_hint' : 'journal_write_hint'),
              style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.35)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(color: mood.top, borderRadius: BorderRadius.circular(26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: quoteStyle(text, scale: .6, color: mood.accent)),
                const SizedBox(height: 10),
                Text(q.authorFor(lang),
                    style: TextStyle(color: mood.accent, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLength: 280,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(hintText: context.t('journal_note_hint')),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.bg,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              label: Text(context.t('journal_write_button')),
            ),
          ),
        ],
      ),
    );
  }
}
