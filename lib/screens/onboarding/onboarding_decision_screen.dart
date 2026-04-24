import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../setup/create_society_screen.dart';
import '../setup/join_society_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/custom_button.dart';

class OnboardingDecisionScreen extends StatelessWidget {
  const OnboardingDecisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.apartment,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to ResiFlow',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you here to join an existing residential society, or setup a new one?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Join Society',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const JoinSocietyScreen(),
                  ));
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CreateSocietyScreen(),
                  ));
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Society',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    child: const Text('Login here', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ));
                    },
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
