import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedMuscle;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogRef = FirebaseDatabase.instance.ref('exerciseCatalog/api_ninjas');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de ejercicios"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Nombre del ejercicio",
                      filled: true,
                      fillColor: const Color(0xFFF2F2F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _openFilter,
                  icon: const Icon(Icons.filter_alt_outlined),
                ),
              ],
            ),
            if (_selectedMuscle != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _FilterChip(
                  label: _selectedMuscle!,
                  onClear: () => setState(() => _selectedMuscle = null),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: catalogRef.onValue,
                builder: (context, snapshot) {
                  final raw = snapshot.data?.snapshot.value;
                  final data = raw is Map ? raw : <dynamic, dynamic>{};
                  final list = _mapExercises(data);
                  final filtered = _applyFilters(list);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay ejercicios con ese filtro",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      return SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(ex),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C7075),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(ex.name),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscles.map((muscle) {
              final selected = muscle == _selectedMuscle;
              return ChoiceChip(
                label: Text(muscle),
                selected: selected,
                onSelected: (value) {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedMuscle = value ? muscle : null;
                  });
                },
                selectedColor: const Color(0xFF2B2E34),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  List<ExerciseLite> _mapExercises(Map<dynamic, dynamic> data) {
    final list = <ExerciseLite>[];
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final name = value['name']?.toString();
      if (name == null || name.trim().isEmpty) continue;
      list.add(
        ExerciseLite(
          idSource: value['idSource']?.toString() ?? entry.key.toString(),
          name: name,
          muscleGroup: value['muscleGroup']?.toString(),
          source: value['source']?.toString() ?? 'api_ninjas',
        ),
      );
    }
    return list;
  }

  List<ExerciseLite> _applyFilters(List<ExerciseLite> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return list.where((e) {
      if (_selectedMuscle != null && _selectedMuscle!.isNotEmpty) {
        if ((e.muscleGroup ?? '').toLowerCase() !=
            _selectedMuscle!.toLowerCase()) {
          return false;
        }
      }
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q);
    }).toList();
  }
}

class ExerciseLite {
  ExerciseLite({
    required this.idSource,
    required this.name,
    required this.muscleGroup,
    required this.source,
  });

  final String idSource;
  final String name;
  final String? muscleGroup;
  final String source;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onClear,
      backgroundColor: const Color(0xFFE0E0E0),
    );
  }
}

const _muscles = <String>[
  'abdominals',
  'abductors',
  'adductors',
  'biceps',
  'calves',
  'chest',
  'forearms',
  'glutes',
  'hamstrings',
  'lats',
  'lower_back',
  'middle_back',
  'neck',
  'quadriceps',
  'traps',
  'triceps',
];
