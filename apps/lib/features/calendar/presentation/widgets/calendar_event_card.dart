import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/features/calendar/domain/models/calendar_event_style.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart';

Widget buildCalendarEvent(BuildContext context, CalendarAppointmentDetails details, List<HabitModel> habits, List<EventCategory> categories, CalendarEventStyle style) {
  final event = details.appointments.first as EventModel;
  
  Color color;
  if (event.categoryId != null) {
    final cat = categories.firstWhere((c) => c.id == event.categoryId, orElse: () => const EventCategory(id: '', name: '', colorPreset: 'Slate'));
    color = colorPalette[cat.colorPreset] ?? Colors.blueGrey;
  } else {
    color = AppTheme.getHabitColor(null);
  }
  
  final theme = ShadTheme.of(context);
  final timeString = '${DateFormat.jm().format(event.startTime.toLocal())} - ${DateFormat.jm().format(event.endTime.toLocal())}';

  Widget buildCard({
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required Color timeColor,
    required bool showDot,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxHeight < 40;
        final bool isTiny = constraints.maxHeight < 25;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: isTiny ? 2 : (isCompact ? 4 : 6),
          ),
          clipBehavior: Clip.hardEdge,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        event.title,
                        style: theme.textTheme.small.copyWith(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.isCompleted)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(LucideIcons.checkCircle2, size: 14, color: textColor),
                      ),
                  ],
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    timeString,
                    style: theme.textTheme.small.copyWith(
                      fontSize: 12,
                      height: 1.2,
                      color: timeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  if (style == CalendarEventStyle.dot) {
    return buildCard(
      backgroundColor: theme.colorScheme.card,
      borderColor: theme.colorScheme.border,
      textColor: theme.colorScheme.foreground,
      timeColor: theme.colorScheme.mutedForeground,
      showDot: true,
    );
  }

  if (style == CalendarEventStyle.colored) {
    return buildCard(
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.2),
      textColor: color,
      timeColor: color.withValues(alpha: 0.9),
      showDot: false,
    );
  }

  // Mixed style
  return buildCard(
    backgroundColor: color.withValues(alpha: 0.1),
    borderColor: color.withValues(alpha: 0.2),
    textColor: color,
    timeColor: color.withValues(alpha: 0.9),
    showDot: true,
  );
}
