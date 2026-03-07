import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final cs = Theme.of(context).colorScheme;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: cs.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.14)),
      ),
      content: Row(
        children: [
          Icon(icon ?? Icons.info_outline_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      action: action,
    ),
  );
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Continue',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (destructive ? cs.error : cs.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
                color: destructive ? cs.error : cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.82)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok == true;
}

Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String closeLabel = 'Got it',
  IconData icon = Icons.info_outline_rounded,
}) async {
  final cs = Theme.of(context).colorScheme;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.82)),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(closeLabel),
          ),
        ],
      );
    },
  );
}
