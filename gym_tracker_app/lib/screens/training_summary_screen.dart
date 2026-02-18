/// resumir resultados al finalizar una sesion de entrenamiento.
import 'package:flutter/material.dart';

class TrainingSummaryScreen extends StatelessWidget {
  const TrainingSummaryScreen({
    super.key,
    required this.durationSec,
    required this.routineName,
  });

  final int durationSec;
  final String routineName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = Duration(seconds: durationSec);
    final min = duration.inMinutes;
    final sec = duration.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(title: const Text("Sesión completada")),
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routineName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tiempo total",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "${min}m ${sec}s",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Volver al inicio"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
