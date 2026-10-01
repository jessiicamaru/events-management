import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/home_widget/home_widget_service.dart';

/// Provider that watches habits and events, then syncs data to Android Home Screen Widgets.
///
/// This provider is designed to be watched from the root widget (e.g., MaterialApp)
/// so that any change to habits or events automatically updates the widgets.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final eventsAsync = ref.watch(eventsProvider);

  // Only sync when both habits and events are loaded
  if (habitsAsync.hasValue && eventsAsync.hasValue) {
    final habits = habitsAsync.value!;
    final events = eventsAsync.value!;

    // Fire and forget — widget update is best-effort
    HomeWidgetService.updateAll(habits: habits, events: events);
  }
});
