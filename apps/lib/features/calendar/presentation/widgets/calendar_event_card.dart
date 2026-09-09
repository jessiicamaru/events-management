import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../../../core/theme/app_theme.dart';

Widget buildCalendarEvent(BuildContext context, CalendarAppointmentDetails details, List<HabitModel> habits) {
  final event = details.appointments.first as EventModel;
  
  final habit = habits.firstWhere(
    (h) => h.id == event.habitId, 
    orElse: () => HabitModel(id: '', name: 'Unknown', targetDays: []),
  );
  final color = AppTheme.getHabitColor(habit.category);
  
  final theme = ShadTheme.of(context);

  return Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      border: Border(
        left: BorderSide(color: color, width: 4),
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            event.title,
            style: theme.textTheme.small.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
