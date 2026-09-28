import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/features/squads/presentation/widgets/squad_empty_state.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/squads/presentation/screens/squad_dashboard_screen.dart';

class SquadsListScreen extends ConsumerWidget {
  const SquadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final squadsList = ref.watch(squadsListProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('my_squads_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: translations.translate('create_squad'),
            onPressed: () => _showCreateSquadDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: translations.translate('join_squad'),
            onPressed: () => _showJoinSquadDialog(context, ref),
          ),
        ],
      ),
      body: squadsList.when(
        data: (list) {
          if (list.isEmpty) {
            return SquadEmptyState(
              onCreateSquad: () => _showCreateSquadDialog(context, ref),
              onJoinSquad: () => _showJoinSquadDialog(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(squadsListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final squad = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(activeSquadIdProvider.notifier).state = squad.id;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SquadDashboardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              squad.name[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primaryForeground,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  squad.name,
                                  style: theme.textTheme.large.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${squad.memberCount} / ${squad.maxMembers} ${translations.translate('buddies').toLowerCase()}',
                                  style: theme.textTheme.muted,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${squad.totalSquadXP} XP',
                                style: theme.textTheme.large.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(LucideIcons.chevronRight, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${translations.translate('error_title')}: $err')),
      ),
    );
  }

  void _showCreateSquadDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final translations = ref.read(translationsProvider);
    int maxMembers = 5;
    bool requireApproval = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: Text(translations.translate('create_squad')),
          description: Text(translations.translate('create_squad_desc')),
          actions: [
            ShadButton.outline(
              child: Text(translations.translate('cancel')),
              onPressed: () => Navigator.pop(ctx),
            ),
            ShadButton(
              child: Text(translations.translate('create_btn')),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    Navigator.pop(ctx);
                    await ref.read(activeSquadProvider.notifier).createSquad(
                          nameController.text,
                          maxMembers,
                          requireApproval,
                        );

                    final activeSquadState = ref.read(activeSquadProvider);
                    if (activeSquadState.hasError) {
                      ShadToaster.of(context).show(
                        ShadToast.destructive(
                          title: const Text('Lỗi tạo nhóm'),
                          description: Text(activeSquadState.error.toString()),
                        ),
                      );
                    } else {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SquadDashboardScreen(),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('Lỗi tạo nhóm'),
                        description: Text(e.toString()),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                ShadInput(
                  controller: nameController,
                  placeholder: Text(translations.translate('squad_name_placeholder')),
                ),
                const SizedBox(height: 20),
                Text(
                  '${translations.translate('members_limit')}: $maxMembers',
                  style: ShadTheme.of(context).textTheme.small,
                ),
                Slider(
                  value: maxMembers.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: maxMembers.toString(),
                  onChanged: (val) {
                    setState(() => maxMembers = val.round());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      translations.translate('require_approval'),
                      style: ShadTheme.of(context).textTheme.small,
                    ),
                    Switch(
                      value: requireApproval,
                      onChanged: (val) {
                        setState(() => requireApproval = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _showJoinSquadDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final translations = ref.read(translationsProvider);

    showDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(translations.translate('join_squad')),
        description: Text(translations.translate('join_squad_desc')),
        actions: [
          ShadButton.outline(
            child: Text(translations.translate('cancel')),
            onPressed: () => Navigator.pop(ctx),
          ),
          ShadButton(
            child: Text(translations.translate('join_btn')),
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                try {
                  Navigator.pop(ctx);
                  final isApproved = await ref.read(activeSquadProvider.notifier).joinSquad(codeController.text);

                  final activeSquadState = ref.read(activeSquadProvider);
                  if (activeSquadState.hasError) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('Lỗi tham gia nhóm'),
                        description: Text(activeSquadState.error.toString()),
                      ),
                    );
                  } else if (!isApproved) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: Text(translations.translate('status_pending')),
                        description: const Text('Yêu cầu tham gia của bạn đang chờ phê duyệt từ Trưởng nhóm.'),
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SquadDashboardScreen(),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  ShadToaster.of(context).show(
                    ShadToast.destructive(
                      title: const Text('Lỗi tham gia nhóm'),
                      description: Text(e.toString()),
                    ),
                  );
                }
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: ShadInput(
            controller: codeController,
            placeholder: Text(translations.translate('invite_code_placeholder')),
          ),
        ),
      ),
    );
  }
}
