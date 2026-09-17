// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HabitsNotifier)
final habitsProvider = HabitsNotifierProvider._();

final class HabitsNotifierProvider
    extends $AsyncNotifierProvider<HabitsNotifier, List<HabitModel>> {
  HabitsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsNotifierHash();

  @$internal
  @override
  HabitsNotifier create() => HabitsNotifier();
}

String _$habitsNotifierHash() => r'c2d2195f0d778b4f4feff45f3e867652d5ef3a3d';

abstract class _$HabitsNotifier extends $AsyncNotifier<List<HabitModel>> {
  FutureOr<List<HabitModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<HabitModel>>, List<HabitModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<HabitModel>>, List<HabitModel>>,
              AsyncValue<List<HabitModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
