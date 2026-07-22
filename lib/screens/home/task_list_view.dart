import 'package:flutter/material.dart';
import 'package:forgex/screens/add_edit_task_screen.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/task_card.dart';

/// Renders the task list for a given tab. [statusFilter] is null on the
/// Home tab (shows everything) and a specific [TaskStatus] on the other
/// three tabs (In Progress / Completed / Cancel).
class TaskListView extends StatelessWidget {
  final TaskStatus? statusFilter;
  final bool isLoading;
  final bool isOffline;

  const TaskListView({
    super.key,
    required this.statusFilter,
    required this.isLoading,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final auth = context.watch<AuthProvider>();

    final tasks = statusFilter == null
        ? taskProvider.allTasks
        : taskProvider.tasksByStatus(statusFilter!);

    return Column(
      children: [
        if (isOffline)
          Container(
            width: double.infinity,
            color: AppColors.accent.withValues(alpha: 0.15),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're offline — showing your saved tasks.",
                    style: TextStyle(fontSize: 12.5, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        if (statusFilter == null) _buildSummaryRow(context, taskProvider),
        Expanded(
          child: isLoading && tasks.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditTaskScreen(existingTask: task),
                        ),
                      ),
                      onDelete: () => taskProvider.deleteTask(
                        token: auth.token,
                        task: task,
                      ),
                      onStatusChange: (status) => taskProvider.updateStatus(
                        token: auth.token,
                        task: task,
                        newStatus: status,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, TaskProvider taskProvider) {
    Widget stat(String label, int count, Color color) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          stat(
            'In Progress',
            taskProvider.countByStatus(TaskStatus.inProgress),
            AppColors.accent,
          ),
          stat(
            'Completed',
            taskProvider.countByStatus(TaskStatus.completed),
            AppColors.success,
          ),
          stat(
            'Cancelled',
            taskProvider.countByStatus(TaskStatus.cancelled),
            AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final message = switch (statusFilter) {
      null => 'No tasks yet. Tap "New Task" to add your first one.',
      TaskStatus.inProgress => 'Nothing in progress right now.',
      TaskStatus.completed => 'No completed tasks yet.',
      TaskStatus.cancelled => 'No cancelled tasks.',
      TaskStatus.pending => 'No pending tasks.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 56,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
