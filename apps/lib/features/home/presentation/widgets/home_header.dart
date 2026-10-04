import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';

/// Greeting, date, and the two numbers worth seeing every day.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    required this.now,
    required this.profile,
    required this.completedToday,
    required this.totalToday,
  });

  final DateTime now;

  /// Null while the profile is still loading or failed to load. The header still
  /// renders — a greeting does not depend on the network, and a home screen that
  /// blanks out because one request is slow is worse than one missing a badge.
  final UserProfileModel? profile;

  final int completedToday;
  final int totalToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final localeStr = ref.watch(localeProvider) == AppLocale.en ? 'en_US' : 'vi';

    final name = profile?.displayName;
    final greeting = translations.translate(_greetingKey(now.hour));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null || name.isEmpty ? greeting : '$greeting, $name',
          style: theme.textTheme.h3,
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('EEEE, d MMMM', localeStr).format(now),
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (totalToday > 0)
              ShadBadge.secondary(
                child: Text(
                  translations.translate(
                    'home_today_progress',
                    params: {
                      'done': '$completedToday',
                      'total': '$totalToday',
                    },
                  ),
                ),
              ),
            if (profile != null && profile!.currentStreak > 0)
              ShadBadge(
                child: Text(
                  translations.translate(
                    'home_streak_days',
                    params: {'n': '${profile!.currentStreak}'},
                  ),
                ),
              ),
            if (profile != null)
              ShadBadge.outline(child: Text('${profile!.totalXP} XP')),
          ],
        ),
      ],
    );
  }

  /// Boundaries at 12:00 and 18:00. Arbitrary, but they match how the words are
  /// used in both languages.
  static String _greetingKey(int hour) {
    if (hour < 12) return 'home_greeting_morning';
    if (hour < 18) return 'home_greeting_afternoon';
    return 'home_greeting_evening';
  }
}
