// File: mobile_app/lib/providers/notification_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- (Model dữ liệu) ---
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // Ví dụ: 'alert', 'reminder'
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

// --- (HÀM BACKGROUND FCM - BẮT BUỘC Ở NGOÀI CLASS) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Handling a background message: ${message.messageId}");
}

class NotificationProvider with ChangeNotifier {
  // --- (Các biến State) ---
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _fcmToken;

  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get fcmToken => _fcmToken;

  // --- (Các dịch vụ) ---
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _sensorListener;

  // Ngưỡng cảnh báo
  static const double SOIL_HUMIDITY_LOW = 30.0;
  static const double TEMP_HIGH = 35.0;

  DateTime? _lastHumidityAlert;
  DateTime? _lastTempAlert;

  /// 1. Khởi tạo (Không tự động lắng nghe)
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _initializeLocalNotifications();
      await requestPermission();
      await _getToken();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          print(
              'Nhận được thông báo (foreground): ${message.notification!.title}');
          showLocalAlert(
            title: message.notification!.title ?? 'Thông báo mới',
            body: message.notification!.body ?? '',
            type: message.data['type'] ?? 'alert',
            payload: message.data['plantId'],
          );
        }
      });

      // KHÔNG TỰ ĐỘNG LẮNG NGHE NỮA
      // startSensorListening();

      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('Error initializing NotificationProvider: $e');
    }
    notifyListeners();
  }

  /// 2. Khởi tạo "cái chuông" (Local Notifications)
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification tapped with payload: ${response.payload}");
        // TODO: Điều hướng
      },
    );
  }

  /// 3. Xin quyền (Task 4.2)
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// 4. Lấy Token và Lưu (Task 4.2)
  Future<String?> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print("✅ FCM Token: $_fcmToken");

      if (_fcmToken != null) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set(
            {'fcmToken': _fcmToken},
            SetOptions(merge: true),
          );
        }
      }
      notifyListeners();
      return _fcmToken;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 5. Bắt đầu lắng nghe (ĐÃ SỬA LỖI HARDCODE)
  void startSensorListening({required String plantId}) {
    stopSensorListening(); // Dừng listener cũ
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print("✅ Bắt đầu lắng nghe dữ liệu cây: $plantId");

    final docStream = _firestore
        .collection('iot_data')
        .doc(plantId) // <--- Dùng plantId thật
        .collection('sensor_readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();

    _sensorListener = docStream.listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _checkSensorData(data);
      }
    });
  }

  /// 6. Dừng lắng nghe
  void stopSensorListening() {
    _sensorListener?.cancel();
    _sensorListener = null;
    print("❌ Dừng lắng nghe dữ liệu cảm biến.");
  }

  /// 7. Kiểm tra dữ liệu và Kích hoạt thông báo
  void _checkSensorData(Map<String, dynamic> data) {
    final double? humidity = data['soilHumidity'] as double?;
    final double? temperature = data['temperature'] as double?;

    print("Nhận dữ liệu mới: Độ ẩm $humidity, Nhiệt độ $temperature");

    // 1. Kiểm tra độ ẩm
    if (humidity != null && humidity < SOIL_HUMIDITY_LOW) {
      if (_canSendAlert(_lastHumidityAlert)) {
        print("🚨 CẢNH BÁO: Độ ẩm thấp!");
        showLocalAlert(
          title: "🌱 Cây cần tưới nước!",
          body: "Độ ẩm đất hiện tại: $humidity%. Cây cần tưới nước!",
          type: "alert_humidity",
        );
        _lastHumidityAlert = DateTime.now();
      }
    }

    // 2. Kiểm tra nhiệt độ
    if (temperature != null && temperature > TEMP_HIGH) {
      if (_canSendAlert(_lastTempAlert)) {
        print("🚨 CẢNH BÁO: Nhiệt độ cao!");
        showLocalAlert(
          title: "🥵 Nhiệt độ quá cao!",
          body: "Nhiệt độ hiện tại: $temperature°C. Hãy che mát cho cây.",
          type: "alert_temp",
        );
        _lastTempAlert = DateTime.now();
      }
    }
  }

  /// 8. Hiển thị thông báo cục bộ (Task 4.4)
  Future<void> showLocalAlert({
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'plant_alerts',
      'Cảnh báo cây trồng',
      channelDescription: 'Kênh thông báo về các cảnh báo của cây trồng',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _localNotifications.show(id, title, body, notificationDetails,
        payload: payload);

    addNotification(NotificationModel(
      id: id.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    ));
  }

  bool _canSendAlert(DateTime? lastAlertTime) {
    if (lastAlertTime == null) return true;
    return DateTime.now().difference(lastAlertTime).inMinutes > 0;
  }

  // --- (CÁC HÀM QUẢN LÝ STATE TỪ CODE CŨ) ---
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String notificationId) {
    var index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      var n = _notifications[index];
      _notifications[index] = NotificationModel(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        timestamp: n.timestamp,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true,
            ))
        .toList();
    notifyListeners();
  }

  // ... (Các hàm deleteNotification, clearAll, clearError giữ nguyên) ...
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
