import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:habit_tracker/core/providers/shared_preferences_provider.dart';
import 'package:habit_tracker/features/habits/presentation/habits_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_toolbar.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/create_event_sheet.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/habit_dock.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/command_center_panel.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_source_filters.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_workspace.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';

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
  bool _isCommandCenterVisible = true;

  @override
  void initState() {
    super.initState();
    // Default to 3-day view
    _calendarController.view = CalendarView.week;

    final prefs = ref.read(sharedPreferencesProvider);
    _isCommandCenterVisible = prefs.getBool('command_center_visible') ?? true;
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
                  onTogglePanel: () {
                    setState(
                      () => _isCommandCenterVisible = !_isCommandCenterVisible,
                    );
                    ref
                        .read(sharedPreferencesProvider)
                        .setBool(
                          'command_center_visible',
                          _isCommandCenterVisible,
                        );
                  },
                  isPanelVisible: _isCommandCenterVisible,
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

                // Command Center Panel
                if (_isCommandCenterVisible) const CommandCenterPanel(),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
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
    );
  }
}
