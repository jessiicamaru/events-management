import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
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
    if (event.id == AppConstants.hoverPreviewEventId) {
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
  String? getRecurrenceRule(int index) => (appointments![index] as EventModel).recurrenceRule;

  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
    final event = appointments![index] as EventModel;
    if (event.recurrenceExceptionDates == null || event.recurrenceExceptionDates!.isEmpty) return null;
    try {
      return event.recurrenceExceptionDates!
          .split(',')
          .map((d) => DateTime.parse(d).toLocal())
          .toList();
    } catch (e) {
      return null;
    }
  }

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
