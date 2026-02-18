/// persistir y consultar datos de sesiones de entrenamiento.
import 'package:firebase_database/firebase_database.dart';

class TrainingSessionService {
  static Future<TrainingSessionResult> completeSession({
    required String userUid,
    required String routineId,
    required String routineName,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<Map<String, Object?>> exercises,
  }) async {
    final root = FirebaseDatabase.instance.ref();

    final durationSec = endedAt.difference(startedAt).inSeconds;
    final sessionRef = root.child('users/$userUid/trainingSessions').push();
    final sessionId = sessionRef.key ?? 'session';

    final sessionData = {
      'routineId': routineId,
      'routineName': routineName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSec': durationSec,
      'exercises': exercises,
    };

    final todayKey = _dateKey(endedAt);
    final statsRef = root.child('users/$userUid/stats');
    final profileRef = root.child('users/$userUid/profile');
    final statsSnap = await statsRef.get();
    final profileSnap = await profileRef.get();
    final stats = statsSnap.value is Map
        ? Map<String, dynamic>.from(statsSnap.value as Map)
        : <String, dynamic>{};
    final profile = profileSnap.value is Map
        ? Map<String, dynamic>.from(profileSnap.value as Map)
        : <String, dynamic>{};

    final trainedMapRaw = stats['trainedDays'];
    final trainedMap = trainedMapRaw is Map
        ? Map<String, dynamic>.from(trainedMapRaw)
        : <String, dynamic>{};
    trainedMap[todayKey] = true;
    final restDays = _parseRestDays(profile['restDays']);

    final streak = _computeStreak(
      trainedMap.keys,
      restDays: restDays,
      referenceDate: endedAt,
    );
    final trainedCount = trainedMap.length;
    final prevRest = (stats['restDaysCount'] is num)
        ? (stats['restDaysCount'] as num).toInt()
        : 0;
    final prevLast = stats['lastTrainedAt']?.toString();
    final addedRest = _computeAddedRestDays(prevLast, endedAt);
    final restTotal = prevRest + addedRest;

    final updates = <String, Object?>{
      'users/$userUid/trainingSessions/$sessionId': sessionData,
      'users/$userUid/stats/trainedDays/$todayKey': true,
      'users/$userUid/stats/streakDays': streak,
      'users/$userUid/stats/trainedDaysCount': trainedCount,
      'users/$userUid/stats/restDaysCount': restTotal,
      'users/$userUid/stats/lastTrainedAt': endedAt.toIso8601String(),
    };

    await root.update(updates);

    return TrainingSessionResult(
      sessionId: sessionId,
      durationSec: durationSec,
      streakDays: streak,
    );
  }

  static int _computeStreak(
    Iterable<String> keys, {
    required Set<int> restDays,
    required DateTime referenceDate,
  }) {
    final dates = keys.map(_parseDateKey).whereType<DateTime>().toSet();
    if (dates.isEmpty) return 0;

    var current = referenceDate;
    current = DateTime(current.year, current.month, current.day);
    var streak = 0;
    var guard = 0;

    while (guard < 3650) {
      guard += 1;
      if (dates.contains(current)) {
        streak += 1;
        current = current.subtract(const Duration(days: 1));
        continue;
      }
      if (restDays.contains(current.weekday)) {
        current = current.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    return streak;
  }

  static int _computeAddedRestDays(String? lastTrainedIso, DateTime now) {
    if (lastTrainedIso == null || lastTrainedIso.trim().isEmpty) return 0;
    final last = DateTime.tryParse(lastTrainedIso);
    if (last == null) return 0;
    final lastDate = DateTime(last.year, last.month, last.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    final diff = nowDate.difference(lastDate).inDays;
    if (diff <= 1) return 0;
    return diff - 1;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _parseDateKey(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static Set<int> _parseRestDays(dynamic raw) {
    final values = <int>{};
    if (raw is List) {
      for (final v in raw) {
        final n = _toInt(v);
        if (n != null && n >= 1 && n <= 7) values.add(n);
      }
    } else if (raw is Map) {
      for (final v in raw.values) {
        final n = _toInt(v);
        if (n != null && n >= 1 && n <= 7) values.add(n);
      }
    }
    final sorted = values.toList()..sort();
    return sorted.take(2).toSet();
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class TrainingSessionResult {
  const TrainingSessionResult({
    required this.sessionId,
    required this.durationSec,
    required this.streakDays,
  });

  final String sessionId;
  final int durationSec;
  final int streakDays;
}
