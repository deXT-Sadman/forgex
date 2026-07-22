import 'package:flutter/material.dart';
import '../../models/task_model.dart';

/// Renders the task list for a given tab. [statusFilter] is null on the
/// Home tab (shows everything) and a specific [TaskStatus] on the other
/// three tabs (In Progress / Completed / Cancel).
///
/// NOTE: today this just shows which filter is active. Day 4 connects it
/// to TaskProvider and a real TaskCard list.
class TaskListView extends StatelessWidget {
  final TaskStatus? statusFilter;

  const TaskListView({super.key, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final label = statusFilter == null
        ? 'Home (all tasks)'
        : statusFilter!.name;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text('Showing: $label', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
