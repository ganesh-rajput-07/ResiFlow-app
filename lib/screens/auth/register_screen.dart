import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleRegister() async {
    // Scaffold UI block for visual representation placeholder
    // Real API integration would be called here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration functionality mocked. Please login.')),
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.app_registration,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join ResiFlow with your mobile and email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _firstNameController, label: 'First Name', hint: 'First Name')),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _lastNameController, label: 'Last Name', hint: 'Last Name')),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _emailController, label: 'Email', hint: 'Enter email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              CustomTextField(controller: _phoneController, label: 'Mobile Number', hint: '10-digit mobile number', prefixIcon: Icons.phone_android, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              CustomTextField(controller: _usernameController, label: 'Username', hint: 'Choose a username', prefixIcon: Icons.person_outline),
              const SizedBox(height: 16),
              CustomTextField(controller: _passwordController, label: 'Password', hint: 'Create a password', obscureText: true, prefixIcon: Icons.lock_outline),
              const SizedBox(height: 32),
              CustomButton(text: 'Register', onPressed: _handleRegister),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Login Here', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
