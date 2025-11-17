import 'package:flutter/material.dart';

/// Add Plant Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.3: Trang Thêm / Xoá / Sửa thông tin cây
class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _plantedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _plantedDate = picked;
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement save logic using PlantProvider
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm cây thành công!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm cây mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên cây',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên cây';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Species
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Loại cây',
                  prefixIcon: Icon(Icons.eco),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập loại cây';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Planted date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Ngày trồng'),
                subtitle: Text(
                  '${_plantedDate.day}/${_plantedDate.month}/${_plantedDate.year}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (không bắt buộc)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Image picker (placeholder)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Thêm ảnh'),
                  subtitle: const Text('Chọn ảnh cây trồng'),
                  trailing: const Icon(Icons.add_photo_alternate),
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
                  child: const Text('Thêm cây'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

