import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/register_email_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final form = context.watch<AuthFormProvider>();
    final auth = context.read<AppAuthProvider>();

    Future<void> onLogin() async {
      final route = await form.loginEmail(auth);
      if (!context.mounted) return;

      if (route == "register") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterEmailScreen()),
        );
        return;
      }
      if (route == "home") {
        Navigator.pushReplacementNamed(context, 'shell');
        return;
      }
      if (route == "completeProfile") {
        Navigator.pushReplacementNamed(context, 'complete_profile');
        return;
      }
    }

    Future<void> onGoogle() async {
      final res = await form.loginGoogle(auth);
      if (!context.mounted) return;

      if (res.cancelled) return;

      if (res.route == "home") {
        Navigator.pushReplacementNamed(context, 'shell');
      } else if (res.route == "completeProfile") {
        Navigator.pushReplacementNamed(context, 'complete_profile');
      }
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 70),
              Text(
                "Gym Tracker",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Entrena hoy, supérate mañana",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 70),
              Text(
                "Iniciar Sesión",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: form.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Gmail",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                ),
                onChanged: (_) => form.clearError(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: form.passCtrl,
                obscureText: true,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colorScheme.outline),
                  ),
                ),
                onChanged: (_) => form.clearError(),
              ),
              const SizedBox(height: 18),

              if (form.error != null) ...[
                Text(
                  form.error!,
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: form.loading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? colorScheme.primary : const Color(0xFF2B2E34),
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: form.loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text("Continuar"),
                ),
              ),

              const SizedBox(height: 18),
              Text(
                "Or",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: form.loading ? null : onGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),

                  child: Row(
                    children: [
                      Image.asset('assets/Google.webp', width: 30),
                      SizedBox(width: 60),
                      const Text(
                        "Continuar con Google",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: form.loading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterEmailScreen(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Crear una cuenta nueva"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
