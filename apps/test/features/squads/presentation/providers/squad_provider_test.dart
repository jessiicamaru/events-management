import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';

class MockApiService implements ApiService {
  SquadModel? squadToReturn;

  @override
  Future<SquadModel?> fetchMySquad() async => squadToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('SquadProvider initial fetch returns squad', () async {
    final mockSquad = SquadModel(
      id: 'squad-1',
      name: 'Alpha Squad',
      isBuddyMode: false,
      totalSquadXP: 1000,
      members: [],
    );

    mockApiService.squadToReturn = mockSquad;

    final container = createContainer();
    final provider = squadProvider;

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


