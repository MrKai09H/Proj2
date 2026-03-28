// File: mobile_app/lib/features/statistics/services/notification_listener_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alert_service.dart'; // Import "cái chuông"

class NotificationListenerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AlertService _alertService = AlertService();

  // Biến để theo dõi các kết nối lắng nghe
  StreamSubscription? _sensorListener;
  String? _currentUserId;

  // Ngưỡng cảnh báo (có thể đọc từ cài đặt, nhưng giờ ta dùng cố định)
  static const double soilHumidityLow = 30.0;
  static const double tempHigh = 35.0;

  // Biến để tránh spam thông báo (gửi 1 lần/phút)
  DateTime? _lastHumidityAlert;
  DateTime? _lastTempAlert;

  /// Bắt đầu lắng nghe dữ liệu
  void startListening() {
    // Chỉ bắt đầu nếu có người dùng đăng nhập
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId == null) {
      print("Listener: Không có người dùng, dừng lắng nghe.");
      return;
    }

    print("✅ Bắt đầu lắng nghe dữ liệu cảm biến...");

    // TODO: Cần có logic để biết đang nghe cây (plantId) nào.
    // Tạm thời, chúng ta sẽ giả định người dùng chỉ có 1 cây
    // và chúng ta biết ID của nó.
    // Bạn sẽ cần sửa lại logic này để lấy plantId của cây đang được chọn.
    const String mockPlantId = "plant_123";

    // Mở một kết nối Stream đến collection dữ liệu cảm biến
    final docStream = _firestore
        .collection('iot_data')
        .doc(mockPlantId) // Lắng nghe 1 cây cụ thể
        .collection('sensor_readings')
        .orderBy('timestamp', descending: true) // Lấy bản ghi mới nhất
        .limit(1) // Chỉ lấy 1 bản ghi
        .snapshots(); // Lắng nghe thay đổi

    _sensorListener = docStream.listen(
      (QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final latestData = snapshot.docs.first.data() as Map<String, dynamic>;
          _checkSensorData(latestData);
        }
      },
      onError: (error) {
        print("Lỗi lắng nghe Firestore: $error");
      },
    );
  }

  /// Kiểm tra dữ liệu cảm biến
  void _checkSensorData(Map<String, dynamic> data) {
    final double? humidity = data['soilHumidity'];
    final double? temperature = data['temperature'];

    print("Nhận dữ liệu mới: Độ ẩm $humidity, Nhiệt độ $temperature");

    // 1. Kiểm tra độ ẩm
    if (humidity != null && humidity < soilHumidityLow) {
      // Chỉ gửi thông báo nếu đã qua 1 phút
      if (_canSendAlert(_lastHumidityAlert)) {
        print("🚨 CẢNH BÁO: Độ ẩm thấp!");
        _alertService.showAlert(
          id: 1, // ID cho loại thông báo này
          title: "🌱 Cây cần tưới nước!",
          body: "Độ ẩm đất hiện tại: $humidity%. Cây cần tưới nước!",
        );
        _lastHumidityAlert = DateTime.now(); // Cập nhật thời gian
      }
    }

    // 2. Kiểm tra nhiệt độ
    if (temperature != null && temperature > tempHigh) {
      if (_canSendAlert(_lastTempAlert)) {
        print("🚨 CẢNH BÁO: Nhiệt độ cao!");
        _alertService.showAlert(
          id: 2, // ID khác
          title: "🥵 Nhiệt độ quá cao!",
          body: "Nhiệt độ hiện tại: $temperature°C. Hãy che mát cho cây.",
        );
        _lastTempAlert = DateTime.now();
      }
    }
  }

  /// Hàm kiểm tra để tránh spam thông báo (cách nhau 1 phút)
  bool _canSendAlert(DateTime? lastAlertTime) {
    if (lastAlertTime == null) {
      return true; // Chưa gửi bao giờ
    }
    final now = DateTime.now();
    // Nếu lần gửi cuối > 1 phút trước, cho phép gửi
    return now.difference(lastAlertTime).inMinutes > 0;
  }

  /// Dừng lắng nghe (khi người dùng đăng xuất)
  void stopListening() {
    print("❌ Dừng lắng nghe dữ liệu cảm biến.");
    _sensorListener?.cancel();
    _sensorListener = null;
  }
}
