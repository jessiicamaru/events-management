import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

/// The message box and send button. Sending is refused while a turn is running: the
/// server answers one message at a time per conversation.
class AssistantComposer extends ConsumerStatefulWidget {
  const AssistantComposer({super.key, required this.busy, required this.onSend});

  final bool busy;
  final ValueChanged<String> onSend;

  @override
  ConsumerState<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends ConsumerState<AssistantComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: _controller,
                placeholder: Text(t.translate('assistant_input_placeholder')),
                minLines: 1,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(AppConstants.assistantMaxMessageLength)],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            ShadIconButton(
              onPressed: widget.busy ? null : _send,
              icon: const Icon(LucideIcons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
