import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plant_care_app/models/user_model.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      // 1️⃣ Tạo tài khoản Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // 2️⃣ Tạo đối tượng UserModel
      final userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );

      // 3️⃣ Lưu UserModel lên Firestore
      await _db.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel; // ✅ trả về UserModel, đúng kiểu
    } catch (e) {
      print('Error in signUp: $e');
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Lấy dữ liệu từ Firestore
      var doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error in signIn: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    var doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }
}
