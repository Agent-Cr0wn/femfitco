import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import 'exercise_card.dart'; // Assuming this exists and is correct

class WorkoutDayView extends StatelessWidget {
  final List<Exercise> exercises;

  const WorkoutDayView({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      // This case should ideally be handled by WorkoutWeekView showing a rest message,
      // but included as a fallback.
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("No exercises scheduled.", style: TextStyle(fontStyle: FontStyle.italic))),
      );
    }
    // Display exercises using ListView.separated for dividers
    return ListView.separated(
      shrinkWrap: true, // Essential inside ExpansionTile or Column
      physics: const NeverScrollableScrollPhysics(), // Disable nested scrolling
      itemCount: exercises.length,
      itemBuilder: (context, index) {
         final exercise = exercises[index];
        // Use a Key for potentially better performance if list items change order/identity
        return ExerciseCard(key: ValueKey(exercise.videoPlaceholder), exercise: exercise);
      },
      separatorBuilder: (context, index) => const Divider(
         height: 1,
         thickness: 1,
         indent: 16, // Indent divider to align with content
         endIndent: 16,
      ),
    );
  }
}