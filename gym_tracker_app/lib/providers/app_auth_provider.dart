import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppAuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  User? get user => _auth.currentUser;

  Future<bool> profileExists(String uid) async {
    final snap = await _db.child('users/$uid/profile').get();
    return snap.exists;
  }

  // EMAIL LOGIN
  Future<String> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;
      final exists = await profileExists(uid);
      return exists ? "home" : "completeProfile";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "register";
      rethrow;
    }
  }

  // GOOGLE LOGIN (sin crear cuenta si no existe)
  Future<GoogleResult> signInWithGoogleCheck() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return GoogleResult.cancelled();

    final email = googleUser.email;
    final methods = await _auth.fetchSignInMethodsForEmail(email);

    if (methods.isEmpty) {
      await GoogleSignIn().signOut();
      return GoogleResult.needsRegister(email);
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;
    final exists = await profileExists(uid);

    return GoogleResult.success(exists ? "home" : "completeProfile");
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    notifyListeners();
  }
}

class GoogleResult {
  final String? route;
  final String? email;
  final bool cancelled;

  GoogleResult._({this.route, this.email, this.cancelled = false});

  factory GoogleResult.success(String route) => GoogleResult._(route: route);

  factory GoogleResult.needsRegister(String email) =>
      GoogleResult._(email: email);

  factory GoogleResult.cancelled() => GoogleResult._(cancelled: true);
}
