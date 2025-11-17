// Đường dẫn: lib/providers/diary_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diary_entry_model.dart'; // Đảm bảo đường dẫn này đúng

class DiaryProvider with ChangeNotifier {
  // Lấy các dịch vụ Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DiaryEntryModel> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<DiaryEntryModel> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // SỬA LỖI ĐỌC (READ): Đọc từ 'diary_entries' VÀ lọc theo plantId
  Future<void> loadEntries(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = "Người dùng chưa đăng nhập.";
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // *** ĐÂY LÀ TRUY VẤN ĐÚNG ***
      // 1. Tìm trong collection gốc 'diary_entries'
      // 2. Lọc theo 'plantId'
      // 3. Lọc theo 'userId' (để tuân thủ quy tắc bảo mật)
      final querySnapshot = await _firestore
          .collection('diary_entries')
          .where('plantId', isEqualTo: plantId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true) // Sắp xếp mới nhất lên đầu
          .get();

      // Chuyển đổi Firestore document thành danh sách DiaryEntryModel
      _entries = querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Lỗi loadEntries: $e"); // In lỗi ra debug console
      _error = "Lỗi tải nhật ký: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
    }
  }

  // SỬA LỖI GHI (WRITE): Phải thêm plantId và userId
  Future<bool> addEntry(DiaryEntryModel entry, String plantId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _error = "Bạn phải đăng nhập để thêm nhật ký";
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      notifyListeners();

      // Chuyển model của bạn thành một Map
      var entryMap = entry.toFirestore();

      // *** ĐÂY LÀ PHẦN SỬA LỖI QUAN TRỌNG NHẤT ***
      // Thêm các trường mà quy tắc bảo mật và service thống kê yêu cầu
      entryMap['plantId'] = plantId;
      entryMap['userId'] = user.uid;
      entryMap['timestamp'] = FieldValue.serverTimestamp(); // Thêm dấu thời gian

      // Ghi vào collection gốc 'diary_entries'
      await _firestore.collection('diary_entries').add(entryMap);

      // Sau khi thêm thành công, tải lại danh sách
      // (Không thêm vào _entries cục bộ nữa, hãy để CSDL làm nguồn tin cậy)
      await loadEntries(plantId);
      
      // _isLoading đã được set lại là false trong loadEntries
      return true;
    } catch (e) {
      print("Lỗi addEntry: $e"); // In lỗi ra debug console
      _error = "Lỗi thêm nhật ký: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cập nhật hàm Xóa (Tùy chọn, nhưng nên làm)
  Future<bool> deleteEntry(String entryId, String plantId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Xóa tài liệu khỏi CSDL
      await _firestore.collection('diary_entries').doc(entryId).delete();
      
      // Tải lại danh sách sau khi xóa
      await loadEntries(plantId);

      return true;
    } catch (e) {
      print("Lỗi deleteEntry: $e"); // In lỗi ra debug console
      _error = "Lỗi xóa nhật ký: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- CÁC HÀM CŨ GIỮ NGUYÊN ---

  // Update diary entry (VẪN CÒN TODO, BẠN CẦN SỬA NẾU DÙNG)
  Future<bool> updateEntry(String entryId, DiaryEntryModel entry) async {
    try {
      _isLoading = true;
      notifyListeners();

      // TODO: Implement Firestore update
      // await _firestore.collection('diary_entries').doc(entryId).update(entry.toFirestore());
      
      var index = _entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _entries[index] = entry;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<DiaryEntryModel> getEntriesByType(String activityType) {
    return _entries.where((e) => e.activityType == activityType).toList();
  }

  List<DiaryEntryModel> getRecentEntries(int count) {
    return _entries.take(count).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}