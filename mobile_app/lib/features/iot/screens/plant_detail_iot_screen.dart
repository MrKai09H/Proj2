import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart'; 

import '../../../providers/iot_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/statistics_provider.dart';
import '../../../core/routes/app_routes.dart';

class PlantDetailIotScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailIotScreen({super.key, required this.plantId});

  @override
  State<PlantDetailIotScreen> createState() => _PlantDetailIotScreenState();
}

class _PlantDetailIotScreenState extends State<PlantDetailIotScreen> {
  // Trạng thái thông tin cây
  String _plantName = 'Đang tải...';
  String _plantType = '--';
  String _plantAge = '0 ngày';
  String? _plantImageUrl; // <--- 1. THÊM BIẾN LƯU URL ẢNH
  bool _isPlantLoading = true;

  final String _chartPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _loadAllData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .startSensorListening(plantId: widget.plantId);
    });
  }

  void _loadAllData() {
    _fetchPlantDetails();
    context.read<IotProvider>().initialize();
    context.read<StatisticsProvider>().fetchStatistics(
        widget.plantId, _chartPeriod);
  }

  // Hàm tải chi tiết cây từ Firestore
  Future<void> _fetchPlantDetails() async {
    if (!mounted) return;
    setState(() => _isPlantLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('plants')
          .doc(widget.plantId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        
        final DateTime plantedDate = (data['plantedDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final int age = DateTime.now().difference(plantedDate).inDays;

        setState(() {
          _plantName = data['name'] ?? 'Cây không tên';
          _plantType = data['plantType'] ?? data['type'] ?? data['species'] ?? 'Chưa rõ loại';
          _plantAge = '$age ngày tuổi';
          
          // <--- 2. LẤY URL TỪ FIRESTORE GÁN VÀO BIẾN
          _plantImageUrl = data['imageUrl']; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plantName = 'Lỗi tải thông tin';
          _plantAge = '';
        });
      }
      debugPrint('Lỗi tải cây: $e');
    } finally {
      if (mounted) setState(() => _isPlantLoading = false);
    }
  }

  @override
  void dispose() {
    Provider.of<NotificationProvider>(context, listen: false)
        .stopSensorListening();
    super.dispose();
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    final style = const TextStyle(fontSize: 12, color: Colors.grey);
    String text = '';
    final int index = value.toInt();
    final now = DateTime.now();
    DateTime startDate;

    if (_chartPeriod == 'week') {
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
    }
    return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(text, style: style));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cây & IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.statistics,
                arguments: widget.plantId,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.pushNamed(context, '/gallery', arguments: widget.plantId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-plant', arguments: widget.plantId)
                  .then((_) => _loadAllData());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THÔNG TIN CÂY & HÌNH ẢNH
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // <--- 3. KHUNG HIỂN THỊ ẢNH
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Dùng ClipRRect để bo góc ảnh cho khớp với Container
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _isPlantLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.green))
                              : (_plantImageUrl != null && _plantImageUrl!.isNotEmpty)
                                  // Nếu có URL ảnh -> Hiển thị ảnh mạng
                                  ? Image.network(
                                      _plantImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    )
                                  // Nếu không có URL -> Hiển thị Icon mặc định
                                  : const Center(child: Icon(Icons.eco, size: 80, color: Colors.green)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _plantName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_plantType • $_plantAge',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. DỮ LIỆU CẢM BIẾN (Code giữ nguyên)
              const Text(
                'Dữ liệu cảm biến',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer<IotProvider>(
                builder: (context, iotProvider, _) {
                  final latestData = iotProvider.latestSensorData;
                  return Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.orange[50],
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.thermostat, size: 40, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  '${latestData != null ? (latestData['temperature'] ?? 0.0).toStringAsFixed(1) : '--'}°C',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const Text('Nhiệt độ', style: TextStyle(color: Colors.orange)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: Colors.blue[50],
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.water_drop, size: 40, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '${latestData != null ? (latestData['soilMoisture'] ?? 0).toString() : '--'}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const Text('Độ ẩm đất', style: TextStyle(color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. ĐIỀU KHIỂN MÁY BƠM (Code giữ nguyên)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Điều khiển tưới nước', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Consumer<IotProvider>(
                        builder: (context, iotProvider, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: iotProvider.pumpState
                                      ? null
                                      : () => iotProvider.controlPump(true),
                                  icon: const Icon(Icons.water_drop),
                                  label: const Text('Bật máy bơm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: !iotProvider.pumpState
                                      ? null
                                      : () => iotProvider.controlPump(false),
                                  icon: const Icon(Icons.stop_circle_outlined),
                                  label: const Text('Tắt máy bơm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Consumer<IotProvider>(
                        builder: (context, iot, _) => Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: iot.pumpState ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Trạng thái: ${iot.pumpState ? "Đang hoạt động" : "Đã tắt"}',
                              style: TextStyle(
                                color: iot.pumpState ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. BIỂU ĐỒ (Code giữ nguyên)
              const Text(
                'Lịch sử chăm sóc (Tuần qua)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<StatisticsProvider>(
                    builder: (context, statsProvider, _) {
                      if (statsProvider.isLoading) {
                          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      }
                      if (statsProvider.hasError) {
                          return SizedBox(height: 200, child: Center(child: Text('Lỗi tải biểu đồ: ${statsProvider.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
                      }
                      if (statsProvider.careHistoryData.isEmpty || statsProvider.careHistoryData.every((spot) => spot.y == 0)) {
                          return const SizedBox(height: 200, child: Center(child: Text('Chưa có hoạt động chăm sóc nào trong tuần.')));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Số lần chăm sóc', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: _getBottomTitles)),
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 28)),
                                ),
                                borderData: FlBorderData(show: false),
                                minX: 0,
                                maxX: statsProvider.chartMaxX,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: statsProvider.careHistoryData,
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.15)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 5. NÚT XEM NHẬT KÝ
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/diary-list', arguments: widget.plantId);
                  },
                  icon: const Icon(Icons.history_edu),
                  label: const Text('Xem nhật ký chi tiết'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.green),
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}