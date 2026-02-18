/// mostrar el detalle completo de una rutina seleccionada.
import 'package:flutter/material.dart';

class RoutineDetailScreen extends StatelessWidget {
  const RoutineDetailScreen({super.key, required this.detail});

  final RoutineDetail detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exercises = detail.exercises ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rutina"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _Tag(
                  label: detail.isPublic == true ? "Pública" : "Privada",
                ),
                if (detail.likesCount != null)
                  _Tag(label: "❤️ ${detail.likesCount}"),
                if (detail.exercisesCount != null)
                  _Tag(label: "${detail.exercisesCount} ejercicios"),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Ejercicios",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exercises.isEmpty
                  ? Center(
                      child: Text(
                        "No hay ejercicios para mostrar.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final name = _getExerciseName(ex) ?? "Ejercicio";
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getExerciseName(dynamic ex) {
    if (ex is Map && ex['name'] != null) return ex['name'].toString();
    if (ex is String) return ex;
    return null;
  }
}

class RoutineDetail {
  const RoutineDetail({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.isPublic,
    required this.likesCount,
    required this.exercises,
    required this.exercisesCount,
  });

  final String id;
  final String name;
  final String ownerUid;
  final bool? isPublic;
  final int? likesCount;
  final List<dynamic>? exercises;
  final int? exercisesCount;
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
