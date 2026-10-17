import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/assistant/domain/assistant_models.dart';
import 'package:habit_tracker/features/assistant/presentation/assistant_labels.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_chat_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/providers/assistant_progress_provider.dart';
import 'package:habit_tracker/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/events_provider.dart';
import '../../test_utils.dart';
import 'fake_assistant_api.dart';

void main() {
  final at = DateTime(2026, 9, 28, 14);

  test('every tool with its own wording has it in both languages, not its raw name', () {
    for (final locale in AppLocale.values) {
      final t = AppTranslations(locale);
      for (final tool in AssistantLabels.knownTools) {
        expect(AssistantLabels.running(t, tool), isNot(contains(tool)), reason: '$locale running $tool');
        expect(AssistantLabels.done(t, tool), isNot(contains(tool)), reason: '$locale done $tool');
      }
    }
    expect(AssistantLabels.knownTools, containsAll(['get_habit_stats', 'propose_schedule']));
  });

  group('placeProposals', () {
    test('puts each proposal after the reply that explains it, as a live turn shows it', () {
      final history = [
        AssistantMessage(role: AssistantRole.user, content: 'chạy bộ 45p', createdAt: at),
        AssistantMessage(
          role: AssistantRole.tool,
          toolName: 'propose_schedule',
          proposals: [FakeAssistantApi.proposal(id: 'a'), FakeAssistantApi.proposal(id: 'b')],
          createdAt: at,
        ),
        AssistantMessage(role: AssistantRole.assistant, content: 'Sáng 5h trống.', createdAt: at),
        AssistantMessage(role: AssistantRole.user, content: 'cảm ơn', createdAt: at),
      ];

      final placed = AssistantChatNotifier.placeProposals(history);

      expect(placed.map((m) => m.role), [
        AssistantRole.user,
        AssistantRole.tool,
        AssistantRole.assistant,
        AssistantRole.proposal,
        AssistantRole.proposal,
        AssistantRole.user,
      ]);
      expect(placed.where((m) => m.role == AssistantRole.proposal).map((m) => m.proposals.single.id), ['a', 'b']);
    });

    test('keeps a proposal whose turn has no reply, at the end of that turn', () {
      final history = [
        AssistantMessage(role: AssistantRole.user, content: 'một', createdAt: at),
        AssistantMessage(role: AssistantRole.tool, proposals: [FakeAssistantApi.proposal()], createdAt: at),
        AssistantMessage(role: AssistantRole.user, content: 'hai', createdAt: at),
      ];

      final placed = AssistantChatNotifier.placeProposals(history);

      expect(placed.map((m) => m.role),
          [AssistantRole.user, AssistantRole.tool, AssistantRole.proposal, AssistantRole.user]);
    });
  });

  group('what adding changes elsewhere', () {
    late FakeAssistantApi api;
    late ProviderContainer container;
    late _CountingEvents events;

    setUp(() async {
      api = FakeAssistantApi();
      events = _CountingEvents();
      container = ProviderContainer(overrides: [
        ...signedInOverrides,
        apiServiceProvider.overrideWithValue(api),
        eventsProvider.overrideWith(() => events),
      ]);
      container.listen(eventsProvider, (_, _) {}, fireImmediately: true);
      container.listen(assistantChatProvider, (_, _) {}, fireImmediately: true);
      await container.read(eventsProvider.future);
    });

    tearDown(() => container.dispose());

    Future<void> settle() => container.read(eventsProvider.future);

    test('adding or taking back reloads the calendar, so the sessions show on every screen', () async {
      await container.read(assistantChatProvider.notifier).applyProposal('p1');
      await settle();
      expect(events.builds, 2);

      await container.read(assistantChatProvider.notifier).undoProposal('p1');
      await settle();
      expect(events.builds, 3);
    });

    test('dismissing changes nothing on the calendar, so nothing is reloaded', () async {
      await container.read(assistantChatProvider.notifier).dismissProposal('p1');
      await settle();

      expect(events.builds, 1);
    });
  });

  group('the proposal card in the chat', () {
    late FakeAssistantApi api;
    late ProviderContainer container;

    Future<void> openWithProposal(WidgetTester tester, {AssistantProposal? proposal}) async {
      api = FakeAssistantApi();
      container = ProviderContainer(overrides: [
        ...commonTestOverrides,
        ...signedInOverrides,
        apiServiceProvider.overrideWithValue(api),
        assistantProgressProvider.overrideWith((ref) {}),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const ShadApp(home: AssistantScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'Chạy bộ 45p mỗi ngày, 5-6h sáng hoặc 6-7h tối');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      api.reply('Sáng 5h trống cả 2 tuần tới.',
          tools: ['propose_schedule'], proposals: [proposal ?? FakeAssistantApi.proposal()]);
      await tester.pumpAndSettle();
    }

    testWidgets('shows what would be added, and adds nothing until the user taps', (tester) async {
      await openWithProposal(tester);

      expect(find.text('Chạy bộ'), findsOneWidget);
      expect(find.text('Every day · 05:00–05:45'), findsOneWidget);
      expect(find.text('Starts Tue 29/09'), findsOneWidget);
      expect(find.text('New habit'), findsOneWidget);
      expect(find.text('Fits your calendar for the next 2 weeks'), findsOneWidget);
      expect(api.proposalActions, isEmpty, reason: 'showing a proposal adds nothing');
    });

    testWidgets('tapping Add to calendar adds it, and the card can then take it back', (tester) async {
      await openWithProposal(tester);

      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();

      expect(api.proposalActions, ['apply:p1']);
      expect(find.text('Added to your calendar'), findsOneWidget);
      expect(find.text('Add to calendar'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(api.proposalActions, ['apply:p1', 'undo:p1']);
      expect(find.text('Taken back'), findsOneWidget);
    });

    testWidgets('dismissing it says so and offers nothing more', (tester) async {
      await openWithProposal(tester);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(api.proposalActions, ['dismiss:p1']);
      expect(find.text('Dismissed'), findsOneWidget);
      expect(find.text('Add to calendar'), findsNothing);
    });

    testWidgets('warns when the proposed time clashes, naming what with', (tester) async {
      await openWithProposal(
        tester,
        proposal: FakeAssistantApi.proposal(start: '18:00', end: '18:45', conflicts: [
          AssistantProposalConflict(date: DateTime(2026, 9, 29), title: 'Gym'),
          AssistantProposalConflict(date: DateTime(2026, 10, 1), title: 'Gym'),
        ]),
      );

      expect(find.text('Clashes on 2 days in the next 2 weeks (Gym)'), findsOneWidget);
    });

    testWidgets('explains why an undo was refused, and keeps the card as added', (tester) async {
      await openWithProposal(tester);
      await tester.tap(find.text('Add to calendar'));
      await tester.pumpAndSettle();
      api.failNextProposalAction = AssistantFailure.proposalHasActivity;

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('cannot be undone here'), findsOneWidget);
      expect(find.text('Added to your calendar'), findsOneWidget);
    });

    testWidgets('a second tap while the first is on its way does nothing', (tester) async {
      await openWithProposal(tester);

      final chat = container.read(assistantChatProvider.notifier);
      final first = chat.applyProposal('p1');
      await chat.applyProposal('p1');
      await first;

      expect(api.proposalActions, ['apply:p1']);
    });
  });
}

/// The calendar's events, counting how often they are loaded.
class _CountingEvents extends EventsNotifier {
  int builds = 0;

  @override
  Future<List<EventModel>> build() async {
    builds++;
    return const [];
  }
}
