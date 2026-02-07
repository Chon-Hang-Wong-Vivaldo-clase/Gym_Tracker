import 'package:flutter/material.dart';

class PremiumInfoScreen extends StatelessWidget {
  const PremiumInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Premium",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const [
          Text(
            "Qué incluye la suscripción",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          SizedBox(height: 12),
          _BenefitItem(
            title: "Rutinas ilimitadas",
            description:
                "Crea tantas rutinas como quieras sin límites.",
          ),
          _BenefitItem(
            title: "Análisis avanzado",
            description:
                "Estadísticas detalladas por músculo, volumen y progreso.",
          ),
          _BenefitItem(
            title: "Planes inteligentes",
            description:
                "Sugerencias automáticas de series, cargas y descansos.",
          ),
          _BenefitItem(
            title: "Backup en la nube",
            description:
                "Sincroniza tu historial y recupéralo en cualquier dispositivo.",
          ),
          _BenefitItem(
            title: "Retos exclusivos",
            description:
                "Acceso a desafíos mensuales y logros especiales.",
          ),
          SizedBox(height: 16),
          Text(
            "Prueba gratis 7 días y cancela cuando quieras.",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, color: Colors.black87, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
