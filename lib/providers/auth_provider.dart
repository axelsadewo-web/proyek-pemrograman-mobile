import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Placeholder auth state for app compile.
/// Fitur cloud/auth belum dipasang di repo ini, jadi dibuat non-crashing.

class FakeUser {
  final String uid;
  FakeUser(this.uid);
}

/// localAuthProvider: apakah user sudah login secara lokal.
final localAuthProvider = StateProvider<bool>((ref) => false);

/// authStateProvider: state async user.
/// Diset selalu null (memaksa login screen) untuk mencegah crash.
final authStateProvider = StreamProvider<FakeUser?>((ref) async* {
  // tidak ada stream asli pada repo ini
  yield null;
});

/// provider yang sering dipakai screens/services.
final authServiceProvider = Provider((ref) {
  return _AuthService();
});

class _AuthService {
  FakeUser? get currentUser => null;
  Future<void> signOut() async {}
}
