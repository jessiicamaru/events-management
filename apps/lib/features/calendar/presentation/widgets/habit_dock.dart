import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../habits/domain/models/habit_model.dart';
import '../../../../core/theme/app_theme.dart';

class HabitDock extends StatelessWidget {
  final List<HabitModel> habits;

  const HabitDock({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    if (habits.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border(top: BorderSide(color: theme.colorScheme.border)),
        ),
        child: Text(
          'No habits to schedule',
          style: theme.textTheme.muted,
        ),
      );
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Drag habits to calendar',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildDraggableHabit(context, habit, theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableHabit(BuildContext context, HabitModel habit, ShadThemeData theme) {
    final habitColor = AppTheme.getHabitColor(habit.category);

    final habitCard = Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: habitColor.withOpacity(0.15),
        border: Border.all(color: habitColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            habit.name,
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.foreground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            habit.category ?? 'Uncategorized',
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    return Draggable<HabitModel>(
      data: habit,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Transform.scale(
            scale: 1.05,
            child: habitCard,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: habitCard,
      ),
      child: habitCard,
    );
  }
}
