import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/training_session_start_screen.dart';
import 'package:gym_tracker_app/screens/training_history_screen.dart';
import 'package:gym_tracker_app/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.user?.uid;
    final statsRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/stats');

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppEndDrawer(),
      appBar: AppBar(
        leading: const SizedBox(),
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              height: 32,
              alignment: FractionalOffset.center,
            ),
          ],
        ),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
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
              padding: EdgeInsets.fromLTRB(10, 0, 0, 10),
              child: WeekSwiper(
                onDateSelected: (date) {
                  print(date);
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 0, 0, 10),
              child: Text("¡Buenos días!", style: TextStyle(fontSize: 22)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 35),
              child: Center(child: _StreakRing(statsRef: statsRef)),
            ),
            const Center(
              child: Text(
                "Seguimiento mensual",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const Divider(height: 30, endIndent: 30, indent: 30),
            _StatsRow(statsRef: statsRef),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MonthlyCalendar(statsRef: statsRef, userUid: uid),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakRing extends StatelessWidget {
  const _StreakRing({required this.statsRef});

  final DatabaseReference? statsRef;

  @override
  Widget build(BuildContext context) {
    if (statsRef == null) {
      return const StreakWaterRing(streakDays: 0, goalDays: 30, size: 260);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: statsRef!.onValue,
      builder: (context, snapshot) {
        final data = snapshot.data?.snapshot.value as Map? ?? {};
        final streakDays = (data['streakDays'] is num)
            ? (data['streakDays'] as num).toInt()
            : 0;
        return StreakWaterRing(streakDays: streakDays, goalDays: 30, size: 260);
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.statsRef});

  final DatabaseReference? statsRef;

  @override
  Widget build(BuildContext context) {
    if (statsRef == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatCard(
            title: "Entrenado",
            value: 0,
            background: const Color(0xFF2B2E34),
            textColor: Colors.white,
          ),
          const SizedBox(width: 14),
          StatCard(
            title: "Descanso",
            value: 0,
            background: const Color(0xFFBDBDBD),
            textColor: Colors.white,
          ),
        ],
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: statsRef!.onValue,
      builder: (context, snapshot) {
        final data = snapshot.data?.snapshot.value as Map? ?? {};
        final trained = (data['trainedDaysCount'] is num)
            ? (data['trainedDaysCount'] as num).toInt()
            : 0;
        final rest = _computeRestDays(data['lastTrainedAt']?.toString());
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatCard(
              title: "Entrenado",
              value: trained,
              background: const Color(0xFF2B2E34),
              textColor: Colors.white,
            ),
            const SizedBox(width: 14),
            StatCard(
              title: "Descanso",
              value: rest,
              background: const Color(0xFFBDBDBD),
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({required this.statsRef, required this.userUid});

  final DatabaseReference? statsRef;
  final String? userUid;

  @override
  Widget build(BuildContext context) {
    if (statsRef == null) {
      return MonthlyWorkoutCalendar(
        plannedDays: const <DateTime>{},
        streakDays: const <DateTime>{},
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

    return StreamBuilder<DatabaseEvent>(
      stream: statsRef!.child('trainedDays').onValue,
      builder: (context, snapshot) {
        final data = snapshot.data?.snapshot.value as Map? ?? {};
        final days = data.keys
            .map((key) => _parseDateKey(key.toString()))
            .whereType<DateTime>()
            .toSet();
        return MonthlyWorkoutCalendar(
          plannedDays: const <DateTime>{},
          streakDays: days,
          onDayTapped: (date) {
            if (userUid == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrainingHistoryScreen(initialDay: date),
              ),
            );
          },
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

int _computeRestDays(String? lastTrainedIso) {
  if (lastTrainedIso == null || lastTrainedIso.trim().isEmpty) return 0;
  final last = DateTime.tryParse(lastTrainedIso);
  if (last == null) return 0;
  final today = DateTime.now();
  final lastDate = DateTime(last.year, last.month, last.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final diff = todayDate.difference(lastDate).inDays;
  return diff > 0 ? diff : 0;
}
