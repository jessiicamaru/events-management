import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One message: the user's on the right in the primary colour, the assistant's on the left.
class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  static const double _radius = 16;
  static const double _maxWidthFraction = 0.8;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final foreground = fromUser ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * _maxWidthFraction),
        decoration: BoxDecoration(
          color: fromUser ? theme.colorScheme.primary : theme.colorScheme.muted,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(_radius),
            topRight: const Radius.circular(_radius),
            bottomLeft: fromUser ? const Radius.circular(_radius) : Radius.zero,
            bottomRight: fromUser ? Radius.zero : const Radius.circular(_radius),
          ),
        ),
        child: SelectableText.rich(
          TextSpan(
            style: theme.textTheme.p.copyWith(color: foreground, height: 1.4),
            children: boldSpans(text),
          ),
        ),
      ),
    );
  }

  /// The model marks emphasis with `**…**`. The app has no Markdown renderer, and a
  /// reply full of asterisks reads badly, so this one mark is honoured and the rest of
  /// the text is shown as written (its lists and line breaks already read well).
  static List<TextSpan> boldSpans(String text) {
    final parts = text.split('**');
    // An odd number of markers leaves the last part unpaired: show it plainly.
    final paired = parts.length.isOdd;
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: i.isOdd && (paired || i < parts.length - 1)
                ? const TextStyle(fontWeight: FontWeight.w600)
                : null,
          ),
    ];
  }
}
