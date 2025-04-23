import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import '../constants/colors.dart';

class BottomNavScaffold extends StatefulWidget {
  final Widget child;
  const BottomNavScaffold({super.key, required this.child});

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  // Calculates the selected index based on the current route location
    int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/workout')) {
      return 0;
    }
    if (location.startsWith('/progress')) {
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    return 0; // Default to the first tab if no match
  }

  // Handles navigation when a bottom nav item is tapped
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/workout');
        break;
      case 1:
        context.go('/progress');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the current index based on the route
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child, // The actual screen content for the current route
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        // Use theme settings for colors and styles
        // backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        // selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        // unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        // selectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.selectedLabelStyle,
        // unselectedLabelStyle: Theme.of(context).bottomNavigationBarTheme.unselectedLabelStyle,
        // type: Theme.of(context).bottomNavigationBarTheme.type,
        // showSelectedLabels: true,
        // showUnselectedLabels: true,
      ),
    );
  }
}