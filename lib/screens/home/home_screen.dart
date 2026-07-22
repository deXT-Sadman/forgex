import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../profile/profile_screen.dart';
import 'task_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabInfo(label: 'Home', icon: Icons.home_rounded, status: null),
    _TabInfo(
      label: 'In Progress',
      icon: Icons.timelapse_rounded,
      status: TaskStatus.inProgress,
    ),
    _TabInfo(
      label: 'Completed',
      icon: Icons.check_circle_rounded,
      status: TaskStatus.completed,
    ),
    _TabInfo(
      label: 'Cancel',
      icon: Icons.cancel_rounded,
      status: TaskStatus.cancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final tab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label == 'Home' ? AppStrings.appName : tab.label),
        actions: [
          IconButton(
            tooltip: themeProvider.isDark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            icon: Icon(
              themeProvider.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: _profileImage(auth),
                child: _profileImage(auth) == null
                    ? Text(
                        (auth.currentUser?.username.isNotEmpty ?? false)
                            ? auth.currentUser!.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: TaskListView(statusFilter: tab.status),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _tabs
            .map(
              (t) =>
                  BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }

  ImageProvider? _profileImage(AuthProvider auth) {
    final user = auth.currentUser;
    if (user == null) return null;
    if (user.localProfileImagePath != null) {
      return FileImage(File(user.localProfileImagePath!));
    }
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return NetworkImage(user.profileImageUrl!);
    }
    return null;
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final TaskStatus? status; // null => Home (all tasks)
  const _TabInfo({
    required this.label,
    required this.icon,
    required this.status,
  });
}
