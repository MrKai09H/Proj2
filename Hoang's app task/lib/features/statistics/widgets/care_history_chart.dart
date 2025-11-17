// File: lib/features/statistics/widgets/care_history_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:plant_care_app/features/statistics/services/statistics_service.dart';

class CareHistoryChart extends StatefulWidget {
  final String period;

  const CareHistoryChart({
    super.key,
    required this.period,
  });

  @override
  State<CareHistoryChart> createState() => _CareHistoryChartState();
}

class _CareHistoryChartState extends State<CareHistoryChart> {
  final StatisticsService _service = StatisticsService();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: FutureBuilder<Map<String, double>>(
          future: _service.getCareHistoryChartData(period: widget.period),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return SizedBox(
                  height: 200,
                  child: Center(child: Text('Lỗi: ${snapshot.error}')));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                  height: 200, child: Center(child: Text('Không có dữ liệu.')));
            }

            final data = snapshot.data!;
            final maxYValue = data.values.isEmpty
                ? 2
                : data.values.reduce((a, b) => a > b ? a : b);

            return SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: _calculateChartWidth(widget.period),
                  child: BarChart(
                    BarChartData(
                      maxY: (maxYValue + 1)
                          .toDouble(), // Thêm chút không gian ở trên
                      barGroups: _createBarGroups(data, widget.period),
                      titlesData: _buildTitles(widget.period),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.round()} lần',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- CÁC HÀM HELPER ĐÃ ĐƯỢC CẬP NHẬT ---

  double _calculateChartWidth(String period) {
    switch (period) {
      case 'month':
        return 800; // Tăng chiều rộng cho tháng
      case 'year':
        return 600; // Tăng chiều rộng cho năm
      case 'week':
      default:
        return 300;
    }
  }

  // === SỬA LẠI LOGIC VẼ CỘT ===
  List<BarChartGroupData> _createBarGroups(
      Map<String, double> data, String period) {
    if (period == 'week') {
      return List.generate(7, (index) {
        final key = index.toString();
        final count = data[key] ?? 0;
        return BarChartGroupData(x: index, barRods: [
          BarChartRodData(
              toY: count,
              color: count > 0 ? Colors.teal : Colors.grey.shade300,
              width: 15,
              borderRadius: BorderRadius.circular(4)),
        ]);
      });
    } else if (period == 'month') {
      return List.generate(31, (index) {
        final key = (index + 1).toString();
        final count = data[key] ?? 0;
        return BarChartGroupData(x: index, barRods: [
          BarChartRodData(
              toY: count,
              color: count > 0 ? Colors.teal : Colors.grey.shade300,
              width: 8,
              borderRadius: BorderRadius.circular(2)),
        ]);
      });
    } else {
      // 'year'
      return List.generate(12, (index) {
        final key = (index + 1).toString();
        final count = data[key] ?? 0;
        return BarChartGroupData(x: index, barRods: [
          BarChartRodData(
              toY: count,
              color: count > 0 ? Colors.teal : Colors.grey.shade300,
              width: 20,
              borderRadius: BorderRadius.circular(4)),
        ]);
      });
    }
  }

  // === SỬA LẠI LOGIC HIỂN THỊ NHÃN ===
  FlTitlesData _buildTitles(String period) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value % 2 != 0)
              return const SizedBox(); // Chỉ hiện các số chẵn
            return Text(value.toInt().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12));
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            const style = TextStyle(
                color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
            String text = '';
            int intValue = value.toInt();

            if (period == 'week') {
              switch (intValue) {
                case 0:
                  text = 'T2';
                  break;
                case 1:
                  text = 'T3';
                  break;
                case 2:
                  text = 'T4';
                  break;
                case 3:
                  text = 'T5';
                  break;
                case 4:
                  text = 'T6';
                  break;
                case 5:
                  text = 'T7';
                  break;
                case 6:
                  text = 'CN';
                  break;
              }
            } else if (period == 'month') {
              // Hiển thị nhãn cho các ngày 1, 5, 10, 15, 20, 25, 30
              if ([0, 4, 9, 14, 19, 24, 29].contains(intValue)) {
                text = (intValue + 1).toString();
              }
            } else {
              // 'year'
              // Hiển thị nhãn cho các tháng
              text = 'T${intValue + 1}';
            }
            return SideTitleWidget(
                axisSide: meta.axisSide, child: Text(text, style: style));
          },
        ),
      ),
    );
  }
}
