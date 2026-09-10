// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heatmap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(heatmap)
final heatmapProvider = HeatmapProvider._();

final class HeatmapProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, int>>,
          Map<DateTime, int>,
          FutureOr<Map<DateTime, int>>
        >
    with
        $FutureModifier<Map<DateTime, int>>,
        $FutureProvider<Map<DateTime, int>> {
  HeatmapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'heatmapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$heatmapHash();

  @$internal
  @override
  $FutureProviderElement<Map<DateTime, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<DateTime, int>> create(Ref ref) {
    return heatmap(ref);
  }
}

String _$heatmapHash() => r'cbf4567b2566f9c0df2eabea3ecc2211a7da4c10';
