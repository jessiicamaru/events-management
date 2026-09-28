import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:collection/collection.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_chat_provider.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';

class SquadChatScreen extends ConsumerStatefulWidget {
  final String squadId;
  final String squadName;

  const SquadChatScreen({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  @override
  ConsumerState<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends ConsumerState<SquadChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final chatNotifier = ref.watch(squadChatProvider(widget.squadId));
    final userProfile = ref.watch(userProfileProvider).value;
    final translations = ref.watch(translationsProvider);
    final activeSquad = ref.watch(activeSquadProvider).value;

    final currentUserId = userProfile?.id;
    final myMembership = activeSquad?.members.firstWhereOrNull((m) => m.userId == currentUserId);
    final isMuted = myMembership?.isMuted ?? false;

    // Scroll to bottom when new messages arrive
    ref.listen(squadChatProvider(widget.squadId), (prev, next) {
      if (prev == null || prev.value.messages.length != next.value.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return ValueListenableBuilder<SquadChatState>(
      valueListenable: chatNotifier,
      builder: (context, chatState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.squadName),
                Text(
                  translations.translate('squad_chat_title'),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(isMuted ? LucideIcons.bellOff : LucideIcons.bell),
                tooltip: translations.translate('mute_chat'),
                onPressed: () {
                  if (activeSquad != null && myMembership != null) {
                    ref.read(activeSquadProvider.notifier).updateMemberSettings(
                          widget.squadId,
                          nickname: myMembership.nickname,
                          isMuted: !isMuted,
                          xpContributionEnabled: myMembership.xpContributionEnabled,
                        );
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: chatState.isConnecting && chatState.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : (activeSquad?.members.where((m) => m.isApproved).length ?? 0) <= 1
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Nhóm hiện tại chỉ có 1 thành viên.\n Hãy chia sẻ mã mời nhóm để mời thêm bạn bè trò chuyện!',
                                style: theme.textTheme.muted,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : chatState.messages.isEmpty
                            ? Center(
                                child: Text(
                                  'Chưa có tin nhắn nào. Bắt đầu trò chuyện!',
                                  style: theme.textTheme.muted,
                                ),
                              )
                            : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            itemCount: chatState.messages.length,
                            itemBuilder: (context, index) {
                              final msg = chatState.messages[index];
                              final isMe = msg.senderUserId == currentUserId;

                              if (msg.isSystemMessage) {
                                return Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.muted.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      msg.message,
                                      style: theme.textTheme.small.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.mutedForeground,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                                          child: Text(
                                            msg.senderDisplayName,
                                            style: theme.textTheme.small.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.mutedForeground,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.accent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              msg.message,
                                              style: TextStyle(
                                                color: isMe
                                                    ? theme.colorScheme.primaryForeground
                                                    : theme.colorScheme.foreground,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTime(msg.sentAt),
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isMe
                                                    ? theme.colorScheme.primaryForeground.withValues(alpha: 0.6)
                                                    : theme.colorScheme.mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              if (chatState.error != null)
                Container(
                  color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                  child: Text(
                    'Lỗi kết nối: ${chatState.error}',
                    style: TextStyle(color: theme.colorScheme.destructive),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        controller: _messageController,
                        placeholder: const Text('Nhập tin nhắn...'),
                        onSubmitted: (val) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShadButton(
                      onPressed: _sendMessage,
                      child: const Icon(LucideIcons.send, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      final activeSquad = ref.read(activeSquadProvider).value;
      final memberCount = activeSquad?.members.where((m) => m.isApproved).length ?? 0;
      if (memberCount <= 1) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Không thể gửi tin nhắn'),
            description: Text('Nhóm hiện tại chỉ có 1 thành viên. Hãy mời thêm thành viên để trò chuyện!'),
          ),
        );
        return;
      }
      ref.read(squadChatProvider(widget.squadId)).sendMessage(text);
      _messageController.clear();
    }
  }

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
