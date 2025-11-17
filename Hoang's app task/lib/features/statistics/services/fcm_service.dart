import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// --- XỬ LÝ THÔNG BÁO KHI APP BỊ TẮT (TERMINATED) ---
/// Hàm này BẮT BUỘC phải nằm ngoài class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Handling a background message: ${message.messageId}");
}

/// --- DỊCH VỤ FCM CHÍNH ---
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Khởi tạo dịch vụ thông báo đẩy FCM
  Future<void> initialize() async {
    // 1️⃣ Xin quyền gửi thông báo
    await _requestNotificationPermission();

    // 2️⃣ Lấy FCM Token của thiết bị
    final String? fcmToken = await _getFCMToken();
    if (fcmToken != null) {
      print("✅ FCM Token: $fcmToken");
      _saveTokenToDatabase(fcmToken);
    }

    // 3️⃣ Theo dõi sự kiện token làm mới
    _onTokenRefresh();

    // 4️⃣ Đăng ký xử lý khi nhận thông báo nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5️⃣ Tùy chọn: xử lý khi người dùng nhấn vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 User tapped notification: ${message.data}");
    });
  }

  /// --- Xin quyền thông báo ---
  Future<void> _requestNotificationPermission() async {
    if (Platform.isIOS) {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission on iOS');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('ℹ️ User granted provisional notification permission');
      } else {
        print('❌ User declined or has not accepted notification permission');
      }
    } else {
      // Android: quyền thường được cấp tự động (Android 13+ có thể yêu cầu riêng)
      print('✅ Android: notification permission usually granted by default');
    }
  }

  /// --- Lấy FCM token của thiết bị ---
  Future<String?> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print("⚠️ Error getting FCM token: $e");
      return null;
    }
  }

  /// --- Lưu token vào Firestore ---
  Future<void> _saveTokenToDatabase(String token) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      print("⚠️ User not logged in, token not saved.");
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print("✅ Token saved to Firestore for user: ${user.uid}");
    } catch (e) {
      print("⚠️ Error saving token to Firestore: $e");
    }
  }

  /// --- Theo dõi token refresh ---
  void _onTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      print("🔄 FCM token refreshed: $newToken");
      _saveTokenToDatabase(newToken);
    });
  }
}
