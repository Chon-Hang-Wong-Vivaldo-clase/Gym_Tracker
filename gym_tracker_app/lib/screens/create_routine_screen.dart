/// permitir crear una nueva rutina de entrenamiento.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/exercise_picker_screen.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  static const int _freeRoutineLimit = 5;
  final _nameCtrl = TextEditingController();
  final _selected = <ExerciseLite>[];
  bool _saving = false;
  bool _isPublic = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final picked = await Navigator.of(context).push<ExerciseLite>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null) return;
    if (_selected.any((e) => e.idSource == picked.idSource)) return;
    setState(() => _selected.add(picked));
  }

  Future<void> _createRoutine() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pon un nombre")));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añade al menos un ejercicio")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay sesión activa")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final root = FirebaseDatabase.instance.ref();
      final profileSnap = await root.child('users/${user.uid}/profile').get();
      final profile = profileSnap.value is Map
          ? (profileSnap.value as Map)
          : <dynamic, dynamic>{};
      final isPremium = _isPremiumActive(profile['isPremium']);

      final routinesRef = root.child('users/${user.uid}/routines');
      final routinesSnap = await routinesRef.get();
      final routinesCount = _countValidCreatedRoutines(
        routinesSnap.children,
        user.uid,
      );

      if (!isPremium && routinesCount >= _freeRoutineLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Límite alcanzado: máximo $_freeRoutineLimit rutinas",
            ),
          ),
        );
        return;
      }

      final newRef = routinesRef.push();
      final routineId = newRef.key;
      if (routineId == null) {
        throw StateError('No se pudo generar el id de la rutina');
      }

      final routineData = {
        'name': name,
        'isPublic': _isPublic,
        'likesCount': 0,
        'ownerUid': user.uid,
        'createdAt': ServerValue.timestamp,
        'exercises': _selected
            .map(
              (e) => {
                'idSource': e.idSource,
                'name': e.name,
                'muscleGroup': e.muscleGroup,
                'source': e.source,
              },
            )
            .toList(),
      };

      final updates = <String, Object?>{
        'users/${user.uid}/routines/$routineId': routineData,
      };
      if (_isPublic) {
        updates['publicRoutines/$routineId'] = routineData;
      }

      await root.update(updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rutina creada")),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isPremiumActive(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      return value == 'true' || value == '1' || value == 'yes';
    }
    return false;
  }

  int _countValidCreatedRoutines(
    Iterable<DataSnapshot> children,
    String currentUid,
  ) {
    var count = 0;
    for (final child in children) {
      final raw = child.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      final name = data['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      final ownerUid = data['ownerUid']?.toString().trim() ?? '';
      if (ownerUid.isNotEmpty && ownerUid != currentUid) continue;
      count += 1;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = colorScheme.surfaceContainerHighest;
    final inputBg = colorScheme.surface;
    final primaryButtonBg = colorScheme.primary;
    final primaryButtonFg = colorScheme.onPrimary;
    final secondaryButtonBg = colorScheme.secondaryContainer;
    final secondaryButtonFg = colorScheme.onSecondaryContainer;
    final hintColor = colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear rutina"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rutina nueva",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: "Nombre de la rutina",
                      filled: true,
                      fillColor: inputBg,
                      hintStyle: TextStyle(color: hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SelectedExercisesList(
                    items: _selected,
                    onRemove: (item) {
                      setState(() => _selected.remove(item));
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _addExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryButtonBg,
                        foregroundColor: secondaryButtonFg,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Añadir ejercicio"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rutina pública",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _createRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryButtonBg,
                  foregroundColor: primaryButtonFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryButtonFg,
                        ),
                      )
                    : const Text("CREAR"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedExercisesList extends StatelessWidget {
  const _SelectedExercisesList({required this.items, required this.onRemove});

  final List<ExerciseLite> items;
  final ValueChanged<ExerciseLite> onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Text(
        "Aún no has añadido ejercicios.",
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: items
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onRemove(e),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
