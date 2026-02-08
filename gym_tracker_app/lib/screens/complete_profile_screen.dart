import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  @override
  void initState() {
    super.initState();
    final form = context.read<AuthFormProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(RegExp(r'\s+'));
      if (form.nameCtrl.text.trim().isEmpty) {
        form.nameCtrl.text = parts.first;
      }
      if (form.surnameCtrl.text.trim().isEmpty && parts.length > 1) {
        form.surnameCtrl.text = parts.sublist(1).join(' ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<AuthFormProvider>();

    Future<void> finish() async {
      final ok = await form.saveProfileForCurrentUser();
      if (!context.mounted) return;

      if (ok) {
        Navigator.pushNamedAndRemoveUntil(context, 'shell', (_) => false);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(form.error ?? "Error")));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Completar perfil")),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            TextField(
              controller: form.usernameCtrl,
              decoration: const InputDecoration(hintText: "@usuario"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.nameCtrl,
              decoration: const InputDecoration(hintText: "Nombre"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.surnameCtrl,
              decoration: const InputDecoration(hintText: "Apellidos"),
              onChanged: (_) => form.clearError(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: form.bioCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: "Biografía (opcional)",
              ),
              onChanged: (_) => form.clearError(),
            ),

            if (form.error != null)
              Text(form.error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: form.loading ? null : finish,
                child: form.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Guardar y continuar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
