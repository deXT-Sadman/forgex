/// Status values matching the four Bottom Navigation tabs:
/// Home shows everything, the other three filter by status.
enum TaskStatus { pending, inProgress, completed, cancelled }

TaskStatus taskStatusFromString(String? value) {
  switch (value) {
    case 'inProgress':
      return TaskStatus.inProgress;
    case 'completed':
      return TaskStatus.completed;
    case 'cancelled':
      return TaskStatus.cancelled;
    case 'pending':
    default:
      return TaskStatus.pending;
  }
}

String taskStatusToString(TaskStatus status) {
  switch (status) {
    case TaskStatus.inProgress:
      return 'inProgress';
    case TaskStatus.completed:
      return 'completed';
    case TaskStatus.cancelled:
      return 'cancelled';
    case TaskStatus.pending:
      return 'pending';
  }
}

enum TaskPriority { low, medium, high }

TaskPriority taskPriorityFromString(String? value) {
  switch (value) {
    case 'high':
      return TaskPriority.high;
    case 'medium':
      return TaskPriority.medium;
    case 'low':
    default:
      return TaskPriority.low;
  }
}

String taskPriorityToString(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'high';
    case TaskPriority.medium:
      return 'medium';
    case TaskPriority.low:
      return 'low';
  }
}

/// Task data model.
///
/// Mirrors a MongoDB document shape:
/// {
///   "_id": "665f1c...",
///   "userId": "665a0b...",
///   "title": "Buy groceries",
///   "description": "Milk, eggs, bread",
///   "status": "pending",
///   "priority": "medium",
///   "dueDate": "2026-07-25T00:00:00.000Z",
///   "createdAt": "...",
///   "updatedAt": "..."
/// }
///
/// [id] is nullable because a task created offline has no Mongo _id yet
/// (a [localId] is used instead until it syncs).
class TaskModel {
  final String? id; // Mongo _id (null until synced with the server)
  final String localId; // stable local key, used for offline caching/CRUD
  final String userId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced; // false => still pending upload to MongoDB

  TaskModel({
    this.id,
    required this.localId,
    required this.userId,
    required this.title,
    this.description = '',
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = true,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Build a [TaskModel] from a MongoDB / REST API JSON document.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString(),
      localId:
          json['localId']?.toString() ??
          json['_id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      userId: json['userId']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: taskStatusFromString(json['status']),
      priority: taskPriorityFromString(json['priority']),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      isSynced: true,
    );
  }

  /// Serialize for sending to the MongoDB-backed REST API.
  /// `_id` is omitted on create; the server generates it.
  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> map = {
      'localId': localId,
      'userId': userId,
      'title': title,
      'description': description,
      'status': taskStatusToString(status),
      'priority': taskPriorityToString(priority),
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (includeId && id != null) map['_id'] = id;
    return map;
  }

  /// Serialize for local SharedPreferences cache (keeps sync flag too).
  Map<String, dynamic> toCacheJson() {
    final map = toJson(includeId: true);
    map['isSynced'] = isSynced;
    return map;
  }

  factory TaskModel.fromCacheJson(Map<String, dynamic> json) {
    final task = TaskModel.fromJson(json);
    return task.copyWith(isSynced: json['isSynced'] ?? true);
  }

  TaskModel copyWith({
    String? id,
    String? localId,
    String? userId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TaskModel(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
