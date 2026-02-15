import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';

const Color cyberGreen = Color.fromARGB(255, 51, 243, 17);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // 🔐 LOGO / ICON
              const Icon(
                Icons.security,
                size: 90,
                color: cyberGreen,
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                  ),

              const SizedBox(height: 24),

              // 🟢 APP NAME
              Text(
                "CYBERSHIELD",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      color: cyberGreen,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              // 🔒 TAGLINE
              Text(
                "Your personal security vault",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CyberTheme.textGrey,
                    ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 600.ms),

              const Spacer(),

              // 🔑 LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyberGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

              const SizedBox(height: 16),

              // 📝 REGISTER BUTTON (OUTLINED)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: cyberGreen,
                      width: 1.5,
                    ),
                    foregroundColor: cyberGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1100.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

              const Spacer(),

              // 🧠 FOOTER TEXT
              Text(
                "Secured with multi-layer encryption",
                style: TextStyle(
                  color: CyberTheme.textGrey.withOpacity(0.5),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1300.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
