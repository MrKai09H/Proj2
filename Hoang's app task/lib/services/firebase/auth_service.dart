// import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class AuthService {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      // TODO: Implement Firebase Authentication
      // UserCredential result = await _auth.signInWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );
      // return _userFromFirebase(result.user);
      
      // Placeholder
      print('Sign in: $email');
      return null;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      // TODO: Implement Firebase Registration
      // UserCredential result = await _auth.createUserWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );
      // await result.user?.updateDisplayName(name);
      // return _userFromFirebase(result.user);
      
      // Placeholder
      print('Sign up: $email, $name');
      return null;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      // User? user = _auth.currentUser;
      // return _userFromFirebase(user);
      
      // Placeholder
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Convert Firebase User to UserModel
  // UserModel? _userFromFirebase(User? user) {
  //   if (user == null) return null;
  //   return UserModel(
  //     id: user.uid,
  //     email: user.email ?? '',
  //     name: user.displayName ?? '',
  //     photoUrl: user.photoURL,
  //     createdAt: user.metadata.creationTime ?? DateTime.now(),
  //   );
  // }

  // Stream of auth changes
  // Stream<UserModel?> get authStateChanges {
  //   return _auth.authStateChanges().map(_userFromFirebase);
  // }
}

