import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutPlan();
    });
  }

  Future<void> _loadWorkoutPlan({bool refresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    final token = authProvider.token;

    if (userId == null || token == null) {
      debugPrint("WorkoutDashboard: Cannot load plan - User not logged in.");
      if (mounted) {
        setState(() {
          _workoutPlanFuture = Future.value(null);
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _workoutPlanFuture = _fetchPlan(userId, token);
      });
    }
  }

  Future<WorkoutPlan?> _fetchPlan(int userId, String token) async {
    debugPrint("Fetching workout plan for user $userId");
    final result = await _apiService.get(
      '${ApiConstants.getWorkoutPlanEndpoint}?user_id=$userId',
      token: token,
    );

    if (result['success'] == true && result['data'] != null) {
      if (result['data'] is Map<String, dynamic>) {
        try {
          return WorkoutPlan.fromJson(result['data'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint("Error parsing workout plan data: $e");
          throw Exception("Failed to parse workout plan.");
        }
      } else {
        debugPrint("Workout plan data is not a Map: ${result['data'].runtimeType}");
        throw Exception("Invalid workout plan data.");
      }
    } else {
      if (result['statusCode'] == 404) {
        debugPrint("No active workout plan found for user $userId.");
        return null;
      } else {
        debugPrint("Failed to fetch workout plan: ${result['message']} (Code: ${result['statusCode']})");
        throw Exception(result['message'] ?? "Failed to load workout plan.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?.name.split(' ').first ?? 'there';

    return Scaffold(
      body: Stack(
        children: [
          // Background image with wine red filter and overlay
          Positioned.fill(
            child: Stack(
              children: [
                // Base image
                Image.asset(
                  'assets/images/workout_bg.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Wine red filter
                Container(
                  color: AppColors.primaryWineRed.withOpacity(0.3),
                ),
                // White gradient overlay for readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Column(
            children: [
              // Custom App Bar with transparent background
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryWineRed.withOpacity(0.9),
                      AppColors.primaryWineRed.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi $userName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your Fitness Journey',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () => _loadWorkoutPlan(refresh: true),
                      tooltip: 'Refresh Plan',
                    ),
                  ],
                ),
              ),
              
              // Main content area
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadWorkoutPlan(refresh: true),
                  color: AppColors.primaryWineRed,
                  child: FutureBuilder<WorkoutPlan?>(
                    future: _workoutPlanFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _workoutPlanFuture != null) {
                        return _buildLoadingState();
                      }
                      if (snapshot.hasError) {
                        return _buildErrorState(context, snapshot.error);
                      }
                      
                      final workoutPlan = snapshot.data;
                      if (workoutPlan == null || workoutPlan.weeks.isEmpty) {
                        return _buildEmptyPlanState(context);
                      }

                      final sortedWeekKeys = workoutPlan.weeks.keys.toList();

                      return DefaultTabController(
                        length: sortedWeekKeys.length,
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: TabBar(
                                isScrollable: sortedWeekKeys.length > 4,
                                tabs: sortedWeekKeys.map((weekKey) => Tab(text: _formatWeekKey(weekKey))).toList(),
                                labelColor: AppColors.primaryWineRed,
                                unselectedLabelColor: AppColors.primaryGrey,
                                indicatorColor: AppColors.primaryWineRed,
                                indicatorSize: TabBarIndicatorSize.label,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                                padding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: TabBarView(
                                  children: sortedWeekKeys.map((weekKey) {
                                    final week = workoutPlan.weeks[weekKey]!;
                                    final weekNum = _parseWeekNumber(weekKey);
                                    return WorkoutWeekView(
                                      key: ValueKey('week_$weekNum'),
                                      week: week,
                                      weekNumber: weekNum,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryWineRed),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your workout plan...',
            style: TextStyle(
              color: AppColors.primaryGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    debugPrint("WorkoutDashboard FutureBuilder Error: $error");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '$error',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () => _loadWorkoutPlan(refresh: true),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlanState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 60,
                    color: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Workout Plan Yet!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Complete your fitness profile and subscribe to get your personalized plan.",
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Go to Profile Setup'),
                  onPressed: () => context.go('/questionnaire'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/subscribe'),
                  child: const Text("View Subscription Options"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatWeekKey(String key) {
    final numPart = key.replaceAll(RegExp(r'[^0-9]'), '');
    return 'Week ${numPart.isNotEmpty ? numPart : '?'}';
  }

  int _parseWeekNumber(String key) {
    return int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}