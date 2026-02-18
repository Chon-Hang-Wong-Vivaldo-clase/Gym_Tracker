import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/training_session_start_screen.dart';
import 'package:gym_tracker_app/screens/training_history_screen.dart';
import 'package:gym_tracker_app/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "¡Buenos Días!";
    if (hour < 20) return "¡Buenas Tardes!";
    return "¡Buenas Noches!";
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.user?.uid;
    final userRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid');

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBg,
      endDrawer: const AppEndDrawer(),
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        scrolledUnderElevation: 0,
        leading: const SizedBox(),
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/image.png'
                  : 'assets/logo-removebg-preview.png',
              fit: BoxFit.contain,
              height: 32,
              alignment: FractionalOffset.center,
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: WeekSwiper(onDateSelected: (_) {}),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 0, 10),
              child: Text(
                _greetingByHour(),
                style: TextStyle(
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrainingSessionStartScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B2E34),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Iniciar entreno"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _HomeStatsSection(userRef: userRef, userUid: uid),
          ],
        ),
      ),
    );
  }
}

class _HomeStatsSection extends StatelessWidget {
  const _HomeStatsSection({required this.userRef, required this.userUid});

  final DatabaseReference? userRef;
  final String? userUid;

  @override
  Widget build(BuildContext context) {
    if (userRef == null) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 20, 0, 35),
            child: Center(child: _StreakRing(streakDays: 0)),
          ),
          Center(
            child: Text(
              "Seguimiento mensual",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 30, endIndent: 30, indent: 30),
          const _StatsRow(trained: 0, rest: 0),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MonthlyCalendar(
              streakDays: const <DateTime>{},
              userUid: userUid,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: userRef!.onValue,
      builder: (context, snapshot) {
        final userData = snapshot.data?.snapshot.value as Map? ?? {};
        final statsRaw = userData['stats'];
        final stats = statsRaw is Map
            ? Map<String, dynamic>.from(statsRaw)
            : <String, dynamic>{};
        final profileRaw = userData['profile'];
        final profile = profileRaw is Map
            ? Map<String, dynamic>.from(profileRaw)
            : <String, dynamic>{};

        final trainedRaw = stats['trainedDays'];
        final trainedMap = trainedRaw is Map
            ? trainedRaw
            : <dynamic, dynamic>{};
        final days = trainedMap.keys
            .map((key) => _parseDateKey(key.toString()))
            .whereType<DateTime>()
            .toSet();
        final trained = _countCurrentMonthTrainedDays(days);
        final rest = _countCurrentMonthRestDays(days);
        final restDays = _parseRestDays(profile['restDays']);
        final streakDays = _computeCurrentStreak(
          trainedDays: days,
          restDays: restDays,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 35),
              child: Center(child: _StreakRing(streakDays: streakDays)),
            ),
            Center(
              child: Text(
                "Seguimiento mensual",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 30, endIndent: 30, indent: 30),
            _StatsRow(trained: trained, rest: rest),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MonthlyCalendar(streakDays: days, userUid: userUid),
            ),
          ],
        );
      },
    );
  }
}

class _StreakRing extends StatelessWidget {
  const _StreakRing({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return StreakWaterRing(streakDays: streakDays, goalDays: 30, size: 260);
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.trained, required this.rest});

  final int trained;
  final int rest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trainedBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF2B2E34);
    final restBg = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : const Color(0xFFBDBDBD);
    final cardTextColor = isDark ? theme.colorScheme.onSurface : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatCard(
          title: "Entrenado",
          value: trained,
          background: trainedBg,
          textColor: cardTextColor,
        ),
        const SizedBox(width: 14),
        StatCard(
          title: "Descanso",
          value: rest,
          background: restBg,
          textColor: cardTextColor,
        ),
      ],
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({required this.streakDays, required this.userUid});

  final Set<DateTime> streakDays;
  final String? userUid;

  @override
  Widget build(BuildContext context) {
    return MonthlyWorkoutCalendar(
      plannedDays: const <DateTime>{},
      streakDays: streakDays,
      onDayTapped: (date) {
        if (userUid == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrainingHistoryScreen(initialDay: date),
          ),
        );
      },
    );
  }
}

DateTime? _parseDateKey(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

int _countCurrentMonthTrainedDays(Set<DateTime> trainedDays) {
  final today = DateTime.now();
  return trainedDays
      .where((day) => day.year == today.year && day.month == today.month)
      .length;
}

int _countCurrentMonthRestDays(Set<DateTime> trainedDays) {
  final today = DateTime.now();
  final trainedThisMonth = _countCurrentMonthTrainedDays(trainedDays);
  final elapsedMonthDays = today.day;
  final restDays = elapsedMonthDays - trainedThisMonth;
  return restDays > 0 ? restDays : 0;
}

Set<int> _parseRestDays(dynamic raw) {
  final result = <int>{};
  if (raw is List) {
    for (final value in raw) {
      final parsed = _toInt(value);
      if (parsed != null && parsed >= 1 && parsed <= 7) result.add(parsed);
    }
  } else if (raw is Map) {
    for (final value in raw.values) {
      final parsed = _toInt(value);
      if (parsed != null && parsed >= 1 && parsed <= 7) result.add(parsed);
    }
  }
  final sorted = result.toList()..sort();
  return sorted.take(2).toSet();
}

int _computeCurrentStreak({
  required Set<DateTime> trainedDays,
  required Set<int> restDays,
}) {
  if (trainedDays.isEmpty) return 0;

  var current = DateTime.now();
  current = DateTime(current.year, current.month, current.day);
  var streak = 0;
  var guard = 0;

  while (guard < 3650) {
    guard += 1;
    if (trainedDays.contains(current)) {
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

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
