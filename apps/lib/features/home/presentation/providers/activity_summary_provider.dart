import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/features/home/domain/models/activity_summary.dart';

/// The home screen's activity summary: one request, aggregated on the server.
///
/// Auto-disposed, so it is fetched when the home screen opens and dropped when the
/// user leaves — one call per visit, plus pull-to-refresh.
///
/// It deliberately does **not** watch `eventsProvider`. That provider reloads on
/// every calendar range change, SignalR push and background Google sync, and tying
/// this to it would turn each of those into a second request the user never sees
/// the benefit of. The cost is that a completion made while sitting on the home
/// screen shows up on the next visit or refresh, not instantly.
///
/// Automatic retry is turned off. Riverpod 3 retries a failed provider by default —
/// measured in the widget test at 11 calls for one failure (the first attempt plus
/// ten retries with backoff). Against a server that is down, that is ten requests
/// the user gains nothing from, and the card already offers a "Try again" button.
final activitySummaryProvider = FutureProvider.autoDispose<ActivitySummary>(
  (ref) {
    final api = ref.watch(apiServiceProvider);
    return api.fetchActivitySummary(days: AppConstants.analyticsSummaryDays);
  },
  retry: (_, _) => null,
);
