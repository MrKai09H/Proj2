import 'package:flutter/material.dart';

/// Add Diary Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.4: Trang Ghi nhật ký chăm sóc
class AddDiaryScreen extends StatefulWidget {
  final String plantId;

  const AddDiaryScreen({super.key, required this.plantId});

  @override
  State<AddDiaryScreen> createState() => _AddDiaryScreenState();
}

class _AddDiaryScreenState extends State<AddDiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedActivity = 'watering';

  final List<Map<String, dynamic>> _activities = [
    {'value': 'watering', 'label': 'Tưới nước', 'icon': Icons.water_drop},
    {'value': 'fertilizing', 'label': 'Bón phân', 'icon': Icons.grass},
    {'value': 'pruning', 'label': 'Tỉa cành', 'icon': Icons.content_cut},
    {'value': 'observation', 'label': 'Quan sát', 'icon': Icons.visibility},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save diary entry
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nhật ký!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi nhật ký'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loại hoạt động',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Activity type selector
              Wrap(
                spacing: 8,
                children: _activities.map((activity) {
                  final isSelected = _selectedActivity == activity['value'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(activity['icon'], size: 16),
                        const SizedBox(width: 4),
                        Text(activity['label']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivity = activity['value'];
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  hintText: 'Ghi chú về hoạt động chăm sóc...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Add photos
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_photo_alternate),
                  title: const Text('Thêm ảnh'),
                  subtitle: const Text('Chụp hoặc chọn ảnh từ thư viện'),
                  onTap: () {
                    // TODO: Implement image picker
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Lưu nhật ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

