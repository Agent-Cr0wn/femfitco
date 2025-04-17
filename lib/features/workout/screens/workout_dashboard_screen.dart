import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/workout_plan.dart'; // Corrected import path assumption
import '../widgets/workout_week_view.dart';
// For debugPrint

class WorkoutDashboardScreen extends StatefulWidget {
  const WorkoutDashboardScreen({super.key});

  @override
  State<WorkoutDashboardScreen> createState() => _WorkoutDashboardScreenState();
}

class _WorkoutDashboardScreenState extends State<WorkoutDashboardScreen> {
  final ApiService _apiService = ApiService();
  // Use the correct type WorkoutPlan?
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
       if (mounted) { setState(() { _workoutPlanFuture = Future.value(null); }); }
       return;
     }

     if (mounted) {
         setState(() { _workoutPlanFuture = _fetchPlan(userId, token); });
     }
  }

  // Ensure return type matches Future declaration
  Future<WorkoutPlan?> _fetchPlan(int userId, String token) async {
    debugPrint("Fetching workout plan for user $userId");
    final result = await _apiService.get(
      '${ApiConstants.getWorkoutPlanEndpoint}?user_id=$userId', token: token, );

    if (result['success'] == true && result['data'] != null) {
      if (result['data'] is Map<String, dynamic>) {
         try {
           return WorkoutPlan.fromJson(result['data'] as Map<String, dynamic>);
         } catch (e) {
            debugPrint("Error parsing workout plan data: $e");
            throw Exception("Failed to parse workout plan."); // Throw for FutureBuilder error state
         }
      } else {
         debugPrint("Workout plan data is not a Map: ${result['data'].runtimeType}");
         throw Exception("Invalid workout plan data."); // Throw for FutureBuilder error state
      }
    } else {
      if (result['statusCode'] == 404) {
         debugPrint("No active workout plan found for user $userId.");
         return null; // Indicate no plan found
      } else {
         debugPrint("Failed to fetch workout plan: ${result['message']} (Code: ${result['statusCode']})");
          throw Exception(result['message'] ?? "Failed to load workout plan."); // Throw error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthProvider>().user?.name.split(' ').first ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi $userName, Your Plan'),
        actions: [ IconButton( icon: const Icon(Icons.refresh), onPressed: () => _loadWorkoutPlan(refresh: true), tooltip: 'Refresh Plan', ), ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadWorkoutPlan(refresh: true),
        color: AppColors.primaryWineRed,
        // Use correct type argument for FutureBuilder
        child: FutureBuilder<WorkoutPlan?>(
          future: _workoutPlanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _workoutPlanFuture != null) { // Only show loader if future is set
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              debugPrint("WorkoutDashboard FutureBuilder Error: ${snapshot.error}");
              return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColors.errorRed), const SizedBox(height: 16),
                  Text( 'Error Loading Plan', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center,), const SizedBox(height: 10),
                  Text( '${snapshot.error}', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center,), const SizedBox(height: 20),
                  ElevatedButton.icon( icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: () => _loadWorkoutPlan(refresh: true),),],),),);
            }
            // Check snapshot.data explicitly for null before accessing properties
            final workoutPlan = snapshot.data;
            if (workoutPlan == null || workoutPlan.weeks.isEmpty) {
              return _buildEmptyPlanState(context);
            }

            // Use workoutPlan directly now
            final sortedWeekKeys = workoutPlan.weeks.keys.toList();

            return DefaultTabController(
              length: sortedWeekKeys.length,
              child: Column( children: [
                  Container( color: Theme.of(context).cardColor, child: TabBar( isScrollable: sortedWeekKeys.length > 4, tabs: sortedWeekKeys.map((weekKey) => Tab(text: _formatWeekKey(weekKey))).toList(), labelColor: AppColors.primaryWineRed, unselectedLabelColor: AppColors.primaryGrey, indicatorColor: AppColors.primaryWineRed, indicatorWeight: 3.0,),),
                  Expanded( child: TabBarView( children: sortedWeekKeys.map((weekKey) {
                      final week = workoutPlan.weeks[weekKey]!;
                      final weekNum = _parseWeekNumber(weekKey);
                      return WorkoutWeekView(key: ValueKey('week_$weekNum'), week: week, weekNumber: weekNum);
                  }).toList(),),),
              ],),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyPlanState(BuildContext context) {
     return Center( child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.calendar_today_outlined, size: 60, color: AppColors.lightGrey), const SizedBox(height: 16),
          Text( 'No Workout Plan Yet!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ), const SizedBox(height: 10),
          Text( "Complete your fitness profile and subscribe to get your personalized plan.", style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center, ), const SizedBox(height: 30),
          ElevatedButton.icon( icon: const Icon(Icons.list_alt_outlined), label: const Text('Go to Profile Setup'), onPressed: () => context.go('/questionnaire'), style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12) ), ), const SizedBox(height: 16),
          TextButton( onPressed: () => context.go('/subscribe'), child: const Text("View Subscription Options"), ) ],),),);
  }

  String _formatWeekKey(String key) {
    final numPart = key.replaceAll(RegExp(r'[^0-9]'), '');
    return 'Week ${numPart.isNotEmpty ? numPart : '?'}';
  }
  int _parseWeekNumber(String key) {
    return int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}