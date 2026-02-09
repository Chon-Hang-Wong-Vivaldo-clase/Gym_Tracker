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
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    final ref = FirebaseDatabase.instance
        .ref('users/${current.uid}/following/${widget.userId}');
    final snap = await ref.get();
    if (!mounted) return;
    setState(() {
      _isFollowing = snap.value == true;
    });
  }

  Future<void> _toggleFollow() async {
    if (_loading) return;
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      return;
    }
    setState(() => _loading = true);

    try {
      final root = FirebaseDatabase.instance.ref();
      final updates = <String, Object?>{
        'users/${current.uid}/following/${widget.userId}':
            _isFollowing ? null : true,
        'users/${widget.userId}/followers/${current.uid}':
            _isFollowing ? null : true,
      };
      await root.update(updates);
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B2E34),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _loading ? null : _toggleFollow,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isFollowing ? "SIGUIENDO" : "SEGUIR"),
            ),
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
          const Text(
            "Rutinas",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
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
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
        child: photoUrl == null
            ? const Icon(Icons.person, size: 44, color: Colors.black54)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(icon, size: 18, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.black54),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routine.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            routine.subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            routine.description,
            style: const TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
