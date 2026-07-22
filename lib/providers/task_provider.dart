import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../services/task_service.dart';

/// Holds every task for the signed-in user and exposes filtered views for
/// the four Bottom Navigation tabs (Home = all, In Progress, Completed,
/// Cancel). Also owns the offline-first sync logic: reads/writes always
/// touch the SharedPreferences cache, and a background sync pushes any
/// locally-made changes once connectivity returns.
class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final _uuid = const Uuid();

  List<TaskModel> _tasks = [];
  bool isLoading = false;
  bool isOffline = false;
  String? errorMessage;

  List<TaskModel> get allTasks => List.unmodifiable(_tasks);

  List<TaskModel> tasksByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  int countByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).length;

  /// Loads from network first; falls back to the local cache if offline,
  /// so the Home screen always has something to show.
  Future<void> loadTasks({required String? token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Always show cached data immediately for a snappy offline-first feel.
    _tasks = await StorageService.instance.getCachedTasks();
    notifyListeners();

    if (token == null) {
      isLoading = false;
      isOffline = true;
      notifyListeners();
      return;
    }

    try {
      final fresh = await _taskService.fetchTasks(token: token);
      _tasks = fresh;
      isOffline = false;
      await StorageService.instance.saveTasks(_tasks);
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      errorMessage = e.isOffline ? null : e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask({
    required String? token,
    required String userId,
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
    TaskStatus status = TaskStatus.pending,
  }) async {
    final localId = _uuid.v4();
    var newTask = TaskModel(
      localId: localId,
      userId: userId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      status: status,
      isSynced: false,
    );

    // Optimistic UI: show it right away, then try to sync.
    _tasks.insert(0, newTask);
    await StorageService.instance.saveTasks(_tasks);
    notifyListeners();

    if (token == null) return true;

    try {
      final synced = await _taskService.createTask(token: token, task: newTask);
      final idx = _tasks.indexWhere((t) => t.localId == localId);
      if (idx != -1) {
        _tasks[idx] = synced.copyWith(localId: localId, isSynced: true);
        await StorageService.instance.saveTasks(_tasks);
        notifyListeners();
      }
      return true;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      // Task stays cached locally as unsynced; it will retry via syncPending().
      notifyListeners();
      return e.isOffline; // offline isn't a failure the user needs an error for
    }
  }

  Future<bool> updateTask({
    required String? token,
    required TaskModel task,
  }) async {
    final idx = _tasks.indexWhere((t) => t.localId == task.localId);
    if (idx == -1) return false;

    final updated = task.copyWith(updatedAt: DateTime.now(), isSynced: false);
    _tasks[idx] = updated;
    await StorageService.instance.saveTasks(_tasks);
    notifyListeners();

    if (token == null || task.id == null) return true;

    try {
      final synced = await _taskService.updateTask(token: token, task: updated);
      _tasks[idx] = synced.copyWith(localId: task.localId, isSynced: true);
      await StorageService.instance.saveTasks(_tasks);
      notifyListeners();
      return true;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      notifyListeners();
      return e.isOffline;
    }
  }

  Future<bool> updateStatus({
    required String? token,
    required TaskModel task,
    required TaskStatus newStatus,
  }) {
    return updateTask(
      token: token,
      task: task.copyWith(status: newStatus),
    );
  }

  Future<bool> deleteTask({
    required String? token,
    required TaskModel task,
  }) async {
    _tasks.removeWhere((t) => t.localId == task.localId);
    await StorageService.instance.saveTasks(_tasks);
    notifyListeners();

    if (token == null || task.id == null) return true;

    try {
      await _taskService.deleteTask(token: token, taskId: task.id!);
      return true;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      notifyListeners();
      return e.isOffline;
    }
  }

  /// Push any tasks created/edited while offline. Call this when
  /// connectivity is restored (e.g. pull-to-refresh). Wired up on Day 5.
  Future<void> syncPending({required String? token}) async {
    if (token == null) return;
    final unsynced = _tasks.where((t) => !t.isSynced).toList();
    for (final task in unsynced) {
      try {
        if (task.id == null) {
          final synced = await _taskService.createTask(
            token: token,
            task: task,
          );
          final idx = _tasks.indexWhere((t) => t.localId == task.localId);
          if (idx != -1) {
            _tasks[idx] = synced.copyWith(
              localId: task.localId,
              isSynced: true,
            );
          }
        } else {
          final synced = await _taskService.updateTask(
            token: token,
            task: task,
          );
          final idx = _tasks.indexWhere((t) => t.localId == task.localId);
          if (idx != -1) {
            _tasks[idx] = synced.copyWith(
              localId: task.localId,
              isSynced: true,
            );
          }
        }
      } on TaskServiceException {
        // Still offline or server error — leave it queued for next attempt.
        break;
      }
    }
    await StorageService.instance.saveTasks(_tasks);
    notifyListeners();
  }

  void clear() {
    _tasks = [];
    notifyListeners();
  }
}
