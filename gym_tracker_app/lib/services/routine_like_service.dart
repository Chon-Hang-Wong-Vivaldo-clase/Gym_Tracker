import 'package:firebase_database/firebase_database.dart';

class RoutineLikeService {
  static Future<void> toggleLike({
    required String userUid,
    required String routineId,
    required RoutineLikeData routineData,
    required bool isLiked,
  }) async {
    final root = FirebaseDatabase.instance.ref();

    final nextLikes = isLiked
        ? ((routineData.likesCount ?? 1) - 1)
        : ((routineData.likesCount ?? 0) + 1);
    final safeLikes = nextLikes < 0 ? 0 : nextLikes;

    final updates = <String, Object?>{
      'users/$userUid/likedRoutines/$routineId': isLiked
          ? null
          : _likedPayload(routineData, safeLikes),
    };

    updates['users/${routineData.ownerUid}/routines/$routineId/likesCount'] =
        safeLikes;

    if (routineData.isPublic == true) {
      updates['publicRoutines/$routineId/likesCount'] = safeLikes;
    }

    await root.update(updates);
  }

  static Map<String, Object?> _likedPayload(RoutineLikeData data, int likes) {
    return {
      'routine': {
        'name': data.name,
        'ownerUid': data.ownerUid,
        'isPublic': data.isPublic ?? false,
        'likesCount': likes,
        'exercises': data.exercises ?? const [],
        'exercisesCount': data.exercisesCount ?? 0,
      },
    };
  }
}

class RoutineLikeData {
  const RoutineLikeData({
    required this.name,
    required this.ownerUid,
    required this.isPublic,
    required this.likesCount,
    required this.exercises,
    required this.exercisesCount,
  });

  final String name;
  final String ownerUid;
  final bool? isPublic;
  final int? likesCount;
  final List<dynamic>? exercises;
  final int? exercisesCount;
}
