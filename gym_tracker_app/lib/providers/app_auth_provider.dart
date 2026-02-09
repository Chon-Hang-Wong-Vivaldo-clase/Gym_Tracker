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

    final email = googleUser.email.trim();
    try {
      final existsInDb = await profileExistsByEmail(email);
      await GoogleSignIn().signOut();

      if (!existsInDb) {
        return GoogleResult.needsRegister(email);
      }
      return GoogleResult.needsPassword(email);
    } on FirebaseAuthException {
      await GoogleSignIn().signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _setOffline();
    await GoogleSignIn().signOut();
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
