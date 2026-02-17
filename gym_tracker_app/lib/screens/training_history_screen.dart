import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gym_tracker_app/providers/app_auth_provider.dart';

class TrainingHistoryScreen extends StatelessWidget {
  const TrainingHistoryScreen({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.user?.uid;
    final sessionsRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/trainingSessions');

    final day = initialDay == null
        ? null
        : DateTime(initialDay!.year, initialDay!.month, initialDay!.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de entrenos"),
      ),
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (day != null)
              _DateFilterPill(
                date: day,
                onClear: () => Navigator.of(context).pop(),
              ),
            if (day != null) const SizedBox(height: 12),
            Expanded(
              child: _HistoryList(
                sessionsRef: sessionsRef,
                filterDay: day,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.sessionsRef,
    required this.filterDay,
  });

  final DatabaseReference? sessionsRef;
  final DateTime? filterDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (sessionsRef == null) {
      return Center(
        child: Text(
          "Inicia sesión para ver tus entrenos",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: sessionsRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final sessions = data.entries
            .map((entry) => TrainingSessionEntry.fromMap(entry.key, entry.value))
            .whereType<TrainingSessionEntry>()
            .where((session) {
              if (filterDay == null) return true;
              final ref = session.endedAt ?? session.startedAt;
              if (ref == null) return false;
              return _isSameDay(ref, filterDay!);
            })
            .toList()
          ..sort((a, b) {
            final aRef = a.endedAt ?? a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bRef = b.endedAt ?? b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bRef.compareTo(aRef);
          });

        if (sessions.isEmpty) {
          return Center(
            child: Text(
              "No hay entrenos registrados",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(
              session: session,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrainingSessionDetailScreen(session: session),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final TrainingSessionEntry session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = session.endedAt ?? session.startedAt;
    final dateLabel = date == null ? "Fecha desconocida" : _formatDateTime(date);
    final duration = _formatDuration(session.durationSec);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fitness_center,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.routineName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              duration,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainingSessionDetailScreen extends StatelessWidget {
  const TrainingSessionDetailScreen({super.key, required this.session});

  final TrainingSessionEntry session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = session.endedAt ?? session.startedAt;
    final dateLabel = date == null ? "Fecha desconocida" : _formatDateTime(date);
    final duration = _formatDuration(session.durationSec);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del entreno"),
      ),
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Text(
            session.routineName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("Duración", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(duration, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          if (session.exercises.isEmpty)
            Text(
              "No hay ejercicios guardados.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          for (final exercise in session.exercises) ...[
            _ExerciseBlock(exercise: exercise),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.exercise});

  final TrainingExercise exercise;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (exercise.sets.isEmpty)
            Text(
              "Sin sets guardados",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          for (var i = 0; i < exercise.sets.length; i++)
            _SetLine(index: i + 1, set: exercise.sets[i]),
        ],
      ),
    );
  }
}

class _SetLine extends StatelessWidget {
  const _SetLine({required this.index, required this.set});

  final int index;
  final TrainingSet set;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final weightLabel =
        set.weight == null ? "--" : set.weight!.toStringAsFixed(1);
    final repsLabel = set.reps == null ? "--" : set.reps!.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "Set $index · $weightLabel kg · $repsLabel reps",
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DateFilterPill extends StatelessWidget {
  const _DateFilterPill({required this.date, required this.onClear});

  final DateTime date;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "Fecha: ${_formatDate(date)}",
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onClear,
          child: const Text("Quitar filtro"),
        ),
      ],
    );
  }
}

class TrainingSessionEntry {
  TrainingSessionEntry({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    required this.exercises,
  });

  final String id;
  final String routineId;
  final String routineName;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSec;
  final List<TrainingExercise> exercises;

  static TrainingSessionEntry? fromMap(String id, Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final exercisesRaw = data['exercises'];
    final exercises = exercisesRaw is List
        ? exercisesRaw
            .map((item) => TrainingExercise.fromMap(item))
            .whereType<TrainingExercise>()
            .toList()
        : <TrainingExercise>[];

    return TrainingSessionEntry(
      id: id,
      routineId: data['routineId']?.toString() ?? '',
      routineName: data['routineName']?.toString() ?? 'Entreno',
      startedAt: DateTime.tryParse(data['startedAt']?.toString() ?? ''),
      endedAt: DateTime.tryParse(data['endedAt']?.toString() ?? ''),
      durationSec: (data['durationSec'] is num)
          ? (data['durationSec'] as num).toInt()
          : 0,
      exercises: exercises,
    );
  }
}

class TrainingExercise {
  TrainingExercise({required this.name, required this.sets});

  final String name;
  final List<TrainingSet> sets;

  static TrainingExercise? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final setsRaw = data['sets'];
    final sets = setsRaw is List
        ? setsRaw
            .map((item) => TrainingSet.fromMap(item))
            .whereType<TrainingSet>()
            .toList()
        : <TrainingSet>[];
    return TrainingExercise(
      name: data['name']?.toString() ?? 'Ejercicio',
      sets: sets,
    );
  }
}

class TrainingSet {
  TrainingSet({required this.reps, required this.weight});

  final int? reps;
  final double? weight;

  static TrainingSet? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    return TrainingSet(
      reps: (data['reps'] is num) ? (data['reps'] as num).toInt() : null,
      weight: (data['weight'] is num)
          ? (data['weight'] as num).toDouble()
          : null,
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDuration(int durationSec) {
  final duration = Duration(seconds: durationSec);
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return "${minutes}m ${seconds}s";
}

String _formatDateTime(DateTime date) {
  final d = _formatDate(date);
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return "$d · $h:$m";
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return "$day/$month/$year";
}
