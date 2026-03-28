// File: lib/features/statistics/widgets/activity_breakdown_chart.dart

import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class ActivityBreakdownChart extends StatelessWidget {
  final Map<String, double> data;

  const ActivityBreakdownChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Khai báo danh sách màu, các màu này sẽ được dùng ở dưới
    final colorList = <Color>[
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.grey.shade400,
    ];

    // Dùng để dịch tên hoạt động từ tiếng Anh sang tiếng Việt
    final Map<String, String> activityNames = {
      'watering': 'Tưới nước',
      'fertilizing': 'Bón phân',
      'pruning': 'Tỉa cành',
      'observation': 'Quan sát',
      'unknown': 'Khác',
    };
    
    // Tạo một Map mới với tên đã được dịch
    final Map<String, double> translatedData = data.map((key, value) {
        return MapEntry(activityNames[key] ?? key, value);
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(
          // Dữ liệu cho biểu đồ
          dataMap: translatedData,
          
          // Các thuộc tính tùy chỉnh giao diện
          animationDuration: const Duration(milliseconds: 800),
          chartLegendSpacing: 40,
          chartRadius: MediaQuery.of(context).size.width / 3.5,
          
          // ==== 2. SỬ DỤNG BIẾN `colorList` TẠI ĐÂY ====
          // Dòng này đảm bảo biến colorList được sử dụng, và sửa lỗi cảnh báo
          colorList: colorList,
          
          initialAngleInDegree: 0,
          chartType: ChartType.ring,
          ringStrokeWidth: 32,
          centerText: "HOẠT ĐỘNG",
          
          // Tùy chọn cho phần chú thích (legend)
          legendOptions: const LegendOptions(
            showLegendsInRow: false,
            legendPosition: LegendPosition.right,
            showLegends: true,
            legendTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Tùy chọn cho các giá trị hiển thị trên biểu đồ
          chartValuesOptions: const ChartValuesOptions(
            showChartValueBackground: false,
            showChartValues: true,
            showChartValuesInPercentage: true,
            showChartValuesOutside: false,
            decimalPlaces: 0,
          ),
        ),
      ),
    );
  }
}