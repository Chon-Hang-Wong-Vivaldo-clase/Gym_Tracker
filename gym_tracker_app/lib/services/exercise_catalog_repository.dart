import 'package:firebase_database/firebase_database.dart';
import 'package:gym_tracker_app/models/exercise.dart';

class ExerciseCatalogRepository {
  ExerciseCatalogRepository({DatabaseReference? root})
      : _root = root ?? FirebaseDatabase.instance.ref();

  final DatabaseReference _root;

  Future<void> upsertCatalog({
    required List<Exercise> exercises,
    required String source,
  }) async {
    final updates = <String, Object?>{};
    for (final ex in exercises) {
      final key = _sanitizeKey(ex.idSource);
      updates['exerciseCatalog/$source/$key'] = ex.toJson();
    }
    if (updates.isNotEmpty) {
      await _root.update(updates);
    }
  }

  String _sanitizeKey(String value) {
    var key = value.trim();
    if (key.isEmpty) key = 'unknown';
    key = key.replaceAll(RegExp(r'[.#$\\[\\]]'), '_');
    return key;
  }
}
