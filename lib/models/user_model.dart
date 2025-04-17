//import 'package:flutter/foundation.dart'; // For @required annotation if needed

class UserModel {
  final int id;
  final String name;
  final String email;
  String subscriptionStatus; // Make modifiable for local updates
  String? subscriptionEndDate; // Make modifiable

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  // Factory constructor to create a UserModel from the JSON map
  // Handles potential variations in keys from different API endpoints (login vs profile)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely get value or default
    T safeGet<T>(Map<String, dynamic> json, String key, T defaultValue) {
      return json.containsKey(key) && json[key] != null ? json[key] as T : defaultValue;
    }

    int parsedId = 0;
    if (json.containsKey('id') && json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    } else if (json.containsKey('user_id') && json['user_id'] != null) {
       parsedId = int.tryParse(json['user_id'].toString()) ?? 0;
    }


    return UserModel(
      id: parsedId,
      name: safeGet<String>(json, 'name', 'Unknown User'),
      email: safeGet<String>(json, 'email', 'no-email@example.com'),
      subscriptionStatus: safeGet<String>(json, 'subscription_status', 'none'),
      subscriptionEndDate: json['subscription_end_date'] as String?, // Allows null
    );
  }
}