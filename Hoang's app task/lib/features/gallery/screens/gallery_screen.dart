import 'package:flutter/material.dart';

/// Gallery Screen - Assigned to: Hoàng Chí Bằng
/// Task 1.5: Trang Thư viện ảnh của cây
class GalleryScreen extends StatefulWidget {
  final String plantId;

  const GalleryScreen({super.key, required this.plantId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    // TODO: Load photos for this plant
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện ảnh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () {
              // TODO: Add photo
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12, // Placeholder
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: View full image
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

