import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/domain/models/habit_model.dart';
import '../../habits/presentation/habits_provider.dart';
import '../domain/models/event_model.dart';
import 'events_provider.dart';
import 'widgets/calendar_toolbar.dart';
import 'widgets/calendar_event_card.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/event_details_dialog.dart';
import 'widgets/habit_dock.dart';
import '../../focus_session/presentation/screens/focus_screen.dart';
import '../../focus_session/presentation/widgets/post_session_dialog.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import 'providers/calendar_settings_provider.dart';

// Helper enum for custom view selection
enum AppCalendarView { day, threeDay, month }
enum CalendarSourceFilter { all, personal, squads }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  final ScrollController _scrollController = ScrollController();
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final settings = ref.watch(calendarSettingsProvider);
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
                  onTodayPressed: () => _calendarController.displayDate = DateTime.now(),
                  onNextPressed: () => _calendarController.forward!(),
                  onPrevPressed: () => _calendarController.backward!(),
                  totalEvents: eventsAsync.value?.length ?? 0,
                ),
                const Divider(height: 1),

                // Source Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildFilterPill('All', CalendarSourceFilter.all, theme),
                      const SizedBox(width: 8),
                      _buildFilterPill('Personal', CalendarSourceFilter.personal, theme),
                      const SizedBox(width: 8),
                      _buildFilterPill('Squads', CalendarSourceFilter.squads, theme),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Calendar wrapped in DragTarget
                      Expanded(
                        child: DragTarget<HabitModel>(
                          onAcceptWithDetails: (details) {
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
                                  initialHabit: details.data,
                                ),
                              ),
                            );
                          },
                          builder: (context, candidateData, rejectedData) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final isThreeDayScrollable = _currentView == AppCalendarView.threeDay;
                            final habits = habitsAsync.value ?? [];

                            // In threeDay view, we render a full week (7 days) but stretch it 
                            // so only 3 days are visible, making it horizontally scrollable.
                            final calendarWidth = isThreeDayScrollable 
                                ? (constraints.maxWidth / 3) * 7 
                                : constraints.maxWidth;

                            Widget calendarWidget = SizedBox(
                              width: calendarWidth,
                              child: eventsAsync.when(
                                data: (events) {
                                      final filteredEvents = events.where((e) {
                                        if (_sourceFilter == CalendarSourceFilter.personal) {
                                          return e.userId == currentUserId;
                                        } else if (_sourceFilter == CalendarSourceFilter.squads) {
                                          return e.userId != currentUserId;
                                        }
                                        return true; // all
                                      }).toList();

                                      Widget calendar = SfCalendar(
                                        controller: _calendarController,
                                        allowDragAndDrop: true,
                                        dataSource: _EventDataSource(filteredEvents, habits, theme, currentUserId),
                                        onViewChanged: _onViewHeaderChanged,
                                        headerHeight: 0, // Hide default header
                                        view: isThreeDayScrollable ? CalendarView.week : (_currentView == AppCalendarView.day ? CalendarView.day : CalendarView.month),
                                        viewNavigationMode: isThreeDayScrollable ? ViewNavigationMode.none : ViewNavigationMode.snap,
                                        firstDayOfWeek: 1,
                                        specialRegions: _getSpecialRegions(theme),
                                        appointmentBuilder: (context, details) => buildCalendarEvent(context, details, habits),
                                        onTap: (CalendarTapDetails tapDetails) async {
                                          if (tapDetails.targetElement == CalendarElement.appointment) {
                                            final event = tapDetails.appointments!.first as EventModel;
                                            final habit = habits.firstWhere(
                                              (h) => h.id == event.habitId, 
                                              orElse: () => HabitModel(id: '', name: 'Unknown', targetDays: []),
                                            );
                                            final startFocus = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => EventDetailsDialog(event: event, habit: habit),
                                            );

                                            if (startFocus == true && context.mounted) {
                                              final focusResult = await Navigator.of(context).push<Map<String, int>>(
                                                MaterialPageRoute(
                                                  builder: (_) => FocusScreen(event: event),
                                                ),
                                              );
                                              
                                              if (focusResult != null && context.mounted) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (context) => PostSessionDialog(
                                                    event: event,
                                                    actualSeconds: focusResult['actual']!,
                                                    targetSeconds: focusResult['target']!,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        viewHeaderStyle: ViewHeaderStyle(
                                          dayTextStyle: theme.textTheme.small,
                                          dateTextStyle: theme.textTheme.p,
                                        ),
                                        timeSlotViewSettings: TimeSlotViewSettings(
                                          startHour: settings.visibleStartHour.toDouble(),
                                          endHour: settings.visibleEndHour.toDouble(),
                                          timeIntervalHeight: 50,
                                          timeFormat: 'h a',
                                        ),
                                      );

                                      // Wrap calendar in SfCalendarTheme to match dark mode
                                      calendar = SfCalendarTheme(
                                        data: SfCalendarThemeData(
                                          backgroundColor: theme.colorScheme.background,
                                          cellBorderColor: theme.colorScheme.border,
                                          todayHighlightColor: theme.colorScheme.primary,
                                          headerTextStyle: theme.textTheme.h4,
                                          viewHeaderDayTextStyle: theme.textTheme.small,
                                          viewHeaderDateTextStyle: theme.textTheme.p,
                                          timeTextStyle: theme.textTheme.small,
                                        ),
                                        child: calendar,
                                      );

                                      if (isThreeDayScrollable) {
                                        // Intercept raw pointer events to manually scroll because SfCalendar consumes horizontal drags
                                        calendar = Listener(
                                          onPointerMove: (PointerMoveEvent event) {
                                            if (_scrollController.hasClients) {
                                              final newOffset = _scrollController.offset - event.delta.dx;
                                              _scrollController.jumpTo(newOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
                                            }
                                          },
                                          child: calendar,
                                        );
                                      }
                                      return calendar;
                                    },
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (err, stack) => Center(child: Text('${AppConstants.errorPrefix}$err')),
                                  ),
                            );

                            if (isThreeDayScrollable) {
                              return SingleChildScrollView(
                                controller: _scrollController,
                                physics: const NeverScrollableScrollPhysics(), // We handle scrolling manually
                                scrollDirection: Axis.horizontal,
                                child: calendarWidget,
                              );
                            }
                              return calendarWidget;
                            },
                          );
                        },
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

  Widget _buildFilterPill(String label, CalendarSourceFilter filter, ShadThemeData theme) {
    final isSelected = _sourceFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _sourceFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: isSelected ? theme.colorScheme.primaryForeground : theme.colorScheme.foreground,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<TimeRegion> _getSpecialRegions(ShadThemeData theme) {
    if (_currentView != AppCalendarView.threeDay) return [];
    
    final regions = <TimeRegion>[];
    // Alternate backgrounds for columns (Day of week 1 to 7)
    // Using subtle background for even days
    final alternateColor = theme.colorScheme.muted.withValues(alpha: 0.3);
    
    // Day 2 (Tuesday), Day 4 (Thursday), Day 6 (Saturday)
    final alternateDays = [
      DateTime.tuesday,
      DateTime.thursday,
      DateTime.saturday,
    ];

    // Note: TimeRegion with recurrence is the easiest way to color the whole column
    for (final day in alternateDays) {
      regions.add(
        TimeRegion(
          startTime: DateTime(2020, 1, 1, 0, 0, 0), // Arbitrary date
          endTime: DateTime(2020, 1, 1, 23, 59, 59),
          enablePointerInteraction: false,
          color: alternateColor,
          recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=${_getRecurrenceDay(day)}',
        ),
      );
    }
    return regions;
  }

  String _getRecurrenceDay(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'MO';
      case DateTime.tuesday: return 'TU';
      case DateTime.wednesday: return 'WE';
      case DateTime.thursday: return 'TH';
      case DateTime.friday: return 'FR';
      case DateTime.saturday: return 'SA';
      case DateTime.sunday: return 'SU';
      default: return 'MO';
    }
  }
}

class _EventDataSource extends CalendarDataSource {
  final List<HabitModel> _habits;
  final String? _currentUserId;

  _EventDataSource(List<EventModel> source, this._habits, ShadThemeData theme, this._currentUserId) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as EventModel).startTime.toLocal();
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as EventModel).endTime.toLocal();
  }

  @override
  String getSubject(int index) {
    final event = appointments![index] as EventModel;
    final isSquadEvent = _currentUserId != null && event.userId != _currentUserId;
    return isSquadEvent ? '[Squad] ${event.title}' : event.title;
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as EventModel;
    final habit = _habits.firstWhere(
      (h) => h.id == event.habitId, 
      orElse: () => HabitModel(id: '', name: 'Unknown', targetDays: []),
    );
    return AppTheme.getHabitColor(habit.category);
  }
}
