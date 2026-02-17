import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

/// Color dorado para la sección Premium.
const Color _gold = Color(0xFFD4AF37);
const Color _goldDark = Color(0xFFB8860B);
const Color _goldLight = Color(0xFFFFE082);

class PremiumInfoScreen extends StatelessWidget {
  const PremiumInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profileRef = user == null
        ? null
        : FirebaseDatabase.instance.ref('users/${user.uid}/profile');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1910) : const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: isDark ? _goldDark : _gold,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          "Premium",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: profileRef == null
          ? const Center(child: Text("Inicia sesión para ver Premium"))
          : StreamBuilder<DatabaseEvent>(
              stream: profileRef.onValue,
              builder: (context, snapshot) {
                final raw = snapshot.data?.snapshot.value;
                final data = raw is Map ? raw : <dynamic, dynamic>{};
                final isSubscribed = _isPremiumActive(data['isPremium']);

                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  children: [
                    if (isSubscribed) _SubscriptionActiveBanner(compact: true),
                    if (isSubscribed) const SizedBox(height: 6),
                    Text(
                      "Qué incluye la suscripción",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? _goldLight : _goldDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _BenefitItem(title: "Rutinas ilimitadas", description: "Sin límites.", isDark: isDark, compact: true),
                    _BenefitItem(title: "Análisis avanzado", description: "Por músculo y progreso.", isDark: isDark, compact: true),
                    _BenefitItem(title: "Planes inteligentes", description: "Series, cargas y descansos.", isDark: isDark, compact: true),
                    _BenefitItem(title: "Backup en la nube", description: "Sincroniza en todos los dispositivos.", isDark: isDark, compact: true),
                    _BenefitItem(title: "Retos exclusivos", description: "Desafíos mensuales.", isDark: isDark, compact: true),
                    const SizedBox(height: 6),
                    Text(
                      "Prueba gratis 7 días. Cancela cuando quieras.",
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    if (isSubscribed)
                      _ManageSubscriptionButton(profileRef: profileRef)
                    else
                      _PayButton(profileRef: profileRef),
                  ],
                );
              },
            ),
    );
  }
}

bool _isPremiumActive(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final value = raw.trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }
  return false;
}

class _SubscriptionActiveBanner extends StatelessWidget {
  const _SubscriptionActiveBanner({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12, horizontal: 12),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _gold, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: _goldDark, size: compact ? 22 : 28),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Text(
              "Suscripción activa",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({required this.profileRef});

  final DatabaseReference profileRef;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _handlePay(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        child: const Text("Suscribirse ahora"),
      ),
    );
  }

  Future<void> _handlePay(BuildContext context) async {
    try {
      await profileRef.child('isPremium').set(true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Suscripción Premium activada!"),
          backgroundColor: _goldDark,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

class _ManageSubscriptionButton extends StatelessWidget {
  const _ManageSubscriptionButton({required this.profileRef});

  final DatabaseReference profileRef;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          await profileRef.child('isPremium').set(false);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Suscripción cancelada (demo)")),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _goldDark,
          side: const BorderSide(color: _gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        child: const Text("Cancelar suscripción (demo)"),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.title,
    required this.description,
    required this.isDark,
    this.compact = false,
  });

  final String title;
  final String description;
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF2A2520) : const Color(0xFFFFF8E7);
    final titleColor = isDark ? _goldLight : Colors.black87;
    final descColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return Container(
      margin: EdgeInsets.only(bottom: compact ? 4 : 10),
      padding: EdgeInsets.all(compact ? 8 : 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: _gold.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star, color: _gold, size: compact ? 16 : 22),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                    color: titleColor,
                  ),
                ),
                if (!compact) const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: descColor, fontSize: compact ? 11 : 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
