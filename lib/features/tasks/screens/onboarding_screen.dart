import 'package:flodo_task_app/features/tasks/screens/task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset:  false,
        backgroundColor: const Color(0xFF1A1D2E),
        body: SafeArea(
          child:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),

                Center(
                  child: Lottie.asset(
                    'assets/character.json',
                    width: size.width * 0.85,
                    height: size.height * 0.45,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(flex: 1),

                // ── Title ─────────────────────────────────────────────
                Text(
                  'Smart Task\nManagement',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Subtitle ──────────────────────────────────────────
                Text(
                  'This smart tool is designed to help you\nbetter manage your tasks',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.6,
                  ),
                ),

                const Spacer(flex: 2),

                // ── Continue Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const  TaskListScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5BE3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'CONTINUE',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}