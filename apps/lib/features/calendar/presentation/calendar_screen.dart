import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_toolbar.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/create_event_sheet.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/habit_dock.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_source_filters.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_workspace.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_fab.dart';

// Helper enum for custom view selection
enum AppCalendarView { day, threeDay, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _calendarKey = GlobalKey();
  AppCalendarView _currentView = AppCalendarView.threeDay;
  DateTime _displayDate = DateTime.now();
  CalendarSourceFilter _sourceFilter = CalendarSourceFilter.all;

  @override
  void initState() {
    super.initState();
    // Default to 3-day view
    _calendarController.view = CalendarView.week;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewChanged(AppCalendarView view) {
    setState(() {
      _currentView = view;
      if (view == AppCalendarView.day) {
        _calendarController.view = CalendarView.day;
      } else if (view == AppCalendarView.threeDay) {
        _calendarController.view = CalendarView.week;
      } else if (view == AppCalendarView.month) {
        _calendarController.view = CalendarView.month;
      }
    });
  }

  void _onViewHeaderChanged(ViewChangedDetails details) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _displayDate = details.visibleDates[details.visibleDates.length ~/ 2];
        });

        if (details.visibleDates.isNotEmpty) {
          DateTime start;
          DateTime end;
          if (details.visibleDates.length <= 7) {
            // Day, 3-Day, Week view: Fetch 3 weeks (1 week before, visible dates, 2 weeks after)
            start = details.visibleDates.first.subtract(const Duration(days: 7));
            end = details.visibleDates.last.add(const Duration(days: 14));
          } else {
            // Month view: Fetch the exact visible month range (covers the 35 or 42 visible days)
            start = details.visibleDates.first;
            end = details.visibleDates.last;
          }
          ref.read(calendarViewRangeProvider.notifier).updateRange(start, end);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = ShadTheme.of(context);
    final currentUserId = userProfileAsync.value?.id;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Toolbar
                CalendarToolbar(
                  displayDate: _displayDate,
                  currentView: _currentView,
                  onViewChanged: _onViewChanged,
                  onTodayPressed: () =>
                      _calendarController.displayDate = DateTime.now(),
                  onNextPressed: () => _calendarController.forward!(),
                  onPrevPressed: () => _calendarController.backward!(),
                  totalEvents: eventsAsync.value?.length ?? 0,
                ),
                const Divider(height: 1),

                // Source Filter Pills
                CalendarSourceFilters(
                  currentFilter: _sourceFilter,
                  onFilterChanged: (filter) =>
                      setState(() => _sourceFilter = filter),
                ),
                const Divider(height: 1),

                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Calendar Workspace
                      Expanded(
                        child: CalendarWorkspace(
                          calendarController: _calendarController,
                          scrollController: _scrollController,
                          calendarKey: _calendarKey,
                          currentView: _currentView,
                          displayDate: _displayDate,
                          sourceFilter: _sourceFilter,
                          eventsAsync: eventsAsync,
                          habitsAsync: habitsAsync,
                          currentUserId: currentUserId,
                          onViewHeaderChanged: _onViewHeaderChanged,
                        ),
                      ),
                    ],
                  ),
                ),

                // Habit Dock at the bottom
                if (habitsAsync.value != null)
                  HabitDock(habits: habitsAsync.value!),
              ],
            );
          },
        ),
      ),
      // Always shown. It used to disappear whenever the command centre panel was
      // open — which was the default — so creating an event meant collapsing the
      // panel first. With the panel moved to the home screen there is nothing left
      // for it to overlap. The assistant's button sits above it, small: the tab
      // shell leaves its own out on this tab so the two do not overlap.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AssistantFab(mini: true),
          const SizedBox(height: 12),
          FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.primaryForeground,
            shape: const CircleBorder(),
            elevation: 4,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (bottomSheetContext) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                  ),
                  child: CreateEventSheet(
                    habitsAsync: habitsAsync,
                    initialDate: _displayDate,
                  ),
                ),
              );
            },
            child: const Icon(LucideIcons.plus, size: 24),
          ),
        ],
      ),
    );
  }
}
