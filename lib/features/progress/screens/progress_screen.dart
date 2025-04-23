import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../common/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/progress_measurement.dart';
import '../providers/progress_provider.dart';
import '../widgets/measurement_input_dialog.dart';
import '../widgets/progress_card.dart';
import '../widgets/achievement_badge.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Reduced from 4 to 3 tabs
    
    // Fetch progress data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final token = authProvider.token;
      
      if (userId != null && token != null) {
        progressProvider.fetchProgressData(userId: userId, token: token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddMeasurementDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId != null) {
      showDialog(
        context: context,
        builder: (context) => MeasurementInputDialog(userId: userId),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add measurements')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ProgressProvider>(context);
    final userName = context.read<AuthProvider>().user?.name.split(' ').first ?? 'there';
    
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Background with image and wine red overlay (fills the whole screen)
          Positioned.fill(
            child: Stack(
              children: [
                // Base image
                Image.asset(
                  'assets/images/progress_bg.jpg',
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
          SafeArea(
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 180.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primaryWineRed, // <-- FIXED: solid color for collapsed state
                    elevation: 0,
                    flexibleSpace: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        // Calculate the collapse percentage
                        final double expandedHeight = 180.0;
                        final double t = ((constraints.maxHeight - kToolbarHeight) / (expandedHeight - kToolbarHeight)).clamp(0.0, 1.0);

                        return FlexibleSpaceBar(
                          background: Opacity(
                            opacity: t,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primaryWineRed.withOpacity(0.9),
                                    AppColors.primaryWineRed.withOpacity(0.6),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi $userName!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Track your fitness journey and celebrate your wins.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'Your Progress Journey',
                            style: TextStyle(
                              color: innerBoxIsScrolled ? AppColors.textLight : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          collapseMode: CollapseMode.parallax,
                        );
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final userId = authProvider.user?.id;
                          final token = authProvider.token;
                          
                          if (userId != null && token != null) {
                            progressProvider.fetchProgressData(userId: userId, token: token);
                          }
                        },
                        tooltip: 'Refresh Data',
                      ),
                    ],
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryWineRed,
                        unselectedLabelColor: AppColors.primaryGrey,
                        indicatorColor: AppColors.primaryWineRed,
                        indicatorWeight: 3,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * 0.028, // Responsive
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: MediaQuery.of(context).size.width * 0.028, // Responsive
                        ),
                        tabs: const [
                          Tab(text: 'OVERVIEW'),
                          Tab(text: 'MEASUREMENTS'),
                          Tab(text: 'ACHIEVEMENTS'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: Container(
                color: Colors.transparent, // <-- Make transparent to show background
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // OVERVIEW TAB
                    _buildOverviewTab(progressProvider),
                    
                    // MEASUREMENTS TAB
                    _buildMeasurementsTab(progressProvider),
                    
                    // ACHIEVEMENTS TAB
                    _buildAchievementsTab(progressProvider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: progressProvider.isLoading
          ? null
          : FloatingActionButton(
              onPressed: _showAddMeasurementDialog,
              backgroundColor: AppColors.primaryWineRed,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildOverviewTab(ProgressProvider progressProvider) {
    final measurements = progressProvider.measurements;
    
    if (progressProvider.isLoading) {
      return _buildLoadingState();
    }
    
    if (measurements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'No Progress Data Yet',
        message: 'Start tracking your progress by adding your measurements.',
        buttonText: 'Add First Measurement',
        onPressed: _showAddMeasurementDialog,
      );
    }
    
    // Get latest and initial measurements for comparison
    final latest = measurements.first;
    final initial = measurements.last;
    
    // Calculate difference
    final weightDiff = latest.weight - initial.weight;
    final bodyFatDiff = latest.bodyFatPercentage != null && initial.bodyFatPercentage != null
        ? latest.bodyFatPercentage! - initial.bodyFatPercentage!
        : null;
    
    // Format dates
    final dateFormat = DateFormat.yMMMd();
    final startDate = dateFormat.format(initial.date);
    final latestDate = dateFormat.format(latest.date);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$startDate - $latestDate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Summary Metrics
                  _buildMetricTile(
                    title: 'Weight Change',
                    value: '${weightDiff.toStringAsFixed(1)} kg',
                    isPositive: weightDiff <= 0, // Weight loss is considered positive
                    icon: Icons.monitor_weight_outlined,
                  ),
                  if (bodyFatDiff != null)
                    _buildMetricTile(
                      title: 'Body Fat Change',
                      value: '${bodyFatDiff.toStringAsFixed(1)}%',
                      isPositive: bodyFatDiff <= 0, // Fat loss is considered positive
                      icon: Icons.accessibility_new_outlined,
                    ),
                  _buildMetricTile(
                    title: 'Workouts Completed',
                    value: '${progressProvider.workoutsCompleted}',
                    isPositive: true,
                    icon: Icons.fitness_center_outlined,
                  ),
                  _buildMetricTile(
                    title: 'Days Tracked',
                    value: '${measurements.length}',
                    isPositive: true,
                    icon: Icons.calendar_today_outlined,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Weight Chart
          const Text(
            'Weight Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 250,
                child: _buildWeightChart(measurements),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Body Stats Row
          Row(
            children: [
              Expanded(
                child: ProgressCard(
                  title: 'Current Weight',
                  value: '${latest.weight} kg',
                  icon: Icons.monitor_weight_outlined,
                  color: AppColors.primaryWineRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProgressCard(
                  title: 'Body Fat',
                  value: latest.bodyFatPercentage != null ? '${latest.bodyFatPercentage}%' : 'Not set',
                  icon: Icons.accessibility_new_outlined,
                  color: AppColors.accentWineRed,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Body Measurements Row
          Row(
            children: [
              Expanded(
                child: ProgressCard(
                  title: 'Chest',
                  value: latest.chest != null ? '${latest.chest} cm' : 'Not set',
                  icon: Icons.straighten_outlined,
                  color: AppColors.primaryGrey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProgressCard(
                  title: 'Waist',
                  value: latest.waist != null ? '${latest.waist} cm' : 'Not set',
                  icon: Icons.straighten_outlined,
                  color: AppColors.primaryGrey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // More Body Measurements Row
          Row(
            children: [
              Expanded(
                child: ProgressCard(
                  title: 'Hips',
                  value: latest.hips != null ? '${latest.hips} cm' : 'Not set',
                  icon: Icons.straighten_outlined,
                  color: AppColors.primaryGrey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ProgressCard(
                  title: 'Thighs',
                  value: latest.thighs != null ? '${latest.thighs} cm' : 'Not set',
                  icon: Icons.straighten_outlined,
                  color: AppColors.primaryGrey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab(ProgressProvider progressProvider) {
    final measurements = progressProvider.measurements;
    
    if (progressProvider.isLoading) {
      return _buildLoadingState();
    }
    
    if (measurements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.straighten_outlined,
        title: 'No Measurements Yet',
        message: 'Track your body measurements to see your progress over time.',
        buttonText: 'Add Measurements',
        onPressed: _showAddMeasurementDialog,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        final dateFormat = DateFormat.yMMMd();
        final formattedDate = dateFormat.format(measurement.date);
        
        // Calculate difference if not the last entry
        String? weightDiff;
        if (index < measurements.length - 1) {
          final prevMeasurement = measurements[index + 1];
          final diff = measurement.weight - prevMeasurement.weight;
          weightDiff = diff > 0 ? '+${diff.toStringAsFixed(1)}' : '${diff.toStringAsFixed(1)}';
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryWineRed.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppColors.primaryWineRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (index == 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWineRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Latest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Text('Weight: ${measurement.weight} kg'),
                if (weightDiff != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      weightDiff,
                      style: TextStyle(
                        color: weightDiff.startsWith('-') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: index == 0
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDeleteMeasurement(measurement),
                  ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    _buildMeasurementDetailRow(
                      'Body Fat',
                      measurement.bodyFatPercentage != null
                          ? '${measurement.bodyFatPercentage}%'
                          : 'Not set',
                    ),
                    _buildMeasurementDetailRow(
                      'Chest',
                      measurement.chest != null ? '${measurement.chest} cm' : 'Not set',
                    ),
                    _buildMeasurementDetailRow(
                      'Waist',
                      measurement.waist != null ? '${measurement.waist} cm' : 'Not set',
                    ),
                    _buildMeasurementDetailRow(
                      'Hips',
                      measurement.hips != null ? '${measurement.hips} cm' : 'Not set',
                    ),
                    _buildMeasurementDetailRow(
                      'Thighs',
                      measurement.thighs != null ? '${measurement.thighs} cm' : 'Not set',
                    ),
                    _buildMeasurementDetailRow(
                      'Arms',
                      measurement.arms != null ? '${measurement.arms} cm' : 'Not set',
                    ),
                    if (measurement.notes != null && measurement.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(measurement.notes!),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab(ProgressProvider progressProvider) {
    final achievements = progressProvider.achievements;
    
    if (progressProvider.isLoading) {
      return _buildLoadingState();
    }
    
    if (achievements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No Achievements Yet',
        message: 'Keep up with your workouts to unlock achievements!',
        buttonText: 'Go to Workouts',
        onPressed: () {
          context.go('/workout');
        },
      );
    }
    
    // Filter unlocked and locked achievements
    final unlockedAchievements = achievements.where((a) => a.unlocked).toList();
    final lockedAchievements = achievements.where((a) => !a.unlocked).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Unlocked Achievements
        if (unlockedAchievements.isNotEmpty) ...[
          const Text(
            'Unlocked Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...unlockedAchievements.map((achievement) {
            final dateFormat = DateFormat.yMMMd();
            final formattedDate = achievement.dateUnlocked != null
                ? dateFormat.format(achievement.dateUnlocked!)
                : null;
            
            return AchievementBadge(
              title: achievement.title,
              description: achievement.description,
              date: formattedDate,
              icon: _getAchievementIcon(achievement.type),
              color: _getAchievementColor(achievement.type),
              unlocked: true,
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
        
        // Locked Achievements
        if (lockedAchievements.isNotEmpty) ...[
          const Text(
            'Upcoming Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...lockedAchievements.map((achievement) {
            return AchievementBadge(
              title: achievement.title,
              description: achievement.description,
              date: null,
              icon: _getAchievementIcon(achievement.type),
              color: _getAchievementColor(achievement.type),
              unlocked: false,
            );
          }).toList(),
        ],
      ],
    );
  }

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'weight_loss':
        return Icons.trending_down;
      case 'workout_streak':
        return Icons.calendar_month;
      case 'strength':
        return Icons.fitness_center;
      case 'body_fat':
        return Icons.accessibility_new;
      case 'consistency':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'weight_loss':
        return Colors.green;
      case 'workout_streak':
        return Colors.blue;
      case 'strength':
        return Colors.orange;
      case 'body_fat':
        return Colors.purple;
      case 'consistency':
        return Colors.amber;
      default:
        return AppColors.primaryWineRed;
    }
  }

  Widget _buildWeightChart(List<ProgressMeasurement> measurements) {
    // Reverse list to get chronological order
    final data = measurements.reversed.toList();
    
    // Only display max 10 points for clarity
    final chartData = data.length > 10 ? data.sublist(data.length - 10) : data;
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final measurement = chartData[barSpot.x.toInt()];
                final date = DateFormat.MMMd().format(measurement.date);
                return LineTooltipItem(
                  '${barSpot.y.toStringAsFixed(1)} kg\n$date',
                  const TextStyle(color: AppColors.primaryWineRed),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0 && value >= 0 && value < chartData.length) {
                  final date = chartData[value.toInt()].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat.MMMd().format(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
            left: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        minX: 0,
        maxX: chartData.length - 1.0,
        minY: chartData.map((m) => m.weight).reduce((a, b) => a < b ? a : b) - 5,
        maxY: chartData.map((m) => m.weight).reduce((a, b) => a > b ? a : b) + 5,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(chartData.length, (index) {
              return FlSpot(index.toDouble(), chartData[index].weight);
            }),
            isCurved: true,
            color: AppColors.primaryWineRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryWineRed,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryWineRed.withOpacity(0.2),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryWineRed.withOpacity(0.3),
                  AppColors.primaryWineRed.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
            'Loading your progress data...',
            style: TextStyle(
              color: AppColors.primaryGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.lightGrey.withOpacity(0.3),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primaryGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required bool isPositive,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? Colors.green : Colors.red,
            size: 20,
          ),
  ],
      ),
    );
  }
  
  Widget _buildMeasurementDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  void _confirmDeleteMeasurement(ProgressMeasurement measurement) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: const Text('Are you sure you want to delete this measurement record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (token != null) {
                Provider.of<ProgressProvider>(context, listen: false)
                    .deleteMeasurement(id: measurement.id, token: token);
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

// Helper class for the SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}