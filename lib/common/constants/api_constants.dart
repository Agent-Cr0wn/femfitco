class ApiConstants {
  // --- Base URL ---
  // IMPORTANT: Choose the correct URL for your setup:
  // - Android Emulator accessing host PC: 'http://10.0.2.2/femfit_api'
  // - iOS Simulator/Web accessing host PC: 'http://localhost/femfit_api'
  // - Physical Device on same WiFi: 'http://YOUR_PC_LOCAL_IP/femfit_api' (e.g., http://192.168.1.105/femfit_api)
  // - Deployed Production API: 'https://yourdomain.com/api' (Use HTTPS!)
  static const String baseUrl = 'https://femfit.ct.ws/api'; // CHANGE AS NEEDED

  // --- Endpoints ---
  static const String registerEndpoint = 'register.php';
  static const String loginEndpoint = 'login.php';
  static const String submitQuestionnaireEndpoint = 'submit_questionnaire.php';
  static const String processSubscriptionEndpoint = 'process_subscription.php'; // Needs webhook in production
  static const String getWorkoutPlanEndpoint = 'get_workout_plan.php'; // Needs user_id param in URL
  static const String getUserProfileEndpoint = 'get_user_profile.php'; // Needs user_id param in URL
  // Progress tracking endpoints
  static const String getUserMeasurementsEndpoint = 'get_user_measurements.php';
  static const String addMeasurementEndpoint = 'add_measurement.php';
  static const String deleteMeasurementEndpoint = 'delete_measurement.php';
  static const String getUserAchievementsEndpoint = 'get_user_achievements.php';

  // Add other endpoints as needed (nutrition, community, etc.)
}