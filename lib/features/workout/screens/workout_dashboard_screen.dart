import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/workout_plan.dart';
import '../widgets/workout_week_view.dart';

class WorkoutDashboardScreen extends StatefulWidget {
  const WorkoutDashboardScreen({super.key});

  @override
  State<WorkoutDashboardScreen> createState() => _WorkoutDashboardScreenState();
}

class _WorkoutDashboardScreenState extends State<WorkoutDashboardScreen> {
  final ApiService _apiService = ApiService();
  Future<WorkoutPlan?>? _workoutPlanFuture;
  bool _isInitialLoad = true; // Flag for initial load shimmer

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if mounted before accessing context after async gap
      if (mounted) {
         _loadWorkoutPlan();
      }
    });
  }

  Future<void> _loadWorkoutPlan({bool refresh = false}) async {
    // Ensure context is still valid before accessing Provider
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    final token = authProvider.token;

    if (userId == null || token == null) {
      debugPrint("WorkoutDashboard: Cannot load plan - User not logged in.");
      if (mounted) {
        setState(() {
          _workoutPlanFuture = Future.value(null); // Explicitly set to null future
          _isInitialLoad = false; // Stop shimmer if user logs out while viewing
        });
      }
      return;
    }

    // Set the future, triggering the FutureBuilder
    // If it's not a refresh triggered by the user, keep _isInitialLoad true
    // until the first data or error arrives.
    if (mounted) {
        setState(() {
             _workoutPlanFuture = _fetchPlan(userId, token);
             // Only set _isInitialLoad to true on the very first load attempt
             // or explicit refresh where we want shimmer again.
             // If _workoutPlanFuture was already set, don't reset shimmer unless refreshing.
             if (refresh || _workoutPlanFuture == null) {
                _isInitialLoad = true;
             }
        });
    }
  }

  Future<WorkoutPlan?> _fetchPlan(int userId, String token) async {
    debugPrint("Fetching workout plan for user $userId");
    try {
      final result = await _apiService.get(
        '${ApiConstants.getWorkoutPlanEndpoint}?user_id=$userId',
        token: token,
      );

      // Set _isInitialLoad to false once data fetch attempt completes (success or error)
      if (mounted) setState(() => _isInitialLoad = false);

      if (result['success'] == true && result['data'] != null) {
        if (result['data'] is Map<String, dynamic>) {
          try {
            return WorkoutPlan.fromJson(result['data'] as Map<String, dynamic>);
          } catch (e, stackTrace) {
            debugPrint("Error parsing workout plan data: $e\n$stackTrace");
            throw Exception("Failed to parse workout plan.");
          }
        } else {
          debugPrint("Workout plan data is not a Map: ${result['data'].runtimeType}");
          throw Exception("Invalid workout plan data format.");
        }
      } else {
        if (result['statusCode'] == 404) {
          debugPrint("No active workout plan found for user $userId.");
          return null; // Indicate no plan found (valid state)
        } else {
          debugPrint("Failed to fetch workout plan: ${result['message']} (Code: ${result['statusCode']})");
          throw Exception(result['message'] ?? "Failed to load workout plan.");
        }
      }
    } catch (e) {
       // Also set _isInitialLoad to false on network or other fetch errors
       if (mounted) setState(() => _isInitialLoad = false);
       debugPrint("Error in _fetchPlan: $e");
       // Re-throw the exception to be caught by FutureBuilder
       throw Exception("Could not connect or fetch plan. Please check your connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to potentially react to username changes if AuthProvider notifies listeners
    final userName = context.watch<AuthProvider>().user?.name.split(' ').first ?? 'there';
    final theme = Theme.of(context);

    return Scaffold(
      // Use a gradient background for the AppBar for visual flair
      appBar: AppBar(
        title: Text(
          'Hi $userName, Your Plan',
          style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold, color: Colors.white), // Ensure text is visible on gradient
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryWineRed, AppColors.primaryWineRedDark], // Replace with the correct dark color
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), // Ensure icon is visible
            onPressed: () => _loadWorkoutPlan(refresh: true),
            tooltip: 'Refresh Plan',
          ),
        ],
        elevation: 4.0, // Add subtle shadow
      ),
      body: Container(
         // Add a subtle gradient background to the body
         decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                    theme.scaffoldBackgroundColor,
                    theme.brightness == Brightness.light
                        ? AppColors.lightGrey.withOpacity(0.1)
                        : Colors.grey[800]!.withOpacity(0.2), // Subtle gradient
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
            ),
         ),
        child: RefreshIndicator(
          onRefresh: () => _loadWorkoutPlan(refresh: true),
          color: AppColors.primaryWineRed, // Progress indicator color
          child: FutureBuilder<WorkoutPlan?>(
            future: _workoutPlanFuture,
            builder: (context, snapshot) {
              // --- Loading State ---
              // Show shimmer only on initial load or explicit refresh
              if ((snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) || _workoutPlanFuture == null && _isInitialLoad) {
                 return _buildLoadingShimmer();
              }
              // Show small indicator for subsequent background refreshes if needed
              if (snapshot.connectionState == ConnectionState.waiting && !_isInitialLoad) {
                 // Optionally show a smaller indicator or nothing during background refresh
                 // return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                 // Or just show the old data until new data arrives
              }

              // --- Error State ---
              if (snapshot.hasError) {
                debugPrint("WorkoutDashboard FutureBuilder Error: ${snapshot.error}");
                return _buildErrorState(snapshot.error, theme);
              }

              // --- Data State (Success or No Plan Found) ---
              final workoutPlan = snapshot.data;

              // --- Empty State (No Plan Found) ---
              if (workoutPlan == null || workoutPlan.weeks.isEmpty) {
                return _buildEmptyPlanState(context, theme);
              }

              // --- Success State (Plan Loaded) ---
              return _buildContent(workoutPlan, theme);
            },
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView( // Allow scrolling if shimmer content exceeds screen
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling within shimmer
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer for Tabs
              Container(
                height: 40.0,
                width: double.infinity,
                decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(8.0)
                ),
              ),
              const SizedBox(height: 24.0),
              // Shimmer for Content Area (e.g., first day card)
              Container(
                height: 120.0,
                width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12.0)
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                height: 100.0,
                width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12.0)
                ),
              ),
               const SizedBox(height: 16.0),
               Container(
                height: 100.0,
                width: double.infinity,
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12.0)
                ),
              ),
              // Add more shimmer elements if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error, ThemeData theme) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(25.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.cloud_off_rounded, size: 70, color: AppColors.errorRed.withOpacity(0.8)),
             const SizedBox(height: 20),
             Text(
               'Oops! Something Went Wrong',
               style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 12),
             Text(
               // Provide a user-friendly message, hiding technical details unless needed
               // '${error}', // Use this for debugging if necessary
               'We couldn\'t load your workout plan. Please check your internet connection and try again.',
               style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 30),
             FilledButton.icon( // Use FilledButton for primary action
               icon: const Icon(Icons.refresh),
               label: const Text('Retry'),
               onPressed: () => _loadWorkoutPlan(refresh: true),
               style: FilledButton.styleFrom(
                 backgroundColor: AppColors.primaryWineRed,
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
               ),
             ),
           ],
         ),
       ),
     );
  }


  Widget _buildEmptyPlanState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 70, color: AppColors.primaryGrey.withOpacity(0.8)),
            const SizedBox(height: 20),
            Text(
              'Your Workout Plan Awaits!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Looks like you don't have an active plan yet. Complete your profile or subscribe to get started.",
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35),
            // Use FilledButton for the primary action
            FilledButton.icon(
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Set Up Profile'),
              onPressed: () => context.go('/questionnaire'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryWineRed,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
            const SizedBox(height: 15),
            // Use TextButton for the secondary action
            TextButton(
              onPressed: () => context.go('/subscribe'),
              child: const Text(
                "View Subscription Options",
                style: TextStyle(color: AppColors.primaryWineRed),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WorkoutPlan workoutPlan, ThemeData theme) {
      final sortedWeekKeys = workoutPlan.weeks.keys.toList()
        ..sort((a, b) => _parseWeekNumber(a).compareTo(_parseWeekNumber(b))); // Ensure weeks are sorted numerically

      return DefaultTabController(
        length: sortedWeekKeys.length,
        child: Column(
          children: [
            Container(
              color: theme.cardColor.withOpacity(0.8), // Slightly transparent card color
              child: TabBar(
                isScrollable: sortedWeekKeys.length > 4,
                tabs: sortedWeekKeys
                    .map((weekKey) => Tab(text: _formatWeekKey(weekKey)))
                    .toList(),
                labelColor: AppColors.primaryWineRed,
                unselectedLabelColor: AppColors.primaryGrey,
                indicatorColor: AppColors.primaryWineRed,
                indicatorWeight: 3.5, // Slightly thicker indicator
                indicatorSize: TabBarIndicatorSize.tab, // Indicator matches tab width
                labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Bold selected label
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: sortedWeekKeys.map((weekKey) {
                  final week = workoutPlan.weeks[weekKey]!;
                  final weekNum = _parseWeekNumber(weekKey);
                  // Use a unique key for each week view for efficient updates
                  return WorkoutWeekView(
                      key: ValueKey('week_$weekNum'), week: week, weekNumber: weekNum);
                }).toList(),
              ),
            ),
          ],
        ),
      );
  }

  String _formatWeekKey(String key) {
    final numPart = key.replaceAll(RegExp(r'[^0-9]'), '');
    return 'Week ${numPart.isNotEmpty ? numPart : '?'}';
  }

  int _parseWeekNumber(String key) {
    // Attempt to parse, default to a high number if unparsable to sort last
    return int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 9999;
  }
}