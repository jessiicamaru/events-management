import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:collection/collection.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/squads/presentation/widgets/change_nickname_dialog.dart';

class SquadSettingsScreen extends ConsumerStatefulWidget {
  final String squadId;

  const SquadSettingsScreen({
    super.key,
    required this.squadId,
  });

  @override
  ConsumerState<SquadSettingsScreen> createState() => _SquadSettingsScreenState();
}

class _SquadSettingsScreenState extends ConsumerState<SquadSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _maxMembers = 5;
  bool _requireApproval = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final squad = ref.watch(activeSquadProvider).value;
    final userProfile = ref.watch(userProfileProvider).value;
    final translations = ref.watch(translationsProvider);

    if (squad == null || userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myMembership = squad.members.firstWhereOrNull((m) => m.userId == userProfile.id);
    if (myMembership == null) {
      return const Scaffold(
        body: Center(child: Text('Bạn không phải thành viên của nhóm này.')),
      );
    }
    final isLeader = myMembership.role == 'Leader';

    if (!_initialized) {
      _nameController.text = squad.name;
      _maxMembers = squad.maxMembers;
      _requireApproval = squad.requireApproval;
      _initialized = true;
    }

    final approvedMembers = squad.members.where((m) => m.isApproved).toList();
    final pendingMembers = squad.members.where((m) => !m.isApproved).toList();

    return Material(
      color: Colors.transparent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translations.translate('squad_settings_title')),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SQUAD INFO SECTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin nhóm', style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (isLeader) ...[
                    ShadInput(
                      controller: _nameController,
                      placeholder: const Text('Tên nhóm'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${translations.translate('members_limit')}: $_maxMembers',
                      style: theme.textTheme.small,
                    ),
                    Slider(
                      value: _maxMembers.toDouble(),
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: _maxMembers.toString(),
                      onChanged: (val) {
                        final currentMembers = approvedMembers.length;
                        if (val.round() >= currentMembers) {
                          setState(() => _maxMembers = val.round());
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(translations.translate('require_approval')),
                        Switch(
                          value: _requireApproval,
                          onChanged: (val) {
                            setState(() => _requireApproval = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ShadButton(
                      child: const Text('Lưu thay đổi cài đặt nhóm'),
                      onPressed: () async {
                        try {
                          await ref.read(activeSquadProvider.notifier).updateSquadSettings(
                                widget.squadId,
                                _nameController.text,
                                _maxMembers,
                                _requireApproval,
                              );
                          final activeSquadState = ref.read(activeSquadProvider);
                          if (activeSquadState.hasError) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: const Text('Lỗi cập nhật cài đặt'),
                                description: Text(activeSquadState.error.toString()),
                              ),
                            );
                          } else {
                            ShadToaster.of(context).show(
                              const ShadToast(
                                title: Text('Đã cập nhật'),
                                description: Text('Cài đặt nhóm đã được lưu thành công.'),
                              ),
                            );
                          }
                        } catch (e) {
                          ShadToaster.of(context).show(
                            ShadToast.destructive(
                              title: const Text('Lỗi cập nhật cài đặt'),
                              description: Text(e.toString()),
                            ),
                          );
                        }
                      },
                    ),
                  ] else ...[
                    Text('Tên nhóm: ${squad.name}', style: theme.textTheme.p),
                    const SizedBox(height: 8),
                    Text('Giới hạn thành viên: ${squad.maxMembers}', style: theme.textTheme.p),
                    const SizedBox(height: 8),
                    Text('Chế độ duyệt: ${squad.requireApproval ? "Cần duyệt" : "Tự do tham gia"}', style: theme.textTheme.p),
                  ],
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mã mời nhóm', style: theme.textTheme.small),
                            Text(squad.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: squad.id));
                          ShadToaster.of(context).show(
                            const ShadToast(
                              description: Text('Đã sao chép mã mời!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PERSONAL SQUAD SETTINGS SECTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cài đặt cá nhân trong nhóm', style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(translations.translate('mute_chat')),
                      Switch(
                        value: myMembership.isMuted,
                        onChanged: (val) {
                          ref.read(activeSquadProvider.notifier).updateMemberSettings(
                                widget.squadId,
                                nickname: myMembership.nickname,
                                isMuted: val,
                                xpContributionEnabled: myMembership.xpContributionEnabled,
                              );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(translations.translate('xp_contribution')),
                      Switch(
                        value: myMembership.xpContributionEnabled,
                        onChanged: (val) {
                          ref.read(activeSquadProvider.notifier).updateMemberSettings(
                                widget.squadId,
                                nickname: myMembership.nickname,
                                isMuted: myMembership.isMuted,
                                xpContributionEnabled: val,
                              );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // PENDING REQUESTS SECTION (Leader only)
            if (isLeader && pendingMembers.isNotEmpty) ...[
              Text(
                translations.translate('pending_requests'),
                style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...pendingMembers.map((m) {
                final name = m.nickname ?? m.email.split('@').first;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(name, style: theme.textTheme.p)),
                      ShadButton(
                        size: ShadButtonSize.sm,
                        child: Text(translations.translate('approve_btn')),
                        onPressed: () => ref.read(activeSquadProvider.notifier).approveMember(widget.squadId, m.userId),
                      ),
                      const SizedBox(width: 8),
                      ShadButton.destructive(
                        size: ShadButtonSize.sm,
                        child: Text(translations.translate('reject_btn')),
                        onPressed: () => ref.read(activeSquadProvider.notifier).rejectMember(widget.squadId, m.userId),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // SQUAD MEMBERS LIST SECTION
            Text('Thành viên nhóm', style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...approvedMembers.map((m) {
              final name = m.nickname ?? m.email.split('@').first;
              final isMe = m.userId == userProfile.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primaryForeground, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: theme.textTheme.large),
                              const SizedBox(width: 6),
                              if (m.role == 'Leader')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Trưởng nhóm', style: TextStyle(color: Colors.white, fontSize: 9)),
                                ),
                            ],
                          ),
                          if (m.nickname != null)
                            Text(m.email, style: theme.textTheme.muted.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    
                    // Nickname edit button for everyone
                    IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 16),
                      tooltip: 'Đổi biệt danh',
                      onPressed: () async {
                        final newNickname = await showDialog<String>(
                          context: context,
                          builder: (context) => ChangeNicknameDialog(
                            squadId: widget.squadId,
                            targetUserId: m.userId,
                            initialNickname: m.nickname ?? '',
                          ),
                        );
                        if (newNickname != null) {
                          ref.read(activeSquadProvider.notifier).changeMemberNickname(widget.squadId, m.userId, newNickname);
                        }
                      },
                    ),

                    // Actions menu for Leader on other members
                    if (isLeader && !isMe)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'transfer') {
                            ref.read(activeSquadProvider.notifier).changeLeader(widget.squadId, m.userId);
                          } else if (value == 'kick') {
                            ref.read(activeSquadProvider.notifier).rejectMember(widget.squadId, m.userId);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'transfer',
                            child: Text(translations.translate('change_leader')),
                          ),
                          PopupMenuItem(
                            value: 'kick',
                            child: Text(
                              translations.translate('kick_member'),
                              style: TextStyle(color: theme.colorScheme.destructive),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),

            // LEAVE SQUAD BUTTON
            ShadButton.destructive(
              child: Text(translations.translate('leave_squad_btn')),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ShadDialog(
                    title: const Text('Rời nhóm'),
                    description: const Text('Bạn có chắc chắn muốn rời nhóm này không? Lịch sử chat và hoạt động nhóm của bạn sẽ không còn hiển thị.'),
                    actions: [
                      ShadButton.outline(
                        child: Text(translations.translate('cancel')),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      ShadButton.destructive(
                        child: const Text('Đồng ý rời'),
                        onPressed: () {
                          ref.read(activeSquadProvider.notifier).leaveSquad(widget.squadId);
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close settings screen
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
   );
  }
}
