import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:gym_tracker_app/screens/routine_detail_screen.dart';
import 'package:gym_tracker_app/screens/social_user_profile_screen.dart';
import 'package:gym_tracker_app/services/routine_like_service.dart';
import 'package:gym_tracker_app/widgets/widgets.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final publicRoutinesRef = FirebaseDatabase.instance.ref('publicRoutines');

    final likesRef = FirebaseDatabase.instance.ref(
      'users/${FirebaseAuth.instance.currentUser?.uid}/likedRoutines',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AppEndDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Social",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Seguidos",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B2E34),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                          ),
                          onPressed: () => _openSearch(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(height: 170, child: const _FollowingList()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Rutinas públicas",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: publicRoutinesRef.onValue,
                builder: (context, snapshot) {
                  final items = _mapPublicRoutines(
                    snapshot.data?.snapshot.value,
                  );
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aún no hay rutinas públicas",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return StreamBuilder<DatabaseEvent>(
                    stream: likesRef.onValue,
                    builder: (context, likesSnapshot) {
                      final likedIds = _mapLikedIds(
                        likesSnapshot.data?.snapshot.value,
                      );
                      final currentUid =
                          FirebaseAuth.instance.currentUser?.uid ?? '';

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final routine = items[index];
                          final isLiked = likedIds.contains(routine.id);
                          return _RoutinePublicCard(
                            item: routine,
                            isLiked: isLiked,
                            onLikeToggle: currentUid.isEmpty
                                ? null
                                : () async {
                                    await RoutineLikeService.toggleLike(
                                      userUid: currentUid,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buscar usuario"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "@usuario"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isEmpty) return;
              final username = (input.startsWith("@") ? input : "@$input")
                  .toLowerCase();

              final usersRef = FirebaseDatabase.instance.ref('users');
              final query = usersRef
                  .orderByChild('profile/username')
                  .equalTo(username);
              final snap = await query.get();

              if (!context.mounted) return;
              if (!snap.exists || snap.children.isEmpty) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ese usuario no existe")),
                );
                return;
              }

              final userSnap = snap.children.first;
              final data = userSnap.value as Map? ?? {};
              final profile = data['profile'] as Map? ?? {};
              final stats = data['stats'] as Map? ?? {};
              final display = profile['username']?.toString() ?? username;
              final trained = (stats['trainedDaysCount'] is num)
                  ? (stats['trainedDaysCount'] as num).toInt()
                  : 0;
              final rest = (stats['restDaysCount'] is num)
                  ? (stats['restDaysCount'] as num).toInt()
                  : 0;
              final targetUid = userSnap.key?.toString() ?? '';

              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SocialUserProfileScreen(
                    userId: targetUid,
                    username: display,
                    trainedDays: trained,
                    restDays: rest,
                    routines: const [],
                  ),
                ),
              );
            },
            child: const Text("Buscar"),
          ),
        ],
      ),
    );
  }
}

class _Friend {
  const _Friend({
    required this.userId,
    required this.username,
    required this.isOnline,
    required this.trainedDays,
    required this.restDays,
  });

  final String userId;
  final String username;
  final bool isOnline;
  final int trainedDays;
  final int restDays;
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onTap});

  final _Friend friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFD9D9D9),
                    child: Icon(Icons.person, color: Colors.black54, size: 18),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                friend.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowingList extends StatelessWidget {
  const _FollowingList();

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const Center(
        child: Text(
          "Inicia sesión para ver seguidos",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final followingRef = FirebaseDatabase.instance.ref(
      'users/$currentUid/following',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: followingRef.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final ids = data.keys.map((e) => e.toString()).toList();
        if (ids.isEmpty) {
          return const Center(
            child: Text(
              "Aún no sigues a nadie",
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final uid = ids[index];
            return _FollowingTile(userId: uid);
          },
        );
      },
    );
  }
}

class _FollowingTile extends StatelessWidget {
  const _FollowingTile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseDatabase.instance.ref('users/$userId');

    return StreamBuilder<DatabaseEvent>(
      stream: userRef.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final profile = data['profile'] as Map? ?? {};
        final stats = data['stats'] as Map? ?? {};
        final presence = data['presence'] as Map? ?? {};
        final username = profile['username']?.toString() ?? '@usuario';
        final trained = (stats['trainedDaysCount'] is num)
            ? (stats['trainedDaysCount'] as num).toInt()
            : 0;
        final rest = (stats['restDaysCount'] is num)
            ? (stats['restDaysCount'] as num).toInt()
            : 0;
        final state = presence['state']?.toString() ?? 'offline';
        final isOnline = state == 'online';

        return _FriendTile(
          friend: _Friend(
            userId: userId,
            username: username,
            isOnline: isOnline,
            trainedDays: trained,
            restDays: rest,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SocialUserProfileScreen(
                  userId: userId,
                  username: username,
                  trainedDays: trained,
                  restDays: rest,
                  routines: const [],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PublicRoutineItem {
  const PublicRoutineItem({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.likesCount,
    required this.exercisesCount,
    required this.exercises,
  });

  final String id;
  final String name;
  final String ownerUid;
  final int likesCount;
  final int exercisesCount;
  final List<dynamic>? exercises;

  RoutineLikeData toLikeData() {
    return RoutineLikeData(
      name: name,
      ownerUid: ownerUid,
      isPublic: true,
      likesCount: likesCount,
      exercises: exercises,
      exercisesCount: exercisesCount,
    );
  }
}

class _RoutinePublicCard extends StatelessWidget {
  const _RoutinePublicCard({
    required this.item,
    this.isLiked = false,
    this.onLikeToggle,
    this.onOpen,
  });

  final PublicRoutineItem item;
  final bool isLiked;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      '${item.exercisesCount} ejercicios',
      '❤️ ${item.likesCount}',
    ].join(' • ');

    return Card(
      elevation: 0,
      color: const Color(0xFFF5F5F5),
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
            IconButton(
              onPressed: onLikeToggle,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFE53935) : Colors.black54,
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

List<PublicRoutineItem> _mapPublicRoutines(Object? raw) {
  if (raw is! Map) return [];
  final items = <PublicRoutineItem>[];

  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    final name = value['name']?.toString();
    if (name == null || name.trim().isEmpty) continue;

    final exercises = value['exercises'];
    final exercisesCount = exercises is List ? exercises.length : 0;
    final likesCount = value['likesCount'] is num
        ? (value['likesCount'] as num).toInt()
        : 0;
    final ownerUid = value['ownerUid']?.toString() ?? '';

    items.add(
      PublicRoutineItem(
        id: entry.key.toString(),
        name: name,
        ownerUid: ownerUid,
        likesCount: likesCount,
        exercisesCount: exercisesCount,
        exercises: exercises is List ? exercises : null,
      ),
    );
  }

  return items;
}

Set<String> _mapLikedIds(Object? raw) {
  if (raw is! Map) return {};
  return raw.keys.map((e) => e.toString()).toSet();
}

void _openDetail(BuildContext context, PublicRoutineItem routine) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RoutineDetailScreen(
        detail: RoutineDetail(
          id: routine.id,
          name: routine.name,
          ownerUid: routine.ownerUid,
          isPublic: true,
          likesCount: routine.likesCount,
          exercises: routine.exercises,
          exercisesCount: routine.exercisesCount,
        ),
      ),
    ),
  );
}
