/// representar una tarjeta reutilizable de estadisticas.
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.background,
    required this.textColor,
  });

  final String title;
  final int value;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            textAlign: TextAlign.center,
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            textAlign: TextAlign.center,
            "$value",
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
