/// Central place to configure your backend.
///
/// Flutter apps cannot talk to MongoDB directly (there is no safe client-side
/// driver) — you need a small REST API in front of it (e.g. Node.js +
/// Express + Mongoose). Point this at that API's base URL.
class ApiConfig {
  // TODO: replace with your deployed API base URL.
  static const String baseUrl = 'https://your-api-domain.com/api';

  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String signupEndpoint = '$baseUrl/auth/signup';
  static const String forgotPasswordEndpoint = '$baseUrl/auth/forgot-password';
  static const String updateProfileEndpoint = '$baseUrl/users/me';

  static const String tasksEndpoint = '$baseUrl/tasks';

  static const Duration requestTimeout = Duration(seconds: 12);
}

/// SharedPreferences keys used across the app for offline support.
class PrefsKeys {
  static const String authToken = 'auth_token';
  static const String currentUser = 'current_user';
  static const String cachedTasks = 'cached_tasks';
  static const String themeMode = 'theme_mode';
  static const String pendingTaskOps = 'pending_task_ops';
}

class AppStrings {
  static const String appName = 'Forgex';
  static const String tagline = 'Plan it. Do it. ForgeX.';
}
