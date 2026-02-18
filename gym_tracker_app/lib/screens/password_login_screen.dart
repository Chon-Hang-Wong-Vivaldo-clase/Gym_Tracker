/// autenticar al usuario mediante correo y contrasena.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/register_email_screen.dart';

class PasswordLoginScreen extends StatelessWidget {
  const PasswordLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final form = context.watch<AuthFormProvider>();
    final auth = context.read<AppAuthProvider>();

    Future<void> onSubmit() async {
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

    return Scaffold(
      appBar: AppBar(title: const Text("Inicia sesión")),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(
              controller: form.emailCtrl,
              readOnly: true,
              decoration: const InputDecoration(hintText: "Correo"),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.passCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Contraseña"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            if (form.error != null)
              Text(form.error!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: form.loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? colorScheme.primary : const Color(0xFF2B2E34),
                  foregroundColor: colorScheme.onPrimary,
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
          ],
        ),
      ),
    );
  }
}
