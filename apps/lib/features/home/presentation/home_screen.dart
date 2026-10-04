import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/home/domain/home_agenda.dart';
import 'package:habit_tracker/features/home/presentation/widgets/habits_without_slot_card.dart';
import 'package:habit_tracker/features/home/presentation/widgets/home_header.dart';
import 'package:habit_tracker/features/home/presentation/widgets/today_schedule_card.dart';
import 'package:habit_tracker/features/home/presentation/widgets/up_next_card.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';

/// The landing screen: what is happening next, what is left today, and what has
/// not been booked yet.
///
/// It scrolls. That is the point of moving this off the calendar — the old
/// `CommandCenterPanel` had to fit in whatever height the calendar grid left over,
/// so it could only ever show one event and a short checklist.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final translations = ref.watch(translationsProvider);
    final theme = ShadTheme.of(context);

    // Read once per build, and pass it down: two widgets deciding "now" separately
    // could disagree across a minute boundary and render an inconsistent screen.
    final now = DateTime.now();

    final agenda = HomeAgenda.build(
      events: eventsAsync.value ?? const [],
      habits: habitsAsync.value ?? const [],
      now: now,
    );

    // Only a first load blocks. A refresh keeps the previous agenda on screen
    // rather than replacing a usable page with a spinner.
    if (eventsAsync.isLoading && !eventsAsync.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            ref.invalidate(habitsProvider);
            await ref.read(eventsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              HomeHeader(
                now: now,
                profile: profileAsync.value,
                completedToday: agenda.completedToday,
                totalToday: agenda.totalToday,
              ),
              const SizedBox(height: 20),
              if (agenda.focusEvent != null)
                UpNextCard(
                  event: agenda.focusEvent!,
                  isHappeningNow: agenda.isHappeningNow,
                )
              else
                _NothingAheadCard(theme: theme, translations: translations),
              const SizedBox(height: 12),
              TodayScheduleCard(events: agenda.restOfToday),
              const SizedBox(height: 12),
              HabitsWithoutSlotCard(
                habits: agenda.habitsWithoutASlotToday,
                // The calendar is where a habit becomes a scheduled event — it is
                // the screen with the habit dock and the drop targets. Sending the
                // user there beats rebuilding that interaction here.
                onTapHabit: (_) => context.go('/calendar'),
              ),
              const SizedBox(height: 12),
              ShadButton.ghost(
                onPressed: () => context.go('/calendar'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.calendarDays, size: 16),
                    const SizedBox(width: 8),
                    Text(translations.translate('home_open_calendar')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NothingAheadCard extends StatelessWidget {
  const _NothingAheadCard({required this.theme, required this.translations});

  final ShadThemeData theme;
  final AppTranslations translations;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.coffee,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                translations.translate('home_nothing_ahead'),
                style: theme.textTheme.large.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            translations.translate('home_nothing_ahead_hint'),
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
