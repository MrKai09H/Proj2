// file: statistics_provider.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; 

/// Lớp helper để tính toán trung bình cộng
class _SensorAggregator {
  double _sum = 0.0;
  int _count = 0;
  void add(double value) { _sum += value; _count++; }
  double get average => _count == 0 ? 0.0 : _sum / _count;
}

class StatisticsProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance; 
  
  // Trạng thái
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Dữ liệu UI
  List<FlSpot> _careHistoryData = [];
  List<FlSpot> _temperatureData = [];
  List<FlSpot> _soilMoistureData = []; // <-- ĐÃ ĐỔI TÊN
  int _totalWaterings = 0;
  int _totalDiaries = 0;
  double _avgTemperature = 0.0;
  double _avgSoilMoisture = 0.0; // <-- ĐÃ ĐỔI TÊN
  Map<String, double> _activityBreakdown = {};
  double _chartMaxX = 6.0;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  List<FlSpot> get careHistoryData => _careHistoryData;
  List<FlSpot> get temperatureData => _temperatureData;
  List<FlSpot> get soilMoistureData => _soilMoistureData; // <-- ĐÃ ĐỔI TÊN
  int get totalWaterings => _totalWaterings;
  int get totalDiaries => _totalDiaries;
  double get avgTemperature => _avgTemperature;
  double get avgSoilMoisture => _avgSoilMoisture; // <-- ĐÃ ĐỔI TÊN
  Map<String, double> get activityBreakdown => _activityBreakdown;
  double get chartMaxX => _chartMaxX;

  String _toDayKey(DateTime timestamp) {
    return "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchStatistics(String plantId, String period) async {
    _isLoading = true;
    _hasError = false;
    _clearData();
    notifyListeners();

    try {
      final dateRange = _calculateDateRange(period);
      final DateTime startDate = dateRange['start']!;
      final DateTime endDate = dateRange['end']!;

      if (period == 'week') _chartMaxX = 6.0;
      else if (period == 'month') _chartMaxX = 29.0;
      else _chartMaxX = 364.0;

      final diaryEntriesFuture = _db
          .collection('diary_entries') 
          .where('plantId', isEqualTo: plantId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt')
          .get();

      final sensorSnapFuture = _rtdb
          .ref('sensorData')
          .orderByChild('plantId')
          .equalTo(plantId)
          .get();
      
      final results = await Future.wait([
        diaryEntriesFuture, 
        sensorSnapFuture    
      ]);

      final diaryEntriesSnap = results[0] as QuerySnapshot;
      final sensorSnap = results[1] as DataSnapshot;
      
      final diaryDocs = diaryEntriesSnap.docs;

      _totalDiaries = diaryDocs.length; 
      _totalWaterings = diaryDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?; 
        return data != null && data['activityType'] == 'watering'; 
      }).length;

      _processActivityBreakdown(diaryDocs);
      _processSensorData(sensorSnap, dateRange, _chartMaxX); 
      _processCareHistory(diaryDocs, startDate, _chartMaxX); 

    } catch (e) {
      _hasError = true;
      _errorMessage = "Lỗi khi tải dữ liệu: ${e.toString()}\n\n"
          "BẠN ĐÃ TẠO INDEX CHO CẢ FIRESTORE VÀ RTDB CHƯA?";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xử lý dữ liệu cảm biến (RTDB)
  void _processSensorData(DataSnapshot snapshot, Map<String, DateTime> dateRange, double chartMaxX) {
    final DateTime startDate = dateRange['start']!;
    final DateTime endDate = dateRange['end']!;
    
    Map<String, _SensorAggregator> dailyTempData = {};
    Map<String, _SensorAggregator> dailyMoistureData = {}; // <-- ĐÃ ĐỔI TÊN
    double totalTemp = 0;
    double totalMoisture = 0; // <-- ĐÃ ĐỔI TÊN
    int validRecordCount = 0; 

    if (snapshot.exists && snapshot.children.isNotEmpty) {
      for (final child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        final int timestampInMs = (data['timestamp'] ?? 0).toInt();
        final DateTime tsDate = DateTime.fromMillisecondsSinceEpoch(timestampInMs);

        if (tsDate.isBefore(startDate) || tsDate.isAfter(endDate)) {
          continue; 
        }
        final double temp = (data['temperature'] ?? 0.0).toDouble();
        final double moisture = (data['soilMoisture'] ?? 0.0).toDouble(); // <-- ĐÃ SỬA TÊN TRƯỜNG

        totalTemp += temp;
        totalMoisture += moisture; // <-- ĐÃ ĐỔI TÊN
        validRecordCount++; 
        String dayKey = _toDayKey(tsDate);
        dailyTempData.putIfAbsent(dayKey, () => _SensorAggregator()).add(temp);
        dailyMoistureData.putIfAbsent(dayKey, () => _SensorAggregator()).add(moisture); // <-- ĐÃ ĐỔI TÊN
      }
    }

    List<FlSpot> tempSpots = [];
    List<FlSpot> moistureSpots = []; // <-- ĐÃ ĐỔI TÊN
    int days = chartMaxX.toInt() + 1; 

    for (int i = 0; i < days; i++) {
      final DateTime currentDay = startDate.add(Duration(days: i));
      final String dayKey = _toDayKey(currentDay);
      final double xValue = i.toDouble();

      if (dailyTempData.containsKey(dayKey)) {
        tempSpots.add(FlSpot(xValue, dailyTempData[dayKey]!.average));
      } else {
        tempSpots.add(FlSpot(xValue, 0)); 
      }

      if (dailyMoistureData.containsKey(dayKey)) { // <-- ĐÃ ĐỔI TÊN
        moistureSpots.add(FlSpot(xValue, dailyMoistureData[dayKey]!.average)); // <-- ĐÃ ĐỔI TÊN
      } else {
        moistureSpots.add(FlSpot(xValue, 0)); // <-- ĐÃ ĐỔI TÊN
      }
    }

    _temperatureData = tempSpots;
    _soilMoistureData = moistureSpots; // <-- ĐÃ ĐỔI TÊN
    if (validRecordCount > 0) {
       _avgTemperature = totalTemp / validRecordCount;
       _avgSoilMoisture = totalMoisture / validRecordCount; // <-- ĐÃ ĐỔI TÊN
    }
  }

  /// Xử lý dữ liệu care_history (Từ 'diary_entries')
  void _processCareHistory(
      List<QueryDocumentSnapshot> docs, DateTime startDate, double chartMaxX) {
    
    Map<String, int> dailyCareCounts = {};
    if (docs.isNotEmpty) {
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final type = data['activityType'] as String?;
        if (type != null && type.isNotEmpty) {
            final Timestamp timestamp = data['createdAt']; 
            final DateTime tsDate = timestamp.toDate();
            String dayKey = _toDayKey(tsDate);
            dailyCareCounts[dayKey] = (dailyCareCounts[dayKey] ?? 0) + 1;
        }
      }
    }

    List<FlSpot> careSpots = [];
    int days = chartMaxX.toInt() + 1; 

    for (int i = 0; i < days; i++) {
      final DateTime currentDay = startDate.add(Duration(days: i));
      final String dayKey = _toDayKey(currentDay);
      final double xValue = i.toDouble();

      if (dailyCareCounts.containsKey(dayKey)) {
        careSpots.add(FlSpot(xValue, dailyCareCounts[dayKey]!.toDouble()));
      } else {
        careSpots.add(FlSpot(xValue, 0)); 
      }
    }
    
    _careHistoryData = careSpots;
  }

  /// Xử lý Phân loại hoạt động (Từ 'diary_entries')
  void _processActivityBreakdown(List<QueryDocumentSnapshot> docs) {
    // ... (Hàm này không đổi)
    if (docs.isEmpty) return;
    Map<String, int> counts = {};
    int totalActivities = 0; 
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final type = data['activityType'] as String?; 
      if (type != null && type.isNotEmpty) {
        totalActivities++; 
        String typeName = 'Khác';
        if (type == 'watering') typeName = 'Tưới nước';
        if (type == 'fertilizing') typeName = 'Bón phân';
        if (type == 'pruning') typeName = 'Tỉa cành';
        if (type == 'observation') typeName = 'Quan sát';
        counts[typeName] = (counts[typeName] ?? 0) + 1;
      }
    }
    Map<String, double> breakdown = {};
    if (totalActivities > 0) { 
      counts.forEach((key, value) {
        breakdown[key] = (value / totalActivities) * 100.0;
      });
    }
    _activityBreakdown = breakdown;
  }
  
  /// Reset data khi bắt đầu fetch mới
  void _clearData() {
    _careHistoryData = [];
    _temperatureData = [];
    _soilMoistureData = []; // <-- ĐÃ ĐỔI TÊN
    _totalWaterings = 0;
    _totalDiaries = 0;
    _avgTemperature = 0.0;
    _avgSoilMoisture = 0.0; // <-- ĐÃ ĐỔI TÊN
    _activityBreakdown = {};
    _chartMaxX = 6.0;
  }

  /// Hàm helper tính toán ngày
  Map<String, DateTime> _calculateDateRange(String period) {
    // ... (Hàm này không đổi)
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (period == 'week') {
      startDate = now.subtract(const Duration(days: 6));
    } else if (period == 'month') {
      startDate = now.subtract(const Duration(days: 29));
    } else { // year
      startDate = now.subtract(const Duration(days: 364));
    }
    startDate = DateTime(startDate.year, startDate.month, startDate.day);
    return {'start': startDate, 'end': endDate};
  }
}