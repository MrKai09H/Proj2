// File: lib/models/diary_entry_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  final String? id; // ID từ Firestore
  final String title;
  final String notes;
  final String activityType; // 'watering', 'fertilizing', v.v.
  final DateTime? timestamp;

  DiaryEntryModel({
    this.id,
    required this.title,
    required this.notes,
    required this.activityType,
    this.timestamp,
  });

  // 1. HÀM ĐỂ ĐỌC TỪ FIRESTORE
  factory DiaryEntryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DiaryEntryModel(
      id: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      notes: data['notes'] ?? '',
      activityType: data['activityType'] ?? 'unknown',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  // 2. HÀM ĐỂ GHI LÊN FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'notes': notes,
      'activityType': activityType,
      // (Không cần thêm plantId, userId, timestamp ở đây
      // vì provider sẽ tự động thêm vào)
    };
  }
}
