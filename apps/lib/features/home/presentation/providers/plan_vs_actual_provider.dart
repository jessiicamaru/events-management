import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/home/domain/models/plan_vs_actual.dart';

/// Booked time against recorded time, for the home screen's second analytics card.
///
/// Shaped exactly like `activitySummaryProvider`, and for the same reasons: auto-disposed,
/// so it is one request per visit plus pull-to-refresh; it does not watch `eventsProvider`,
/// which would turn every SignalR push and background sync into another request; and
/// automatic retry is off, because Riverpod 3 otherwise retries a failed provider ten times
/// and the card offers a "Try again" of its own.
///
/// Same window as the activity card (`AppConstants.analyticsSummaryDays`), because both say
/// "last N days" on the same screen.
final planVsActualProvider = FutureProvider.autoDispose<PlanVsActual>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    return api.fetchPlanVsActual(days: AppConstants.analyticsSummaryDays);
  },
  retry: (_, _) => null,
);
