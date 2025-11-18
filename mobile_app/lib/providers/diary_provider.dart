import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry_model.dart';
import '../services/firebase/firestore_service.dart'; // Đảm bảo đường dẫn đúng
import '../services/firebase/storage_service.dart';   // Đảm bảo đường dẫn đúng

class DiaryProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DiaryEntryModel> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<DiaryEntryModel> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==========================================
  // 1. LOAD ENTRIES (Lấy danh sách nhật ký/ảnh)
  // ==========================================
  Future<void> loadEntries(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // ⚠️ LƯU Ý QUAN TRỌNG:
      // Nếu App bị Crash hoặc báo lỗi đỏ lòm ở dòng dưới đây, hãy mở Log (Run Tab).
      // Firebase sẽ cung cấp 1 đường link bắt đầu bằng "https://console.firebase.google.com..."
      // Bấm vào link đó để tạo Index tự động cho query (userId + plantId + createdAt).
      
      final snapshot = await FirebaseFirestore.instance
          .collection('diary_entries')
          .where('userId', isEqualTo: user.uid)
          .where('plantId', isEqualTo: plantId)
          .orderBy('createdAt', descending: true)
          .get();

      _entries = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Gán ID của document vào model
        return DiaryEntryModel.fromMap(data);
      }).toList();

    } catch (e) {
      _error = 'Lỗi tải dữ liệu: $e';
      print('Error loading diary entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 2. ADD ENTRY (Thêm nhật ký đầy đủ)
  // ==========================================
  Future<bool> addEntry(DiaryEntryModel entry, {List<File>? imageFiles}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      List<String> imageUrls = [];
      String tempEntryId = DateTime.now().millisecondsSinceEpoch.toString();

      if (imageFiles != null && imageFiles.isNotEmpty) {
        final basePath = 'diary/${user.uid}/$tempEntryId';
        imageUrls = await _storage.uploadMultipleImages(basePath, imageFiles);
      }

      final entryData = {
        'activityType': entry.activityType,
        'content': entry.content,
        'plantId': entry.plantId,
        'userId': user.uid,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.addDocument('diary_entries', entryData);
      await loadEntries(entry.plantId); // Load lại list ngay

      return true;
    } catch (e) {
      _error = 'Lỗi thêm nhật ký: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // 3. ADD PHOTO LOG (Dùng riêng cho GalleryScreen)
  // ==========================================
  // Hàm này giúp GalleryScreen thêm ảnh nhanh mà không cần tạo model phức tạp
  Future<void> addPhotoLog(String plantId, String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Tạo một entry nhật ký loại "photo"
      final entryData = {
        'userId': user.uid,
        'plantId': plantId,
        'activityType': 'photo', 
        'content': 'Đã thêm ảnh mới vào thư viện',
        'imageUrls': [imageUrl], // Lưu URL ảnh vào mảng
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.addDocument('diary_entries', entryData);
      
      // Load lại để UI cập nhật ảnh mới
      await loadEntries(plantId);
      
    } catch (e) {
      print('Lỗi addPhotoLog: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. DELETE IMAGE (Xóa ảnh khỏi thư viện)
  // ==========================================
  // Lưu ý: Hàm này sẽ tìm Entry chứa ảnh đó và xóa URL khỏi mảng imageUrls
  Future<void> deleteImageFromGallery(String plantId, String imageUrl) async {
     _isLoading = true;
     notifyListeners();
     
     try {
       // 1. Xóa file trên Storage trước
       await _storage.deleteImage(imageUrl);

       // 2. Tìm xem ảnh này thuộc về bài đăng nào
       // (Cách này hơi thủ công nhưng an toàn)
       for (var entry in _entries) {
         if (entry.imageUrls.contains(imageUrl)) {
           
           // Tạo mảng ảnh mới đã loại bỏ ảnh cần xóa
           List<String> newImages = List.from(entry.imageUrls);
           newImages.remove(imageUrl);

           // Cập nhật lại Firestore
           await _firestore.updateDocument('diary_entries', entry.id, {
             'imageUrls': newImages,
             'updatedAt': FieldValue.serverTimestamp(),
           });
           
           break; // Đã tìm thấy và xóa xong
         }
       }
       
       // 3. Load lại dữ liệu
       await loadEntries(plantId);

     } catch (e) {
       _error = 'Lỗi xóa ảnh: $e';
       print(_error);
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  // ==========================================
  // 5. DELETE ENTRY (Xóa bài nhật ký hoàn toàn)
  // ==========================================
  Future<bool> deleteEntry(String entryId, String plantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Tìm entry cần xóa để lấy danh sách ảnh (dọn dẹp Storage)
      // Dùng orElse để tạo model rỗng tránh lỗi nếu không tìm thấy
      final entryToDelete = _entries.firstWhere(
        (e) => e.id == entryId,
        orElse: () => DiaryEntryModel(
            id: '', 
            plantId: '', 
            userId: '', 
            activityType: '', 
            content: '', 
            imageUrls: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()
        ),
      );

      // 2. Nếu tìm thấy entry, tiến hành xóa ảnh trên Storage trước
      if (entryToDelete.id.isNotEmpty && entryToDelete.imageUrls.isNotEmpty) {
        for (String imageUrl in entryToDelete.imageUrls) {
          try {
            await _storage.deleteImage(imageUrl);
          } catch (e) {
            print('Cảnh báo: Không xóa được ảnh $imageUrl ($e)');
            // Tiếp tục chạy, không dừng lại chỉ vì 1 ảnh lỗi
          }
        }
      }

      // 3. Xóa document trong Firestore
      await _firestore.deleteDocument('diary_entries', entryId);

      // 4. Load lại danh sách
      await loadEntries(plantId);

      return true; // Trả về true báo thành công
    } catch (e) {
      _error = 'Lỗi xóa nhật ký: $e';
      print(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
