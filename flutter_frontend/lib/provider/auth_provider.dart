import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        for (var info in currentUser.providerData) {
          if (info.providerId == GoogleAuthProvider.PROVIDER_ID) {
            await GoogleSignIn().signOut();
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      notifyListeners();
    }
  }
}
