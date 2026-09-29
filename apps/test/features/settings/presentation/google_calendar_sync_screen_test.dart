import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/settings/presentation/google_calendar_sync_screen.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';
import '../../../test_utils.dart';

class FakeApiService extends Fake implements ApiService {
  bool connectCalled = false;
  bool syncCalled = false;
  bool disconnectCalled = false;
  String? lastAuthCode;
  String? lastEmail;

  @override
  Future<void> connectGoogleCalendar(String authCode, String email) async {
    connectCalled = true;
    lastAuthCode = authCode;
    lastEmail = email;
  }

  @override
  Future<void> syncGoogleCalendar() async {
    syncCalled = true;
  }

  @override
  Future<void> disconnectGoogleCalendar() async {
    disconnectCalled = true;
  }
}

class FakeUserProfileNotifier extends UserProfileNotifier {
  final UserProfileModel _profile;
  FakeUserProfileNotifier(this._profile);

  @override
  Future<UserProfileModel> build() async => _profile;
}

void main() {
  late FakeApiService fakeApiService;

  setUp(() {
    fakeApiService = FakeApiService();
  });

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const ShadApp(
        home: Material(
          child: GoogleCalendarSyncScreen(),
        ),
      ),
    );
  }

  testWidgets('GoogleCalendarSyncScreen renders disconnected state correctly', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApiService),
        userProfileProvider.overrideWith(() => FakeUserProfileNotifier(const UserProfileModel(
              id: 'user-123',
              email: 'test@example.com',
              totalXP: 100,
              googleEmail: null, // Disconnected
            ))),
        ...commonTestOverrides,
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Google Calendar Sync'), findsWidgets);
    expect(find.text('Not Connected'), findsOneWidget);
    expect(find.text('Connect Google Calendar'), findsOneWidget);
    expect(find.text('Sync Now'), findsNothing);
  });

  testWidgets('GoogleCalendarSyncScreen renders connected state correctly', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApiService),
        userProfileProvider.overrideWith(() => FakeUserProfileNotifier(const UserProfileModel(
              id: 'user-123',
              email: 'test@example.com',
              totalXP: 100,
              googleEmail: 'synced_email@gmail.com', // Connected
            ))),
        ...commonTestOverrides,
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Google Calendar Sync'), findsWidgets);
    expect(find.text('Connected to:'), findsOneWidget);
    expect(find.text('synced_email@gmail.com'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
  });

  testWidgets('GoogleCalendarSyncScreen calls sync endpoint when Sync Now tapped', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApiService),
        userProfileProvider.overrideWith(() => FakeUserProfileNotifier(const UserProfileModel(
              id: 'user-123',
              email: 'test@example.com',
              totalXP: 100,
              googleEmail: 'synced_email@gmail.com',
            ))),
        ...commonTestOverrides,
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync Now'));
    await tester.pump();

    expect(fakeApiService.syncCalled, isTrue);
  });

  testWidgets('GoogleCalendarSyncScreen calls disconnect when Disconnect tapped', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(fakeApiService),
        userProfileProvider.overrideWith(() => FakeUserProfileNotifier(const UserProfileModel(
              id: 'user-123',
              email: 'test@example.com',
              totalXP: 100,
              googleEmail: 'synced_email@gmail.com',
            ))),
        ...commonTestOverrides,
      ],
    );

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Disconnect'));
    await tester.pump();

    expect(fakeApiService.disconnectCalled, isTrue);
  });
}
