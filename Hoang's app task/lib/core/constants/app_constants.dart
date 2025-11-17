class AppConstants {
  // App Info
  static const String appName = 'Plant Care App';
  static const String appVersion = '1.0.0';
  
  // Database Collections
  static const String usersCollection = 'users';
  static const String plantsCollection = 'plants';
  static const String diaryEntriesCollection = 'diary_entries';
  static const String iotDataCollection = 'iot_data';
  static const String notificationsCollection = 'notifications';
  
  // Storage Paths
  static const String plantImagesPath = 'plant_images';
  static const String diaryImagesPath = 'diary_images';
  static const String userAvatarsPath = 'user_avatars';
  
  // Sensor Thresholds
  static const double soilMoistureLowThreshold = 30.0;
  static const double soilMoistureHighThreshold = 80.0;
  static const double temperatureLowThreshold = 10.0;
  static const double temperatureHighThreshold = 35.0;
  
  // Time Intervals
  static const int sensorReadingInterval = 5; // seconds
  static const int notificationCheckInterval = 60; // seconds
  static const int maxDaysWithoutWatering = 3;
  
  // Pagination
  static const int plantsPerPage = 10;
  static const int diaryEntriesPerPage = 20;
  
  // Image Settings
  static const int maxImageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
}

