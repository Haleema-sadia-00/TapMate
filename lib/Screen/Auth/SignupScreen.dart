import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/Auth/permissionscreen.dart';
import 'package:tapmate/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _recoveryEmailController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _recoveryEmailError;

  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  void _validateInputs() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? "Full Name is required" : null;

      if (_emailController.text.trim().isEmpty) {
        _emailError = "Email is required";
      } else if (!_isValidEmail(_emailController.text.trim())) {
        _emailError = "Enter a valid email";
      } else {
        _emailError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = "Password is required";
      } else if (_passwordController.text.length < 6) {
        _passwordError = "Password must be at least 6 characters";
      } else {
        _passwordError = null;
      }

      if (_recoveryEmailController.text.trim().isNotEmpty &&
          !_isValidEmail(_recoveryEmailController.text.trim())) {
        _recoveryEmailError = "Invalid recovery email";
      } else {
        _recoveryEmailError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFA64D79), Color(0xFF6A1E55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.download, color: Colors.white, size: 40),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1E55),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Sign up to get started",
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              _inputField(
                controller: _nameController,
                icon: Icons.person_outline,
                hint: "Full Name",
                error: _nameError,
                onChange: _validateInputs,
              ),

              const SizedBox(height: 15),

              _inputField(
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: "Email Address",
                error: _emailError,
                onChange: _validateInputs,
              ),

              const SizedBox(height: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (_) => _validateInputs(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                      hintText: "Password",
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),
                  if (_passwordError != null)
                    Text(_passwordError!, style: const TextStyle(color: Colors.red)),
                ],
              ),

              const SizedBox(height: 15),

              _inputField(
                controller: _recoveryEmailController,
                icon: Icons.email,
                hint: "Recovery Email (Optional)",
                error: _recoveryEmailError,
                onChange: _validateInputs,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton(
                  onPressed: () {
                    _validateInputs();
                    if (_nameError == null && _emailError == null && _passwordError == null) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      String userId = AuthProvider.generateUserIdFromEmail(_emailController.text);
                      authProvider.setUserInfo(userId: userId, email: _emailController.text);
                      authProvider.markAsNewSignUp();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PermissionScreen()),
                      );
                    }
                  },
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A1E55), Color(0xFFA64D79)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text("Create Account",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Sign In",
                      style: TextStyle(color: Color(0xFFA64D79), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ SOCIAL BUTTONS WITH SNACKBAR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Google button tapped"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: _socialButtonImage("Google", 'assets/icons/google_logo.png'),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Facebook button tapped"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: _socialButtonImage("Facebook", 'assets/icons/facebook_logo.png'),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? error,
    required Function onChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => onChange(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (error != null)
          Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _socialButtonImage(String title, String assetPath) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
          color: const Color(0xFFF0F0F0),
        ),
        child: Row(
            children: [
              Image.asset(assetPath, width: 24, height: 24),
              const SizedBox(width: 5),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
            ),
        );
    }
}
