import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/quote.dart';
import '../services/quote_service.dart';
import '../services/report_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'share_card.dart';

/// Bir sözün "..." menüsü: paylaş, şikâyet et, engelle, sil.
class QuoteActions {
  static Future<void> show(
    BuildContext context,
    Quote quote, {
    VoidCallback? onDeleted,
    VoidCallback? onBlocked,
  }) async {
    final isMine = quote.ownerId != null &&
        quote.ownerId == UserService.instance.uid;
    final canModerate = quote.isRemote && !isMine && quote.ownerId != null;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.ios_share, color: Colors.white),
              title: Text(sheetCtx.t('share'),
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetCtx);
                QuoteShareSheet.show(context, quote);
              },
            ),
            if (canModerate) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: Text(sheetCtx.t('report'),
                    style: const TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showReportDialog(context, quote);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: Text(sheetCtx.t('block'),
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await ReportService.instance.block(quote.ownerId!);
                  onBlocked?.call();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('blocked'))),
                    );
                  }
                },
              ),
            ],
            if (isMine)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(sheetCtx.t('delete'),
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final ok = await _confirmDelete(context);
                  if (!ok) return;
                  await QuoteService.instance.deleteQuote(quote);
                  onDeleted?.call();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('deleted'))),
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Text(ctx.t('delete_confirm'),
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('delete'),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  static Future<void> _showReportDialog(
      BuildContext context, Quote quote) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              sheetCtx.t('report_title'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final key in ReportService.reasons)
              ListTile(
                title: Text(sheetCtx.t(key),
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await ReportService.instance.reportQuote(
                    quoteId: quote.id,
                    reasonKey: key,
                    ownerId: quote.ownerId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('report_sent'))),
                    );
                  }
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
