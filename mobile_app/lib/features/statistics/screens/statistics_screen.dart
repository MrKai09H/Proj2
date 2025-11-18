// file: statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; 
// Sửa đường dẫn này nếu cần
import '../../../providers/statistics_provider.dart'; // <-- Dùng '..' để đi lên 1 cấp 
 

class StatisticsScreen extends StatefulWidget {
  final String plantId;

  const StatisticsScreen({
    super.key,
    required this.plantId,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'week';

  // --- Không còn mock data ---

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    // Sửa lỗi cú pháp: Dùng context.read
    context
        .read<StatisticsProvider>()
        .fetchStatistics(widget.plantId, _selectedPeriod);
  }

  // Helpers để lấy icon/màu
  IconData _getActivityIcon(String activityName) {
    if (activityName.contains('Tưới nước')) return Icons.water_drop;
    if (activityName.contains('Bón phân')) return Icons.grass;
    if (activityName.contains('Tỉa cành')) return Icons.content_cut;
    if (activityName.contains('Quan sát')) return Icons.visibility;
    return Icons.pending_actions;
  }

  Color _getActivityColor(String activityName) {
    if (activityName.contains('Tưới nước')) return Colors.blue;
    if (activityName.contains('Bón phân')) return Colors.green;
    if (activityName.contains('Tỉa cành')) return Colors.orange;
    if (activityName.contains('Quan sát')) return Colors.purple;
    return Colors.grey;
  }

  /// 1. (THAY ĐỔI) Widget helper cho Chip chọn thời gian
  Widget _buildPeriodChip(BuildContext context, String label, String period) {
    final bool isSelected = _selectedPeriod == period;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        // Hoạt động như ChoiceChip (luôn phải chọn 1)
        if (!isSelected) { // Chỉ cập nhật nếu chọn chip mới
          setState(() => _selectedPeriod = period);
          _fetchData(); 
        }
      },
      // Style để giống Mẫu
      selectedColor: Colors.green, // Màu nền xanh lá cây
      showCheckmark: true,
      checkmarkColor: Colors.white, // Dấu check màu trắng
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Bo góc (ít)
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey[400]!,
        ),
      ),
      backgroundColor: Colors.white, // Nền trắng khi không chọn
    );
  }

  /// 2. (THAY ĐỔI) Widget helper cho nhãn Trục X (Bottom Titles)
  Widget _getBottomTitles(double value, TitleMeta meta) {
    final style = const TextStyle(fontSize: 12, color: Colors.grey);
    String text = '';
    final int index = value.toInt();

    // Lấy ngày bắt đầu dựa trên provider
    final now = DateTime.now();
    DateTime startDate;

    if (_selectedPeriod == 'week') {
      // Trục X là 0-6. Tính toán T2, T3...
      startDate = now.subtract(const Duration(days: 6));
      final dayForValue = startDate.add(Duration(days: index));
      
      switch (dayForValue.weekday) {
        case DateTime.monday: text = 'T2'; break;
        case DateTime.tuesday: text = 'T3'; break;
        case DateTime.wednesday: text = 'T4'; break;
        case DateTime.thursday: text = 'T5'; break;
        case DateTime.friday: text = 'T6'; break;
        case DateTime.saturday: text = 'T7'; break;
        case DateTime.sunday: text = 'CN'; break;
      }
    } else if (_selectedPeriod == 'month') {
      // Trục X là 0-29. Hiển thị ngày (ví dụ: 1, 5, 10...)
      // Chỉ hiển thị 5 ngày một lần (hoặc 7 ngày 1 lần cho đỡ rối)
      if (index % 7 == 0) { // Hiển thị 7 ngày 1 lần
        startDate = now.subtract(const Duration(days: 29));
        final dayForValue = startDate.add(Duration(days: index));
        text = dayForValue.day.toString(); // Hiển thị ngày
      }
    } else { // 'year'
      // Trục X là 0-364. Hiển thị tháng (T1, T2...)
      startDate = now.subtract(const Duration(days: 364));
      final dayForValue = startDate.add(Duration(days: index));

      // Chỉ hiển thị nhãn cho ngày đầu tiên của tháng (hoặc ngày 0)
      if (dayForValue.day == 1 || index == 0) {
        text = 'T${dayForValue.month}';
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Sửa lại tiêu đề cho khớp mẫu
        title: const Text('Thống kê & Báo cáo'), 
        backgroundColor: Colors.green, // Thêm màu nền cho AppBar
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Đã xảy ra lỗi: ${provider.errorMessage}'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. (THAY ĐỔI) Dùng widget helper _buildPeriodChip
                Row(
                  children: [
                    _buildPeriodChip(context, 'Tuần', 'week'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(context, 'Tháng', 'month'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(context, 'Năm', 'year'),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary cards (Giữ nguyên)
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                provider.totalWaterings.toString(),
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const Text('Lần tưới nước'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.green[100],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                provider.totalDiaries.toString(),
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const Text('Nhật ký'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Care history chart
                const Text(
                  'Lịch sử chăm sóc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số lần chăm sóc',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: provider.careHistoryData.isEmpty
                              ? const Center(child: Text('Không có dữ liệu'))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 2, // Tăng khoảng cách lưới Y
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withAlpha(51),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      // 4. (THAY ĐỔI) Dùng hàm helper _getBottomTitles
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1, 
                                          getTitlesWidget: _getBottomTitles,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 2, // Giống interval lưới
                                          reservedSize: 28,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: provider.chartMaxX, // Trục X động
                                    // 5. (THAY ĐỔI) Xóa minY/maxY để tự động điều chỉnh
                                    // minY: 0,
                                    // maxY: 8, 
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: provider.careHistoryData,
                                        isCurved: true, // Đường cong
                                        color: Colors.green,
                                        barWidth: 4,
                                        dotData: const FlDotData(show: false), // Ẩn chấm
                                        belowBarData: BarAreaData( // Tô bóng
                                          show: true,
                                          color: Colors.green.withAlpha(51),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sensor data chart
                const Text(
                  'Dữ liệu cảm biến',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 12, height: 12, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text('Nhiệt độ (°C)', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Container(width: 12, height: 12, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text('Độ ẩm (%)', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: provider.temperatureData.isEmpty &&
                                  provider.soilMoistureData.isEmpty
                              ? const Center(child: Text('Không có dữ liệu'))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: 20,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withAlpha(51),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      // 4. (THAY ĐỔI) Dùng hàm helper _getBottomTitles
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget: _getBottomTitles,
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 20,
                                          reservedSize: 35,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: provider.chartMaxX, // Trục X động
                                    // 5. (THAY ĐỔI) Xóa minY/maxY để tự động điều chỉnh
                                    // minY: 0,
                                    // maxY: 80, 
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: provider.temperatureData,
                                        isCurved: true,
                                        color: Colors.orange,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                      LineChartBarData(
                                        spots: provider.soilMoistureData,
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSensorInfo(
                              '🌡️',
                              '${provider.avgTemperature.toStringAsFixed(1)}°C',
                              'Nhiệt độ TB',
                              Colors.orange,
                            ),
                            _buildSensorInfo(
                              '💧',
                              '${provider.avgSoilMoisture.toStringAsFixed(1)}%',
                              'Độ ẩm TB',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Activity breakdown
                const Text(
                  'Phân loại hoạt động',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: provider.activityBreakdown.isEmpty
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Không có hoạt động nào'),
                          ))
                        : Column(
                            children: provider.activityBreakdown.entries
                                .map((entry) {
                              final activityName = entry.key;
                              final percentage = entry.value;
                              return ListTile(
                                leading: Icon(
                                  _getActivityIcon(activityName),
                                  color: _getActivityColor(activityName),
                                ),
                                title: Text(activityName),
                                trailing: Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildSensorInfo (Giữ nguyên)
  Widget _buildSensorInfo(
      String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}