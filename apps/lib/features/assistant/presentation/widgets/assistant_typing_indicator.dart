import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown while a turn runs: "Thinking…", or what the assistant is looking at right now.
class AssistantTypingIndicator extends StatelessWidget {
  const AssistantTypingIndicator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.mutedForeground),
            ),
            const SizedBox(width: 10),
            Text(label, style: theme.textTheme.muted),
          ],
        ),
      ),
    );
  }
}
