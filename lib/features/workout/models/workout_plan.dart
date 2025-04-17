import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint

// Helper function to safely decode top-level JSON string
WorkoutPlan? workoutPlanFromJson(String str) {
  try {
    final jsonData = json.decode(str);
    if (jsonData is Map<String, dynamic>) {
       return WorkoutPlan.fromJson(jsonData);
    } else {
       debugPrint("Error decoding WorkoutPlan: Input string is not a valid JSON object.");
       return null;
    }
  } catch (e) {
    debugPrint("Error decoding WorkoutPlan JSON string: $e");
    return null;
  }
}

// Main Workout Plan model
class WorkoutPlan {
  final Map<String, WorkoutWeek> weeks; // Use week key (e.g., 'week1')

  WorkoutPlan({required this.weeks});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    Map<String, WorkoutWeek> parsedWeeks = {};
    json.forEach((key, value) {
      if (key.toLowerCase().startsWith('week') && value is Map<String, dynamic>) {
        try {
          parsedWeeks[key] = WorkoutWeek.fromJson(value);
        } catch (e) {
          debugPrint("Error parsing week '$key': $e. Skipping week.");
        }
      } else {
        // debugPrint("Skipping invalid entry in WorkoutPlan JSON: key '$key' is not a week or value is not a Map.");
      }
    });
    // Ensure weeks are sorted numerically if possible
    var sortedKeys = parsedWeeks.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    Map<String, WorkoutWeek> sortedWeeks = {
      for (var key in sortedKeys) key : parsedWeeks[key]!
    };

    return WorkoutPlan(weeks: sortedWeeks);
  }
}

// Represents a single week
class WorkoutWeek {
  final Map<String, WorkoutDay> days; // Use day key (e.g., 'day1', 'restDay')

  WorkoutWeek({required this.days});

  factory WorkoutWeek.fromJson(Map<String, dynamic> json) {
    Map<String, WorkoutDay> parsedDays = {};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        try {
          parsedDays[key] = WorkoutDay.fromJson(value);
        } catch (e) {
          debugPrint("Error parsing day '$key': $e. Skipping day.");
        }
      } else {
        debugPrint("Skipping invalid day format for key '$key': value is not a Map.");
      }
    });

     // Ensure days are sorted if possible ('day1', 'day2', ...)
    var sortedKeys = parsedDays.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
         // If both are non-numeric (like 'restDay'), sort alphabetically
        if (numA == 0 && numB == 0) return a.compareTo(b);
        return numA.compareTo(numB);
      });

      Map<String, WorkoutDay> sortedDays = {
        for (var key in sortedKeys) key : parsedDays[key]!
      };

    return WorkoutWeek(days: sortedDays);
  }
}

// Represents a single day's workout
class WorkoutDay {
  final List<Exercise> exercises;
  final String? dayName; // Optional descriptive name from Gemini

  WorkoutDay({required this.exercises, this.dayName});

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    List<Exercise> exercisesList = [];
    if (json['exercises'] != null && json['exercises'] is List) {
      var list = json['exercises'] as List;
      exercisesList = list.map((item) {
        if (item is Map<String, dynamic>) {
          try {
            return Exercise.fromJson(item);
          } catch (e) {
            debugPrint("Error parsing exercise: $e. Data: $item. Returning placeholder.");
            // Return a placeholder exercise on error
            return Exercise(
                name: 'Error Parsing Exercise', sets: '?', reps: '?', rest: '?', videoPlaceholder: 'error');
          }
        } else {
           debugPrint("Skipping invalid exercise item: Not a Map. Data: $item");
            return Exercise(
                name: 'Invalid Exercise Data', sets: '?', reps: '?', rest: '?', videoPlaceholder: 'error');
        }
      }).toList();
    } else {
      // If 'exercises' key is missing or not a list, it might be a rest day
       if (json['day_name'] != null && json['day_name'].toLowerCase().contains('rest')) {
         debugPrint("No exercises found for day, assuming rest day based on name: ${json['day_name']}");
       } else {
         debugPrint("Warning: 'exercises' key missing or not a list in day JSON: ${json.keys}");
       }
    }

    return WorkoutDay(
      exercises: exercisesList,
      dayName: json['day_name'] as String?,
    );
  }
}

// Represents a single exercise
class Exercise {
  final String name;
  final String sets; // Keep as String for flexibility (e.g., "3", "2-3", "As many as possible")
  final String reps; // Keep as String (e.g., "8-12", "AMRAP", "To failure")
  final String rest; // Keep as String (e.g., "60s", "90sec", "None")
  final String videoPlaceholder; // Unique ID generated by Gemini

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.videoPlaceholder,
  });

  // Robust factory method with type checking and defaults for missing/invalid data
  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Helper to safely get string value, handles null, numbers, etc.
    String getString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value.isNotEmpty ? value : defaultValue;
      return value.toString();
    }

    return Exercise(
      name: getString(json['name'], 'Unknown Exercise'),
      sets: getString(json['sets'], '?'),
      reps: getString(json['reps'], '?'),
      rest: getString(json['rest'], '?'),
      videoPlaceholder: getString(json['video_placeholder'], 'no_video_id'),
    );
  }
}