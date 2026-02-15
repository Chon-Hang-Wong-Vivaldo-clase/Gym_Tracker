import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SocialUserProfileScreen extends StatefulWidget {
  const SocialUserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.trainedDays,
    required this.restDays,
    required this.routines,
  });

  final String userId;
  final String username;
  final String? photoUrl;
  final int trainedDays;
  final int restDays;
  final List<SocialRoutine> routines;

  @override
  State<SocialUserProfileScreen> createState() => _SocialUserProfileScreenState();
}

class _SocialUserProfileScreenState extends State<SocialUserProfileScreen> {
  bool _loading = false;

  Future<void> _setFollow(bool follow) async {
    if (_loading) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    setState(() => _loading = true);
    try {
      final root = FirebaseDatabase.instance.ref();
      final updates = <String, Object?>{
        'users/${current.uid}/following/${widget.userId}': follow ? true : null,
        'users/${widget.userId}/followers/${current.uid}': follow ? true : null,
      };
      await root.update(updates);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final followingRef = currentUid == null
        ? null
        : FirebaseDatabase.instance.ref('users/$currentUid/following/${widget.userId}');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _ProfileAvatar(photoUrl: widget.photoUrl),
          const SizedBox(height: 10),
          Center(
            child: Text(
              widget.username,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (followingRef == null)
            const SizedBox.shrink()
          else
            StreamBuilder<DatabaseEvent>(
              stream: followingRef.onValue,
              builder: (context, snapshot) {
                final isFollowing = snapshot.data?.snapshot.value == true;
                return Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (isFollowing) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "SIGUIENDO",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading ? null : () => _setFollow(false),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("Dejar de seguir"),
                        ),
                      ] else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _loading ? null : () => _setFollow(true),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text("SEGUIR"),
                        ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Entrenado",
                  value: "${widget.trainedDays}",
                  unit: "días",
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: "Descanso",
                  value: "${widget.restDays}",
                  unit: "días",
                  icon: Icons.nightlight_round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "Rutinas",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: widget.routines
                  .map((routine) => _RoutineCard(routine: routine))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: photoUrl == null
            ? Icon(Icons.person, size: 44, color: theme.colorScheme.onSurfaceVariant)
            : ClipOval(
                child: Image.network(
                  photoUrl!,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final outline = theme.colorScheme.outline.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: onSurface),
              ),
              Icon(icon, size: 18, color: onSurface),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(color: onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SocialRoutine {
  const SocialRoutine({
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String title;
  final String subtitle;
  final String description;
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});

  final SocialRoutine routine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routine.title,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            routine.subtitle,
            style: TextStyle(color: onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            routine.description,
            style: TextStyle(color: onSurface, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
