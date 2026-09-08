import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

void main() {
  group('ApiService', () {
    late Dio dio;
    late ApiService apiService;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/habits' && options.method == 'GET') {
            return handler.resolve(
              Response(
                requestOptions: options,
                data: [
                  {
                    'id': '123',
                    'name': 'Test Habit',
                    'category': 'Health',
                    'targetDays': [1, 2]
                  }
                ],
                statusCode: 200,
              ),
            );
          }
          if (options.path == '/habits' && options.method == 'POST') {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
              ),
            );
          }
          return handler.next(options);
        },
      ));
      
      apiService = ApiService(dio);
    });

    test('fetchHabits returns list of HabitModel', () async {
      final habits = await apiService.fetchHabits();
      
      expect(habits, isA<List<HabitModel>>());
      expect(habits.length, 1);
      expect(habits.first.name, 'Test Habit');
      expect(habits.first.category, 'Health');
    });

    test('syncHabit completes successfully without throwing', () async {
      const habit = HabitModel(
        id: '123',
        name: 'Test',
        targetDays: [1]
      );
      
      await expectLater(apiService.syncHabit(habit), completes);
    });
  });
}
