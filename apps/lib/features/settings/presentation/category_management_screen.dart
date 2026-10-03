import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/calendar/presentation/providers/event_category_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/settings/presentation/widgets/category_list_view.dart';
import 'package:habit_tracker/features/settings/presentation/widgets/add_category_dialog.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';

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
    final categoriesAsync = ref.watch(eventCategoriesProvider(squadId: null));
    final translations = ref.watch(translationsProvider);
    final activeSquadId = ref.watch(activeSquadIdProvider);

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
                      translations.translate('category_management'),
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
                tabs: [
                  Tab(text: translations.translate('my_categories')),
                  Tab(text: translations.translate('squad_categories')),
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
                            child: CategoryListView(categoriesAsync: categoriesAsync, theme: theme, isSquad: false),
                          ),
                          const SizedBox(height: 16),
                          ShadButton(
                            child: Text(translations.translate('add_category')),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AddCategoryDialog(isSquad: false, translations: translations),
                              );
                            },
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
                            child: CategoryListView(categoriesAsync: categoriesAsync, theme: theme, isSquad: true),
                          ),
                          const SizedBox(height: 16),
                          ShadButton.secondary(
                            // No squad selected means there is nothing to attach the
                            // category to, so the action is unavailable rather than broken.
                            onPressed: activeSquadId == null
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AddCategoryDialog(
                                        isSquad: true,
                                        squadId: activeSquadId,
                                        translations: translations,
                                      ),
                                    );
                                  },
                            child: Text(translations.translate('add_squad_category')),
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

}
