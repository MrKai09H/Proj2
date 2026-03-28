import 'package:flutter/material.dart';

/// Diary List Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.4: Trang Ghi nhật ký chăm sóc
class DiaryListScreen extends StatefulWidget {
  final String plantId;

  const DiaryListScreen({super.key, required this.plantId});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  void _loadDiaryEntries() {
    // TODO: Load diary entries for this plant
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký chăm sóc'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // Placeholder
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Tưới nước',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${DateTime.now().day}/${DateTime.now().month}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Đã tưới nước cho cây vào buổi sáng'),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add-diary',
            arguments: widget.plantId,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

