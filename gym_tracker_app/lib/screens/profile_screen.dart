import 'package:flutter/material.dart';

import 'package:gym_tracker_app/screens/premium_info_screen.dart';
import 'package:gym_tracker_app/screens/goals_screen.dart';
import 'package:gym_tracker_app/screens/edit_profile_screen.dart';
import 'package:gym_tracker_app/screens/terms_conditions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.menu))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            const _ProfileAvatar(),
            const SizedBox(height: 10),
            const Text(
              "Nombre",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "Entrenado",
                    value: "18",
                    unit: "días",
                    icon: Icons.fitness_center,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Descanso",
                    value: "4",
                    unit: "días",
                    icon: Icons.nightlight_round,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ajustes",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              onPremium: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumInfoScreen()),
                );
              },
              onGoals: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
              },
              onEditProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              onTerms: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen(),
                  ),
                );
              },
              onDelete: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Eliminar perfil"),
                    content: const Text(
                      "¿Seguro que quieres eliminar tu perfil? Esta acción no se puede deshacer.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Eliminar"),
                      ),
                    ],
                  ),
                );
                if (shouldDelete == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Perfil eliminado.")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 44, color: Colors.black54),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.onPremium,
    required this.onGoals,
    required this.onEditProfile,
    required this.onTerms,
    required this.onDelete,
  });

  final VoidCallback onPremium;
  final VoidCallback onGoals;
  final VoidCallback onEditProfile;
  final VoidCallback onTerms;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: [
          _SettingsItem(
            icon: Icons.star_border,
            label: "Premium",
            filled: true,
            onTap: onPremium,
          ),
          _SettingsItem(
            icon: Icons.emoji_events_outlined,
            label: "Objetivos",
            onTap: onGoals,
          ),
          _SettingsItem(
            icon: Icons.edit_outlined,
            label: "Editar Perfil",
            onTap: onEditProfile,
          ),
          _SettingsItem(
            icon: Icons.list_alt,
            label: "Términos y Condiciones",
            onTap: onTerms,
          ),
          _SettingsItem(
            icon: Icons.delete_outline,
            label: "Eliminar Perfil",
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: filled ? const Color(0xFF2B2E34) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: filled ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
