import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';
import 'package:habit_tracker/features/home/presentation/providers/activity_summary_provider.dart';

/// Formats a minute count as "45 min", "2h" or "1h 30m", in the user's language.
String formatFocusDuration(AppTranslations translations, int minutes) {
  if (minutes < Duration.minutesPerHour) {
    return translations.translate('duration_minutes', params: {'m': '$minutes'});
  }

  final hours = minutes ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;

  if (rest == 0) {
    return translations.translate('duration_hours', params: {'h': '$hours'});
  }

  return translations.translate(
    'duration_hours_minutes',
    params: {'h': '$hours', 'm': '$rest'},
  );
}

/// The last two weeks at a glance: how much got done, and how much focus time went
/// into it.
///
/// Focus time is the chart because it is the most trustworthy number the app has:
/// only a finished focus session writes it, so it measures time actually spent. The
/// completed count sits beside it as a tile rather than a second series — two
/// measures with different units on one chart would need two scales.
class ActivitySummaryCard extends ConsumerWidget {
  const ActivitySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final summaryAsync = ref.watch(activitySummaryProvider);
    // The series and split-off days needed to count repeating events. Already loaded
    // app-wide, so this costs no request — only a recount when events change.
    final events = ref.watch(eventsProvider).value;

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.translate(
              'home_activity_title',
              params: {'n': '${AppConstants.analyticsSummaryDays}'},
            ),
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // `when` keeps showing the previous data while a pull-to-refresh is in
          // flight, instead of flashing a spinner over a chart that is still valid.
          summaryAsync.when(
            loading: () => const _LoadingPlaceholder(),
            error: (_, _) => _ErrorState(
              onRetry: () => ref.invalidate(activitySummaryProvider),
            ),
            data: (fromServer) {
              // Without the events the repeating days would be missing, and the numbers
              // would jump once they arrived — wait instead.
              if (events == null) return const _LoadingPlaceholder();

              final summary = fromServer.withRepeatingDays(events);
              return summary.isEmpty
                  ? Text(
                      translations.translate('home_activity_empty'),
                      style: theme.textTheme.muted,
                    )
                  : _SummaryBody(summary: summary);
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: _ActivityChart.totalHeight,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    final rate = summary.completionRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatTile(
                label: translations.translate('home_activity_completed'),
                value: rate == null
                    ? translations.translate('home_activity_nothing_scheduled')
                    : translations.translate(
                        'home_activity_of_total',
                        params: {
                          'done': '${summary.totalCompleted}',
                          'total': '${summary.totalScheduled}',
                        },
                      ),
                // The rate is the context for the count, so it rides underneath
                // rather than competing with it.
                detail: rate == null ? null : '${(rate * 100).round()}%',
              ),
            ),
            Expanded(
              child: _StatTile(
                label: translations.translate('home_activity_focus'),
                value: formatFocusDuration(translations, summary.totalFocusMinutes),
              ),
            ),
            Expanded(
              child: _StatTile(
                label: translations.translate('home_activity_best_day'),
                value: formatFocusDuration(translations, summary.bestFocusMinutes),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActivityChart(days: summary.days),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.large.copyWith(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          Text(
            detail!,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
      ],
    );
  }
}

/// Focus minutes per day as bars, one per day, today on the right.
///
/// Tapping a day shows its numbers in the line above the bars. That line is the
/// way to read an exact value — there is no number on each bar, and no tooltip that
/// would be the only way in. Today is selected to begin with, so the line is never
/// empty.
class _ActivityChart extends ConsumerStatefulWidget {
  const _ActivityChart({required this.days});

  final List<DailyActivity> days;

  static const double _plotHeight = 72;
  static const double _labelBandHeight = 18;
  static const double _readoutHeight = 22;

  /// Plot plus the readout and the axis-label band. The loading placeholder uses
  /// this, so the card does not jump in height when the data arrives.
  static const double totalHeight =
      _readoutHeight + 8 + _plotHeight + 1 + 6 + _labelBandHeight;

  @override
  ConsumerState<_ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends ConsumerState<_ActivityChart> {
  late int _selected = widget.days.length - 1;

  @override
  void didUpdateWidget(covariant _ActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A refresh can change the window (the day rolled over); keep the index valid.
    if (_selected >= widget.days.length) _selected = widget.days.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final localeStr = ref.watch(localeProvider) == AppLocale.en ? 'en_US' : 'vi';
    final days = widget.days;

    if (days.isEmpty) return const SizedBox.shrink();

    final maxMinutes = days
        .map((d) => d.focusMinutes)
        .fold<int>(0, (a, b) => a > b ? a : b);

    final selectedDay = days[_selected];
    final dayLabel = DateFormat('EEE d MMM', localeStr).format(selectedDay.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _ActivityChart._readoutHeight,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$dayLabel  ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: translations.translate(
                    'home_activity_day_detail',
                    params: {
                      'focus': formatFocusDuration(
                        translations,
                        selectedDay.focusMinutes,
                      ),
                      'done': '${selectedDay.completed}',
                      'total': '${selectedDay.scheduled}',
                    },
                  ),
                  style: TextStyle(color: theme.colorScheme.mutedForeground),
                ),
              ],
            ),
            style: theme.textTheme.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _ActivityChart._plotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _Bar(
                    day: days[i],
                    maxMinutes: maxMinutes,
                    isSelected: i == _selected,
                    semanticLabel: _semanticLabel(days[i], translations, localeStr),
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
            ],
          ),
        ),
        // Baseline: solid and recessive, in the border colour.
        Container(height: 1, color: theme.colorScheme.border),
        const SizedBox(height: 6),
        SizedBox(
          height: _ActivityChart._labelBandHeight,
          child: _AxisLabels(days: days, localeStr: localeStr),
        ),
      ],
    );
  }

  String _semanticLabel(
    DailyActivity day,
    AppTranslations translations,
    String localeStr,
  ) {
    final date = DateFormat('EEEE d MMMM', localeStr).format(day.date);
    final detail = translations.translate(
      'home_activity_day_detail',
      params: {
        'focus': formatFocusDuration(translations, day.focusMinutes),
        'done': '${day.completed}',
        'total': '${day.scheduled}',
      },
    );
    return '$date, $detail';
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.maxMinutes,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  final DailyActivity day;
  final int maxMinutes;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;

  /// A day with no focus time still gets a sliver, so the axis reads as fourteen
  /// days rather than as gaps of unknown meaning.
  static const double _emptyStubHeight = 2;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final primary = theme.colorScheme.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      // The whole column is the tap target, not just the bar: a short bar on a
      // phone is far too small to hit reliably.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasFocus = day.focusMinutes > 0 && maxMinutes > 0;
            final height = hasFocus
                ? (day.focusMinutes / maxMinutes * constraints.maxHeight)
                    .clamp(_emptyStubHeight * 2, constraints.maxHeight)
                : _emptyStubHeight;

            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // 1px each side = the 2px gap between neighbouring bars.
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: height,
                  decoration: BoxDecoration(
                    color: !hasFocus
                        ? theme.colorScheme.border
                        : isSelected
                            ? primary
                            : primary.withValues(alpha: 0.45),
                    // Rounded where the data ends, square where it meets the axis.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// First day, and today — enough to anchor the axis without a label per bar.
class _AxisLabels extends StatelessWidget {
  const _AxisLabels({required this.days, required this.localeStr});

  final List<DailyActivity> days;
  final String localeStr;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final style = theme.textTheme.small.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontSize: 11,
    );
    final format = DateFormat('d MMM', localeStr);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(format.format(days.first.date), style: style),
        Text(format.format(days.last.date), style: style),
      ],
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Row(
      children: [
        Expanded(
          child: Text(
            translations.translate('home_activity_error'),
            style: theme.textTheme.muted,
          ),
        ),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: onRetry,
          child: Text(translations.translate('home_activity_retry')),
        ),
      ],
    );
  }
}
