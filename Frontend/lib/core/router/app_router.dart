import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/client/home/screens/home_screen.dart';
import '../../features/manager/dashboard/screens/dashboard_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: null, // Será configurado no app.dart ou via provider
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final bool loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!authProvider.isAuthenticated && !loggingIn && state.matchedLocation != '/') {
        return '/login';
      }

      if (authProvider.isAuthenticated && loggingIn) {
        return authProvider.isManager ? '/manager' : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/manager',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}
