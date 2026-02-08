import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/training_session_start_screen.dart';
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
      endDrawer: const _HomeEndDrawer(),
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
              child: _MonthlyCalendar(statsRef: statsRef),
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
  const _MonthlyCalendar({required this.statsRef});

  final DatabaseReference? statsRef;

  @override
  Widget build(BuildContext context) {
    if (statsRef == null) {
      return MonthlyWorkoutCalendar(
        plannedDays: const <DateTime>{},
        streakDays: const <DateTime>{},
        onDayTapped: (date) {
          debugPrint('Calendario: ${date.toIso8601String()}');
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
            debugPrint('Calendario: ${date.toIso8601String()}');
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

class _HomeEndDrawer extends StatefulWidget {
  const _HomeEndDrawer();

  @override
  State<_HomeEndDrawer> createState() => _HomeEndDrawerState();
}

class _HomeEndDrawerState extends State<_HomeEndDrawer> {
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.user;
    final uid = user?.uid;
    final profileRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/profile');
    final settingsRef = uid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$uid/settings');

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(height: 8),
              _ProfileHeader(userEmail: user?.email, profileRef: profileRef),
              const SizedBox(height: 18),
              _SettingsSwitch(
                label: "Activo",
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFBDBDBD),
                settingsRef: settingsRef,
                fieldKey: "active",
                fallback: false,
              ),
              const SizedBox(height: 6),
              _LocalSwitch(
                label: "Tema Oscuro",
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: const Color(0xFFBDBDBD),
                value: _darkTheme,
                onChanged: (next) {
                  setState(() {
                    _darkTheme = next;
                  });
                },
              ),
              const SizedBox(height: 24),
              _DrawerButton(
                label: "Crear una nueva rutina",
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('create_routine');
                },
              ),
              const SizedBox(height: 12),
              _DrawerButton(
                label: "Mis rutinas",
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('routines');
                },
              ),
              const Spacer(),
              _LogoutButton(
                onPressed: () async {
                  await context.read<AppAuthProvider>().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userEmail, required this.profileRef});

  final String? userEmail;
  final DatabaseReference? profileRef;

  @override
  Widget build(BuildContext context) {
    if (profileRef == null) {
      return _ProfileContent(
        name: "Invitado",
        email: userEmail ?? "Sin email",
        photoUrl: null,
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: profileRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final name = (data["name"] ?? "").toString();
        final surname = (data["surname"] ?? "").toString();
        final displayName = [
          name,
          surname,
        ].where((value) => value.trim().isNotEmpty).join(' ').trim();
        final email = (data["email"] ?? userEmail ?? "Sin email").toString();
        final photoUrl = data["photoUrl"]?.toString();

        return _ProfileContent(
          name: displayName.isEmpty ? "Usuario" : displayName,
          email: email,
          photoUrl: photoUrl,
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
          child: photoUrl == null
              ? const Icon(Icons.person, color: Colors.black54)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.label,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.settingsRef,
    required this.fieldKey,
    required this.fallback,
  });

  final String label;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final DatabaseReference? settingsRef;
  final String fieldKey;
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    if (settingsRef == null) {
      return _SwitchRow(
        label: label,
        value: fallback,
        activeTrackColor: activeTrackColor,
        inactiveTrackColor: inactiveTrackColor,
        onChanged: null,
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: settingsRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final value = (data[fieldKey] ?? fallback) == true;

        return _SwitchRow(
          label: label,
          value: value,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          onChanged: (next) async {
            await settingsRef!.child(fieldKey).set(next);
          },
        );
      },
    );
  }
}

class _LocalSwitch extends StatelessWidget {
  const _LocalSwitch({
    required this.label,
    required this.value,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SwitchRow(
      label: label,
      value: value,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      onChanged: onChanged,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
        ),
      ],
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C7075),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B2E34),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text("Cerrar Sesión"),
      ),
    );
  }
}
