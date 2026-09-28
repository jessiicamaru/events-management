import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_chat_provider.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/squads/presentation/widgets/squad_stats_card.dart';
import 'package:habit_tracker/features/squads/presentation/widgets/squad_member_row.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/squads/presentation/screens/squad_chat_screen.dart';
import 'package:habit_tracker/features/squads/presentation/screens/squad_settings_screen.dart';

class SquadDashboardScreen extends ConsumerWidget {
  const SquadDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final squadState = ref.watch(activeSquadProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final translations = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(translations.translate('nav_squad')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (squadState.value != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.messageSquare),
              tooltip: translations.translate('squad_chat_title'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SquadChatScreen(
                      squadId: squadState.value!.id,
                      squadName: squadState.value!.name,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.userPlus),
              tooltip: translations.translate('invite_friends'),
              onPressed: () => _showInviteDialog(context, ref, squadState.value!.id),
            ),
            IconButton(
              icon: const Icon(LucideIcons.settings),
              tooltip: translations.translate('squad_settings_title'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SquadSettingsScreen(
                      squadId: squadState.value!.id,
                    ),
                  ),
                );
              },
            ),
          ]
        ],
      ),
      body: squadState.when(
        data: (squad) {
          if (squad == null) {
            return const Center(child: Text('Không tìm thấy nhóm.'));
          }
          return _buildDashboard(context, ref, theme, squad, translations, userProfile?.unlockedEmojis ?? []);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${translations.translate('error_heatmap')} $err')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    ShadThemeData theme,
    SquadModel squad,
    AppTranslations translations,
    List<String> currentUserEmojis,
  ) {
    final isBuddyMode = squad.maxMembers == 2;
    final approvedMembers = squad.members.where((m) => m.isApproved).toList();

    final sortedMembers = List<SquadMemberModel>.from(approvedMembers)
      ..sort((a, b) => b.totalXP.compareTo(a.totalXP));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SquadStatsCard(squad: squad),
          const SizedBox(height: 24),
          Text(isBuddyMode ? translations.translate('buddies') : translations.translate('leaderboard'), style: theme.textTheme.h4),
          const SizedBox(height: 16),
          ...sortedMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SquadMemberRow(
                member: member, 
                rank: index + 1, 
                isBuddyMode: isBuddyMode,
                currentUserEmojis: currentUserEmojis,
                onPoke: () {
                  ref.read(squadChatProvider(squad.id)).sendPoke(member.userId);
                  ShadToaster.of(context).show(
                    ShadToast(
                      description: Text('Đã gửi chọc tới ${member.nickname ?? member.email.split('@').first} ✋'),
                    ),
                  );
                },
                onReact: (emoji) {
                  ref.read(squadChatProvider(squad.id)).sendReaction(member.userId, emoji);
                  ShadToaster.of(context).show(
                    ShadToast(
                      description: Text('Đã thả biểu cảm $emoji'),
                    ),
                  );
                },
              ),
            );
          }),
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
                  ShadToaster.of(context).show(
                    const ShadToast(
                      description: Text('Đã sao chép mã mời vào bộ nhớ tạm!'),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
