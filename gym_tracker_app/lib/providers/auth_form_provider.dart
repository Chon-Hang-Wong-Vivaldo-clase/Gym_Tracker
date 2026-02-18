/// manejar estado y validaciones de formularios de autenticacion.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';

class AuthFormProvider extends ChangeNotifier {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();

  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();

  bool loading = false;
  String? error;

  void setEmail(String email) {
    emailCtrl.text = email;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  Future<void> _writeUserData({
    required User user,
    required String username,
    required String name,
    required String surname,
    required String bio,
    String? email,
  }) async {
    final safeEmail = (email ?? user.email ?? '').trim();

    final updates = <String, Object?>{
      'users/${user.uid}/profile': {
        "username": username,
        "name": name,
        "surname": surname,
        "bio": bio,
        "email": safeEmail,
        "photoUrl": user.photoURL,
        "isAdmin": false,
        "isPremium": false,
        "createdAt": ServerValue.timestamp,
      },
    };
    await FirebaseDatabase.instance.ref().update(updates);
  }

  bool _validateProfileFields() {
    final normalizedUsername = _normalizeUsername(usernameCtrl.text);
    final name = nameCtrl.text.trim();
    final surname = surnameCtrl.text.trim();
    final bio = bioCtrl.text.trim();

    if (normalizedUsername.isEmpty) {
      error = "El nombre de usuario es obligatorio";
      notifyListeners();
      return false;
    }
    if (normalizedUsername.length < 3) {
      error = "El nombre de usuario es demasiado corto";
      notifyListeners();
      return false;
    }
    if (normalizedUsername.contains(' ')) {
      error = "El nombre de usuario no puede tener espacios";
      notifyListeners();
      return false;
    }
    if (usernameCtrl.text.trim() != normalizedUsername) {
      usernameCtrl.text = normalizedUsername;
    }

    if (name.isEmpty || surname.isEmpty) {
      error = "Nombre y apellidos son obligatorios";
      notifyListeners();
      return false;
    }
    if (bio.length > 200) {
      error = "La biografía no puede superar 200 caracteres";
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> _isUsernameAvailable(String username,
      {String? currentUid}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return false;
    final snap = await FirebaseDatabase.instance
        .ref('users')
        .orderByChild('profile/username')
        .equalTo(normalized)
        .get();
    if (!snap.exists) return true;
    final raw = snap.value;
    if (raw is! Map) return true;
    if (currentUid == null) return false;
    for (final entry in raw.entries) {
      if (entry.key.toString() != currentUid) {
        return false;
      }
    }
    return true;
  }

  // LOGIN email
  Future<String> loginEmail(AppAuthProvider auth) async {
    _setLoading(true);
    error = null;

    try {
      final route = await auth.signInWithEmail(emailCtrl.text, passCtrl.text);
      return route;
    } on FirebaseAuthException catch (e) {
      error = e.message ?? e.code;
      return "error";
    } finally {
      _setLoading(false);
    }
  }

  // LOGIN google
  Future<GoogleResult> loginGoogle(AppAuthProvider auth) async {
    _setLoading(true);
    error = null;
    try {
      final res = await auth.signInWithGoogleCheck();
      return res;
    } catch (e) {
      error = "Error Google: $e";
      return GoogleResult.cancelled();
    } finally {
      _setLoading(false);
    }
  }

  // REGISTRO paso 1: validar email/pass
  bool validateRegisterEmail() {
    error = null;
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final pass2 = pass2Ctrl.text;

    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      error = "Rellena todos los campos";
      notifyListeners();
      return false;
    }
    if (pass != pass2) {
      error = "Las contraseñas no coinciden";
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  // REGISTRO paso 2: crear usuario y guardar RTDB
  Future<bool> createAccountAndSaveProfile() async {
    error = null;
    if (!_validateProfileFields()) return false;

    _setLoading(true);
    try {
      final username = _normalizeUsername(usernameCtrl.text);
      final available = await _isUsernameAvailable(username);
      if (!available) {
        error = "El nombre de usuario ya está en uso";
        notifyListeners();
        return false;
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      final user = cred.user!;
      await _writeUserData(
        user: user,
        username: username,
        name: nameCtrl.text.trim(),
        surname: surnameCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      error = e.message ?? e.code;
      return false;
    } on FirebaseException catch (e) {
      error = e.message ?? e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Completar perfil para usuarios ya autenticados (Google / login sin perfil)
  Future<bool> saveProfileForCurrentUser() async {
    error = null;
    if (!_validateProfileFields()) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      error = "No hay sesión activa";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final username = _normalizeUsername(usernameCtrl.text);
      final available =
          await _isUsernameAvailable(username, currentUid: user.uid);
      if (!available) {
        error = "El nombre de usuario ya está en uso";
        notifyListeners();
        return false;
      }
      await _writeUserData(
        user: user,
        username: username,
        name: nameCtrl.text.trim(),
        surname: surnameCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
        email: user.email,
      );
      return true;
    } on FirebaseException catch (e) {
      error = e.message ?? e.code;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    nameCtrl.dispose();
    surnameCtrl.dispose();
    bioCtrl.dispose();
    usernameCtrl.dispose();
    super.dispose();
  }

  String _normalizeUsername(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final withAt = trimmed.startsWith('@') ? trimmed : '@$trimmed';
    return withAt.toLowerCase();
  }
}
