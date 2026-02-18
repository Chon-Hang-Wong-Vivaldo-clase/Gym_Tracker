/// visualizar y administrar metas de entrenamiento del usuario.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _workoutsController = TextEditingController();
  final _streakController = TextEditingController();
  final _weightController = TextEditingController();
  final _year = DateTime.now().year;

  DatabaseReference? _goalsRef;
  DatabaseReference? _profileGoalsRef;
  bool _loading = true;
  bool _saving = false;
  bool _lockedForYear = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _workoutsController.dispose();
    _streakController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    _goalsRef = FirebaseDatabase.instance.ref('users/${user.uid}/goals/$_year');
    _profileGoalsRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/profile/goals/$_year',
    );

    Map<dynamic, dynamic> data = <dynamic, dynamic>{};
    try {
      final snap = await _goalsRef!.get();
      final raw = snap.value;
      if (raw is Map) {
        data = raw;
      }
    } catch (_) {}

    if (data.isEmpty) {
      try {
        final profileSnap = await _profileGoalsRef!.get();
        final profileRaw = profileSnap.value;
        if (profileRaw is Map) {
          data = profileRaw;
        }
      } catch (_) {}
    }

    if (data.isEmpty) {
      final local = await _loadLocalGoals(user.uid);
      if (local != null) {
        data = local;
      }
    }

    if (!mounted) return;
    _applyGoalData(data);

    setState(() => _loading = false);
  }

  String _nextUnlockDateText() => '1 de enero de ${_year + 1}';

  void _applyGoalData(Map<dynamic, dynamic> data) {
    _workoutsController.text = (data['workoutsTarget'] ?? '').toString();
    _streakController.text = (data['streakTarget'] ?? '').toString();
    _weightController.text = (data['weightTarget'] ?? '').toString();
    _lockedForYear = (data['locked'] == true) || data['lockedAt'] != null;
  }

  String _localGoalsKey(String uid) => 'goals_${uid}_$_year';

  Future<void> _saveLocalGoals(String uid, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localGoalsKey(uid), jsonEncode(payload));
  }

  Future<Map<dynamic, dynamic>?> _loadLocalGoals(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localGoalsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _trySaveRemote(
    DatabaseReference ref,
    Map<String, dynamic> payload,
  ) async {
    try {
      await ref.set(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveGoals() async {
    if (_saving || _lockedForYear) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay sesión activa.")),
      );
      return;
    }

    final workouts = int.tryParse(_workoutsController.text.trim());
    final streak = int.tryParse(_streakController.text.trim());
    final normalizedWeight = _weightController.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(normalizedWeight);

    if (workouts == null || streak == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa los 3 objetivos con valores válidos.")),
      );
      return;
    }

    final payload = <String, dynamic>{
      'year': _year,
      'workoutsTarget': workouts,
      'streakTarget': streak,
      'weightTarget': weight,
      'locked': true,
      'lockedAt': ServerValue.timestamp,
    };

    setState(() => _saving = true);
    try {
      _goalsRef ??= FirebaseDatabase.instance.ref('users/${user.uid}/goals/$_year');
      _profileGoalsRef ??= FirebaseDatabase.instance.ref(
        'users/${user.uid}/profile/goals/$_year',
      );

      final savedPrimary = await _trySaveRemote(_goalsRef!, payload);
      final savedProfile = await _trySaveRemote(_profileGoalsRef!, payload);
      final savedRemote = savedPrimary || savedProfile;

      await _saveLocalGoals(user.uid, {
        'year': _year,
        'workoutsTarget': workouts,
        'streakTarget': streak,
        'weightTarget': weight,
        'locked': true,
        'lockedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (!mounted) return;
      setState(() => _lockedForYear = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedRemote
                ? "Objetivos guardados. No podrás modificarlos hasta ${_nextUnlockDateText()}."
                : "Objetivos guardados en este dispositivo. No podrás modificarlos hasta ${_nextUnlockDateText()}.",
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error al guardar objetivos.")),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final warningBg = theme.colorScheme.surfaceContainerHighest;

    if (_loading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        elevation: 0,
        title: Text(
          "Objetivos",
          style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            "Objetivos para $_year",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: onSurface),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              _lockedForYear
                  ? "Ya guardaste tus objetivos de $_year. No podrás modificarlos hasta ${_nextUnlockDateText()}."
                  : "Aviso: cuando guardes tus objetivos, quedarán bloqueados hasta ${_nextUnlockDateText()}.",
              style: TextStyle(
                color: onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Field(
            label: "Entrenamientos totales",
            hint: "Ej: 180",
            controller: _workoutsController,
            enabled: !_lockedForYear,
          ),
          _Field(
            label: "Mayor racha (días)",
            hint: "Ej: 45",
            controller: _streakController,
            enabled: !_lockedForYear,
          ),
          _Field(
            label: "Peso objetivo (kg)",
            hint: "Ej: 72",
            controller: _weightController,
            keyboardType: TextInputType.number,
            enabled: !_lockedForYear,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (_saving || _lockedForYear) ? null : _saveGoals,
            child: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : Text(
                    _lockedForYear ? "Objetivos bloqueados" : "Guardar objetivos",
                  ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceContainer = theme.colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(color: onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: onSurfaceVariant),
              filled: true,
              fillColor: surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
