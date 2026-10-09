import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';

/// Whether the assistant is on for this user, and whether the server can run it at all.
///
/// Auto-disposed and without automatic retry, like the home screen's cards: one request
/// per visit to the assistant, and the screen offers its own "Try again".
final assistantSettingsProvider =
    AsyncNotifierProvider.autoDispose<AssistantSettingsNotifier, AssistantSettings>(
  AssistantSettingsNotifier.new,
  retry: (_, _) => null,
);

class AssistantSettingsNotifier extends AsyncNotifier<AssistantSettings> {
  @override
  Future<AssistantSettings> build() => ref.watch(apiServiceProvider).fetchAssistantSettings();

  /// Turns the assistant on or off. Turning it on is the user's consent; the server
  /// records when it was first given.
  Future<void> setEnabled(bool enabled) async {
    final alwaysConfirm = state.value?.alwaysConfirm ?? false;
    state = const AsyncLoading<AssistantSettings>();
    state = await AsyncValue.guard(() => ref
        .read(apiServiceProvider)
        .updateAssistantSettings(enabled: enabled, alwaysConfirm: alwaysConfirm));
  }
}
