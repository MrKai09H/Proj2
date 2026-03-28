class SensorDataModel {
  final String id;
  final String plantId;
  final double temperature;
  final double soilMoisture;
  final double? humidity;
  final DateTime timestamp;

  SensorDataModel({
    required this.id,
    required this.plantId,
    required this.temperature,
    required this.soilMoisture,
    this.humidity,
    required this.timestamp,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'temperature': temperature,
      'soilMoisture': soilMoisture,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory SensorDataModel.fromMap(Map<String, dynamic> map) {
    return SensorDataModel(
      id: map['id'] ?? '',
      plantId: map['plantId'] ?? '',
      temperature: (map['temperature'] ?? 0).toDouble(),
      soilMoisture: (map['soilMoisture'] ?? 0).toDouble(),
      humidity: map['humidity']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // Check if moisture is low
  bool get isMoistureLow => soilMoisture < 30.0;
  
  // Check if moisture is high
  bool get isMoistureHigh => soilMoisture > 80.0;
  
  // Check if temperature is low
  bool get isTemperatureLow => temperature < 10.0;
  
  // Check if temperature is high
  bool get isTemperatureHigh => temperature > 35.0;
  
  // Get moisture status
  String get moistureStatus {
    if (soilMoisture < 30) return 'Khô';
    if (soilMoisture < 60) return 'Trung bình';
    return 'Ẩm';
  }
  
  // Get temperature status
  String get temperatureStatus {
    if (temperature < 15) return 'Lạnh';
    if (temperature < 25) return 'Mát';
    if (temperature < 30) return 'Ấm';
    return 'Nóng';
  }
}

