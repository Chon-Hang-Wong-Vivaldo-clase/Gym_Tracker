import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/training_session_start_screen.dart';
import 'package:gym_tracker_app/screens/training_summary_screen.dart';
import 'package:gym_tracker_app/services/training_session_service.dart';

class TrainingSessionScreen extends StatefulWidget {
  const TrainingSessionScreen({super.key, required this.routine});

  final RoutineSessionData routine;

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  late final DateTime _startedAt;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  int _exerciseIndex = 0;
  int _setsCount = 3;
  final Map<int, List<WorkoutSet>> _setsByExercise = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });
    });
    _ensureSetsForCurrent();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureSetsForCurrent() {
    final list = _setsByExercise[_exerciseIndex] ?? <WorkoutSet>[];
    if (list.isEmpty) {
      _setsByExercise[_exerciseIndex] =
          List.generate(_setsCount, (index) => WorkoutSet());
      return;
    }
    if (_setsCount > list.length) {
      list.addAll(
        List.generate(_setsCount - list.length, (_) => WorkoutSet()),
      );
    } else if (_setsCount < list.length) {
      list.removeRange(_setsCount, list.length);
    }
    _setsByExercise[_exerciseIndex] = list;
  }

  Future<void> _nextExercise() async {
    if (!_validateSets()) return;
    if (_exerciseIndex < widget.routine.exercises.length - 1) {
      setState(() {
        _exerciseIndex += 1;
        _setsCount = _setsByExercise[_exerciseIndex]?.length ?? 3;
        _ensureSetsForCurrent();
      });
      return;
    }
    await _finishSession();
  }

  bool _validateSets() {
    final list = _setsByExercise[_exerciseIndex] ?? [];
    for (final s in list) {
      if (s.reps == null || s.weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Completa repeticiones y peso")),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _finishSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final exercises = _buildExercisesPayload();
      final result = await TrainingSessionService.completeSession(
        userUid: user.uid,
        routineId: widget.routine.id,
        routineName: widget.routine.name,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        exercises: exercises,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TrainingSummaryScreen(
            durationSec: result.durationSec,
            routineName: widget.routine.name,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, Object?>> _buildExercisesPayload() {
    final payload = <Map<String, Object?>>[];
    for (var i = 0; i < widget.routine.exercises.length; i++) {
      final ex = widget.routine.exercises[i];
      final name = ex['name']?.toString() ?? 'Ejercicio';
      final sets = _setsByExercise[i] ?? [];
      payload.add({
        'name': name,
        'idSource': ex['idSource']?.toString(),
        'sets': sets
            .map(
              (s) => {
                'reps': s.reps,
                'weight': s.weight,
              },
            )
            .toList(),
      });
    }
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final exercise = widget.routine.exercises[_exerciseIndex];
    final name = exercise['name']?.toString() ?? 'Ejercicio';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sesión de entrenamiento"),
      ),
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SessionHeader(
              routineName: widget.routine.name,
              elapsed: _elapsed,
              current: _exerciseIndex + 1,
              total: widget.routine.exercises.length,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sets",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                DropdownButton<int>(
                  value: _setsCount,
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _setsCount = value;
                      _ensureSetsForCurrent();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _SetsList(
                sets: _setsByExercise[_exerciseIndex] ?? const [],
                onChanged: (index, next) {
                  final list = _setsByExercise[_exerciseIndex] ?? [];
                  if (index < 0 || index >= list.length) return;
                  list[index] = next;
                  _setsByExercise[_exerciseIndex] = list;
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _nextExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
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
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        _exerciseIndex < widget.routine.exercises.length - 1
                            ? "Siguiente"
                            : "Finalizar",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.routineName,
    required this.elapsed,
    required this.current,
    required this.total,
  });

  final String routineName;
  final Duration elapsed;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routineName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TimerPill(elapsed: elapsed),
            Text("$current / $total"),
          ],
        ),
      ],
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final min = elapsed.inMinutes.toString().padLeft(2, '0');
    final sec = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "$min:$sec",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SetsList extends StatelessWidget {
  const _SetsList({required this.sets, required this.onChanged});

  final List<WorkoutSet> sets;
  final void Function(int index, WorkoutSet next) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (sets.isEmpty) {
      return Center(
        child: Text(
          "No hay sets",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      itemCount: sets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final set = sets[index];
        return _SetRow(
          index: index + 1,
          set: set,
          onChanged: (next) => onChanged(index, next),
        );
      },
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.index,
    required this.set,
    required this.onChanged,
  });

  final int index;
  final WorkoutSet set;
  final ValueChanged<WorkoutSet> onChanged;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: _formatWeight(widget.set.weight),
    );
    _repsCtrl = TextEditingController(
      text: widget.set.reps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.weight != widget.set.weight) {
      _weightCtrl.text = _formatWeight(widget.set.weight);
    }
    if (oldWidget.set.reps != widget.set.reps) {
      _repsCtrl.text = widget.set.reps?.toString() ?? '';
    }
  }

  String _formatWeight(double? value) {
    if (value == null) return '';
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final rowBackground = isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final rowBorder = isDark
        ? colorScheme.outline.withOpacity(0.45)
        : const Color(0xFFD8DBE0);
    final fieldBackground = isDark ? colorScheme.surface : const Color(0xFFF8F9FA);
    final fieldBorder = isDark
        ? colorScheme.outline.withOpacity(0.35)
        : const Color(0xFFCED3DA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rowBorder, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "Set ${widget.index}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Kg",
                filled: true,
                fillColor: fieldBackground,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(isDark ? 0.7 : 0.5),
                    width: 1.2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                final weight = double.tryParse(value);
                widget.onChanged(widget.set.copyWith(weight: weight));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Reps",
                filled: true,
                fillColor: fieldBackground,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withOpacity(isDark ? 0.7 : 0.5),
                    width: 1.2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                final reps = int.tryParse(value);
                widget.onChanged(widget.set.copyWith(reps: reps));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutSet {
  WorkoutSet({this.reps, this.weight});

  final int? reps;
  final double? weight;

  WorkoutSet copyWith({int? reps, double? weight}) {
    return WorkoutSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }
}
