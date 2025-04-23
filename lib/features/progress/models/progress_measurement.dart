class ProgressMeasurement {
  final String id;
  final int userId;
  final DateTime date;
  final double weight;
  final double? bodyFatPercentage;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? thighs;
  final double? arms;
  final String? notes;
  
  ProgressMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.bodyFatPercentage,
    this.chest,
    this.waist,
    this.hips,
    this.thighs,
    this.arms,
    this.notes,
  });
  
  // Factory constructor to create a ProgressMeasurement from JSON
  factory ProgressMeasurement.fromJson(Map<String, dynamic> json) {
    return ProgressMeasurement(
      id: json['id'].toString(),
      userId: int.parse(json['user_id'].toString()),
      date: DateTime.parse(json['date'].toString()),
      weight: double.parse(json['weight'].toString()),
      bodyFatPercentage: json['body_fat_percentage'] != null ? 
          double.parse(json['body_fat_percentage'].toString()) : null,
      chest: json['chest'] != null ? double.parse(json['chest'].toString()) : null,
      waist: json['waist'] != null ? double.parse(json['waist'].toString()) : null,
      hips: json['hips'] != null ? double.parse(json['hips'].toString()) : null,
      thighs: json['thighs'] != null ? double.parse(json['thighs'].toString()) : null,
      arms: json['arms'] != null ? double.parse(json['arms'].toString()) : null,
      notes: json['notes'] as String?,
    );
  }
  
  // Convert ProgressMeasurement to JSON for API
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'weight': weight,
    };
    
    if (id.isNotEmpty && id != '0') {
      data['id'] = id;
    }
    
    if (bodyFatPercentage != null) data['body_fat_percentage'] = bodyFatPercentage;
    if (chest != null) data['chest'] = chest;
    if (waist != null) data['waist'] = waist;
    if (hips != null) data['hips'] = hips;
    if (thighs != null) data['thighs'] = thighs;
    if (arms != null) data['arms'] = arms;
    if (notes != null && notes!.isNotEmpty) data['notes'] = notes;
    
    return data;
  }
}