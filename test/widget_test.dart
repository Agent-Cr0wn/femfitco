import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:femfit_collective/main.dart'; // Import your main app file
import 'package:femfit_collective/features/auth/providers/auth_provider.dart';
import 'package:femfit_collective/common/screens/splash_screen.dart'; // Import SplashScreen

void main() {
  testWidgets('App starts and shows splash screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
       ChangeNotifierProvider(
         create: (_) => AuthProvider(),
         child: const FemFitApp(), // Use the correct app widget name
       ),
    );

    // Verify that the splash screen shows initially.
    expect(find.byType(SplashScreen), findsOneWidget); // Check if SplashScreen is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // Check for loading indicator

  });
}