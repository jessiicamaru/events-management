import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class CustomRecurrenceDialog extends StatefulWidget {
  final String? initialRrule;
  const CustomRecurrenceDialog({super.key, this.initialRrule});

  @override
  State<CustomRecurrenceDialog> createState() => _CustomRecurrenceDialogState();
}

class _CustomRecurrenceDialogState extends State<CustomRecurrenceDialog> {
  String _freq = 'WEEKLY';
  int _interval = 1;
  List<String> _byDays = [];
  String _endType = 'never'; // 'never', 'date', 'count'
  DateTime _untilDate = DateTime.now().add(const Duration(days: 30));
  int _count = 10;

  @override
  void initState() {
    super.initState();
    if (widget.initialRrule != null && widget.initialRrule!.isNotEmpty) {
      final parts = widget.initialRrule!.replaceAll('RRULE:', '').split(';');
      for (final part in parts) {
        if (part.startsWith('FREQ=')) _freq = part.substring(5);
        if (part.startsWith('INTERVAL=')) _interval = int.tryParse(part.substring(9)) ?? 1;
        if (part.startsWith('BYDAY=')) _byDays = part.substring(6).split(',');
        if (part.startsWith('UNTIL=')) {
          _endType = 'date';
          final dateStr = part.substring(6);
          if (dateStr.length >= 8) {
            final y = int.parse(dateStr.substring(0, 4));
            final m = int.parse(dateStr.substring(4, 6));
            final d = int.parse(dateStr.substring(6, 8));
            _untilDate = DateTime(y, m, d);
          }
        }
        if (part.startsWith('COUNT=')) {
          _endType = 'count';
          _count = int.tryParse(part.substring(6)) ?? 10;
        }
      }
    }
  }

  String _buildRrule() {
    final List<String> rruleParts = [];
    rruleParts.add('FREQ=$_freq');
    rruleParts.add('INTERVAL=$_interval');
    if (_freq == 'WEEKLY' && _byDays.isNotEmpty) {
      rruleParts.add('BYDAY=${_byDays.join(',')}');
    }
    if (_endType == 'date') {
      rruleParts.add('UNTIL=${_untilDate.toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.').first}Z');
    } else if (_endType == 'count') {
      rruleParts.add('COUNT=$_count');
    }
    return 'RRULE:${rruleParts.join(';')}';
  }

  Widget _buildDayButton(String label, String dayCode) {
    final isSelected = _byDays.contains(dayCode);
    final theme = ShadTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) _byDays.remove(dayCode);
          else _byDays.add(dayCode);
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
              ? theme.colorScheme.primary 
              : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? theme.colorScheme.primaryForeground 
                : theme.colorScheme.foreground,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String label, String value, {Widget? trailing}) {
    final isSelected = _endType == value;
    final theme = ShadTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radioColor = isSelected ? theme.colorScheme.primary : (isDark ? Colors.white38 : Colors.black38);

    return GestureDetector(
      onTap: () => setState(() => _endType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioColor, width: 2),
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              ),
              child: isSelected 
                  ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primaryForeground))) 
                  : null,
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 14)),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              Expanded(child: trailing),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final inputDecoration = BoxDecoration(
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
    );

    return ShadDialog(
      title: const Text('Repeat'),
      child: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Every', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 70,
                    height: 40,
                    child: ShadInput(
                      initialValue: _interval.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      onChanged: (val) {
                        setState(() {
                          _interval = int.tryParse(val) ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadSelect<String>(
                      initialValue: _freq,
                      onChanged: (val) {
                        if (val != null) setState(() => _freq = val);
                      },
                      options: const [
                        ShadOption(value: 'DAILY', child: Text('day')),
                        ShadOption(value: 'WEEKLY', child: Text('week')),
                        ShadOption(value: 'MONTHLY', child: Text('month')),
                        ShadOption(value: 'YEARLY', child: Text('year')),
                      ],
                      selectedOptionBuilder: (context, value) => Text(
                        value == 'DAILY' ? 'day' : value == 'WEEKLY' ? 'week' : value == 'MONTHLY' ? 'month' : 'year'
                      ),
                    ),
                  ),
                ],
              ),
              if (_freq == 'WEEKLY') ...[
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('On', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDayButton('Su', 'SU'),
                          _buildDayButton('Mo', 'MO'),
                          _buildDayButton('Tu', 'TU'),
                          _buildDayButton('We', 'WE'),
                          _buildDayButton('Th', 'TH'),
                          _buildDayButton('Fr', 'FR'),
                          _buildDayButton('Sa', 'SA'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              const Text('Ends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildRadio('Never', 'never'),
              _buildRadio(
                'On', 
                'date',
                trailing: GestureDetector(
                  onTap: () async {
                    setState(() => _endType = 'date');
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _untilDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => _untilDate = picked);
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: inputDecoration,
                    alignment: Alignment.centerLeft,
                    child: Text(DateFormat('E MMM d').format(_untilDate), style: TextStyle(color: theme.colorScheme.foreground.withOpacity(0.8))),
                  ),
                ),
              ),
              _buildRadio(
                'After', 
                'count',
                trailing: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 40,
                      child: ShadInput(
                        initialValue: _count.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        onChanged: (val) {
                          setState(() {
                            _endType = 'count';
                            _count = int.tryParse(val) ?? 10;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('times', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: () => Navigator.of(context).pop(_buildRrule()),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

Future<String?> showRecurrenceEditOptionDialog(BuildContext context, AppTranslations translations) async {
  return showShadDialog<String>(
    context: context,
    builder: (context) => ShadDialog(
      title: Text(translations.translate('edit_recurring_event')),
      description: Text(translations.translate('edit_recurring_event_prompt')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('ThisOccurrence'),
          child: Text(translations.translate('this_occurrence')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('ThisAndFuture'),
          child: Text(translations.translate('this_and_future_occurrences')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('AllOccurrences'),
          child: Text(translations.translate('all_occurrences')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(translations.translate('cancel')),
        ),
      ],
    ),
  );
}
