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

  /// Saves the task locally (fast) and returns immediately — the network
  /// sync happens in the background via [_syncCreate], so the Add/Edit
  /// screen's "Create Task" button never sits waiting on a slow or
  /// unreachable server.
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
    final newTask = TaskModel(
      localId: localId,
      userId: userId,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      status: status,
      isSynced: false,
    );

    try {
      // Optimistic UI: show it right away.
      _tasks.insert(0, newTask);
      await StorageService.instance.saveTasks(_tasks);
      notifyListeners();
    } catch (_) {
      // Extremely unlikely (disk write failure), but if the local save
      // itself fails, this is a genuine failure the UI should know about.
      return false;
    }

    if (token != null) {
      // Fire-and-forget: don't make the caller wait on this.
      _syncCreate(token: token, localId: localId, task: newTask);
    }

    return true;
  }

  Future<void> _syncCreate({
    required String token,
    required String localId,
    required TaskModel task,
  }) async {
    try {
      final synced = await _taskService.createTask(token: token, task: task);
      final idx = _tasks.indexWhere((t) => t.localId == localId);
      if (idx != -1) {
        _tasks[idx] = synced.copyWith(localId: localId, isSynced: true);
        await StorageService.instance.saveTasks(_tasks);
        notifyListeners();
      }
      isOffline = false;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      // Task stays cached locally as unsynced; retried later via syncPending().
      notifyListeners();
    }
  }

  /// Same fire-and-forget pattern as [addTask] — updates the local cache
  /// instantly and syncs to the server in the background.
  Future<bool> updateTask({
    required String? token,
    required TaskModel task,
  }) async {
    final idx = _tasks.indexWhere((t) => t.localId == task.localId);
    if (idx == -1) return false;

    final updated = task.copyWith(updatedAt: DateTime.now(), isSynced: false);

    try {
      _tasks[idx] = updated;
      await StorageService.instance.saveTasks(_tasks);
      notifyListeners();
    } catch (_) {
      return false;
    }

    if (token != null && task.id != null) {
      _syncUpdate(token: token, updated: updated);
    }

    return true;
  }

  Future<void> _syncUpdate({
    required String token,
    required TaskModel updated,
  }) async {
    try {
      final synced = await _taskService.updateTask(token: token, task: updated);
      final idx = _tasks.indexWhere((t) => t.localId == updated.localId);
      if (idx != -1) {
        _tasks[idx] = synced.copyWith(localId: updated.localId, isSynced: true);
        await StorageService.instance.saveTasks(_tasks);
        notifyListeners();
      }
      isOffline = false;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      notifyListeners();
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

  /// Deletion also returns instantly (local removal), syncing the server
  /// delete in the background.
  Future<bool> deleteTask({
    required String? token,
    required TaskModel task,
  }) async {
    _tasks.removeWhere((t) => t.localId == task.localId);
    await StorageService.instance.saveTasks(_tasks);
    notifyListeners();

    if (token != null && task.id != null) {
      _syncDelete(token: token, taskId: task.id!);
    }

    return true;
  }

  Future<void> _syncDelete({
    required String token,
    required String taskId,
  }) async {
    try {
      await _taskService.deleteTask(token: token, taskId: taskId);
      isOffline = false;
    } on TaskServiceException catch (e) {
      isOffline = e.isOffline;
      notifyListeners();
    }
  }

  /// Push any tasks created/edited while offline. Call this when
  /// connectivity is restored (e.g. pull-to-refresh).
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
