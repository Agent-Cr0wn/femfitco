import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import 'workout_day_view.dart'; // Assuming this exists and is correct
import '../../../common/constants/colors.dart'; // Import colors

class WorkoutWeekView extends StatelessWidget {
  final WorkoutWeek week;
  final int weekNumber;

  const WorkoutWeekView({super.key, required this.week, required this.weekNumber});

  @override
  Widget build(BuildContext context) {
    // Keys are already sorted by WorkoutPlan.fromJson
    final sortedDayKeys = week.days.keys.toList();

    if (sortedDayKeys.isEmpty) {
       return const Center(
         child: Padding(
           padding: EdgeInsets.all(20.0),
           child: Text("No days scheduled for this week.", style: TextStyle(fontStyle: FontStyle.italic)),
         ),
       );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0), // Padding for the list
      itemCount: sortedDayKeys.length,
      itemBuilder: (context, index) {
        final dayKey = sortedDayKeys[index];
        final day = week.days[dayKey]!;
        final dayTitle = day.dayName ?? _formatDayKey(dayKey); // Use formatted key if no name
        final bool isRestDay = day.exercises.isEmpty && dayTitle.toLowerCase().contains('rest');

        // Use ExpansionTile for collapsible day details
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // Spacing between day cards
           elevation: 2.0,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            title: Text(dayTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isRestDay ? AppColors.primaryGrey : AppColors.textDark)),
            subtitle: Text(
               isRestDay ? 'Focus on recovery' : '${day.exercises.length} exercises',
               style: TextStyle(color: Colors.grey[600]),
            ),
            leading: Icon(
               isRestDay ? Icons.self_improvement : Icons.fitness_center, // Different icon for rest days
               color: isRestDay ? AppColors.accentWineRed : AppColors.primaryWineRed,
            ),
             // initiallyExpanded: index == 0, // Expand the first day by default? Or none?
             childrenPadding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
             expandedCrossAxisAlignment: CrossAxisAlignment.start,
             expandedAlignment: Alignment.topLeft,
             tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             iconColor: AppColors.primaryWineRed, // Expansion icon color
             collapsedIconColor: AppColors.primaryGrey,
             children: [
                if (isRestDay)
                   const Padding(
                     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                     child: Text(
                       "Rest day! Listen to your body. Consider light activity like walking or stretching.",
                       style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.primaryGrey),
                     ),
                   )
                else if (day.exercises.isEmpty)
                     const Padding( // Handle case where exercises might be empty but not explicitly named "Rest"
                       padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                       child: Text(
                         "No specific exercises scheduled for this day.",
                         style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.primaryGrey),
                       ),
                     )
                else
                    WorkoutDayView(exercises: day.exercises) // Pass exercises
             ],
          ),
        );
      },
    );
  }

  // Helper to format 'day1' into 'Day 1' or handle 'restDay' -> 'Rest Day'
  String _formatDayKey(String key) {
     key = key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}'); // Add space before caps
     key = key[0].toUpperCase() + key.substring(1); // Capitalize first letter
     // Replace number with space
     key = key.replaceAllMapped(RegExp(r'([a-zA-Z])([0-9]+)'), (match) => '${match.group(1)} ${match.group(2)}');
     return key.trim(); // "day1" -> "Day 1", "restDay" -> "Rest Day"
  }
}
