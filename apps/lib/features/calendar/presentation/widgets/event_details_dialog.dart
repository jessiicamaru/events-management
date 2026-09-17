import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';
import '../../domain/models/event_model.dart';
import '../../../habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/focus_session/presentation/screens/focus_screen.dart';
import '../../../../core/localization/locale_provider.dart';

import '../events_provider.dart';
import '../../../habits/presentation/habits_provider.dart';
import 'create_event_sheet.dart';

class EventDetailsDialog extends ConsumerWidget {
  final EventModel event;
  final HabitModel habit;

  const EventDetailsDialog({
    super.key,
    required this.event,
    required this.habit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);
    final localeStr = currentLocale == AppLocale.en ? 'en_US' : 'vi';

    final dateFormat = DateFormat('EEEE, MMM d, yyyy', localeStr);
    final timeFormat = DateFormat('h:mm a', localeStr);
    final theme = ShadTheme.of(context);

    String translatedCategory = habit.category ?? translations.translate('uncategorized');
    if (habit.category == 'Health') translatedCategory = translations.translate('category_health');
    if (habit.category == 'Work') translatedCategory = translations.translate('category_work');
    if (habit.category == 'Learning') translatedCategory = translations.translate('category_learning');
    if (habit.category == 'Wellness') translatedCategory = translations.translate('category_wellness');

    return ShadDialog(
      title: Text(translations.translate(event.title)),
      description: Text(translations.translate('event_details')),
      actions: const [], // We will move the close button to the bottom of the child for better layout
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, LucideIcons.calendar, translations.translate('date'), dateFormat.format(event.startTime)),
              const SizedBox(height: 12),
              _buildDetailRow(context, LucideIcons.clock, translations.translate('time'), '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}'),
              const SizedBox(height: 12),
              _buildDetailRow(context, LucideIcons.tag, translations.translate('category'), translatedCategory),
              const SizedBox(height: 12),
              _buildDetailRow(context, LucideIcons.checkCircle, translations.translate('status'), event.isCompleted ? translations.translate('completed') : translations.translate('pending')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  backgroundColor: event.isCompleted ? theme.colorScheme.destructive : Colors.green,
                  hoverBackgroundColor: event.isCompleted ? theme.colorScheme.destructive.withOpacity(0.9) : Colors.green.withOpacity(0.9),
                  onPressed: () {
                    if (event.isCompleted) {
                      ref.read(eventsProvider.notifier).toggleEvent(event.id, false);
                      Navigator.of(context).pop(false);
                    } else {
                      Navigator.of(context).pop(true); // Return true to start focus session
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(event.isCompleted ? LucideIcons.xCircle : LucideIcons.play, size: 16),
                      const SizedBox(width: 8),
                      Text(event.isCompleted ? translations.translate('mark_pending') : translations.translate('start_focus')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (bottomSheetContext) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                            ),
                            child: CreateEventSheet(
                              habitsAsync: ref.watch(habitsProvider),
                              eventToEdit: event,
                              initialHabit: habit,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.pencil, size: 16),
                          const SizedBox(width: 8),
                          Text(translations.translate('edit')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ShadButton.destructive(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => ShadDialog(
                            title: Text(translations.translate('delete_event_confirm_title')),
                            description: Text(translations.translate('delete_event_confirm_desc')),
                            actions: [
                              ShadButton.outline(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(translations.translate('cancel')),
                              ),
                              ShadButton.destructive(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(translations.translate('delete')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          try {
                            await ref.read(eventsProvider.notifier).deleteEvent(event.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ShadToaster.of(context).show(
                                ShadToast(
                                  title: Text(translations.translate('event_deleted_toast')),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ShadToaster.of(context).show(
                                ShadToast.destructive(
                                  title: Text(translations.translate('error')),
                                  description: Text(e.toString()),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.trash2, size: 16),
                          const SizedBox(width: 8),
                          Text(translations.translate('delete')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ShadButton.ghost(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(translations.translate('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground)),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
