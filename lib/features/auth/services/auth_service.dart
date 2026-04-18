import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state — drives persistent login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── SIGN UP with email & password ───────────────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(name);

    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // ─── SIGN IN with email & password ───────────────────────────────────────
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    return await _getUserFromFirestore(credential.user!.uid);
  }

  // ─── GOOGLE SIGN IN ───────────────────────────────────────────────────────
  /// Returns UserModel if existing user, or null if new (needs role selection)
  Future<({UserModel? user, bool isNewUser})> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final uid = userCredential.user!.uid;
    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (isNew) {
      return (user: null, isNewUser: true);
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      return (user: null, isNewUser: true);
    }

    return (user: UserModel.fromFirestore(doc), isNewUser: false);
  }

  /// Called after Google sign-in to save role for new users
  Future<UserModel> completeGoogleSignUp({
    required UserRole role,
    required String phone,
  }) async {
    final user = _auth.currentUser!;
    final userModel = UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phone: phone.trim(),
      role: role,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  // ─── GET USER FROM FIRESTORE ──────────────────────────────────────────────
  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found.');
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _getUserFromFirestore(user.uid);
    } catch (_) {
      return null;
    }
  }

  // ─── SIGN OUT ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── PASSWORD RESET ───────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
