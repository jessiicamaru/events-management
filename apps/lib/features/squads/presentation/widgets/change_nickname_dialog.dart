import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class ChangeNicknameDialog extends ConsumerStatefulWidget {
  final String squadId;
  final String targetUserId;
  final String initialNickname;

  const ChangeNicknameDialog({
    super.key,
    required this.squadId,
    required this.targetUserId,
    required this.initialNickname,
  });

  @override
  ConsumerState<ChangeNicknameDialog> createState() => _ChangeNicknameDialogState();
}

class _ChangeNicknameDialogState extends ConsumerState<ChangeNicknameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);

    return ShadDialog(
      title: Text(translations.translate('nickname_dialog_title')),
      actions: [
        ShadButton.outline(
          child: Text(translations.translate('cancel')),
          onPressed: () => Navigator.pop(context),
        ),
        ShadButton(
          child: Text(translations.translate('join_btn')), // Reuse "Join" / "Apply" style button
          onPressed: () {
            Navigator.pop(context, _controller.text);
          },
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: ShadInput(
          controller: _controller,
          placeholder: Text(translations.translate('enter_nickname')),
          autofocus: true,
        ),
      ),
    );
  }
}
