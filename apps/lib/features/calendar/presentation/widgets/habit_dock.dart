import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_card.dart';

class HabitDock extends ConsumerWidget {
  final List<HabitModel> habits;

  const HabitDock({super.key, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    final categories = ref.watch(eventCategoriesProvider(squadId: null)).value ?? [];

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
      height: 120,
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
                  child: _buildDraggableHabit(context, habit, theme, categories, translations),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableHabit(BuildContext context, HabitModel habit, ShadThemeData theme, List<EventCategory> categories, dynamic translations) {
    String categoryName = translations.translate('uncategorized');
    String? categoryPreset;

    if (habit.categoryId != null) {
      final category = categories.firstWhere(
        (c) => c.id == habit.categoryId,
        orElse: () => const EventCategory(id: '', name: 'Uncategorized', colorPreset: 'Slate'),
      );
      if (category.id.isNotEmpty) {
        categoryPreset = category.colorPreset;
        categoryName = category.name;
      }
    }

    final habitCard = SizedBox(
      width: 140,
      child: HabitCard(
        habit: habit,
        categoryName: categoryName,
        categoryColorPreset: categoryPreset,
        compact: true,
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
      childWhenDragging: Container(
        alignment: Alignment.center,
        child: Opacity(
          opacity: 0.3,
          child: habitCard,
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        child: habitCard,
      ),
    );
  }
}
