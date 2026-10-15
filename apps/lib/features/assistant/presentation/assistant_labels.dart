import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';

/// The words the chat uses for the server's tool names, failures and notices — kept in
/// one place so a new tool or failure has exactly one spot to be given a label.
abstract final class AssistantLabels {
  /// Tools that have their own wording; any other falls back to a generic label.
  static const Set<String> knownTools = {'get_events', 'get_habits', 'get_categories', 'get_stats'};

  /// While [tool] runs: "Looking at your calendar…". Null [tool] means the model itself.
  static String running(AppTranslations t, String? tool) {
    if (tool == null) return t.translate('assistant_thinking');
    return knownTools.contains(tool)
        ? t.translate('assistant_tool_running_$tool')
        : t.translate('assistant_tool_running_other');
  }

  /// After [tool] ran: "Checked your calendar".
  static String done(AppTranslations t, String tool) => knownTools.contains(tool)
      ? t.translate('assistant_tool_done_$tool')
      : t.translate('assistant_tool_done_other', params: {'tool': tool});

  static String failure(AppTranslations t, AssistantFailure failure) => t.translate(switch (failure) {
        AssistantFailure.notConfigured => 'assistant_not_configured',
        AssistantFailure.disabled => 'assistant_error_disabled',
        AssistantFailure.dailyLimit => 'assistant_error_daily_limit',
        AssistantFailure.modelUnavailable => 'assistant_error_model',
        AssistantFailure.conversationNotFound => 'assistant_error_not_found',
        AssistantFailure.network => 'assistant_error_network',
        AssistantFailure.unknown => 'assistant_error_unknown',
      });

  static String notice(AppTranslations t, AssistantNotice notice) => t.translate(switch (notice) {
        AssistantNotice.truncated => 'assistant_notice_truncated',
        AssistantNotice.refused => 'assistant_notice_refused',
        AssistantNotice.stepLimit => 'assistant_notice_step_limit',
      });

  /// Questions offered on an empty conversation, as translation keys.
  static const List<String> suggestionKeys = [
    'assistant_suggestion_tomorrow',
    'assistant_suggestion_week',
    'assistant_suggestion_focus',
    'assistant_suggestion_skipped',
  ];
}
