import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/calendar_event_style.dart';
import 'package:intl/intl.dart';

Widget buildCalendarEvent(BuildContext context, CalendarAppointmentDetails details, List<HabitModel> habits, CalendarEventStyle style) {
  final event = details.appointments.first as EventModel;
  
  final habit = habits.firstWhere(
    (h) => h.id == event.habitId, 
    orElse: () => HabitModel(id: '', name: 'Unknown', targetDays: []),
  );
  final color = AppTheme.getHabitColor(habit.category);
  
  final theme = ShadTheme.of(context);

  final timeString = '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}';

  if (style == CalendarEventStyle.dot) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timeString,
                  style: theme.textTheme.small.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (event.isCompleted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(LucideIcons.checkCircle2, size: 14, color: color),
            ),
        ],
      ),
    );
  }

  if (style == CalendarEventStyle.colored) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.small.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.isCompleted)
                Icon(LucideIcons.checkCircle2, size: 14, color: color),
            ],
          ),
          Text(
            timeString,
            style: theme.textTheme.small.copyWith(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Mixed style
  return Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      border: Border(
        left: BorderSide(color: color, width: 4),
        top: BorderSide(color: theme.colorScheme.border),
        right: BorderSide(color: theme.colorScheme.border),
        bottom: BorderSide(color: theme.colorScheme.border),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                timeString,
                style: theme.textTheme.small.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (event.isCompleted)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(LucideIcons.checkCircle2, size: 14, color: color),
          ),
      ],
    ),
  );
}
