import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/dio_client.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

final apiServiceProvider = Provider((ref) {
  final dio = DioClient().dio;
  
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Read token from the provider's future — safe and correct
      final token = await ref.read(authProvider.future);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        // Here we could implement refresh token logic later
      }
      return handler.next(error);
    }
  ));
  
  return ApiService(dio);
});

class ApiService {
  final Dio _dio;
  Dio get dio => _dio;

  ApiService(this._dio);

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<void> syncHabit(HabitModel habit) async {
    try {
      await _dio.post('/habits', data: habit.toJson());
    } catch (e) {
      // Typically we'd save to local DB and sync later
      rethrow;
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    try {
      await _dio.put('/habits/${habit.id}', data: habit.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      await _dio.delete('/habits/$id');
    } catch (e) {
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

  Future<void> toggleEvent(String id, bool isCompleted) async {
    await _dio.put(
      '/events/$id/toggle',
      data: {'isCompleted': isCompleted},
      options: Options(contentType: 'application/json'),
    );
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('/events/$id');
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _dio.put(
      '/events/$id',
      data: data,
      options: Options(contentType: 'application/json'),
    );
  }

  Future<void> completeSession(String id, String actualDuration, bool updateCalendar) async {
    await _dio.put(
      '/events/$id/complete-session',
      data: {
        'actualDuration': actualDuration,
        'updateCalendar': updateCalendar,
      },
      options: Options(contentType: 'application/json'),
    );
  }
  Future<SquadModel?> fetchMySquad() async {
    try {
      final response = await _dio.get('/squads');
      return SquadModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SquadModel> createSquad(String name, bool isBuddyMode) async {
    final response = await _dio.post('/squads', data: {
      'name': name,
      'isBuddyMode': isBuddyMode,
    });
    return SquadModel.fromJson(response.data);
  }

  Future<void> joinSquad(String squadId) async {
    await _dio.post('/squads/join', data: {
      'squadId': squadId,
    });
  }

  Future<UserProfileModel> fetchMe() async {
    final response = await _dio.get('/users/me');
    return UserProfileModel.fromJson(response.data);
  }

  Future<void> updateCosmetics({List<String>? unlockedEmojis, String? avatarBorderColor}) async {
    final data = <String, dynamic>{};
    if (unlockedEmojis != null) data['unlockedEmojis'] = unlockedEmojis;
    if (avatarBorderColor != null) data['avatarBorderColor'] = avatarBorderColor;
    
    await _dio.put('/users/me/cosmetics', data: data);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? avatar,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth.toUtc().toIso8601String();
    if (gender != null) data['gender'] = gender;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (avatar != null) data['avatar'] = avatar;
    
    await _dio.put('/users/me', data: data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/users/me/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
