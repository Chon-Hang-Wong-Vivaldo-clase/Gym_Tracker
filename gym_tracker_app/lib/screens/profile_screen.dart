import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:gym_tracker_app/screens/premium_info_screen.dart';
import 'package:gym_tracker_app/screens/goals_screen.dart';
import 'package:gym_tracker_app/screens/edit_profile_screen.dart';
import 'package:gym_tracker_app/screens/terms_conditions_screen.dart';
import 'package:gym_tracker_app/widgets/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statsRef = user == null
        ? null
        : FirebaseDatabase.instance.ref('users/${user.uid}/stats');
    final profileRef = user == null
        ? null
        : FirebaseDatabase.instance.ref('users/${user.uid}/profile');

    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
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
          "Perfil",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            _ProfileHeader(profileRef: profileRef),
            const SizedBox(height: 10),
            _ProfileName(profileRef: profileRef),
            const SizedBox(height: 18),
            _StatsRow(
              statsRef: statsRef,
              accountCreatedAt: user?.metadata.creationTime,
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ajustes",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceContainer = theme.colorScheme.surfaceContainerHighest;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: photoUrl == null
          ? Icon(Icons.person, size: 44, color: onSurfaceVariant)
          : ClipOval(
              child: Image.network(
                photoUrl!,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profileRef});

  final DatabaseReference? profileRef;

  @override
  Widget build(BuildContext context) {
    if (profileRef == null) {
      return const _ProfileAvatar(photoUrl: null);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: profileRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final photoUrl = data['photoUrl']?.toString();
        return _ProfileAvatar(photoUrl: photoUrl);
      },
    );
  }
}

class _ProfileName extends StatelessWidget {
  const _ProfileName({required this.profileRef});

  final DatabaseReference? profileRef;

  @override
  Widget build(BuildContext context) {
    if (profileRef == null) {
      return Text(
        "Usuario",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: profileRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? raw : <dynamic, dynamic>{};
        final name = (data['name'] ?? '').toString();
        final surname = (data['surname'] ?? '').toString();
        final displayName = [
          name,
          surname,
        ].where((value) => value.trim().isNotEmpty).join(' ').trim();

        return Text(
          displayName.isEmpty ? "Usuario" : displayName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.statsRef,
    required this.accountCreatedAt,
  });

  final DatabaseReference? statsRef;
  final DateTime? accountCreatedAt;

  @override
  Widget build(BuildContext context) {
    if (statsRef == null) {
      return Row(
        children: const [
          Expanded(
            child: _StatCard(
              title: "Entrenado",
              value: "0",
              unit: "días",
              icon: Icons.fitness_center,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: "Descanso",
              value: "0",
              unit: "días",
              icon: Icons.nightlight_round,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: statsRef!.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final trainedRaw = data['trainedDays'];
        final trainedMap = trainedRaw is Map
            ? Map<String, dynamic>.from(trainedRaw)
            : <String, dynamic>{};
        final trained = trainedMap.length;
        final rest = _computeRestTotalSinceAccountCreation(
          accountCreatedAt: accountCreatedAt,
          trainedTotal: trained,
          fallback: (data['restDaysCount'] is num)
              ? (data['restDaysCount'] as num).toInt()
              : 0,
        );

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: "Entrenado",
                value: trained.toString(),
                unit: "días",
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: "Descanso",
                value: rest.toString(),
                unit: "días",
                icon: Icons.nightlight_round,
              ),
            ),
          ],
        );
      },
    );
  }
}

int _computeRestTotalSinceAccountCreation({
  required DateTime? accountCreatedAt,
  required int trainedTotal,
  required int fallback,
}) {
  if (accountCreatedAt == null) return fallback;
  final now = DateTime.now();
  final created = DateTime(
    accountCreatedAt.year,
    accountCreatedAt.month,
    accountCreatedAt.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  final elapsedDays = today.difference(created).inDays + 1;
  if (elapsedDays <= 0) return fallback;
  final rest = elapsedDays - trainedTotal;
  return rest >= 0 ? rest : 0;
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
    final outline = theme.colorScheme.outline.withOpacity(0.3);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final shadowColor = theme.colorScheme.shadow.withOpacity(0.06);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final containerColor = colorScheme.surfaceContainerHighest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(
                color: colorScheme.outline.withOpacity(0.5),
                width: 1.2,
              )
            : null,
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: [
          _SettingsItem(
            icon: Icons.star,
            label: "Premium",
            filled: true,
            isPremium: true,
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

/// Color dorado para la sección Premium.
const Color _premiumGold = Color(0xFFD4AF37);
const Color _premiumGoldDark = Color(0xFFB8860B);

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.isPremium = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outline.withOpacity(0.65);
    final circleColor = isPremium
        ? (isDark ? _premiumGoldDark : _premiumGold)
        : (filled ? theme.colorScheme.primaryContainer : theme.colorScheme.surface);
    final iconColor = isPremium
        ? Colors.black87
        : (filled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface);
    final labelColor = isPremium && filled
        ? (isDark ? _premiumGold : _premiumGoldDark)
        : theme.colorScheme.onSurface;
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
                color: circleColor,
                shape: BoxShape.circle,
                border: isDark
                    ? Border.all(
                        color: isPremium ? _premiumGold : outline,
                        width: 1.1,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
