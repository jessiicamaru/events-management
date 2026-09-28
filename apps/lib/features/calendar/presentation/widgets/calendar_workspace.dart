import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_core/theme.dart';

import 'package:habit_tracker/core/utils/app_constants.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/calendar_screen.dart'; // For AppCalendarView
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_source_filters.dart'; // For CalendarSourceFilter
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/create_event_sheet.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/event_details_dialog.dart';
import 'package:habit_tracker/features/focus_session/presentation/screens/focus_screen.dart';
import 'package:habit_tracker/features/focus_session/presentation/widgets/post_session_dialog.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/calendar_settings_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_event_card.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/sticky_time_ruler_overlay.dart';

/// Width of the time ruler column (logical pixels).
const double _kTimeRulerWidth = 60.0;

/// Explicit view header height for sticky overlay alignment.
const double _kViewHeaderHeight = 65.0;

/// Height of each time interval slot (logical pixels).
const double _kTimeIntervalHeight = 50.0;

class CalendarWorkspace extends ConsumerStatefulWidget {
  final CalendarController calendarController;
  final ScrollController scrollController;
  final GlobalKey calendarKey;
  final AppCalendarView currentView;
  final DateTime displayDate;
  final CalendarSourceFilter sourceFilter;
  final AsyncValue<List<EventModel>> eventsAsync;
  final AsyncValue<List<HabitModel>> habitsAsync;
  final String? currentUserId;
  final ValueChanged<ViewChangedDetails> onViewHeaderChanged;

  const CalendarWorkspace({
    super.key,
    required this.calendarController,
    required this.scrollController,
    required this.calendarKey,
    required this.currentView,
    required this.displayDate,
    required this.sourceFilter,
    required this.eventsAsync,
    required this.habitsAsync,
    required this.currentUserId,
    required this.onViewHeaderChanged,
  });

  @override
  ConsumerState<CalendarWorkspace> createState() => _CalendarWorkspaceState();
}

class _CalendarWorkspaceState extends ConsumerState<CalendarWorkspace> {
  EventModel? _hoverEvent;
  final ScrollController _overlayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDay();
    });
  }

  @override
  void didUpdateWidget(CalendarWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentView == AppCalendarView.threeDay && oldWidget.currentView != AppCalendarView.threeDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentDay();
      });
    }
  }

  void _scrollToCurrentDay() {
    if (widget.currentView == AppCalendarView.threeDay && widget.scrollController.hasClients) {
      if (!mounted) return;
      final double availableWidth = MediaQuery.sizeOf(context).width - _kTimeRulerWidth;
      final double dayWidth = availableWidth / 3;
      final int dayIndex = DateTime.now().weekday - 1; // 0 for Monday
      
      final double dayCenter = (dayIndex * dayWidth) + (dayWidth / 2);
      final double screenCenter = availableWidth / 2;
      
      double targetOffset = dayCenter - screenCenter;
      targetOffset = targetOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent);
      widget.scrollController.jumpTo(targetOffset);
    }
  }

  @override
  void dispose() {
    _overlayScrollController.dispose();
    super.dispose();
  }

  List<TimeRegion> _getSpecialRegions(ShadThemeData theme) {
    if (widget.currentView != AppCalendarView.threeDay) return [];
    
    final regions = <TimeRegion>[];
    final alternateColor = theme.colorScheme.muted.withValues(alpha: 0.3);
    
    final alternateDays = [
      DateTime.tuesday,
      DateTime.thursday,
      DateTime.saturday,
    ];

    for (final day in alternateDays) {
      regions.add(
        TimeRegion(
          startTime: DateTime(2020, 1, 1, 0, 0, 0),
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

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final settings = ref.watch(calendarSettingsProvider);
    final categories = ref.watch(eventCategoriesProvider(squadId: null)).value ?? [];

    return DragTarget<HabitModel>(
      onMove: (details) {
        if (widget.calendarKey.currentContext != null) {
          final box = widget.calendarKey.currentContext!.findRenderObject() as RenderBox;
          final localOffset = box.globalToLocal(details.offset);
          final tapDetails = widget.calendarController.getCalendarDetailsAtOffset?.call(localOffset);
          
          if (tapDetails != null && tapDetails.date != null) {
            final hoverDate = tapDetails.date!;
            if (_hoverEvent?.startTime != hoverDate) {
              setState(() {
                _hoverEvent = EventModel(
                  id: 'hover_preview',
                  title: 'Drop to schedule',
                  habitId: details.data.id,
                  startTime: hoverDate,
                  endTime: hoverDate.add(const Duration(hours: 1)),
                );
              });
            }
          }
        }
      },
      onLeave: (data) {
        setState(() { _hoverEvent = null; });
      },
      onAcceptWithDetails: (details) {
        DateTime initialDate = widget.displayDate;
        if (widget.calendarKey.currentContext != null) {
          final box = widget.calendarKey.currentContext!.findRenderObject() as RenderBox;
          final localOffset = box.globalToLocal(details.offset);
          final centerOffset = localOffset + const Offset(70, 35);
          final tapDetails = widget.calendarController.getCalendarDetailsAtOffset?.call(centerOffset);
          
          if (tapDetails != null && tapDetails.date != null) {
            initialDate = tapDetails.date!;
          } else {
            if (context.mounted) {
              ShadToaster.of(context).show(
                ShadToast.destructive(
                  title: const Text('Debug'),
                  description: Text('Offset: $centerOffset -> NULL'),
                ),
              );
            }
          }
        }
        
        setState(() { _hoverEvent = null; });

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (bottomSheetContext) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
            child: CreateEventSheet(
              habitsAsync: widget.habitsAsync,
              initialDate: initialDate,
              initialHabit: details.data,
            ),
          ),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isThreeDayScrollable = widget.currentView == AppCalendarView.threeDay;
            final habits = widget.habitsAsync.value ?? [];

            final calendarWidth = isThreeDayScrollable 
                ? (constraints.maxWidth / 3) * 7 
                : constraints.maxWidth;

            Widget calendarWidget = SizedBox(
              width: calendarWidth,
              child: widget.eventsAsync.when(
                data: (events) {
                  final filteredEvents = events.where((e) {
                    if (widget.sourceFilter == CalendarSourceFilter.personal) {
                      return e.userId == widget.currentUserId;
                    } else if (widget.sourceFilter == CalendarSourceFilter.squads) {
                      return e.userId != widget.currentUserId;
                    }
                    return true;
                  }).toList();

                  if (_hoverEvent != null) {
                    filteredEvents.add(_hoverEvent!);
                  }

                  Widget calendar = SfCalendar(
                    key: widget.calendarKey,
                    controller: widget.calendarController,
                    allowDragAndDrop: true,
                    onDragEnd: (AppointmentDragEndDetails details) async {
                      if (details.appointment != null && details.droppingTime != null) {
                        final event = details.appointment as EventModel;
                        final duration = event.endTime.difference(event.startTime);
                        final updatedEvent = event.copyWith(
                          startTime: details.droppingTime!,
                          endTime: details.droppingTime!.add(duration),
                        );
                        try {
                          await ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
                        } catch (e) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: Text(translations.translate('error')),
                                description: Text(e.toString()),
                              ),
                            );
                            ref.invalidate(eventsProvider);
                          }
                        }
                      }
                    },
                    allowAppointmentResize: true,
                    onAppointmentResizeEnd: (AppointmentResizeEndDetails details) async {
                      if (details.appointment != null && details.startTime != null && details.endTime != null) {
                        final event = details.appointment as EventModel;
                        final updatedEvent = event.copyWith(
                          startTime: details.startTime!,
                          endTime: details.endTime!,
                        );
                        try {
                          await ref.read(eventsProvider.notifier).updateEvent(updatedEvent);
                        } catch (e) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: Text(translations.translate('error')),
                                description: Text(e.toString()),
                              ),
                            );
                            ref.invalidate(eventsProvider);
                          }
                        }
                      }
                    },
                    dataSource: EventDataSource(filteredEvents, habits, theme, widget.currentUserId, translations),
                    onViewChanged: widget.onViewHeaderChanged,
                    initialDisplayDate: DateTime.now(),
                    headerHeight: 0,
                    viewHeaderHeight: _kViewHeaderHeight,
                    view: isThreeDayScrollable ? CalendarView.week : (widget.currentView == AppCalendarView.day ? CalendarView.day : CalendarView.month),
                    viewNavigationMode: isThreeDayScrollable ? ViewNavigationMode.none : ViewNavigationMode.snap,
                    firstDayOfWeek: 1,
                    specialRegions: _getSpecialRegions(theme),
                    dragAndDropSettings: const DragAndDropSettings(
                      allowScroll: false,
                      allowNavigation: false,
                    ),
                    appointmentBuilder: (context, details) => buildCalendarEvent(context, details, habits, categories, settings.eventStyle),
                    onTap: (CalendarTapDetails tapDetails) async {
                      if (tapDetails.targetElement == CalendarElement.appointment) {
                        final event = tapDetails.appointments!.first as EventModel;
                        final habit = habits.firstWhere(
                          (h) => h.id == event.habitId, 
                          orElse: () => HabitModel(id: '', name: translations.translate('unknown_habit'), targetDays: []),
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
                      timeIntervalHeight: _kTimeIntervalHeight,
                      timeRulerSize: _kTimeRulerWidth,
                      timeFormat: 'h a',
                    ),
                  );

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
                    calendar = NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification &&
                            notification.metrics.axis == Axis.vertical &&
                            _overlayScrollController.hasClients) {
                          final clampedOffset = notification.metrics.pixels.clamp(
                            0.0,
                            _overlayScrollController.position.maxScrollExtent,
                          );
                          _overlayScrollController.jumpTo(clampedOffset);
                        }
                        return false;
                      },
                      child: calendar,
                    );
                    calendar = Listener(
                      onPointerMove: (PointerMoveEvent event) {
                        if (widget.scrollController.hasClients) {
                          final newOffset = widget.scrollController.offset - event.delta.dx;
                          widget.scrollController.jumpTo(newOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent));
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
              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: widget.scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: calendarWidget,
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: StickyTimeRulerOverlay(
                      viewHeaderHeight: _kViewHeaderHeight,
                      timeRulerWidth: _kTimeRulerWidth,
                      timeIntervalHeight: _kTimeIntervalHeight,
                      startHour: settings.visibleStartHour,
                      endHour: settings.visibleEndHour,
                      scrollController: _overlayScrollController,
                      timeTextStyle: theme.textTheme.small,
                      backgroundColor: theme.colorScheme.background,
                      borderColor: theme.colorScheme.border,
                    ),
                  ),
                ],
              );
            }
            return calendarWidget;
          },
        );
      },
    );
  }
}

class EventDataSource extends CalendarDataSource {
  final List<HabitModel> habits;
  final ShadThemeData theme;
  final String? currentUserId;
  final AppTranslations translations;

  EventDataSource(
    List<EventModel> source, 
    this.habits, 
    this.theme, 
    this.currentUserId,
    this.translations,
  ) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => (appointments![index] as EventModel).startTime.toLocal();

  @override
  DateTime getEndTime(int index) => (appointments![index] as EventModel).endTime.toLocal();

  @override
  String getSubject(int index) => (appointments![index] as EventModel).title;

  @override
  Color getColor(int index) {
    final event = appointments![index] as EventModel;
    final isPersonal = event.userId == currentUserId;
    
    // Dim the color slightly for squad events to distinguish them
    if (event.id == 'hover_preview') {
      return theme.colorScheme.primary.withValues(alpha: 0.5);
    }
    
    if (event.isCompleted) {
      return isPersonal 
          ? const Color(0xFF10B981) // Emerald 500
          : const Color(0xFF10B981).withValues(alpha: 0.6); // Dimmer Emerald
    }

    // Uncompleted events
    return isPersonal
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.6);
  }

  @override
  Object? getId(int index) => (appointments![index] as EventModel).id;

  @override
  Object? convertAppointmentToObject(Object? customData, Appointment appointment) {
    if (customData is EventModel) {
      return customData.copyWith(
        startTime: appointment.startTime.toUtc(),
        endTime: appointment.endTime.toUtc(),
      );
    }
    return super.convertAppointmentToObject(customData, appointment);
  }

  @override
  bool isAllDay(int index) => false;
}
