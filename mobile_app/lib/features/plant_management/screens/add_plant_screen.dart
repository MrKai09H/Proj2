import 'dart:io'; // <--- 1. Thêm thư viện này để dùng File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Import các file trong dự án
import '../../../providers/auth_provider.dart';
import '../../../providers/plant_provider.dart';
import '../../../models/plant_model.dart';
import '../../../services/firebase/storage_service.dart'; // <--- 2. Import StorageService
import '../widgets/plant_form_field.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/date_picker_field.dart';

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
  
  // Khởi tạo StorageService
  final _storageService = StorageService(); 

  DateTime? _plantedDate;
  XFile? _pickedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Lưu context để dùng sau khi await
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_plantedDate == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày trồng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // --- LOGIC UPLOAD ẢNH THẬT ---
      String imageUrl = ''; // Mặc định là rỗng

      if (_pickedImage != null) {
        // 1. Chuyển đổi XFile sang File
        File imageFile = File(_pickedImage!.path);
        
        // 2. Tạo đường dẫn file duy nhất: plants/{userId}/{timestamp}.jpg
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String path = 'plants/${user.id}/$timestamp.jpg';

        // 3. Gọi StorageService để upload
        String? uploadedUrl = await _storageService.uploadImage(path, imageFile);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl; // Gán URL thật
        }
      }
      // -----------------------------

      final plant = PlantModel(
        id: '', // Firestore sẽ tự sinh ID, nhưng Provider đã xử lý việc này
        userId: user.id,
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        plantedDate: _plantedDate!,
        imageUrl: imageUrl, // <--- Sử dụng URL thật ở đây
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Gọi Provider để lưu vào Firestore
      final success = await context.read<PlantProvider>().addPlant(plant);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đã thêm cây mới thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(); // Đóng màn hình
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi thêm cây (Provider trả về false)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thêm cây mới'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            ImagePickerWidget(
              onImagePicked: (image) {
                setState(() {
                  _pickedImage = image;
                });
              },
            ),
            const SizedBox(height: 24),

            // Name Field
            PlantFormField(
              label: 'Tên cây *',
              hint: 'VD: Xương rồng nhà tôi',
              controller: _nameController,
              prefixIcon: Icons.eco,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên cây';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Species Field
            PlantFormField(
              label: 'Loài cây *',
              hint: 'VD: Xương rồng, Cây Sen Đá',
              controller: _speciesController,
              prefixIcon: Icons.category,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập loài cây';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Planted Date
            DatePickerField(
              label: 'Ngày trồng *',
              selectedDate: _plantedDate,
              onDateSelected: (date) {
                setState(() {
                  _plantedDate = date;
                });
              },
              validator: (date) {
                if (date == null) {
                  return 'Vui lòng chọn ngày trồng';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description Field
            PlantFormField(
              label: 'Mô tả (Tùy chọn)',
              hint: 'Ghi chú về cây của bạn...',
              controller: _descriptionController,
              prefixIcon: Icons.note,
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Thêm cây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Help Text
            Center(
              child: Text(
                '* Trường bắt buộc',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}