import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../utils/constants.dart';

/// Raised whenever a task API call fails so callers can distinguish
/// "no internet" from "server rejected the request".
class TaskServiceException implements Exception {
  final String message;
  final bool isOffline;
  TaskServiceException(this.message, {this.isOffline = false});
  @override
  String toString() => message;
}

/// All CRUD operations against the MongoDB-backed REST API for tasks.
/// TaskProvider decides what to do when these throw (fall back to the
/// SharedPreferences cache).
class TaskService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<TaskModel>> fetchTasks({required String token}) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.tasksEndpoint), headers: _headers(token))
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded
            .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      throw TaskServiceException(
        'Could not load tasks (${response.statusCode}).',
      );
    } on SocketException {
      throw TaskServiceException('No internet connection.', isOffline: true);
    } on TaskServiceException {
      rethrow;
    } catch (e) {
      throw TaskServiceException('Could not load tasks.', isOffline: true);
    }
  }

  Future<TaskModel> createTask({
    required String token,
    required TaskModel task,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.tasksEndpoint),
            headers: _headers(token),
            body: jsonEncode(task.toJson()),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TaskModel.fromJson(jsonDecode(response.body));
      }
      throw TaskServiceException('Could not create the task.');
    } on SocketException {
      throw TaskServiceException('No internet connection.', isOffline: true);
    } on TaskServiceException {
      rethrow;
    } catch (e) {
      throw TaskServiceException('Could not create the task.', isOffline: true);
    }
  }

  Future<TaskModel> updateTask({
    required String token,
    required TaskModel task,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.tasksEndpoint}/${task.id}'),
            headers: _headers(token),
            body: jsonEncode(task.toJson()),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        return TaskModel.fromJson(jsonDecode(response.body));
      }
      throw TaskServiceException('Could not update the task.');
    } on SocketException {
      throw TaskServiceException('No internet connection.', isOffline: true);
    } on TaskServiceException {
      rethrow;
    } catch (e) {
      throw TaskServiceException('Could not update the task.', isOffline: true);
    }
  }

  Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.tasksEndpoint}/$taskId'),
            headers: _headers(token),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw TaskServiceException('Could not delete the task.');
    } on SocketException {
      throw TaskServiceException('No internet connection.', isOffline: true);
    } on TaskServiceException {
      rethrow;
    } catch (e) {
      throw TaskServiceException('Could not delete the task.', isOffline: true);
    }
  }
}
