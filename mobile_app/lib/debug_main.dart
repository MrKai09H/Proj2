// File: mobile_app/lib/debug_main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các dịch vụ và màn hình
// (Hãy chắc chắn các đường dẫn này đúng với cấu trúc dự án của bạn)
import 'features/statistics/screens/statistics_screen.dart';
import 'features/statistics/services/fcm_service.dart';
import 'features/statistics/services/alert_service.dart';

// Import các provider (BẮT BUỘC)
import 'providers/auth_provider.dart';
import 'providers/plant_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/iot_provider.dart';
import 'providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // --- BẮT ĐẦU PHẦN TẠO DỮ LIỆU MẪU ---
  try {
    // 1. Đăng nhập vào tài khoản test của bạn
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "hiep123@gmail.com", // Email bạn đang dùng để test
        password: "123456" // Mật khẩu của tài khoản đó
        );
    print("✅ DEBUG: Dang nhap test (hiep123@gmail.com) thanh cong!");

    // 2. Chạy hàm tạo dữ liệu mẫu
    await _seedMockData();
  } catch (e) {
    print("❌ LOI DANG NHAP TEST: $e");
    print("Vui long dam bao email/password la dung va chay lai.");
    return;
  }
  // --- KẾT THÚC PHẦN TẠO DỮ LIỆU MẪU ---

  // Khởi tạo các dịch vụ thông báo (phải sau khi đăng nhập)
  await FCMService().initialize();
  await AlertService().initialize();

  runApp(const DebugStatisticsApp());
}

/// HÀM TẠO DỮ LIỆU MẪU (SEEDER)
Future<void> _seedMockData() async {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  const String plantId = "estFucJNVBHhFnQL5rEZ"; // ID cây giả định

  // === PHẦN SỬA ĐỔI QUAN TRỌNG ===
  // Bỏ đi đoạn kiểm tra so sánh với testUserId cố định.
  // Bây giờ chỉ cần kiểm tra xem đã đăng nhập thành công hay chưa.
  if (userId == null) {
    print("❌ Loi Seeder: Khong the lay duoc User ID. Huy bo tao du lieu mau.");
    return;
  }
  // ==============================

  print("--- DEBUG: Bat dau tao du lieu mau (seeding) cho userId: $userId ---");

  final collection = firestore.collection('diary_entries');

  // Xóa dữ liệu cũ của user này (để test cho sạch)
  var oldData = await collection.where('userId', isEqualTo: userId).get();
  for (var doc in oldData.docs) {
    await doc.reference.delete();
  }
  print("DEBUG: Da xoa ${oldData.size} muc nhat ky cu.");

  // Dữ liệu mẫu mới
  final mockData = [
    // Tuần này
    {
      'activityType': 'watering',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      'notes': 'Tuoi 100ml'
    },
    {
      'activityType': 'observation',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      'notes': 'Cay ra la moi'
    },
    {
      'activityType': 'watering',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      'notes': 'Tuoi 150ml'
    },

    // Tháng này
    {
      'activityType': 'fertilizing',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      'notes': 'Bon phan NPK'
    },
    {
      'activityType': 'pruning',
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      'notes': 'Tia la vang'
    },

    // Năm này
    {
      'activityType': 'watering',
      'createdAt': DateTime.now().subtract(const Duration(days: 40)),
      'notes': 'Tuoi 100ml'
    },
  ];

  // Đẩy lên Firebase
  for (var data in mockData) {
    await collection.add({
      'plantId': plantId,
      'userId': userId,
      'activityType': data['activityType'],
      'createdAt': data['createdAt'],
      'notes': data['notes'],
      'title': data['activityType']
    });
  }
  print("✅ DEBUG: Da tao ${mockData.length} muc nhat ky mau tren Firebase!");
}

class DebugStatisticsApp extends StatelessWidget {
  const DebugStatisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // BẮT BUỘC: Phải cung cấp các provider cho ứng dụng
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MaterialApp(
        title: 'Debug Statistics Screen',
        home: StatisticsScreen(), // Chạy thẳng vào màn hình Thống kê
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
