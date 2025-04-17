import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'app/router.dart';
import 'common/constants/colors.dart';
import 'features/auth/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Create AuthProvider instance once
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const FemFitApp(),
    ),
  );
}

class FemFitApp extends StatefulWidget {
  const FemFitApp({super.key});

  @override
  State<FemFitApp> createState() => _FemFitAppState();
}

class _FemFitAppState extends State<FemFitApp> {
  late final GoRouter _router; // Store the router instance

  @override
  void initState() {
    super.initState();
    // Create the router here, passing the AuthProvider instance
    // Use context.read because initState is called once before build
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FemFit Collective',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Color Scheme (Adjusted based on deprecation warnings)
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryWineRed,
          primary: AppColors.primaryWineRed,
          secondary: AppColors.accentWineRed,
          // Use surface/surfaceVariant for backgrounds typically
          surface: Colors.white, // Card backgrounds, dialogs etc.
          onPrimary: AppColors.textLight,
          onSecondary: AppColors.textLight,
          onSurface: AppColors.textDark, // Text on surface (white)
          onSurfaceVariant: AppColors.textDark, // Text on backgroundGrey
          error: AppColors.errorRed, // Use defined error color
          onError: AppColors.textLight,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.backgroundGrey, // Explicit background color

        // Typography
        fontFamily: 'Georgia',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: AppColors.primaryGrey),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: AppColors.primaryGrey),
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: AppColors.textDark),
          labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textLight),
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGrey,
          foregroundColor: AppColors.textLight,
          elevation: 2.0,
          titleTextStyle: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.textLight, fontFamily: 'Georgia'),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryWineRed,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
             shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

         // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(8),
             borderSide: const BorderSide(color: AppColors.lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(8),
             borderSide: const BorderSide(color: AppColors.primaryWineRed, width: 2),
          ),
           labelStyle: const TextStyle(color: AppColors.primaryGrey),
           hintStyle: const TextStyle(color: AppColors.lightGrey),
           contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0)
        ),

         // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primaryWineRed,
          unselectedItemColor: AppColors.primaryGrey,
          backgroundColor: Colors.white, // Explicit background
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),

         // Card Theme
         cardTheme: CardTheme(
           elevation: 1.0,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
           ),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            color: Colors.white, // Explicit card color
         ),

         // Progress Indicator Theme
         progressIndicatorTheme: const ProgressIndicatorThemeData(
           color: AppColors.primaryWineRed,
         ),

        useMaterial3: true,
      ),
      // Use the router instance created in initState
      routerConfig: _router,
    );
  }
}