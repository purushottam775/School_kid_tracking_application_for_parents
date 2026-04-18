class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String roleSelection = '/role-selection';

  // Parent routes
  static const String parentHome = '/parent/home';
  static const String parentMap = '/parent/map';
  static const String parentNotifications = '/parent/notifications';
  static const String addStudent = '/parent/add-student';

  // Driver routes
  static const String driverHome = '/driver/home';
  static const String driverTrip = '/driver/trip';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStudents = '/admin/students';
  static const String adminBuses = '/admin/buses';
  static const String adminUsers = '/admin/users';
}
