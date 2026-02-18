/// gestionar el estado de autenticacion y la sesion del usuario.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppAuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  DatabaseReference? _presenceRef;
  StreamSubscription<DatabaseEvent>? _connectedSub;
  StreamSubscription<User?>? _authSub;

  User? get user => _auth.currentUser;

  AppAuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
    _handleAuthChange(_auth.currentUser);
  }

  Future<void> _handleAuthChange(User? nextUser) async {
    await _disposePresence();
    if (nextUser == null) return;

    _presenceRef = _db.child('users/${nextUser.uid}/presence');
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');

    _connectedSub = connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value == true;
      if (!connected || _presenceRef == null) return;
      await _presenceRef!.onDisconnect().set({
        'state': 'offline',
        'lastChanged': ServerValue.timestamp,
      });
      await _setOnline();
    });

    await _setOnline();
  }

  Future<void> _setOnline() async {
    if (_presenceRef == null) return;
    await _presenceRef!.set({
      'state': 'online',
      'lastChanged': ServerValue.timestamp,
    });
  }

  Future<void> _setOffline() async {
    if (_presenceRef == null) return;
    await _presenceRef!.set({
      'state': 'offline',
      'lastChanged': ServerValue.timestamp,
    });
  }

  Future<void> _disposePresence() async {
    await _connectedSub?.cancel();
    _connectedSub = null;
    _presenceRef = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOffline();
    }
  }

  Future<bool> profileExists(String uid) async {
    final snap = await _db.child('users/$uid/profile').get();
    return snap.exists;
  }

  Future<bool> profileExistsByEmail(String email) async {
    final target = email.trim().toLowerCase();
    if (target.isEmpty) return false;
    final snap = await _db.child('users').get();
    if (!snap.exists) return false;
    final raw = snap.value;
    if (raw is! Map) return false;
    for (final entry in raw.entries) {
      final userNode = entry.value;
      if (userNode is! Map) continue;
      final profile = userNode['profile'];
      if (profile is! Map) continue;
      final storedEmail = profile['email']?.toString().trim().toLowerCase();
      if (storedEmail != null && storedEmail == target) {
        return true;
      }
    }
    return false;
  }

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

  Future<GoogleResult> signInWithGoogleCheck() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        userCred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return GoogleResult.cancelled();

        final googleAuth = await googleUser.authentication;
        final hasToken =
            (googleAuth.accessToken != null &&
                googleAuth.accessToken!.isNotEmpty) ||
            (googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty);
        if (!hasToken) {
          throw FirebaseAuthException(
            code: 'google-auth-missing-token',
            message: 'Google no devolvio tokens de autenticacion.',
          );
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await _auth.signInWithCredential(credential);
      }

      final uid = userCred.user?.uid;
      if (uid == null) return GoogleResult.cancelled();

      final exists = await profileExists(uid);
      return GoogleResult.success(exists ? "home" : "completeProfile");
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _setOffline();
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }

    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _connectedSub?.cancel();
    super.dispose();
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

  factory GoogleResult.needsPassword(String email) =>
      GoogleResult._(route: "password", email: email);

  factory GoogleResult.cancelled() => GoogleResult._(cancelled: true);
}
