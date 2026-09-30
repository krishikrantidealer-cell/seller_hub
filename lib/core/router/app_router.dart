import 'package:go_router/go_router.dart';
import '../../presentation/auth/views/login_view.dart';
import '../../presentation/dashboard/views/dashboard_view.dart';
import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardView(),
      ),
    ],
  );
}
