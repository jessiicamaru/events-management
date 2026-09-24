import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/api_service.dart';

part 'heatmap_provider.g.dart';

@riverpod
Future<Map<DateTime, int>> heatmap(Ref ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.dio.get('/analytics/heatmap');
  
  final Map<DateTime, int> data = {};
  if (response.statusCode == 200) {
    for (var item in (response.data as List)) {
      final date = DateTime.parse(item['date']);
      final count = item['count'] as int;
      data[DateTime(date.year, date.month, date.day)] = count;
    }
  }
  return data;
}
