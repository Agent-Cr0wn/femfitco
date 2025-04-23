import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint and kDebugMode
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/questionnaire/screens/questionnaire_screen.dart';
import '../features/workout/screens/workout_dashboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/subscription/screens/subscription_screen.dart';
import '../common/widgets/bottom_nav_scaffold.dart';
import '../common/screens/splash_screen.dart';
import '../features/progress/screens/progress_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  // createRouter accepts the AuthProvider for refreshListenable
  static GoRouter createRouter(AuthProvider authProviderForListenable) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: kDebugMode,

      // Use the passed AuthProvider instance for listening to changes
      refreshListenable: authProviderForListenable,

      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Other top-level routes
        GoRoute(
          path: '/questionnaire',
          name: 'questionnaire',
          builder: (context, state) => const QuestionnaireScreen(),
        ),
        GoRoute(
          path: '/subscribe',
          name: 'subscribe',
          builder: (context, state) => const SubscriptionScreen(),
        ),

        // Main Application Structure with Bottom Navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return BottomNavScaffold(child: child);
          },
          routes: [
            GoRoute(
              path: '/workout',
              name: 'workout',
              builder: (context, state) => const WorkoutDashboardScreen(),
            ),
            GoRoute(
              path: '/progress',
              name: 'progress',
              builder: (context, state) => const ProgressScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],

      // --- CORRECTED REDIRECT LOGIC ---
      redirect: (BuildContext context, GoRouterState state) {
        // Use context.read inside the redirect callback to get the current provider state
        final authProvider = context.read<AuthProvider>();
        final bool loggedIn = authProvider.isLoggedIn;
        final bool isLoading = authProvider.isLoading;

        final String location = state.matchedLocation;
        final bool isSplash = location == '/splash';
        final bool isAuthRoute = location == '/login' || location == '/register';

        debugPrint("Router Redirect: Location=$location, LoggedIn=$loggedIn, Loading=$isLoading");

        // 1. While loading is true, *always* stay on splash
        if (isLoading) {
          return isSplash ? null : '/splash';
        }

        // --- After Loading ---

        // 2. If NOT logged in:
        if (!loggedIn) {
          // If trying to access auth routes, allow. Otherwise, redirect to login.
          return isAuthRoute ? null : '/login';
        }

        // 3. If logged IN:
        if (loggedIn) {
          // If on splash or auth routes, redirect to the main app. Otherwise, allow.
          return (isSplash || isAuthRoute) ? '/workout' : null;
        }

        // Fallback
        return null;
      },
      // --- END OF CORRECTED REDIRECT ---
    );
  }
}