import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/settings/presentation/category_management_screen.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final String categoryName;
  final String? categoryColorPreset;
  final Widget? trailing;
  final bool compact;

  const HabitCard({
    super.key,
    required this.habit,
    required this.categoryName,
    this.categoryColorPreset,
    this.trailing,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final categoryColor = categoryColorPreset != null 
        ? (colorPalette[categoryColorPreset] ?? Colors.blueGrey)
        : Colors.blueGrey;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left border indicator
            Container(
              width: 6, // Slightly thicker for better visibility
              color: categoryColor,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: compact ? 8.0 : 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            habit.name,
                            style: compact 
                                ? theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)
                                : theme.textTheme.large,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: compact ? 2.0 : 4.0),
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: compact ? 10 : 12,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
