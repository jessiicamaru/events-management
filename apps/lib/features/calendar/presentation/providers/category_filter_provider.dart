import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_filter_provider.g.dart';

@riverpod
class CategoryFilter extends _$CategoryFilter {
  @override
  String? build() => null;

  void setCategory(String? category) {
    state = category;
  }
}
