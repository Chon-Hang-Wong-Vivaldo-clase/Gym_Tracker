import 'package:flutter/material.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = [
      _RoutineItem(
        title: "Full Body - Fuerza",
        subtitle: "4 ejercicios • 45 min",
      ),
      _RoutineItem(
        title: "Piernas + Core",
        subtitle: "5 ejercicios • 50 min",
      ),
      _RoutineItem(
        title: "Push (Pecho/Hombro)",
        subtitle: "6 ejercicios • 60 min",
      ),
      _RoutineItem(
        title: "Pull (Espalda/Bíceps)",
        subtitle: "5 ejercicios • 55 min",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis rutinas"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: routines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final routine = routines[index];
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
                routine.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(routine.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

class _RoutineItem {
  const _RoutineItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
