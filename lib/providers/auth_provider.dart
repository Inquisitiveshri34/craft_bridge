import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters
  UserModel? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.role == AppConstants.roleAdmin;
  bool get isApprovedArtisan =>
      _currentUser?.role == AppConstants.roleArtisan &&
      (_currentUser?.isApproved ?? false);

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      } else {
        try {
          _currentUser = await _firestoreService.getUser(firebaseUser.uid);
          _isInitialized = true;
          notifyListeners();
        } catch (e) {
          _currentUser = null;
          _isInitialized = true;
          notifyListeners();
        }
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = await _firestoreService.getUser(credential.user!.uid);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role,
    String bio = '',
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final UserModel newUser = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        role: role,
        photoUrl: '',
        bio: bio.trim(),
        isApproved: role == AppConstants.roleBuyer,
        createdAt: Timestamp.now(),
      );
      await _firestoreService.createUser(newUser);
      _currentUser = newUser;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
