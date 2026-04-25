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
  final _otpController = TextEditingController();

  // Firebase OTP Tracking variables
  // String? _verificationId;

  void _verifyOTPAndRegister() async {
    Navigator.of(context).pop(); // Close the OTP Sheet
    
    // =========================================================
    // FIREBASE OTP VERIFICATION LOGIC (Uncomment when Firebase is setup)
    // =========================================================
    /*
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Phone is verified successfully! Proceed to register.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP Code.'), backgroundColor: Colors.red));
      return;
    }
    */
    
    // MOCK OTP CHECKER FOR TESTING FLOW
    if (_otpController.text != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. (Hint: Use 123456)'), backgroundColor: Colors.red));
      return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.register({
      'username': _usernameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'phone': _phoneController.text,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! You can now login.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Registration failed'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOTPDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verify Mobile Number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('We sent a 6-digit OTP code to ${_phoneController.text}.', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _otpController, 
                label: 'OTP Code', 
                hint: '123456', 
                keyboardType: TextInputType.number,
                prefixIcon: Icons.message,
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Verify & Register', onPressed: _verifyOTPAndRegister),
              const SizedBox(height: 32),
            ]
          ),
        );
      }
    );
  }

  void _handleRegister() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    
    // Quick validation before hitting API
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _emailController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username, Email, and Password are required.'), backgroundColor: Colors.red));
       return;
    }

    // =========================================================
    // FIREBASE OTP SEND LOGIC (Uncomment when Firebase is setup)
    // =========================================================
    /*
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text}',
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP Failed: ${e.message}'), backgroundColor: Colors.red));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _showOTPDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    return;
    */
    
    // Proceed to mock OTP screen
    _showOTPDialog();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
              CustomButton(text: 'Register', onPressed: _handleRegister, isLoading: isLoading),
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
