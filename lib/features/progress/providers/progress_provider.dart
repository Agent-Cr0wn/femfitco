import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';
import '../models/progress_measurement.dart';
import '../models/achievement.dart';

class ProgressProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ProgressMeasurement> _measurements = [];
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Statistics
  int _workoutsCompleted = 0;
  
  // Getters
  List<ProgressMeasurement> get measurements => _measurements;
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get workoutsCompleted => _workoutsCompleted;
  
  // Fetch progress data from the API
  Future<void> fetchProgressData({required int userId, required String token}) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // Get measurements
      final measurementsResult = await _apiService.get(
        '${ApiConstants.getUserMeasurementsEndpoint}?user_id=$userId', 
        token: token
      );
      
      if (measurementsResult['success'] == true && measurementsResult['data'] != null) {
        final List<dynamic> measurementsData = measurementsResult['data'] as List<dynamic>;
        _measurements = measurementsData
            .map((item) => ProgressMeasurement.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Sort measurements by date (newest first)
        _measurements.sort((a, b) => b.date.compareTo(a.date));
      } else {
        _measurements = [];
        debugPrint('Error fetching measurements: ${measurementsResult['message']}');
      }
      
      // Get achievements
      final achievementsResult = await _apiService.get(
        '${ApiConstants.getUserAchievementsEndpoint}?user_id=$userId', 
        token: token
      );
      
      if (achievementsResult['success'] == true && achievementsResult['data'] != null) {
        final Map<String, dynamic> achievementsData = achievementsResult['data'] as Map<String, dynamic>;
        _workoutsCompleted = achievementsData['workouts_completed'] as int? ?? 0;
        
        if (achievementsData.containsKey('achievements')) {
          final List<dynamic> achievementsList = achievementsData['achievements'] as List<dynamic>;
          _achievements = achievementsList
              .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          _achievements = [];
        }
      } else {
        _achievements = [];
        _workoutsCompleted = 0;
        debugPrint('Error fetching achievements: ${achievementsResult['message']}');
      }
      
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load progress data: $e';
      _measurements = [];
      _achievements = [];
      _workoutsCompleted = 0;
      _setLoading(false);
      debugPrint('Exception while fetching progress data: $e');
    }
  }
  
  // Add a new measurement
  Future<bool> addMeasurement({required ProgressMeasurement measurement, required String token}) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final data = measurement.toJson();
      
      final result = await _apiService.post(
        ApiConstants.addMeasurementEndpoint,
        data,
        token: token
      );
      
      if (result['success'] == true) {
        // Update local data with the measurement that was returned from the server
        if (result['data'] != null && result['data'] is Map<String, dynamic>) {
          final serverMeasurement = ProgressMeasurement.fromJson(result['data'] as Map<String, dynamic>);
          
          // Add to local list and sort by date (newest first)
          _measurements.add(serverMeasurement);
          _measurements.sort((a, b) => b.date.compareTo(a.date));
        } else {
          // Fallback if server doesn't return the measurement
          _measurements.add(measurement);
          _measurements.sort((a, b) => b.date.compareTo(a.date));
        }
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to add measurement';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to add measurement: $e';
      _setLoading(false);
      return false;
    }
  }
  
  // Delete a measurement
  Future<bool> deleteMeasurement({required String id, required String token}) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final result = await _apiService.post(
        ApiConstants.deleteMeasurementEndpoint,
        {'measurement_id': id},
        token: token
      );
      
      if (result['success'] == true) {
        // Remove from local list
        _measurements.removeWhere((measurement) => measurement.id == id);
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to delete measurement';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete measurement: $e';
      _setLoading(false);
      return false;
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}