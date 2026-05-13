import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/client/home/screens/home_screen.dart';
import '../../features/client/explore/screens/explore_screen.dart';
import '../../features/client/vehicle_detail/screens/vehicle_detail_screen.dart';
import '../../features/client/booking/screens/period_selection_screen.dart';
import '../../features/client/booking/screens/checkout_screen.dart';
import '../../features/client/reservations/screens/my_reservations_screen.dart';
import '../../features/client/reservations/screens/reservation_detail_screen.dart';
import '../../features/client/profile/screens/profile_screen.dart';
import '../models/reserva.dart';
import '../../features/manager/dashboard/screens/dashboard_screen.dart';
import '../../features/manager/reservations/screens/reservations_screen.dart';
import '../../features/manager/inventory/screens/inventory_screen.dart';
import '../../features/manager/inventory/screens/add_vehicle_screen.dart';
import '../../features/manager/inventory/screens/edit_vehicle_screen.dart';
import '../../features/manager/clients/screens/clients_screen.dart';
import '../../features/manager/insurance/screens/insurance_screen.dart';
import '../../features/manager/settings/screens/manager_settings_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_create_manager_screen.dart';
import '../models/veiculo.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final bool loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (authProvider.isLoading) return null;

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
      
      // Rotas do Cliente
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/vehicle-detail',
        builder: (context, state) {
          final vehicle = state.extra as Veiculo;
          return VehicleDetailScreen(veiculo: vehicle);
        },
      ),
      GoRoute(
        path: '/booking-period',
        builder: (context, state) => const PeriodSelectionScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/my-reservations',
        builder: (context, state) => const MyReservationsScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final reserva = state.extra as Reserva;
              return ReservationDetailScreen(reserva: reserva);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Rotas do Gerente / Admin
      GoRoute(
        path: '/manager',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          // Sub-rotas de Admin (dentro de /manager para manter o Scaffold)
          GoRoute(
            path: 'admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'admin/create-manager',
            builder: (context, state) => const AdminCreateManagerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/manager/reservations',
        builder: (context, state) => const ReservationsScreen(),
      ),
      GoRoute(
        path: '/manager/inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddVehicleScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final vehicle = state.extra as Veiculo;
              return EditVehicleScreen(veiculo: vehicle);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/manager/clients',
        builder: (context, state) => const ClientsScreen(),
        routes: [
          GoRoute(
            path: 'reservations',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ReservationsScreen(
                clienteId: extra?['clienteId'] as String?,
                clienteNome: extra?['clienteNome'] as String?,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/manager/insurance',
        builder: (context, state) => const InsuranceScreen(),
      ),
      GoRoute(
        path: '/manager/settings',
        builder: (context, state) => const ManagerSettingsScreen(),
      ),
    ],
  );
}
