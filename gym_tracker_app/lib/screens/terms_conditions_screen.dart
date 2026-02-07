import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Términos y Condiciones",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const [
          Text(
            "Resumen",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            "Esta es una vista previa de los términos y condiciones. "
            "Aquí puedes incluir información sobre privacidad, uso de datos, "
            "suscripciones y responsabilidades del usuario.",
            style: TextStyle(color: Colors.black87),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
