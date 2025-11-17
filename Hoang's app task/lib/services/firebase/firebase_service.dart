// Đường dẫn: lib/services/firebase/firebase_service.dart

import 'package:firebase_core/firebase_core.dart';
// 1. SỬ DỤNG IMPORT TƯƠNG ĐỐI (đi lùi 2 cấp thư mục)
import 'package:plant_care_app/firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    // 2. Code này bây giờ sẽ hết báo lỗi
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
