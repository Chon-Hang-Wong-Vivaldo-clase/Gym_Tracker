import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/screens/routine_detail_screen.dart';
import 'package:gym_tracker_app/services/routine_like_service.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mis rutinas"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Creadas"),
              Tab(text: "Likes"),
            ],
          ),
        ),
        backgroundColor: colorScheme.surface,
        body: const TabBarView(
          children: [_CreatedRoutinesTab(), _LikedRoutinesTab()],
        ),
      ),
    );
  }
}

class _CreatedRoutinesTab extends StatelessWidget {
  const _CreatedRoutinesTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("No hay sesión activa"));
    }

    final routinesRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/routines',
    );
    final likesRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/likedRoutines',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: routinesRef.onValue,
      builder: (context, snapshot) {
        final items = _mapRoutineList(snapshot.data?.snapshot.value);
        if (items.isEmpty) {
          final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
          return Center(
            child: Text(
              "Aún no has creado rutinas",
              style: TextStyle(color: onSurfaceVariant),
            ),
          );
        }

        return StreamBuilder<DatabaseEvent>(
          stream: likesRef.onValue,
          builder: (context, likesSnapshot) {
            final likedIds = _mapLikedIds(likesSnapshot.data?.snapshot.value);

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final routine = items[index];
                final isLiked = likedIds.contains(routine.id);
                return _RoutineCard(
                  item: routine,
                  showLike: true,
                  isLiked: isLiked,
                  onLikeToggle: () async {
                    await RoutineLikeService.toggleLike(
                      userUid: user.uid,
                      routineId: routine.id,
                      routineData: routine.toLikeData(),
                      isLiked: isLiked,
                    );
                  },
                  onOpen: () => _openDetail(context, routine),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LikedRoutinesTab extends StatelessWidget {
  const _LikedRoutinesTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("No hay sesión activa"));
    }

    final likesRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/likedRoutines',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: likesRef.onValue,
      builder: (context, snapshot) {
        final items = _mapRoutineList(snapshot.data?.snapshot.value);
        if (items.isEmpty) {
          final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
          return Center(
            child: Text(
              "Aún no has dado likes",
              style: TextStyle(color: onSurfaceVariant),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final routine = items[index];
            return _RoutineCard(
              item: routine,
              showLike: true,
              isLiked: true,
              onLikeToggle: () async {
                await RoutineLikeService.toggleLike(
                  userUid: user.uid,
                  routineId: routine.id,
                  routineData: routine.toLikeData(),
                  isLiked: true,
                );
              },
              onOpen: () => _openDetail(context, routine),
            );
          },
        );
      },
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.item,
    this.showLike = false,
    this.isLiked = false,
    this.onLikeToggle,
    this.onOpen,
  });

  final RoutineItem item;
  final bool showLike;
  final bool isLiked;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;
    final subtitle = [
      if (item.exercisesCount != null) '${item.exercisesCount} ejercicios',
      item.isPublic == true ? 'Pública' : 'Privada',
      if (item.likesCount != null) '❤️ ${item.likesCount}',
    ].where((e) => e.toString().trim().isNotEmpty).join(' • ');

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLike)
              IconButton(
                onPressed: onLikeToggle,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? const Color(0xFFE53935) : onSurfaceVariant,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class RoutineItem {
  RoutineItem({
    required this.id,
    required this.name,
    required this.exercisesCount,
    required this.likesCount,
    required this.isPublic,
    required this.ownerUid,
    required this.exercises,
  });

  final String id;
  final String name;
  final int? exercisesCount;
  final int? likesCount;
  final bool? isPublic;
  final String ownerUid;
  final List<dynamic>? exercises;

  RoutineLikeData toLikeData() {
    return RoutineLikeData(
      name: name,
      ownerUid: ownerUid,
      isPublic: isPublic,
      likesCount: likesCount,
      exercises: exercises,
      exercisesCount: exercisesCount,
    );
  }
}

List<RoutineItem> _mapRoutineList(Object? raw) {
  if (raw is! Map) return [];
  final items = <RoutineItem>[];
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final data = _unwrapRoutineMap(value);
    final name = data['name']?.toString();
    if (name == null || name.trim().isEmpty) continue;

    final exercises = data['exercises'];
    final exercisesCount = exercises is List
        ? exercises.length
        : (data['exercisesCount'] is num
              ? (data['exercisesCount'] as num).toInt()
              : null);
    final likesCountRaw = data['likesCount'];
    final likesCount = likesCountRaw is num ? likesCountRaw.toInt() : null;
    final isPublic = data['isPublic'] == true;
    final ownerUid = data['ownerUid']?.toString() ?? '';

    items.add(
      RoutineItem(
        id: entry.key.toString(),
        name: name,
        exercisesCount: exercisesCount,
        likesCount: likesCount,
        isPublic: isPublic,
        ownerUid: ownerUid,
        exercises: exercises is List ? exercises : null,
      ),
    );
  }
  return items;
}

Map<dynamic, dynamic> _unwrapRoutineMap(Map<dynamic, dynamic> value) {
  final routine = value['routine'];
  if (routine is Map) return routine;
  return value;
}

Set<String> _mapLikedIds(Object? raw) {
  if (raw is! Map) return {};
  return raw.keys.map((e) => e.toString()).toSet();
}

void _openDetail(BuildContext context, RoutineItem routine) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RoutineDetailScreen(
        detail: RoutineDetail(
          id: routine.id,
          name: routine.name,
          ownerUid: routine.ownerUid,
          isPublic: routine.isPublic,
          likesCount: routine.likesCount,
          exercises: routine.exercises,
          exercisesCount: routine.exercisesCount,
        ),
      ),
    ),
  );
}
