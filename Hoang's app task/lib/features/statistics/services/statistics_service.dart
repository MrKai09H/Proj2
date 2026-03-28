// File: mobile_app/lib/features/statistics/services/statistics_service.dart
// *** ĐÂY LÀ PHIÊN BẢN CHUẨN (LỌC THEO USERID VÀ CREATEDAT) ***
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy UserID của người dùng đang đăng nhập
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Tính ngày bắt đầu dựa trên khoảng thời gian
  DateTime _getStartDate(DateTime now, String period) {
    switch (period) {
      case 'month':
        // Lấy ngày đầu tiên của tháng hiện tại
        return DateTime(now.year, now.month, 1);
      case 'year':
        // Lấy ngày đầu tiên của năm hiện tại
        return DateTime(now.year, 1, 1);
      case 'week':
      default:
        // Lấy ngày đầu tiên của tuần hiện tại (Thứ 2)
        return now.subtract(Duration(days: now.weekday - 1));
    }
  }

  // Lấy dữ liệu tóm tắt (Số lần tưới nước, tổng số nhật ký)
  Future<Map<String, int>> getSummaryData({required String period}) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Nguoi dung chua dang nhap');

    final now = DateTime.now();
    final startDate = _getStartDate(now, period);

    print("DEBUG (Summary): Lay du lieu tu ngay: $startDate");

    try {
      final querySnapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      print("DEBUG (Summary): Tim thay ${querySnapshot.docs.length} document(s).");

      if (querySnapshot.docs.isEmpty) {
        return {'wateringCount': 0, 'diaryCount': 0};
      }

      int wateringCount = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('activityType') && data['activityType'] == 'watering') {
          wateringCount++;
        }
      }

      return {
        'wateringCount': wateringCount,
        'diaryCount': querySnapshot.docs.length,
      };
    } catch (e) {
      print("Loi khi lay du lieu tom tat: $e");
      throw Exception('Loi tom tat: $e');
    }
  }

  // Lấy dữ liệu cho biểu đồ cột (Lịch sử chăm sóc)
  Future<Map<String, double>> getCareHistoryChartData({required String period}) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Nguoi dung chua dang nhap');

    final now = DateTime.now();
    final startDate = _getStartDate(now, period);

    final querySnapshot = await _firestore
        .collection('diary_entries')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('createdAt')
        .get();

    final Map<String, double> chartData = {};

    for (var doc in querySnapshot.docs) {
      final timestamp = (doc.data()['createdAt'] as Timestamp).toDate();
      String key;

      if (period == 'week') {
        // Key là ngày trong tuần (0=Thứ 2, 1=Thứ 3, ..., 6=Chủ nhật)
        key = (timestamp.weekday - 1).toString();
      } else if (period == 'month') {
        // Key là ngày trong tháng
        key = timestamp.day.toString();
      } else { // 'year'
        // Key là tháng trong năm
        key = timestamp.month.toString();
      }
      
      chartData[key] = (chartData[key] ?? 0) + 1;
    }
    
    print("DEBUG (ChartData): $chartData");
    return chartData;
  }

  // Lấy dữ liệu cho biểu đồ tròn (Phân loại hoạt động)
  Future<Map<String, double>> getActivityBreakdown({required String period}) async {
    final userId = _getCurrentUserId();
    if (userId == null) throw Exception('Nguoi dung chua dang nhap');

    final now = DateTime.now();
    final startDate = _getStartDate(now, period);

    try {
      final querySnapshot = await _firestore
          .collection('diary_entries')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      if (querySnapshot.docs.isEmpty) return {};

      final Map<String, int> activityCounts = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final activityType = data['activityType'] as String? ?? 'unknown';
        activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;
      }

      final Map<String, double> activityPercentage = {};
      activityCounts.forEach((key, value) {
        // Không cần chuyển sang %, thư viện pie_chart sẽ tự làm
        activityPercentage[key] = value.toDouble(); 
      });

      return activityPercentage;
    } catch (e) {
      print("Loi khi lay du lieu phan loai: $e");
      throw Exception('Loi phan loai: $e');
    }
  }
}