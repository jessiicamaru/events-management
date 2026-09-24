import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final colorPalette = {
  'Slate': Colors.blueGrey,
  'Red': Colors.red,
  'Rose': Colors.pink,
  'Orange': Colors.orange,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Yellow': Colors.yellow,
  'Violet': Colors.purple,
};

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    // Fetch all categories (personal and squad)
    final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ShadButton.outline(
                      width: 40,
                      height: 40,
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(LucideIcons.arrowLeft, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Category Management',
                      style: theme.textTheme.h3,
                    ),
                  ],
                ),
              ),
              
              // Custom styled TabBar
              TabBar(
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.mutedForeground,
                indicatorWeight: 3,
                dividerColor: theme.colorScheme.border,
                labelStyle: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: theme.textTheme.small,
                tabs: const [
                  Tab(text: 'My Categories'),
                  Tab(text: 'Squad Categories'),
                ],
              ),
              
              // TabBarView Content
              Expanded(
                child: TabBarView(
                  children: [
                    // My Categories
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildCategoryList(context, ref, categoriesAsync, theme, isSquad: false),
                          ),
                          const SizedBox(height: 16),
                          ShadButton(
                            child: const Text('Add Category'),
                            onPressed: () => _showAddCategoryDialog(context, ref, false),
                          ),
                        ],
                      ),
                    ),
                    
                    // Squad Categories
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildCategoryList(context, ref, categoriesAsync, theme, isSquad: true),
                          ),
                          const SizedBox(height: 16),
                          ShadButton.secondary(
                            child: const Text('Add Squad Category'),
                            onPressed: () => _showAddCategoryDialog(context, ref, true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context, 
    WidgetRef ref, 
    AsyncValue<List<EventCategory>> asyncValue, 
    ShadThemeData theme,
    {required bool isSquad}
  ) {
    return asyncValue.when(
      data: (allCategories) {
        final categories = allCategories.where((c) => isSquad ? c.squadId != null : c.squadId == null).toList();

        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.tags, size: 48, color: theme.colorScheme.mutedForeground),
                const SizedBox(height: 16),
                Text(
                  isSquad ? 'No squad categories found.' : 'No personal categories found.',
                  style: theme.textTheme.large.copyWith(color: theme.colorScheme.mutedForeground),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create one to organize your events.',
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final color = colorPalette[category.colorPreset] ?? Colors.blueGrey;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.large,
                    ),
                  ),
                  ShadButton.ghost(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.zero,
                    hoverBackgroundColor: theme.colorScheme.destructive,
                    hoverForegroundColor: theme.colorScheme.destructiveForeground,
                    child: const Icon(LucideIcons.trash2, size: 16),
                    onPressed: () {
                      ref.read(eventCategoriesProvider(squadId: category.squadId).notifier)
                         .deleteCategory(category.id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.destructive))),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, bool isSquad) {
    String name = '';
    String selectedColor = 'Slate';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = ShadTheme.of(context);
            
            return ShadDialog(
              title: const Text('New Category'),
              description: Text(isSquad ? 'Create a category for your squad.' : 'Create a personal category.'),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ShadButton(
                  onPressed: () {
                    if (name.trim().isNotEmpty) {
                      ref.read(eventCategoriesProvider(squadId: isSquad ? 'TODO_SQUAD_ID' : null).notifier)
                         .addCategory(name.trim(), selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ShadInput(
                      placeholder: const Text('e.g. Work, Health, etc.'),
                      onChanged: (val) => name = val,
                    ),
                    const SizedBox(height: 24),
                    Text('Color', style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: colorPalette.entries.map((e) {
                        final isSelected = selectedColor == e.key;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = e.key),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: theme.colorScheme.foreground, width: 2) : null,
                              boxShadow: isSelected 
                                ? [BoxShadow(color: e.value.withValues(alpha: 0.5), blurRadius: 8)] 
                                : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}
