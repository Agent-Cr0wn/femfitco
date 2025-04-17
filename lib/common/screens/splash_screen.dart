import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/colors.dart'; // Import colors

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // AuthProvider attempts auto-login in its constructor.
    // GoRouter's redirect logic will handle navigation once AuthProvider's state changes.
    // No need for explicit navigation logic here.
  }

  @override
  Widget build(BuildContext context) {
    // Watching the provider ensures this screen might update if needed,
    // although redirects usually happen before significant rebuilds.
    context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey, // Use theme background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional: Add your app logo here
            // Image.asset('assets/images/logo.png', height: 100),
            // const SizedBox(height: 30),
            const CircularProgressIndicator(
               valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryWineRed),
            ),
            const SizedBox(height: 20),
            Text(
              "Initializing FemFit Collective...",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primaryGrey),
            ),
          ],
        ),
      ),
    );
  }
}