/// preparar e iniciar una nueva sesion de entrenamiento.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/training_session_screen.dart';

class TrainingSessionStartScreen extends StatelessWidget {
  const TrainingSessionStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Iniciar sesión"),
        ),
        body: Center(
          child: Text(
            "No hay sesión activa",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elegir rutina"),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: userRef.onValue,
        builder: (context, snapshot) {
          final items = _mapAvailableRoutines(snapshot.data?.snapshot.value);
          if (items.isEmpty) {
            return Center(
              child: Text(
                "No tienes rutinas creadas ni con like",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final routine = items[index];
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    routine.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${routine.exercises.length} ejercicios • ${routine.sourceLabel}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrainingSessionScreen(
                          routine: routine,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RoutineSessionData {
  const RoutineSessionData({
    required this.id,
    required this.name,
    required this.exercises,
    required this.sourceLabel,
  });

  final String id;
  final String name;
  final List<Map<String, dynamic>> exercises;
  final String sourceLabel;
}

List<RoutineSessionData> _mapAvailableRoutines(Object? rawUser) {
  if (rawUser is! Map) return [];
  final created = _mapCreatedRoutines(rawUser['routines']);
  final liked = _mapLikedRoutines(rawUser['likedRoutines']);
  final byId = <String, RoutineSessionData>{};

  for (final item in created) {
    byId[item.id] = item;
  }
  for (final item in liked) {
    byId.putIfAbsent(item.id, () => item);
  }

  final createdIds = created.map((e) => e.id).toSet();
  final list = byId.values.toList()
    ..sort((a, b) {
      final aOwn = createdIds.contains(a.id);
      final bOwn = createdIds.contains(b.id);
      if (aOwn != bOwn) return aOwn ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  return list;
}

List<RoutineSessionData> _mapCreatedRoutines(Object? raw) {
  if (raw is! Map) return [];
  final list = <RoutineSessionData>[];

  for (final entry in raw.entries) {
    final item = _toRoutine(entry: entry, sourceLabel: 'Tu rutina');
    if (item != null) list.add(item);
  }

  return list;
}

List<RoutineSessionData> _mapLikedRoutines(Object? raw) {
  if (raw is! Map) return [];
  final list = <RoutineSessionData>[];

  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final routineRaw = value['routine'];
    if (routineRaw is! Map) continue;
    final wrappedEntry = MapEntry(entry.key, routineRaw);
    final item = _toRoutine(entry: wrappedEntry, sourceLabel: 'Rutina con like');
    if (item != null) list.add(item);
  }

  return list;
}

RoutineSessionData? _toRoutine({
  required MapEntry<dynamic, dynamic> entry,
  required String sourceLabel,
}) {
  final value = entry.value;
  if (value is! Map) return null;
  final name = value['name']?.toString();
  if (name == null || name.trim().isEmpty) return null;

  final exercisesRaw = value['exercises'];
  final exercises = <Map<String, dynamic>>[];
  if (exercisesRaw is List) {
    for (final ex in exercisesRaw) {
      if (ex is Map) {
        exercises.add(Map<String, dynamic>.from(ex));
      }
    }
  }

  return RoutineSessionData(
    id: entry.key.toString(),
    name: name,
    exercises: exercises,
    sourceLabel: sourceLabel,
  );
}
