import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Términos y Condiciones",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _SectionTitle("1. Aceptación"),
          const SizedBox(height: 8),
          Text(
            "Al utilizar la aplicación GymTracker aceptas estos términos y condiciones. "
            "Si no estás de acuerdo con alguna parte, no debes usar la aplicación.",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SectionTitle("2. Uso del servicio"),
          const SizedBox(height: 8),
          Text(
            "GymTracker es una aplicación para el seguimiento de entrenamientos y rutinas. "
            "Debes usar el servicio de forma lícita y responsable. No está permitido usar la app "
            "para fines fraudulentos, ni compartir credenciales con terceros.",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SectionTitle("3. Datos y privacidad"),
          const SizedBox(height: 8),
          Text(
            "Recopilamos y procesamos los datos necesarios para ofrecer el servicio: perfil, "
            "rutinas, historial de entrenos y datos de uso. Tus datos se almacenan de forma segura "
            "y no se venden a terceros. Puedes solicitar la eliminación de tu cuenta y datos desde "
            "la opción \"Eliminar Perfil\" en Ajustes.",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SectionTitle("4. Suscripciones y pagos"),
          const SizedBox(height: 8),
          Text(
            "Las funciones Premium, si están disponibles, pueden requerir suscripción de pago. "
            "Los precios y condiciones se mostrarán antes de confirmar. Las suscripciones se gestionan "
            "según las políticas de la tienda de aplicaciones (App Store / Google Play).",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SectionTitle("5. Responsabilidad"),
          const SizedBox(height: 8),
          Text(
            "El contenido de la aplicación es informativo. El entrenamiento y la actividad física "
            "implican riesgos; consulta a un profesional de la salud antes de comenzar. GymTracker "
            "no se hace responsable de lesiones o daños derivados del uso de la información o "
            "rutinas sugeridas en la app.",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 20),
          _SectionTitle("6. Contacto"),
          const SizedBox(height: 8),
          Text(
            "Para consultas sobre estos términos o sobre la aplicación, puedes contactarnos "
            "a través de los canales indicados en la tienda de aplicaciones o en la web del producto.",
            style: TextStyle(color: onSurface, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
