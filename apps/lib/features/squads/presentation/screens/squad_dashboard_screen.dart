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

class SquadDashboardScreen extends ConsumerWidget {
  const SquadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final squadState = ref.watch(squadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (squadState.value != null)
            IconButton(
              icon: Icon(LucideIcons.userPlus),
              onPressed: () => _showInviteDialog(context, squadState.value!.id),
            )
        ],
      ),
      body: squadState.when(
        data: (squad) {
          if (squad == null) {
            return _buildEmptyState(context, ref, theme);
          }
          return _buildDashboard(context, ref, theme, squad);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, ShadThemeData theme) {
    return SquadEmptyState(
      onCreateSquad: () => _showCreateSquadDialog(context, ref),
      onJoinSquad: () => _showJoinSquadDialog(context, ref),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, ShadThemeData theme, SquadModel squad) {
    final sortedMembers = List<SquadMemberModel>.from(squad.members)
      ..sort((a, b) => b.totalXP.compareTo(a.totalXP));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SquadStatsCard(squad: squad),
          const SizedBox(height: 24),
          Text(squad.isBuddyMode ? 'Buddies' : 'Leaderboard', style: theme.textTheme.h4),
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

  Widget _buildSquadStatsCard(ShadThemeData theme, SquadModel squad) {
    final level = (squad.totalSquadXP / 1000).floor() + 1;
    final progress = (squad.totalSquadXP % 1000) / 1000.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.flame, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(squad.name, style: theme.textTheme.h3),
          const SizedBox(height: 8),
          Text('Total XP: ${squad.totalSquadXP}', style: theme.textTheme.muted),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('Level $level', style: theme.textTheme.small),
        ],
      ),
    );
  }

  Widget _buildMemberRow(ShadThemeData theme, SquadMemberModel member, {required int rank, required bool isBuddyMode}) {
    String rankIcon = '';
    if (!isBuddyMode) {
      if (rank == 1) rankIcon = '🥇 ';
      if (rank == 2) rankIcon = '🥈 ';
      if (rank == 3) rankIcon = '🥉 ';
    }
    final name = member.email.split('@').first;
    final emoji = member.unlockedEmojis.isNotEmpty ? member.unlockedEmojis.first : '👍';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.accent.withOpacity(0.1),
      ),
      child: Row(
        children: [
          if (!isBuddyMode)
            SizedBox(
              width: 30,
              child: Text(
                rankIcon.isNotEmpty ? rankIcon : '#$rank',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primaryForeground)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.large),
                Text('${member.totalXP} XP', style: theme.textTheme.muted),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          ShadButton.outline(
            child: const Icon(LucideIcons.hand),
            onPressed: () {
              // Poke logic
            },
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, String squadId) {
    showDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Invite Friends'),
        description: const Text('Share this code with your friends so they can join your squad.'),
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
                  // Optionally show a toast here
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
    bool isBuddyMode = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => ShadDialog(
          title: const Text('Create Squad'),
          description: const Text('Start a new group.'),
          actions: [
            ShadButton.outline(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ShadButton(
              child: const Text('Create'),
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
                  placeholder: const Text('Squad Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mode'),
                    ShadSelect<bool>(
                      initialValue: isBuddyMode,
                      options: const [
                        ShadOption(value: true, child: Text('Buddy (2 members)')),
                        ShadOption(value: false, child: Text('Squad (5 members)')),
                      ],
                      selectedOptionBuilder: (context, value) => Text(value ? 'Buddy' : 'Squad'),
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

    showDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Join Squad'),
        description: const Text('Enter the invite code from your friend.'),
        actions: [
          ShadButton.outline(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ShadButton(
            child: const Text('Join'),
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
            placeholder: const Text('Invite Code (e.g. uuid)'),
          ),
        ),
      ),
    );
  }
}
