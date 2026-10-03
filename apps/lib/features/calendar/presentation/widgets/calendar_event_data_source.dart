import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/calendar/domain/event_occurrence.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

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

    for (final event in source) {
      final parentId = event.parentEventId;
      final day = event.exceptionDate;
      if (parentId == null || day == null) continue;

      _splitOffDays.putIfAbsent(parentId, () => []).add(day.toLocal());
    }
  }

  /// For each series, the days that have their own event.
  ///
  /// The calendar draws a series' days itself, from its repeat rule, and hides only the
  /// dates in its exception list. A day split off locally — by a ticked task or a
  /// finished session — is deliberately *not* in that list (it would be pushed to Google
  /// and cancel the day there), so without this it would be drawn twice: the series' day
  /// and the day's own event.
  final Map<String, List<DateTime>> _splitOffDays = {};

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
    if (event.id == AppConstants.hoverPreviewEventId) {
      return theme.colorScheme.primary.withValues(alpha: 0.5);
    }
    
    // A series is drawn with the series row's colour on every day. Its flag says nothing
    // about a single day — done days have their own event, drawn separately.
    if (event.isCompleted && !event.isSeriesOccurrence) {
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
  String? getRecurrenceRule(int index) => (appointments![index] as EventModel).recurrenceRule;

  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
    final event = appointments![index] as EventModel;
    final exceptions = <DateTime>[...?_splitOffDays[event.id]];

    final stored = event.recurrenceExceptionDates;
    if (stored != null && stored.isNotEmpty) {
      for (final raw in stored.split(',')) {
        final parsed = DateTime.tryParse(raw.trim());
        if (parsed != null) exceptions.add(parsed.toLocal());
      }
    }

    return exceptions.isEmpty ? null : exceptions;
  }

  @override
  Object? convertAppointmentToObject(Object? customData, Appointment appointment) {
    if (customData is EventModel) {
      final day = customData.copyWith(
        startTime: appointment.startTime.toUtc(),
        endTime: appointment.endTime.toUtc(),
      );

      // Same rule as EventOccurrenceExpander: a day of a series starts undone.
      return day.isSeriesOccurrence
          ? day.copyWith(isCompleted: false, actualDuration: null)
          : day;
    }
    return super.convertAppointmentToObject(customData, appointment);
  }

  @override
  bool isAllDay(int index) => false;
}
