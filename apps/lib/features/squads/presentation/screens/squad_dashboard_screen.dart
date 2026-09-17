import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/squad_provider.dart';
import '../widgets/friend_activity_feed.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import '../widgets/squad_empty_state.dart';
import '../widgets/squad_stats_card.dart';
import '../widgets/squad_member_row.dart';
import '../../../../core/localization/locale_provider.dart';

class SquadDashboardScreen extends ConsumerWidget {
  const SquadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final squadState = ref.watch(squadProvider);
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('nav_squad')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (squadState.value != null)
            IconButton(
              icon: const Icon(LucideIcons.userPlus),
              onPressed: () => _showInviteDialog(context, ref, squadState.value!.id),
            )
        ],
      ),
      body: squadState.when(
        data: (squad) {
          if (squad == null) {
            return _buildEmptyState(context, ref, theme);
          }
          return _buildDashboard(context, ref, theme, squad, translations);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${translations.translate('error_heatmap')} $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, ShadThemeData theme) {
    return SquadEmptyState(
      onCreateSquad: () => _showCreateSquadDialog(context, ref),
      onJoinSquad: () => _showJoinSquadDialog(context, ref),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, ShadThemeData theme, SquadModel squad, AppTranslations translations) {
    final sortedMembers = List<SquadMemberModel>.from(squad.members)
      ..sort((a, b) => b.totalXP.compareTo(a.totalXP));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SquadStatsCard(squad: squad),
          const SizedBox(height: 24),
          Text(squad.isBuddyMode ? translations.translate('buddies') : translations.translate('leaderboard'), style: theme.textTheme.h4),
          const SizedBox(height: 16),
          ...sortedMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SquadMemberRow(
                member: member, 
                rank: index + 1, 
                isBuddyMode: squad.isBuddyMode,
                onPoke: () {
                  // Poke logic
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          const FriendActivityFeed(),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, String squadId) {
    final translations = ref.read(translationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(translations.translate('invite_friends')),
        description: Text(translations.translate('invite_desc')),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ShadTheme.of(context).colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    squadId,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ShadButton.secondary(
                child: const Icon(LucideIcons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: squadId));
                  Navigator.pop(ctx);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSquadDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final translations = ref.read(translationsProvider);
    bool isBuddyMode = true;

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
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  ref.read(squadProvider.notifier).createSquad(nameController.text, isBuddyMode);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(translations.translate('mode')),
                    ShadSelect<bool>(
                      initialValue: isBuddyMode,
                      options: [
                        ShadOption(value: true, child: Text(translations.translate('mode_buddy'))),
                        ShadOption(value: false, child: Text(translations.translate('mode_squad'))),
                      ],
                      selectedOptionBuilder: (context, value) => Text(value ? translations.translate('buddies') : translations.translate('nav_squad')),
                      onChanged: (val) {
                        if (val != null) setState(() => isBuddyMode = val);
                      },
                    ),
                  ],
                ),
              ],
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
            onPressed: () {
              if (codeController.text.isNotEmpty) {
                ref.read(squadProvider.notifier).joinSquad(codeController.text);
                Navigator.pop(ctx);
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
