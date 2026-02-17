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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBg,
      endDrawer: const AppEndDrawer(),
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: scaffoldBg,
        scrolledUnderElevation: 0,
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
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                        width: 1.2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Seguidos",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: isDark
                              ? Border.all(
                                  color: colorScheme.outline.withOpacity(0.7),
                                  width: 1.0,
                                )
                              : null,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.person_add,
                            color: colorScheme.onPrimaryContainer,
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                    return Center(
                      child: Text(
                        "Aún no hay rutinas públicas",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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

  Future<void> _openSearch(BuildContext context) async {
    final selectedUser = await showModalBottomSheet<_UserSearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SocialUserSearchSheet(),
    );
    if (!context.mounted || selectedUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SocialUserProfileScreen(
          userId: selectedUser.userId,
          username: selectedUser.username,
          photoUrl: selectedUser.photoUrl,
          trainedDays: selectedUser.trainedDays,
          restDays: selectedUser.restDays,
          routines: const [],
        ),
      ),
    );
  }
}

class _SocialUserSearchSheet extends StatefulWidget {
  const _SocialUserSearchSheet();

  @override
  State<_SocialUserSearchSheet> createState() => _SocialUserSearchSheetState();
}

class _SocialUserSearchSheetState extends State<_SocialUserSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeQuery(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalized = _normalizeQuery(_query);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final usersRef = FirebaseDatabase.instance.ref('users');
    final query = normalized.isEmpty
        ? null
        : usersRef
              .orderByChild('profile/username')
              .startAt(normalized)
              .endAt('$normalized\uf8ff')
              .limitToFirst(20);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buscar usuario',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '@usuario',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: query == null
                    ? Center(
                        child: Text(
                          'Escribe para buscar usuarios',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : StreamBuilder<DatabaseEvent>(
                        stream: query.onValue,
                        builder: (context, snapshot) {
                          final results = _mapUserSearchResults(
                            snapshot.data?.snapshot.value,
                            currentUid: currentUid,
                          );
                          if (results.isEmpty) {
                            return Center(
                              child: Text(
                                'No hay usuarios con ese texto',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = results[index];
                              return Material(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.surface,
                                    backgroundImage: user.photoUrl == null
                                        ? null
                                        : NetworkImage(user.photoUrl!),
                                    child: user.photoUrl == null
                                        ? Icon(
                                            Icons.person,
                                            color: colorScheme.onSurfaceVariant,
                                          )
                                        : null,
                                  ),
                                  title: Text(user.username),
                                  subtitle: Text(
                                    '${user.trainedDays} entrenados · ${user.restDays} descanso',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).pop(user),
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
      ),
    );
  }
}

class _UserSearchResult {
  const _UserSearchResult({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.trainedDays,
    required this.restDays,
  });

  final String userId;
  final String username;
  final String? photoUrl;
  final int trainedDays;
  final int restDays;
}

List<_UserSearchResult> _mapUserSearchResults(
  Object? raw, {
  required String currentUid,
}) {
  if (raw is! Map) return const [];
  final results = <_UserSearchResult>[];
  for (final entry in raw.entries) {
    final uid = entry.key.toString();
    if (uid.isEmpty || uid == currentUid) continue;
    final value = entry.value;
    if (value is! Map) continue;

    final data = Map<String, dynamic>.from(value);
    final profileRaw = data['profile'];
    final profile = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : <String, dynamic>{};
    final username = profile['username']?.toString().trim() ?? '';
    if (username.isEmpty) continue;

    final statsRaw = data['stats'];
    final stats = statsRaw is Map
        ? Map<String, dynamic>.from(statsRaw)
        : <String, dynamic>{};
    final trainedDays = _getTrainedTotalFromStats(stats);
    final restDays = _computeRestTotalFromCreatedAt(
      createdAtRaw: profile['createdAt'],
      trainedTotal: trainedDays,
      fallback: (stats['restDaysCount'] is num)
          ? (stats['restDaysCount'] as num).toInt()
          : 0,
    );

    results.add(
      _UserSearchResult(
        userId: uid,
        username: username,
        photoUrl: profile['photoUrl']?.toString(),
        trainedDays: trainedDays,
        restDays: restDays,
      ),
    );
  }
  results.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
  return results;
}

class _Friend {
  const _Friend({
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.isOnline,
    required this.trainedDays,
    required this.restDays,
  });

  final String userId;
  final String username;
  final String? photoUrl;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final outline = theme.colorScheme.outline.withOpacity(0.55);

    return Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isDark
            ? BorderSide(color: outline, width: 1.1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: friend.photoUrl == null
                        ? null
                        : NetworkImage(friend.photoUrl!),
                    child: friend.photoUrl == null
                        ? Icon(Icons.person, color: onSurfaceVariant, size: 18)
                        : null,
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
                          border: Border.all(color: surface, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Text(
                friend.username,
                style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: onSurfaceVariant),
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
      return Center(
        child: Text(
          "Inicia sesión para ver seguidos",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
          return Center(
            child: Text(
              "Aún no sigues a nadie",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
        final photoUrl = profile['photoUrl']?.toString();
        final trained = _getTrainedTotalFromStats(stats);
        final rest = _computeRestTotalFromCreatedAt(
          createdAtRaw: profile['createdAt'],
          trainedTotal: trained,
          fallback: (stats['restDaysCount'] is num)
              ? (stats['restDaysCount'] as num).toInt()
              : 0,
        );
        final state = presence['state']?.toString() ?? 'offline';
        final isOnline = state == 'online';

        return _FriendTile(
          friend: _Friend(
            userId: userId,
            username: username,
            photoUrl: photoUrl,
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
                  photoUrl: photoUrl,
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

    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: onSurfaceVariant)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onLikeToggle,
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? const Color(0xFFE53935) : onSurfaceVariant,
              ),
            ),
            Icon(Icons.chevron_right, color: onSurfaceVariant),
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

int _getTrainedTotalFromStats(Map<dynamic, dynamic> stats) {
  final trainedRaw = stats['trainedDays'];
  if (trainedRaw is Map) return trainedRaw.length;
  if (stats['trainedDaysCount'] is num) {
    return (stats['trainedDaysCount'] as num).toInt();
  }
  return 0;
}

int _computeRestTotalFromCreatedAt({
  required dynamic createdAtRaw,
  required int trainedTotal,
  required int fallback,
}) {
  final createdAt = _parseCreatedAt(createdAtRaw);
  if (createdAt == null) return fallback;

  final now = DateTime.now();
  final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final elapsedDays = today.difference(createdDate).inDays + 1;
  if (elapsedDays <= 0) return fallback;
  final rest = elapsedDays - trainedTotal;
  return rest >= 0 ? rest : 0;
}

DateTime? _parseCreatedAt(dynamic raw) {
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  }
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  return null;
}
