import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _initAuthState();
  }

  void _initAuthState() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      } else {
        final user = await _authService.getCurrentUserModel();
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
        } else {
          // Firebase user exists but no Firestore doc yet (Google new user)
          _status = AuthStatus.unauthenticated;
        }
      }
      notifyListeners();
    });
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Returns true if existing user, false if new user (needs role selection)
  Future<({bool success, bool isNewUser})> signInWithGoogle() async {
    _setLoading();
    try {
      final result = await _authService.signInWithGoogle();
      if (!result.isNewUser && result.user != null) {
        _currentUser = result.user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return (success: true, isNewUser: false);
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return (success: true, isNewUser: true);
      }
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return (success: false, isNewUser: false);
    } catch (e) {
      _setError(e.toString());
      return (success: false, isNewUser: false);
    }
  }

  Future<bool> completeGoogleSignUp({
    required UserRole role,
    required String phone,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.completeGoogleSignUp(
        role: role,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }
}
