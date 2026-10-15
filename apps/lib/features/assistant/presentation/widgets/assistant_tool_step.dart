import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A step the assistant took — "Checked your calendar" — shown small, so the user sees
/// where an answer came from without reading raw tool output.
class AssistantToolStep extends StatelessWidget {
  const AssistantToolStep({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.circleCheck, size: 14, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.muted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
