import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/home/domain/models/plan_vs_actual.dart';
import 'package:habit_tracker/features/home/presentation/providers/plan_vs_actual_provider.dart';
import 'package:habit_tracker/features/home/presentation/widgets/activity_summary_card.dart'
    show formatFocusDuration;

/// How long sessions were booked for, against how long they actually took.
///
/// Both numbers have been written on every focus session since the feature existed and
/// have never been shown together. Only finished sessions count, so this answers "when you
/// do this, how long does it really take" — the activity card above already answers "how
/// often do you do it".
///
/// Habits lead, because that is the unit people plan in. Categories follow, collapsed by
/// default: the same sessions, grouped more coarsely, and useful only once there are
/// several categories.
class PlanVsActualCard extends ConsumerWidget {
  const PlanVsActualCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final reportAsync = ref.watch(planVsActualProvider);

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translations.translate('home_plan_actual_title'),
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            translations.translate(
              'home_plan_actual_subtitle',
              params: {'n': '${AppConstants.analyticsSummaryDays}'},
            ),
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 12),
          // `when` keeps the previous data on screen during a pull-to-refresh instead of
          // flashing a spinner over numbers that are still valid.
          reportAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _ErrorRow(
              onRetry: () => ref.invalidate(planVsActualProvider),
            ),
            data: (report) => report.isEmpty
                ? Text(
                    translations.translate('home_plan_actual_empty'),
                    style: theme.textTheme.muted,
                  )
                : _ReportBody(report: report),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final PlanVsActual report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The headline: one sentence, because the per-habit rows below answer "which one".
        Text(
          _headline(translations, report),
          style: theme.textTheme.p,
        ),
        const SizedBox(height: 12),
        for (final item in report.byHabit) _ItemRow(item: item),
        if (report.byCategory.length > 1) ...[
          const SizedBox(height: 4),
          _CategoryBreakdown(items: report.byCategory),
        ],
      ],
    );
  }

  /// "You book 2h 30m and spend 1h 59m" — the totals, in the user's language.
  static String _headline(AppTranslations translations, PlanVsActual report) =>
      translations.translate('home_plan_actual_headline', params: {
        'planned': formatFocusDuration(translations, report.totalPlannedMinutes),
        'actual': formatFocusDuration(translations, report.totalActualMinutes),
        'n': '${report.totalSessions}',
      });
}

/// One habit or category: its name, the two durations, and a bar showing the ratio.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final PlanVsActualItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final ratio = item.ratio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.small,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                translations.translate('home_plan_actual_pair', params: {
                  'planned': formatFocusDuration(translations, item.plannedMinutes),
                  'actual': formatFocusDuration(translations, item.actualMinutes),
                }),
                style: theme.textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _RatioBar(ratio: ratio),
          const SizedBox(height: 2),
          Text(
            ratio == null
                ? translations.translate('home_plan_actual_no_target')
                : _verdict(translations, item),
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }

  /// "7 min under, over 3 sessions" / "5 min over, over 1 session" / "as booked".
  static String _verdict(AppTranslations translations, PlanVsActualItem item) {
    final difference = item.differenceMinutes;
    final sessions = translations.translate(
      'home_plan_actual_sessions',
      params: {'n': '${item.sessions}'},
    );

    if (difference == 0) {
      return translations.translate('home_plan_actual_as_booked', params: {'s': sessions});
    }

    return translations.translate(
      difference > 0 ? 'home_plan_actual_over' : 'home_plan_actual_under',
      params: {
        'd': formatFocusDuration(translations, difference.abs()),
        's': sessions,
      },
    );
  }
}

/// A single bar: the booked time is the full width, the recorded time fills it.
///
/// One bar rather than two, because the question is a comparison, not two quantities. Over
/// 100% the fill is capped at the width and the colour changes — a bar that grew past its
/// track would need a scale nothing else on the card has.
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.ratio});

  static const double height = 6;

  final double? ratio;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final over = (ratio ?? 0) > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          Container(height: height, color: theme.colorScheme.muted),
          if (ratio != null)
            FractionallySizedBox(
              widthFactor: ratio!.clamp(0.0, 1.0),
              child: Container(
                height: height,
                color: over ? theme.colorScheme.destructive : theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The same sessions by category, behind a tap. Off by default: it is the coarser view, and
/// on a card already listing habits it is the second question, not the first.
class _CategoryBreakdown extends ConsumerStatefulWidget {
  const _CategoryBreakdown({required this.items});

  final List<PlanVsActualItem> items;

  @override
  ConsumerState<_CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends ConsumerState<_CategoryBreakdown> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.link(
            padding: EdgeInsets.zero,
            onPressed: () => setState(() => _open = !_open),
            child: Text(
              translations.translate(
                _open ? 'home_plan_actual_hide_categories' : 'home_plan_actual_show_categories',
              ),
            ),
          ),
        ),
        if (_open)
          for (final item in widget.items) _ItemRow(item: item),
      ],
    );
  }
}

class _ErrorRow extends ConsumerWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);

    return Row(
      children: [
        Expanded(
          child: Text(
            translations.translate('home_plan_actual_error'),
            style: theme.textTheme.muted,
          ),
        ),
        ShadButton.ghost(
          onPressed: onRetry,
          child: Text(translations.translate('home_activity_retry')),
        ),
      ],
    );
  }
}
