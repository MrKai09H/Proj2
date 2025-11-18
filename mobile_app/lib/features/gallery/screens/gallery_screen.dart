import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Import đúng đường dẫn file trong project của bạn
import '../../../providers/plant_provider.dart';
import '../../../providers/diary_provider.dart';
import '../../../services/firebase/storage_service.dart';
import '../widgets/photo_grid_item.dart'; 
import '../widgets/full_screen_image_viewer.dart';
import '../../home/widgets/empty_state_widget.dart';

class GalleryScreen extends StatefulWidget {
  final String plantId;

  const GalleryScreen({super.key, required this.plantId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  bool _isLoading = false;
  List<String> _allPhotos = [];

  @override
  void initState() {
    super.initState();
    // Load dữ liệu sau khi build xong frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhotos();
    });
  }

  // Hàm tải ảnh tổng hợp từ Plant Profile và Diary
  Future<void> _loadPhotos() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final diaryProvider = context.read<DiaryProvider>();
      final plantProvider = context.read<PlantProvider>();
      
      // 1. Load danh sách nhật ký từ Firestore
      await diaryProvider.loadEntries(widget.plantId);
      final diaryEntries = diaryProvider.entries;

      // 2. Lấy thông tin cây để lấy ảnh đại diện (nếu cần)
      // Lưu ý: Dùng try-catch hoặc firstWhereOrNull để tránh crash nếu cây bị xóa
      String? plantImage;
      try {
        final plant = plantProvider.plants.firstWhere((p) => p.id == widget.plantId);
        plantImage = plant.imageUrl;
      } catch (_) {
        // Không tìm thấy cây, bỏ qua
      }

      // 3. Gom tất cả ảnh vào 1 list
      final photos = <String>[];
      
      // Thêm ảnh đại diện cây (nếu có)
      if (plantImage != null && plantImage.isNotEmpty) {
        photos.add(plantImage);
      }

      // Thêm ảnh từ các bài nhật ký
      for (final entry in diaryEntries) {
        if (entry.imageUrls.isNotEmpty) {
          photos.addAll(entry.imageUrls);
        }
      }

      if (mounted) {
        setState(() {
          _allPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Hàm thêm ảnh mới
  Future<void> _addPhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      // 1. Upload lên Storage
      final file = File(pickedFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = 'plants/${widget.plantId}/gallery/$timestamp.jpg';
      
      final imageUrl = await _storageService.uploadImage(imagePath, file);

      if (imageUrl == null) {
        throw Exception('Upload thất bại (URL null)');
      }

      // 2. QUAN TRỌNG: Gọi Provider để lưu URL vào Firestore
      if (mounted) {
        await context.read<DiaryProvider>().addPhotoLog(widget.plantId, imageUrl);
      }

      // 3. Reload UI
      await _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm ảnh thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm xóa ảnh
  Future<void> _confirmDeletePhoto(int index) async {
    final imageUrl = _allPhotos[index];
    
    // Hỏi xác nhận trước khi xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa ảnh?"),
        content: const Text("Hành động này không thể hoàn tác."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      
      // Gọi hàm xóa thông minh trong Provider
      await context.read<DiaryProvider>().deleteImageFromGallery(widget.plantId, imageUrl);
      
      await _loadPhotos(); // Reload lại list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ảnh'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // UI chọn nguồn ảnh (Camera/Thư viện)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chọn nguồn ảnh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _viewPhoto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: _allPhotos,
          initialIndex: index,
          onDelete: (deleteIndex) async {
             Navigator.pop(context); // Đóng viewer trước
             await _confirmDeletePhoto(deleteIndex); // Gọi hàm xóa
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy tên cây an toàn
    String plantName = "Cây của tôi";
    try {
      final plant = context.read<PlantProvider>().plants.firstWhere((p) => p.id == widget.plantId);
      plantName = plant.name;
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thư viện ảnh'),
            Text(plantName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
           if (_isLoading)
             const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))
           else
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _addPhoto,
            )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPhotos,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allPhotos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allPhotos.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.photo_library_outlined,
        title: 'Chưa có ảnh nào',
        message: 'Lưu giữ khoảnh khắc phát triển của cây\nbằng cách thêm ảnh mới.',
        buttonText: 'Thêm ảnh ngay',
        onButtonPressed: _addPhoto,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _allPhotos.length,
      itemBuilder: (context, index) {
        return PhotoGridItem(
          imageUrl: _allPhotos[index],
          onTap: () => _viewPhoto(index),
        );
      },
    );
  }
}