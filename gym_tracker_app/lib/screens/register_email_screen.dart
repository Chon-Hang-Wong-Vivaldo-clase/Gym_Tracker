import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';
import 'package:gym_tracker_app/screens/register_profile_screen.dart';

class RegisterEmailScreen extends StatelessWidget {
  const RegisterEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final form = context.watch<AuthFormProvider>();

    void next() {
      if (form.validateRegisterEmail()) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterProfileScreen()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Información Personal")),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(
              controller: form.emailCtrl,
              decoration: const InputDecoration(hintText: "Correo electrónico"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.passCtrl,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Contraseña"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.pass2Ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Confirmar contraseña",
              ),
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
                onPressed: form.loading ? null : next,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

