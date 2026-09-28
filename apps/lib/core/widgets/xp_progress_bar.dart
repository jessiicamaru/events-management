import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/utils/level_system.dart';

class XpProgressBar extends StatelessWidget {
  final int totalXp;

  const XpProgressBar({super.key, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final level = LevelSystem.getLevel(totalXp);
    final progress = LevelSystem.getProgressPercentage(totalXp);
    final xpProgress = LevelSystem.getXpProgressWithinLevel(totalXp);
    final xpNeeded = LevelSystem.getXpNeededWithinLevel(level);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Calculate offset for the floating XP text
        final double progressOffset = width * progress;
        // Text configuration
        const double textWidth = 60.0;
        final double leftPosition = (progressOffset - (textWidth / 2)).clamp(0.0, width - textWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Floating indicator for current XP within this level
            SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: leftPosition,
                    width: textWidth,
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$xpProgress XP',
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 10,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar itself
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.muted,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            // Labels at the two ends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 XP',
                  style: theme.textTheme.muted.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                ),
                Text(
                  '$xpNeeded XP',
                  style: theme.textTheme.muted.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
