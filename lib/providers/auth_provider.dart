import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  // Notification state
  bool _notificationEnabled = true;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationEnabled => _notificationEnabled;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _notificationEnabled = await NotificationService.isNotificationEnabled();
    } catch (_) {}

    if (_notificationEnabled) {
      try {
        await NotificationService.scheduleDailyReminder();
      } catch (_) {}
    }

    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        try {
          await loadUserData();
        } catch (_) {}
        try {
          await _firestoreService.syncLocalToFirestore();
        } catch (_) {}
        try {
          await _firestoreService.cleanupOldRecords(user.uid);
        } catch (_) {}
        try {
          if (_notificationEnabled) {
            await NotificationService.scheduleDailyReminder();
          }
        } catch (_) {}
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> loadUserData() async {
    if (_user == null) return;
    try {
      _userModel = await _firestoreService.getUser(_user!.uid);
    } catch (e) {
      _userModel = UserModel(
        uid: _user!.uid,
        name: _user!.displayName ?? '',
        email: _user!.email ?? '',
        photoUrl: _user!.photoURL,
      );
    }
    notifyListeners();
  }

  // ===================== EMAIL AUTH =====================

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmail(email, password);
      if (credential?.user != null) {
        await _authService.saveLoginSession(credential!.user!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return credential != null;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.registerWithEmail(email, password);
      if (credential?.user != null) {
        final firebaseUser = credential!.user!;
        await _authService.updateDisplayName(name);

        // Send Firebase verification link
        try {
          await firebaseUser.sendEmailVerification();
        } catch (_) {}

        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: name,
          email: email,
        );
        try {
          await _firestoreService.createUser(newUser);
        } catch (_) {}
        _userModel = newUser;
        await _authService.saveLoginSession(firebaseUser.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===================== RESEND VERIFICATION LINK =====================

  Future<void> resendEmailVerification() async {
    try {
      final user = _authService.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (_) {
      _error = 'Gagal mengirim ulang email verifikasi.';
      notifyListeners();
    }
  }

  // ===================== GOOGLE AUTH =====================

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential?.user != null) {
        await _authService.saveLoginSession(credential!.user!.uid);

        UserModel? existingUser;
        try {
          existingUser =
              await _firestoreService.getUser(credential.user!.uid);
        } catch (_) {}

        if (existingUser == null) {
          final newUser = UserModel(
            uid: credential.user!.uid,
            name: credential.user!.displayName ?? '',
            email: credential.user!.email ?? '',
            photoUrl: credential.user!.photoURL,
          );
          try {
            await _firestoreService.createUser(newUser);
          } catch (_) {}
          _userModel = newUser;
        }
      }
      _isLoading = false;
      notifyListeners();
      return credential != null;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login dengan Google gagal. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ===================== ONBOARDING =====================

  Future<void> saveOnboardingData({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) async {
    if (_user == null) return;

    try {
      await _firestoreService.saveOnboardingData(_user!.uid, {
        'name': name,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
      });
    } catch (_) {}

    _userModel = _userModel?.copyWith(
      name: name,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      onboardingCompleted: true,
    );
    notifyListeners();
  }

  // ===================== NOTIFICATION SETTINGS =====================

  Future<void> toggleNotification(bool enabled) async {
    _notificationEnabled = enabled;
    notifyListeners();

    await NotificationService.setNotificationEnabled(enabled);

    if (_user != null) {
      await _firestoreService.saveNotificationSetting(_user!.uid, enabled);
    }
  }

  // ===================== PROFILE =====================

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    try {
      await _firestoreService.updateUser(_user!.uid, data);
    } catch (_) {}
    await loadUserData();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  // ===================== HELPERS =====================

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tidak ada akun dengan email ini.';
      case 'wrong-password':
        return 'Password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Email tidak valid.';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
