import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/network/dio_client.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_task_model.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_task_model.dart';
import 'package:habit_tracker/features/calendar/models/event_category.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';

import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

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
  Future<List<MySquadSummaryModel>> fetchMySquads() async {
    final response = await _dio.get('/squads/list');
    return (response.data as List)
        .map((json) => MySquadSummaryModel.fromJson(json))
        .toList();
  }

  Future<SquadModel?> fetchSquadDetails(String squadId) async {
    try {
      final response = await _dio.get('/squads', queryParameters: {'squadId': squadId});
      return SquadModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SquadModel> createSquad(String name, int maxMembers, bool requireApproval) async {
    final response = await _dio.post('/squads', data: {
      'name': name,
      'maxMembers': maxMembers,
      'requireApproval': requireApproval,
    });
    return SquadModel.fromJson(response.data);
  }

  Future<bool> joinSquad(String squadId) async {
    final response = await _dio.post('/squads/join', data: {
      'squadId': squadId,
    });
    return response.data['isApproved'] as bool;
  }

  Future<void> approveMember(String squadId, String targetUserId) async {
    await _dio.post('/squads/$squadId/approve/$targetUserId');
  }

  Future<void> rejectMember(String squadId, String targetUserId) async {
    await _dio.post('/squads/$squadId/reject/$targetUserId');
  }

  Future<void> leaveSquad(String squadId) async {
    await _dio.delete('/squads/$squadId/leave');
  }

  Future<void> deleteSquad(String squadId) async {
    await _dio.delete('/squads/$squadId');
  }

  Future<void> updateSquadSettings(String squadId, String name, int maxMembers, bool requireApproval) async {
    await _dio.put('/squads/$squadId/settings', data: {
      'name': name,
      'maxMembers': maxMembers,
      'requireApproval': requireApproval,
    });
  }

  Future<void> changeLeader(String squadId, String targetUserId) async {
    await _dio.post('/squads/$squadId/change-leader', data: {
      'targetUserId': targetUserId,
    });
  }

  Future<void> updateMemberSettings(String squadId, {String? nickname, required bool isMuted, required bool xpContributionEnabled}) async {
    await _dio.put('/squads/$squadId/member-settings', data: {
      'nickname': nickname,
      'isMuted': isMuted,
      'xpContributionEnabled': xpContributionEnabled,
    });
  }

  Future<void> changeMemberNickname(String squadId, String targetUserId, String newNickname) async {
    await _dio.put('/squads/$squadId/member-nickname', data: {
      'targetUserId': targetUserId,
      'newNickname': newNickname,
    });
  }

  Future<List<SquadChatMessageModel>> fetchChatHistory(String squadId) async {
    final response = await _dio.get('/squads/$squadId/chat-history');
    return (response.data as List)
        .map((json) => SquadChatMessageModel.fromJson(json))
        .toList();
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

  // --- Habit Tasks ---

  Future<List<HabitTaskModel>> fetchHabitTasks(String habitId) async {
    final response = await _dio.get('/habits/$habitId/tasks');
    final data = response.data as List;
    return data.map((json) => HabitTaskModel.fromJson(json)).toList();
  }

  Future<void> createHabitTask(String habitId, HabitTaskModel task) async {
    await _dio.post('/habits/$habitId/tasks', data: task.toJson());
  }

  Future<void> updateHabitTask(String habitId, HabitTaskModel task) async {
    await _dio.put('/habits/$habitId/tasks/${task.id}', data: task.toJson());
  }

  Future<void> deleteHabitTask(String habitId, String taskId) async {
    await _dio.delete('/habits/$habitId/tasks/$taskId');
  }

  Future<void> reorderHabitTasks(String habitId, List<Map<String, dynamic>> orders) async {
    await _dio.put('/habits/$habitId/tasks/reorder', data: orders);
  }

  // --- Event Tasks ---

  Future<List<EventTaskModel>> fetchEventTasks(String eventId) async {
    final response = await _dio.get('/events/$eventId/tasks');
    final data = response.data as List;
    return data.map((json) => EventTaskModel.fromJson(json)).toList();
  }

  Future<void> createEventTask(String eventId, EventTaskModel task) async {
    await _dio.post('/events/$eventId/tasks', data: task.toJson());
  }

  Future<void> updateEventTask(String eventId, EventTaskModel task) async {
    await _dio.put('/events/$eventId/tasks/${task.id}', data: task.toJson());
  }

  Future<void> deleteEventTask(String eventId, String taskId) async {
    await _dio.delete('/events/$eventId/tasks/$taskId');
  }

  Future<void> toggleEventTask(String eventId, String taskId, bool isCompleted) async {
    await _dio.patch('/events/$eventId/tasks/$taskId/toggle', data: {'isCompleted': isCompleted});
  }

  // --- Event Categories ---

  Future<List<EventCategory>> fetchEventCategories({String? squadId}) async {
    final queryParameters = <String, dynamic>{};
    if (squadId != null) queryParameters['squadId'] = squadId;
    
    final response = await _dio.get('/event-categories', queryParameters: queryParameters);
    final data = response.data as List;
    return data.map((json) => EventCategory.fromJson(json)).toList();
  }

  Future<EventCategory> createEventCategory(EventCategory category) async {
    final response = await _dio.post('/event-categories', data: category.toJson());
    // The backend might only return the ID, but we want the full object if possible. 
    // Assuming we construct the object locally or fetch it.
    return category.copyWith(id: response.data.toString());
  }

  Future<void> updateEventCategory(EventCategory category) async {
    await _dio.put('/event-categories/${category.id}', data: category.toJson());
  }

  Future<void> deleteEventCategory(String id, {String? replacementCategoryId}) async {
    final queryParams = <String, dynamic>{};
    if (replacementCategoryId != null) {
      queryParams['replacementCategoryId'] = replacementCategoryId;
    }
    await _dio.delete('/event-categories/$id', queryParameters: queryParams);
  }

  // --- Google Calendar Sync ---

  Future<void> connectGoogleCalendar(String authCode, String email) async {
    await _dio.post('/google-calendar/connect', data: {
      'authCode': authCode,
      'googleEmail': email,
    });
  }

  Future<void> syncGoogleCalendar() async {
    await _dio.post(
      '/google-calendar/sync',
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<void> disconnectGoogleCalendar() async {
    await _dio.post('/google-calendar/disconnect');
  }
}
