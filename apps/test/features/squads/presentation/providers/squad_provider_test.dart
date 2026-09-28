import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';

import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

class MockApiService implements ApiService {
  SquadModel? squadToReturn;
  List<MySquadSummaryModel> squadsListToReturn = [];

  @override
  Future<SquadModel?> fetchSquadDetails(String squadId) async => squadToReturn;

  @override
  Future<List<MySquadSummaryModel>> fetchMySquads() async => squadsListToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuth extends Auth {
  @override
  Future<String?> build() async => 'dummy-token';
}

void main() {
  late MockApiService mockApiService;

  setUp(() {
    mockApiService = MockApiService();
  });

  ProviderContainer createContainer({
    ProviderContainer? parent,
  }) {
    final container = ProviderContainer(
      parent: parent,
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        authProvider.overrideWith(() => MockAuth()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('SquadProvider initial fetch returns squad', () async {
    final mockSquad = SquadModel(
      id: 'squad-1',
      name: 'Alpha Squad',
      maxMembers: 5,
      requireApproval: false,
      totalSquadXP: 1000,
      members: [],
    );

    mockApiService.squadToReturn = mockSquad;
    mockApiService.squadsListToReturn = [
      const MySquadSummaryModel(
        id: 'squad-1',
        name: 'Alpha Squad',
        memberCount: 0,
        maxMembers: 5,
        totalSquadXP: 1000,
      )
    ];

    final container = createContainer();
    // activeSquadProvider handles detail fetching
    final provider = activeSquadProvider;

    final states = <AsyncValue<SquadModel?>>[];
    container.listen(
      provider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );

    // Initial state is loading
    expect(states[0], isA<AsyncLoading<SquadModel?>>());

    // Wait for the future to complete
    await container.read(provider.future);

    // Check final state
    expect(states[1].value, mockSquad);
  });
}
