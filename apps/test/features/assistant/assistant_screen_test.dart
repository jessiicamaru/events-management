import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_progress_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_message_bubble.dart';
import '../../test_utils.dart';
import 'fake_assistant_api.dart';

void main() {
  late FakeAssistantApi api;
  late ProviderContainer container;

  Future<void> open(WidgetTester tester) async {
    container = ProviderContainer(overrides: [
      ...commonTestOverrides,
      ...signedInOverrides,
      apiServiceProvider.overrideWithValue(api),
      // No hub in a widget test; progress is driven through the notifier instead.
      assistantProgressProvider.overrideWith((ref) {}),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const ShadApp(home: AssistantScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => api = FakeAssistantApi());

  testWidgets('asks for consent first, and opens the chat once the user agrees', (tester) async {
    api.settings = const AssistantSettings(assistantEnabled: false, alwaysConfirm: false, serverConfigured: true);
    await open(tester);

    expect(find.text('Turn on the assistant?'), findsOneWidget);
    expect(find.textContaining('sent to an external AI service'), findsOneWidget);
    expect(find.text('Ask about your schedule…'), findsNothing, reason: 'no chat before consent');

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(api.settingsUpdates, [true]);
    expect(find.text('Ask me about your schedule'), findsOneWidget);
  });

  testWidgets('says so when the server has no assistant, instead of asking for consent', (tester) async {
    api.settings = const AssistantSettings(assistantEnabled: false, alwaysConfirm: false, serverConfigured: false);
    await open(tester);

    expect(find.text('The assistant is not set up on this server yet.'), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
  });

  testWidgets('offers a retry when the settings cannot be loaded', (tester) async {
    api.failSettings = AssistantFailure.network;
    await open(tester);

    expect(find.text('Could not load the assistant.'), findsOneWidget);

    api.failSettings = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Ask me about your schedule'), findsOneWidget);
  });

  testWidgets('a suggestion sends itself; the chat shows what the assistant is doing, then the reply',
      (tester) async {
    await open(tester);

    await tester.tap(find.text("What's on tomorrow?"));
    await tester.pump();

    expect(api.sent.single.text, "What's on tomorrow?");
    expect(find.text('Thinking…'), findsOneWidget);

    container.read(assistantChatProvider.notifier).toolStarted('conversation-1', 'get_events');
    await tester.pump();
    expect(find.text('Looking at your calendar…'), findsOneWidget);

    api.reply('Tomorrow you run at **06:00**.', tools: ['get_events']);
    await tester.pumpAndSettle();

    expect(find.text('Looking at your calendar…'), findsNothing);
    expect(find.text('Checked your calendar'), findsOneWidget);
    expect(find.text('Tomorrow you run at 06:00.', findRichText: true), findsOneWidget);
  });

  testWidgets('typing a message sends it and clears the box', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(EditableText), 'Tuần này thế nào?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(api.sent.single.text, 'Tuần này thế nào?');
    expect(find.text('Tuần này thế nào?'), findsOneWidget, reason: 'shown as a bubble, gone from the box');

    api.reply('ok');
    await tester.pumpAndSettle();
  });

  testWidgets('explains a failed turn and keeps the message', (tester) async {
    await open(tester);
    api.failNextSend = AssistantFailure.dailyLimit;

    await tester.tap(find.text("What's on tomorrow?"));
    await tester.pumpAndSettle();

    expect(find.text("You have reached today's message limit. Try again tomorrow."), findsOneWidget);
    expect(find.text("What's on tomorrow?", findRichText: true), findsOneWidget);
  });

  testWidgets('shows the history of the last conversation', (tester) async {
    api
      ..latestConversationId = 'c1'
      ..history = [
        AssistantMessage(role: AssistantRole.user, content: 'Mai có gì?', createdAt: DateTime(2026, 9, 28)),
        AssistantMessage(role: AssistantRole.tool, toolName: 'get_events', createdAt: DateTime(2026, 9, 28)),
        AssistantMessage(role: AssistantRole.assistant, content: 'Mai trống.', createdAt: DateTime(2026, 9, 28)),
      ];
    await open(tester);

    expect(find.text('Mai có gì?', findRichText: true), findsOneWidget);
    expect(find.text('Checked your calendar'), findsOneWidget);
    expect(find.text('Mai trống.', findRichText: true), findsOneWidget);
  });

  test('bold marks become bold text, and an unpaired mark is shown plainly', () {
    final spans = AssistantMessageBubble.boldSpans('Run at **06:00** and **read');

    expect(spans.map((s) => s.text), ['Run at ', '06:00', ' and ', 'read']);
    expect(spans[1].style?.fontWeight, FontWeight.w600);
    expect(spans[3].style, isNull, reason: 'no closing mark');
  });
}
