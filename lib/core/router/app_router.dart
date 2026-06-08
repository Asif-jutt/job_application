import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/company/screens/company_chat_screen.dart';
import '../../features/company/screens/company_home_screen.dart';
import '../../features/user/screens/user_chat_screen.dart';
import '../../features/user/screens/user_home_screen.dart';
import '../../features/user/screens/user_job_detail_screen.dart';
import '../constants/route_constants.dart';
import '../models/job_model.dart';
import '../models/user_role.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.register;
      final isSplash = state.matchedLocation == RouteConstants.splash;

      if (isLoading && isSplash) return null;
      if (isLoading) return RouteConstants.splash;

      if (user == null) {
        return isAuthRoute || isSplash ? null : RouteConstants.login;
      }

      if (isAuthRoute || isSplash) {
        return _homeForRole(user.role);
      }

      return _guardRoute(state.matchedLocation, user.role);
    },
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (_, _) => const RegisterScreen(),
      ),

      // User routes
      GoRoute(
        path: RouteConstants.userHome,
        builder: (_, _) => const UserHomeScreen(),
        routes: [
          GoRoute(
            path: 'jobs/:jobId',
            builder: (context, state) {
              final job = state.extra as JobModel?;
              if (job != null) return UserJobDetailScreen(job: job);
              return const Scaffold(
                body: Center(child: Text('Job not found')),
              );
            },
          ),
          GoRoute(
            path: 'chats/:chatId',
            builder: (_, state) => UserChatScreen(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
        ],
      ),

      // Company routes
      GoRoute(
        path: RouteConstants.companyHome,
        builder: (_, _) => const CompanyHomeScreen(),
        routes: [
          GoRoute(
            path: 'chats/:chatId',
            builder: (_, state) => CompanyChatScreen(
              chatId: state.pathParameters['chatId']!,
            ),
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: RouteConstants.adminHome,
        builder: (_, _) => const AdminHomeScreen(),
      ),
    ],
  );
});

String _homeForRole(UserRole role) => switch (role) {
      UserRole.user => RouteConstants.userHome,
      UserRole.company => RouteConstants.companyHome,
      UserRole.admin => RouteConstants.adminHome,
    };

String? _guardRoute(String location, UserRole role) {
  final userPrefix = RouteConstants.userHome;
  final companyPrefix = RouteConstants.companyHome;
  final adminPrefix = RouteConstants.adminHome;

  return switch (role) {
    UserRole.user when !location.startsWith(userPrefix) => userPrefix,
    UserRole.company when !location.startsWith(companyPrefix) => companyPrefix,
    UserRole.admin when !location.startsWith(adminPrefix) => adminPrefix,
    _ => null,
  };
}
