import 'package:flutter/material.dart';

import 'package:gym_tracker_app/screens/social_user_profile_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = <_Friend>[
      const _Friend(
        username: "@USER",
        isOnline: true,
        trainedDays: 18,
        restDays: 4,
      ),
      const _Friend(
        username: "@USER",
        isOnline: false,
        trainedDays: 12,
        restDays: 6,
      ),
      const _Friend(
        username: "@USER",
        isOnline: true,
        trainedDays: 22,
        restDays: 3,
      ),
      const _Friend(
        username: "@USER",
        isOnline: false,
        trainedDays: 9,
        restDays: 10,
      ),
      const _Friend(
        username: "@USER",
        isOnline: true,
        trainedDays: 15,
        restDays: 5,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _openSearch(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Container(
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
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      onPressed: () => _openSearch(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _FriendTile(
                      friend: friend,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SocialUserProfileScreen(
                              username: friend.username,
                              trainedDays: friend.trainedDays,
                              restDays: friend.restDays,
                              routines: const [
                                SocialRoutine(
                                  title: "Rutina 1",
                                  subtitle: "Hombro - Pecho",
                                  description:
                                      "Rutina tranquila para ejercitar el hombro y el pecho.",
                                ),
                                SocialRoutine(
                                  title: "Rutina 2",
                                  subtitle: "Piernas - Espalda",
                                  description:
                                      "La mejor rutina para piernas y espalda.",
                                ),
                              ],
                            ),
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

  void _openSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buscar usuario"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "@usuario",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final username = controller.text.trim();
              if (username.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SocialUserProfileScreen(
                    username: username.startsWith("@") ? username : "@$username",
                    trainedDays: 18,
                    restDays: 4,
                    routines: const [
                      SocialRoutine(
                        title: "Rutina 1",
                        subtitle: "Full Body",
                        description: "Rutina visible del usuario.",
                      ),
                    ],
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
    required this.username,
    required this.isOnline,
    required this.trainedDays,
    required this.restDays,
  });

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
