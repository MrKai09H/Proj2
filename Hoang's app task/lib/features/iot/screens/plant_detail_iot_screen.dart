import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/iot_provider.dart';

/// Plant Detail with IoT Screen - Assigned to: Nguyễn Anh Tiến
/// Task 3.4: Trang Chi tiết cây & Hiển thị dữ liệu IoT
/// Task 3.5: Tích hợp chức năng Điều khiển tưới nước
class PlantDetailIotScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailIotScreen({super.key, required this.plantId});

  @override
  State<PlantDetailIotScreen> createState() => _PlantDetailIotScreenState();
}

class _PlantDetailIotScreenState extends State<PlantDetailIotScreen> {
  @override
  void initState() {
    super.initState();
    _loadIotData();
  }

  void _loadIotData() {
    context.read<IotProvider>().loadSensorData(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết cây & IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              Navigator.pushNamed(context, '/gallery', arguments: widget.plantId);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/edit-plant', arguments: widget.plantId);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadIotData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.eco, size: 80, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tên cây',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text('Loại cây • X ngày tuổi'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Real-time sensor data
              const Text(
                'Dữ liệu cảm biến',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Consumer<IotProvider>(
                builder: (context, iotProvider, _) {
                  final latestData = iotProvider.latestData;
                  
                  return Row(
                    children: [
                      // Temperature card
                      Expanded(
                        child: Card(
                          color: Colors.orange[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.thermostat, size: 40, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  '${latestData?.temperature.toStringAsFixed(1) ?? '--'}°C',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Nhiệt độ'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Soil moisture card
                      Expanded(
                        child: Card(
                          color: Colors.blue[100],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(Icons.water_drop, size: 40, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text(
                                  '${latestData?.soilMoisture.toStringAsFixed(0) ?? '--'}%',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('Độ ẩm đất'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Pump control
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điều khiển tưới nước',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Consumer<IotProvider>(
                        builder: (context, iotProvider, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: iotProvider.pumpState
                                      ? null
                                      : () => iotProvider.controlPump(widget.plantId, true),
                                  icon: const Icon(Icons.water),
                                  label: const Text('Bật máy bơm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: !iotProvider.pumpState
                                      ? null
                                      : () => iotProvider.controlPump(widget.plantId, false),
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Tắt máy bơm'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trạng thái: ${context.watch<IotProvider>().pumpState ? "Đang bật" : "Đã tắt"}',
                        style: TextStyle(
                          color: context.watch<IotProvider>().pumpState
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Chart placeholder
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biểu đồ lịch sử',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Biểu đồ sẽ được hiển thị ở đây'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Diary button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/diary-list', arguments: widget.plantId);
                  },
                  icon: const Icon(Icons.book),
                  label: const Text('Xem nhật ký chăm sóc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

