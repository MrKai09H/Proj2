import 'package:flutter/material.dart';
import '../models/sensor_data_model.dart';

class IotProvider with ChangeNotifier {
  List<SensorDataModel> _sensorData = [];
  SensorDataModel? _latestData;
  bool _pumpState = false;
  bool _isLoading = false;
  String? _error;

  List<SensorDataModel> get sensorData => _sensorData;
  SensorDataModel? get latestData => _latestData;
  bool get pumpState => _pumpState;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load sensor data for a plant
  Future<void> loadSensorData(String plantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: Implement Firestore real-time listener
      // Stream for iot_data/{plantId}/sensor_readings
      _sensorData = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get latest sensor reading
  void updateLatestData(SensorDataModel data) {
    _latestData = data;
    _sensorData.insert(0, data);
    
    // Keep only last 100 readings
    if (_sensorData.length > 100) {
      _sensorData = _sensorData.take(100).toList();
    }
    
    notifyListeners();
  }

  // Control pump (turn on/off)
  Future<bool> controlPump(String plantId, bool state) async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Write to Firebase iot_data/{plantId}/control/pumpState
      // ESP32 will listen to this field and control relay
      
      _pumpState = state;
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Auto water based on moisture level
  Future<bool> autoWater(String plantId) async {
    if (_latestData != null && _latestData!.isMoistureLow) {
      return await controlPump(plantId, true);
    }
    return false;
  }

  // Get sensor data for specific time range
  List<SensorDataModel> getDataInRange(DateTime start, DateTime end) {
    return _sensorData
        .where((data) =>
            data.timestamp.isAfter(start) && data.timestamp.isBefore(end))
        .toList();
  }

  // Get average temperature
  double? getAverageTemperature() {
    if (_sensorData.isEmpty) return null;
    var sum = _sensorData.fold<double>(0, (sum, data) => sum + data.temperature);
    return sum / _sensorData.length;
  }

  // Get average moisture
  double? getAverageMoisture() {
    if (_sensorData.isEmpty) return null;
    var sum = _sensorData.fold<double>(0, (sum, data) => sum + data.soilMoisture);
    return sum / _sensorData.length;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

