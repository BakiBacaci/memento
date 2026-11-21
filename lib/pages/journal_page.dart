import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/journal_service.dart';
import '../theme.dart';
import '../widgets/share_card.dart';
import 'daily_page.dart';

/// Memento defteri: ay takvimi. Söz işlenen günler o sözün renginde,
/// bugün halkalı. Bir güne dokununca o günün sözü ve notu açılır.
class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalPage()));

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _selected = JournalService.key(DateTime.now());

  static const _trM = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _enM = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final s = JournalService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('journal'))),
      body: ValueListenableBuilder<Map<String, JournalEntry>>(
        valueListenable: s.entries,
        builder: (context, map, _) {
          final entry = map[_selected];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              // Özet: toplam sayfa ve seri
              Row(
                children: [
                  _Stat(value: '${map.length}', label: context.t('journal_pages')),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<int>(
                    valueListenable: s.streak,
                    builder: (context, n, _) => _Stat(value: '🔥 $n', label: context.t('journal_streak')),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text('${(lang == 'en' ? _enM : _trM)[_month.month - 1]} ${_month.year}',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
                    onPressed: _month.year == DateTime.now().year && _month.month == DateTime.now().month
                        ? null
                        : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _Calendar(
                month: _month,
                entries: map,
                selected: _selected,
                lang: lang,
                onTap: (k) => setState(() => _selected = k),
              ),
              const SizedBox(height: 22),
              if (entry != null)
                _EntryCard(entry: entry, lang: lang)
              else
                _EmptyDay(isToday: _selected == JournalService.key(DateTime.now())),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.entries,
    required this.selected,
    required this.lang,
    required this.onTap,
  });

  final DateTime month;
  final Map<String, JournalEntry> entries;
  final String selected, lang;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1; // Pazartesi başlar
    final todayKey = JournalService.key(DateTime.now());
    final heads = lang == 'en' ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'] : ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];
    final now = DateTime.now();

    return Column(
      children: [
        Row(
          children: heads
              .map((h) => Expanded(
                  child: Center(
                      child: Text(h,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)))))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: lead + days,
          itemBuilder: (context, i) {
            if (i < lead) return const SizedBox.shrink();
            final d = DateTime(month.year, month.month, i - lead + 1);
            final k = JournalService.key(d);
            final e = entries[k];
            final mood = e == null ? null : QuoteMood.forQuote(e.quote);
            final isToday = k == todayKey;
            final future = d.isAfter(now);
            final sel = k == selected;
            return GestureDetector(
              onTap: future ? null : () => onTap(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: mood?.top ?? (future ? Colors.transparent : AppColors.surface2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AppColors.textPrimary : (isToday ? AppColors.textMuted : Colors.transparent),
                    width: sel ? 2.5 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text('${d.day}',
                    style: TextStyle(
                      color: mood?.accent ?? (future ? AppColors.border : AppColors.textMuted),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    )),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.lang});
  final JournalEntry entry;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final q = entry.quote;
    final mood = QuoteMood.forQuote(q);
    final text = q.textFor(lang);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 14, 14),
      decoration: BoxDecoration(color: mood.top, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: quoteStyle(text, scale: .7, color: mood.accent)),
          const SizedBox(height: 10),
          Text(q.authorFor(lang), style: TextStyle(color: mood.accent, fontWeight: FontWeight.w600, fontSize: 15)),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: mood.accent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(entry.note,
                  style: TextStyle(color: mood.accent, fontSize: 15, height: 1.35, fontWeight: FontWeight.w600)),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(Icons.ios_share, color: mood.accent),
              onPressed: () => QuoteShareSheet.show(context, q),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isToday});
  final bool isToday;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t(isToday ? 'journal_today_empty' : 'journal_day_empty'),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, height: 1.25)),
            if (isToday) ...[
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.bg,
                ),
                onPressed: () => DailyPage.open(context),
                child: Text(context.t('journal_open_daily')),
              ),
            ],
          ],
        ),
      );
}
