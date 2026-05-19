import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/feedback/app_feedback.dart';
import 'core/widgets/app_loading_overlay.dart';
import 'package:go_router/go_router.dart';
import 'calls/api_core.dart';
import 'features/client/explore/providers/explore_provider.dart';
import 'features/client/booking/providers/booking_provider.dart';
import 'features/manager/inventory/providers/inventory_provider.dart';
import 'features/manager/reservations/providers/reservations_provider.dart';
import 'features/manager/clients/providers/clients_provider.dart';
import 'features/manager/insurance/providers/insurance_provider.dart';
import 'features/client/reservations/providers/my_reservations_provider.dart';
import 'features/manager/dashboard/providers/dashboard_provider.dart';
import 'features/filial/services/ifilial_service.dart';
import 'features/filial/services/filial_service.dart';
import 'features/filial/services/mock_filial_service.dart';

import 'features/auth/services/iauth_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/mock_auth_service.dart';

import 'features/client/booking/services/ibooking_service.dart';
import 'features/client/booking/services/booking_service.dart';
import 'features/client/booking/services/mock_booking_service.dart';

import 'features/manager/reservations/services/ireservation_manager_service.dart';
import 'features/manager/reservations/services/reservation_manager_service.dart';
import 'features/manager/reservations/services/mock_reservation_manager_service.dart';

import 'features/client/explore/services/iexplore_service.dart';
import 'features/client/explore/services/explore_service.dart';
import 'features/client/explore/services/mock_explore_service.dart';

import 'features/manager/inventory/services/iinventory_service.dart';
import 'features/manager/inventory/services/inventory_service.dart';
import 'features/manager/inventory/services/mock_inventory_service.dart';

import 'features/manager/clients/services/iclient_manager_service.dart';
import 'features/manager/clients/services/client_manager_service.dart';
import 'features/manager/clients/services/mock_client_manager_service.dart';

import 'features/manager/dashboard/services/idashboard_service.dart';
import 'features/manager/dashboard/services/dashboard_service.dart';
import 'features/manager/dashboard/services/mock_dashboard_service.dart';

import 'features/manager/insurance/services/iinsurance_service.dart';
import 'features/manager/insurance/services/insurance_service.dart';
import 'features/manager/insurance/services/mock_insurance_service.dart';

import 'features/admin/providers/admin_provider.dart';
import 'features/admin/services/iadmin_service.dart';
import 'features/admin/services/admin_service.dart';
import 'features/admin/services/mock_admin_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class DriveConnectApp extends StatelessWidget {
  const DriveConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bool useMock = false; // Toggle centralizado

    // Configure session expiry handler (JWT 401 → logout)
    onSessionExpired = () {
      final ctx = AppRouter.rootNavigatorKey.currentContext;
      if (ctx != null) {
        ctx.read<AuthProvider>().logout().then((_) {
          if (ctx.mounted) ctx.go('/login');
        });
      }
    };
    
    // Services: no longer require ApiClient, they use the calls layer internally
    final IAuthService authService = useMock
        ? MockAuthService()
        : AuthService();

    final IExploreService exploreService = useMock
        ? MockExploreService()
        : ExploreService();

    final IBookingService bookingService = useMock 
        ? MockBookingService() 
        : BookingService();

    final IReservationManagerService reservationManagerService = useMock
        ? MockReservationManagerService()
        : ReservationManagerService();

    final IInventoryService inventoryService = useMock
        ? MockInventoryService()
        : InventoryService();

    final IClientManagerService clientManagerService = useMock
        ? MockClientManagerService()
        : ClientManagerService();

    final IDashboardService dashboardService = useMock
        ? MockDashboardService()
        : DashboardService();

    final IInsuranceService insuranceService = useMock
        ? MockInsuranceService()
        : InsuranceService();
        
    final IAdminService adminService = useMock
        ? MockAdminService()
        : AdminService();

    final IFilialService filialService = useMock
        ? MockFilialService()
        : FilialService();

    return MultiProvider(
      providers: [
        Provider<IFilialService>.value(value: filialService),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(
          create: (_) => ExploreProvider(exploreService),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(bookingService),
        ),
        ChangeNotifierProvider(create: (_) => InventoryProvider(inventoryService)),
        ChangeNotifierProvider(create: (_) => ReservationsProvider(reservationManagerService)),
        ChangeNotifierProvider(create: (_) => ClientsProvider(clientManagerService)),
        ChangeNotifierProvider(create: (_) => InsuranceProvider(insuranceService)),
        ChangeNotifierProvider(create: (_) => MyReservationsProvider(bookingService)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardService)),
        ChangeNotifierProvider(create: (_) => AdminProvider(adminService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Drive Connect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            scrollBehavior: const AppScrollBehavior(),
            scaffoldMessengerKey: AppFeedback.messengerKey,
            builder: (context, child) => AppLoadingOverlay(child: child ?? const SizedBox.shrink()),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
