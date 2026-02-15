import 'dart:math';
import 'package:flutter/material.dart';

class StreakWaterRing extends StatefulWidget {
  const StreakWaterRing({
    super.key,
    required this.streakDays,
    required this.goalDays,
    this.size = 240,
  });

  final int streakDays;
  final int goalDays;
  final double size;
  final int maxVisualDays = 70;

  @override
  State<StreakWaterRing> createState() => _StreakWaterRingState();
}

class _StreakWaterRingState extends State<StreakWaterRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _streakColor(int days) {
    if (days <= 7) return const  Color(0xFF4CC9F0);
    if (days <= 14) return const Color(0xFF45B6E9);
    if (days <= 21) return const Color(0xFF3EA3E2);
    if (days <= 28) return const Color(0xFF4895EF);
    if (days <= 35) return const Color(0xFF447EEB);
    if (days <= 42) return const Color(0xFF4361EE);
    if (days <= 49) return const Color(0xFF4150DA);
    if (days <= 56) return const Color(0xFF3F37C9);
    if (days <= 63) return const Color(0xFF3C26B6);
    if (days <= 70) return const Color(0xFF3A0CA3);
    if (days <= 77) return const Color(0xFF420CA6);
    if (days <= 84) return const  Color(0xFF480CA8);
    if (days <= 91) return const  Color(0xFF4F0DAB);
    if (days <= 98) return const Color(0xFF560BAD);
    if (days <= 105) return const Color(0xFF640AB1);
    if (days <= 112) return const Color(0xFF7209B7);
    if (days <= 119) return const Color(0xFF8A0FBF);
    if (days <= 126) return const Color(0xFFB5179E);
    if (days <= 133) return const Color(0xFFD01E8E);
    return Color(0xFFF72585);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.streakDays / widget.maxVisualDays).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final centerColor = isDark ? const Color(0xFF616161) : const Color(0xFF9E9E9E);
    final waterColor = _streakColor(widget.streakDays);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Contenedor circular exterior (borde) — visible en claro y oscuro
          Builder(
            builder: (context) {
              final borderColor = Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black26;
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
              );
            },
          ),

          // Agua dentro del círculo exterior
          ClipOval(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _WaterPainter(
                    progress: progress,
                    phase: _ctrl.value * 2 * pi,
                    color: waterColor,
                  ),
                );
              },
            ),
          ),

          // Círculo central (encima del agua)
          Container(
            width: widget.size * 0.72,
            height: widget.size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: centerColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Llevas una racha de",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${widget.streakDays} días",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Entrenando\nconsecutivamente",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.progress,
    required this.phase,
    required this.color,
  });

  final double progress; 
  final double phase; 
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final waterY = h * (1.05 - progress);

    final paint1 = Paint()
      ..color = color.withOpacity(0.70)
      ..style = PaintingStyle.fill;

    final path1 = Path()..moveTo(0, waterY);
    for (double x = 0; x <= w; x++) {
      final y = waterY +
          sin((x / w * 2 * pi) + phase) * 10;
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = color.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final path2 = Path()..moveTo(0, waterY);
    for (double x = 0; x <= w; x++) {
      final y = waterY +
          sin((x / w * 2 * pi) + phase + pi / 2) * 6; 
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.color != color;
  }
}