import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// FIREBASE AUTH SERVICE
// ============================================================================

/// Service untuk Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream untuk auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign up dengan email dan password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      await _createUserProfile(userCredential.user!, name);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  /// Sign in dengan email dan password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Gagal logout: $e';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? name, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User tidak ditemukan';

      if (name != null) {
        await user.updateDisplayName(name);
        await _updateUserProfile(user.uid, {'name': name});
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw 'Gagal update profile: $e';
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User tidak ditemukan';

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete user account
      await user.delete();
    } catch (e) {
      throw 'Gagal hapus akun: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'user-not-found':
        return 'User tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(User user, String name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'totalXP': 0,
      'currentLevel': 1,
      'habitsCount': 0,
      'longestStreak': 0,
      'totalCompleted': 0,
    });
  }

  /// Update user profile in Firestore
  Future<void> _updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Delete user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    // Delete user profile
    await _firestore.collection('users').doc(uid).delete();

    // Delete all user habits
    final habitsQuery = await _firestore
        .collection('users')
        .doc(uid)
        .collection('habits')
        .get();

    for (final doc in habitsQuery.docs) {
      await doc.reference.delete();
    }
  }
}

// ============================================================================
// FIRESTORE SERVICE
// ============================================================================

/// Service untuk Firestore operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync habits ke Firestore
  Future<void> syncHabitsToCloud(String userId, List<dynamic> habits) async {
    try {
      final batch = _firestore.batch();

      // Delete existing habits
      final existingHabits = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();

      for (final doc in existingHabits.docs) {
        batch.delete(doc.reference);
      }

      // Add new habits
      for (final habit in habits) {
        final habitRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('habits')
            .doc(habit.id);

        batch.set(habitRef, {
          ...habit.toMap(),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw 'Gagal sync ke cloud: $e';
    }
  }

  /// Get habits dari Firestore
  Future<List<Map<String, dynamic>>> getHabitsFromCloud(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw 'Gagal ambil data dari cloud: $e';
    }
  }

  /// Update user stats di Firestore
  Future<void> updateUserStats(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...stats,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Gagal update stats: $e';
    }
  }

  /// Get user profile dari Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      throw 'Gagal ambil profile: $e';
    }
  }

  /// Backup habits ke Firestore (sebagai backup tambahan)
  Future<void> backupHabits(String userId, List<dynamic> habits) async {
    try {
      final backupRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(DateTime.now().millisecondsSinceEpoch.toString());

      await backupRef.set({
        'habits': habits.map((h) => h.toMap()).toList(),
        'backupDate': FieldValue.serverTimestamp(),
        'habitsCount': habits.length,
      });
    } catch (e) {
      throw 'Gagal backup: $e';
    }
  }

  /// Get backup list dari Firestore
  Future<List<Map<String, dynamic>>> getBackups(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .orderBy('backupDate', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw 'Gagal ambil backup list: $e';
    }
  }
}

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Provider untuk authentication state
final authStateProvider = StreamProvider<User?>((ref) {
  return AuthService().authStateChanges;
});

/// Provider untuk auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider untuk firestore service
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// ============================================================================
// AUTH SCREENS
// ============================================================================
