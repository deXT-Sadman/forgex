import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    ImageProvider? avatar;
    if (user?.localProfileImagePath != null) {
      avatar = FileImage(File(user!.localProfileImagePath!));
    } else if (user?.profileImageUrl != null &&
        user!.profileImageUrl!.isNotEmpty) {
      avatar = NetworkImage(user.profileImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    backgroundImage: avatar,
                    child: avatar == null
                        ? Text(
                            (user?.username.isNotEmpty ?? false)
                                ? user!.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.username ?? 'Guest',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Edit Profile',
              icon: Icons.edit_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 14),
            CustomButton(
              label: 'Log Out',
              icon: Icons.logout_rounded,
              isOutlined: true,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                      'You can sign back in anytime. Your tasks are saved.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<TaskProvider>().clear();
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
