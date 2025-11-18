// lib/auth/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Ambil role string dari collection users/{uid}. return null jika tidak ada
  static Future<String?> fetchRoleForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return fetchRoleForUid(user.uid);
  }

  /// Ambil role untuk uid tertentu
  static Future<String?> fetchRoleForUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final role = data['role'];
      if (role is String) return role;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Helper kecil: cek apakah current user admin
  static Future<bool> isCurrentUserAdmin() async {
    final role = await fetchRoleForCurrentUser();
    return role == 'admin';
  }
}
