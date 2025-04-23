class Achievement {
  final String id;
  final String title;
  final String description;
  final String type; // e.g., 'weight_loss', 'workout_streak', 'consistency', etc.
  final bool unlocked;
  final DateTime? dateUnlocked;
  final double? progressPercentage; // Optional progress percentage for upcoming achievements
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.unlocked,
    this.dateUnlocked,
    this.progressPercentage,
  });
  
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      unlocked: json['unlocked'] == 1 || json['unlocked'] == true,
      dateUnlocked: json['date_unlocked'] != null ? 
          DateTime.parse(json['date_unlocked'].toString()) : null,
      progressPercentage: json['progress_percentage'] != null ?
          double.parse(json['progress_percentage'].toString()) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'unlocked': unlocked ? 1 : 0,
    };
    
    if (dateUnlocked != null) {
      data['date_unlocked'] = dateUnlocked!.toIso8601String().split('T')[0];
    }
    
    if (progressPercentage != null) {
      data['progress_percentage'] = progressPercentage;
    }
    
    return data;
  }
}