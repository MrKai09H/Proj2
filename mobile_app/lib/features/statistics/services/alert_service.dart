// File: mobile_app/lib/features/statistics/services/alert_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  // 1. Khởi tạo plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Khởi tạo dịch vụ
  Future<void> initialize() async {
    // 2. Cài đặt cho từng nền tảng
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      'app_icon', 
    );

    // Cài đặt cho iOS (hỏi quyền)
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Xử lý khi nhận thông báo trên iOS đời cũ
      },
    );

    // 3. Khởi tạo plugin với các cài đặt
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng nhấn vào thông báo
        print("Notification tapped with payload: ${response.payload}");
      },
    );
  }

  /// Hàm chính để hiển thị thông báo
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload, // Dữ liệu đi kèm, ví dụ 'plant_123'
  }) async {
    // 4. Định nghĩa chi tiết thông báo
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'plant_alerts', // ID của channel
      'Cảnh báo cây trồng', // Tên của channel
      channelDescription: 'Kênh thông báo về các cảnh báo của cây trồng',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 5. Hiển thị thông báo
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
