import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/dio_client.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';

final apiServiceProvider = Provider((ref) => ApiService(DioClient().dio));

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<void> syncHabit(HabitModel habit) async {
    try {
      await _dio.post('/habits', data: habit.toJson());
    } catch (e) {
      // Typically we'd save to local DB and sync later
      rethrow;
    }
  }

  Future<List<HabitModel>> fetchHabits() async {
    final response = await _dio.get('/habits');
    final data = response.data as List;
    return data.map((json) => HabitModel.fromJson(json)).toList();
  }

  Future<void> syncEvent(EventModel event) async {
    try {
      await _dio.post('/events', data: event.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventModel>> fetchEvents() async {
    final response = await _dio.get('/events');
    final data = response.data as List;
    return data.map((json) => EventModel.fromJson(json)).toList();
  }
}
