import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/providers/auth_form_provider.dart';
import 'package:gym_tracker_app/providers/app_auth_provider.dart';
import 'package:gym_tracker_app/screens/register_email_screen.dart';
import 'package:gym_tracker_app/screens/password_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF2B2E34);
    const greyBtn = Color(0xFF8A8F98);

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

      if (res.email != null && res.route == "password") {
        form.setEmail(res.email!);
        form.passCtrl.clear();
        form.pass2Ctrl.clear();
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PasswordLoginScreen()),
        );
        return;
      }

      if (res.email != null) {
        form.setEmail(res.email!);
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterEmailScreen()),
        );
        return;
      }

      if (res.route == "home") {
        Navigator.pushReplacementNamed(context, 'shell');
      } else if (res.route == "completeProfile") {
        Navigator.pushReplacementNamed(context, 'complete_profile');
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 70),
              const Text(
                "Gym Tracker",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Entrena hoy, supérate mañana",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 70),
              const Text(
                "Iniciar Sesión",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: form.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Gmail",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => form.clearError(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: form.passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => form.clearError(),
              ),
              const SizedBox(height: 18),

              if (form.error != null) ...[
                Text(form.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: form.loading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: form.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Continuar"),
                ),
              ),

              const SizedBox(height: 18),
              const Text("Or", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: form.loading ? null : onGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greyBtn,
                    foregroundColor: Colors.white,
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
                        "Continue with Google",
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
                    backgroundColor: greyBtn,
                    foregroundColor: Colors.white,
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
