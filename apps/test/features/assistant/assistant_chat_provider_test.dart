import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';
import '../../test_utils.dart';
import 'fake_assistant_api.dart';

void main() {
  late FakeAssistantApi api;
  late ProviderContainer container;

  AssistantChatNotifier chat() => container.read(assistantChatProvider.notifier);
  AssistantChatState state() => container.read(assistantChatProvider);

  setUp(() {
    api = FakeAssistantApi();
    container = ProviderContainer(overrides: [...signedInOverrides, apiServiceProvider.overrideWithValue(api)]);
    container.listen(assistantChatProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => container.dispose());

  group('load', () {
    test('opens the most recent conversation with its history', () async {
      api
        ..latestConversationId = 'c1'
        ..history = [
          AssistantMessage(role: AssistantRole.user, content: 'hi', createdAt: DateTime(2026, 9, 28)),
          AssistantMessage(role: AssistantRole.assistant, content: 'hello', createdAt: DateTime(2026, 9, 28)),
        ];

      await chat().load();

      expect(state().conversationId, 'c1');
      expect(state().messages.map((m) => m.content), ['hi', 'hello']);
      expect(state().loaded, isTrue);
    });

    test('starts empty when there is no conversation yet, without creating one', () async {
      await chat().load();

      expect(state().conversationId, isNull);
      expect(state().messages, isEmpty);
      expect(api.conversationsCreated, 0);
    });
  });

  group('send', () {
    test('shows the message at once, then the tool steps and the reply in the order they happened', () async {
      final sending = chat().send('  Mai mình có lịch gì?  ');
      await pumpEventQueue();

      expect(state().sending, isTrue);
      expect(state().messages.single.content, 'Mai mình có lịch gì?', reason: 'trimmed and shown before the reply');

      api.reply('Mai bạn chạy bộ lúc 06:00.', tools: ['get_events']);
      await sending;

      expect(state().sending, isFalse);
      expect(state().messages.map((m) => (m.role, m.content ?? m.toolName)), [
        (AssistantRole.user, 'Mai mình có lịch gì?'),
        (AssistantRole.tool, 'get_events'),
        (AssistantRole.assistant, 'Mai bạn chạy bộ lúc 06:00.'),
      ]);
    });

    test('creates the conversation with the first message, and reuses it after', () async {
      final first = chat().send('một');
      await pumpEventQueue();
      api.reply('1');
      await first;
      final second = chat().send('hai');
      await pumpEventQueue();
      api.reply('2');
      await second;

      expect(api.conversationsCreated, 1);
      expect(api.sent.map((s) => s.conversationId), ['conversation-1', 'conversation-1']);
    });

    test('ignores a second message while a turn is running', () async {
      final first = chat().send('một');
      await pumpEventQueue();
      await chat().send('hai');
      api.reply('1');
      await first;

      expect(api.sent.map((s) => s.text), ['một']);
    });

    test('ignores an empty message', () async {
      await chat().send('   ');

      expect(api.sent, isEmpty);
      expect(state().messages, isEmpty);
    });

    test('keeps the message and reports why, when the turn fails', () async {
      api.failNextSend = AssistantFailure.dailyLimit;

      await chat().send('còn đó không?');

      expect(state().sending, isFalse);
      expect(state().failure, AssistantFailure.dailyLimit);
      expect(state().messages.single.content, 'còn đó không?');
    });

    test('starts a new conversation after the server says the old one is gone', () async {
      api.latestConversationId = 'gone';
      await chat().load();
      api.failNextSend = AssistantFailure.conversationNotFound;
      await chat().send('một');

      final retry = chat().send('hai');
      await pumpEventQueue();
      api.reply('ok');
      await retry;

      expect(api.sent.map((s) => s.conversationId), ['gone', 'conversation-1']);
      expect(state().failure, isNull, reason: 'a new request clears the last failure');
    });

    test('notes a reply that was cut off, or refused', () async {
      final first = chat().send('dài');
      await pumpEventQueue();
      api.reply('…', status: 'Truncated');
      await first;
      expect(state().notice, AssistantNotice.truncated);

      final second = chat().send('xoá hết');
      await pumpEventQueue();
      api.reply('Không.', status: 'Refused');
      await second;
      expect(state().notice, AssistantNotice.refused);
    });
  });

  group('progress', () {
    test('shows the tool the server reports for this conversation, while its turn runs', () async {
      final sending = chat().send('mai?');
      await pumpEventQueue();

      chat().toolStarted('someone-else', 'get_stats');
      expect(state().activeTool, isNull, reason: 'another conversation');

      chat().toolStarted('conversation-1', 'get_events');
      expect(state().activeTool, 'get_events');

      api.reply('ok');
      await sending;
      expect(state().activeTool, isNull, reason: 'cleared when the reply arrives');

      chat().toolStarted('conversation-1', 'get_habits');
      expect(state().activeTool, isNull, reason: 'no turn is running');
    });
  });

  test('a new conversation clears the chat, and is only created with its first message', () async {
    api.latestConversationId = 'c1';
    await chat().load();

    chat().startNewConversation();

    expect(state().conversationId, isNull);
    expect(state().messages, isEmpty);
    expect(state().loaded, isTrue, reason: 'must not reload the old one');
    expect(api.conversationsCreated, 0);
  });
}
