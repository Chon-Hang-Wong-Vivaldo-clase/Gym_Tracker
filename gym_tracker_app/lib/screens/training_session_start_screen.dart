import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/training_session_screen.dart';

class TrainingSessionStartScreen extends StatelessWidget {
  const TrainingSessionStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Iniciar sesión"),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: const Center(child: Text("No hay sesión activa")),
      );
    }

    final routinesRef =
        FirebaseDatabase.instance.ref('users/${user.uid}/routines');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Elegir rutina"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DatabaseEvent>(
        stream: routinesRef.onValue,
        builder: (context, snapshot) {
          final items = _mapRoutines(snapshot.data?.snapshot.value);
          if (items.isEmpty) {
            return const Center(
              child: Text(
                "Aún no tienes rutinas",
                style: TextStyle(color: Colors.black54),
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
                color: const Color(0xFFF5F5F5),
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
                  subtitle: Text('${routine.exercises.length} ejercicios'),
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
  });

  final String id;
  final String name;
  final List<Map<String, dynamic>> exercises;
}

List<RoutineSessionData> _mapRoutines(Object? raw) {
  if (raw is! Map) return [];
  final list = <RoutineSessionData>[];

  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final name = value['name']?.toString();
    if (name == null || name.trim().isEmpty) continue;
    final exercisesRaw = value['exercises'];
    final exercises = <Map<String, dynamic>>[];
    if (exercisesRaw is List) {
      for (final ex in exercisesRaw) {
        if (ex is Map) {
          exercises.add(Map<String, dynamic>.from(ex));
        }
      }
    }

    list.add(
      RoutineSessionData(
        id: entry.key.toString(),
        name: name,
        exercises: exercises,
      ),
    );
  }

  return list;
}
