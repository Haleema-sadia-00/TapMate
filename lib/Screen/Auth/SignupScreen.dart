// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/auth_provider.dart';
import 'dart:async';
import '../home/home_screen.dart';
import 'email_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _dobFocusNode = FocusNode();

  // Error messages
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _usernameError;
  String? _phoneError;
  String? _dobError;
  String? _genderError;
  String? _signupError;

  // Success messages (suggestions)
  String? _nameSuccess;
  String? _emailSuccess;
  String? _usernameSuccess;
  String? _passwordSuccess;
  String? _confirmPasswordSuccess;
  String? _phoneSuccess;

  // Variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isCheckingUsername = false;

  // Username checking debouncer
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Name validation on change
    _nameController.addListener(() {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        if (name.length < 2) {
          _nameError = "Name must be at least 2 characters";
          _nameSuccess = null;
        } else if (name.length > 50) {
          _nameError = "Name must be less than 50 characters";
          _nameSuccess = null;
        } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
          _nameError = "Only letters and spaces allowed";
          _nameSuccess = null;
        } else {
          _nameError = null;
          _nameSuccess = "✓ Valid name";
        }
        setState(() {});
      } else {
        _nameError = null;
        _nameSuccess = null;
        setState(() {});
      }
    });

    // Email validation on change
    _emailController.addListener(() {
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        if (!_isValidEmail(email)) {
          _emailError = "Enter a valid email address";
          _emailSuccess = null;
        } else {
          _emailError = null;
          _emailSuccess = "✓ Valid email";
        }
        setState(() {});
      } else {
        _emailError = null;
        _emailSuccess = null;
        setState(() {});
      }
    });

    // Password validation on change
    _passwordController.addListener(() {
      final password = _passwordController.text;
      if (password.isNotEmpty) {
        if (password.length < 8) {
          _passwordError = "Password must be at least 8 characters";
          _passwordSuccess = null;
        } else if (!RegExp(r'(?=.*[a-z])').hasMatch(password)) {
          _passwordError = "Must contain a lowercase letter";
          _passwordSuccess = null;
        } else if (!RegExp(r'(?=.*[A-Z])').hasMatch(password)) {
          _passwordError = "Must contain an uppercase letter";
          _passwordSuccess = null;
        } else if (!RegExp(r'(?=.*\d)').hasMatch(password)) {
          _passwordError = "Must contain a number";
          _passwordSuccess = null;
        } else if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(password)) {
          _passwordError = "Must contain a special character (@, !, #, etc.)";
          _passwordSuccess = null;
        } else {
          _passwordError = null;
          _passwordSuccess = "✓ Strong password";
        }
        setState(() {});
      } else {
        _passwordError = null;
        _passwordSuccess = null;
        setState(() {});
      }
    });

    // Confirm password validation on change
    _confirmPasswordController.addListener(() {
      final password = _passwordController.text;
      final confirm = _confirmPasswordController.text;
      if (confirm.isNotEmpty) {
        if (password != confirm) {
          _confirmPasswordError = "Passwords do not match";
          _confirmPasswordSuccess = null;
        } else {
          _confirmPasswordError = null;
          _confirmPasswordSuccess = "✓ Passwords match";
        }
        setState(() {});
      } else {
        _confirmPasswordError = null;
        _confirmPasswordSuccess = null;
        setState(() {});
      }
    });

    // Phone validation on change
    _phoneController.addListener(() {
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty) {
        final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length < 10) {
          _phoneError = "Phone number must be at least 10 digits";
          _phoneSuccess = null;
        } else if (digitsOnly.length > 15) {
          _phoneError = "Phone number must be less than 15 digits";
          _phoneSuccess = null;
        } else {
          _phoneError = null;
          _phoneSuccess = "✓ Valid phone number";
        }
        setState(() {});
      } else {
        _phoneError = null;
        _phoneSuccess = null;
        setState(() {});
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  Future<bool> _checkUsernameExists(String username) async {
    if (username.isEmpty) return false;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return await authProvider.checkUsernameExists(username);
    } catch (e) {
      return false;
    }
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isEmpty) {
        setState(() {
          _usernameError = null;
          _usernameSuccess = null;
          _isCheckingUsername = false;
        });
        return;
      }

      setState(() => _isCheckingUsername = true);

      // Format validation
      if (!_isValidUsername(value)) {
        setState(() {
          _usernameError = "3-20 characters, letters, numbers, underscore only";
          _usernameSuccess = null;
          _isCheckingUsername = false;
        });
        return;
      }

      // Check availability
      final exists = await _checkUsernameExists(value);
      setState(() {
        if (exists) {
          _usernameError = "Username already taken";
          _usernameSuccess = null;
        } else {
          _usernameError = null;
          _usernameSuccess = "✓ Username available";
        }
        _isCheckingUsername = false;
      });
    });
  }

  String _capitalizeName(String name) {
    return name
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _dobError = null;
      });
    }
  }

  void _showPasswordRequirements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Password Requirements"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("• At least 8 characters"),
            Text("• At least one uppercase letter"),
            Text("• At least one lowercase letter"),
            Text("• At least one number"),
            Text("• At least one special character (@, !, #, \$, %, etc.)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _signUp() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _phoneError = null;
      _dobError = null;
      _genderError = null;
    });

    // Validate all fields
    bool hasError = false;

    // Name validation
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Full name is required");
      hasError = true;
    }

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = "Email is required");
      hasError = true;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = "Enter a valid email address");
      hasError = true;
    }

    // Username validation
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = "Username is required");
      hasError = true;
    } else if (!_isValidUsername(username)) {
      setState(
        () => _usernameError =
            "3-20 characters, letters, numbers, underscore only",
      );
      hasError = true;
    }

    // Password validation
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = "Password is required");
      hasError = true;
    } else if (password.length < 8) {
      setState(() => _passwordError = "Password must be at least 8 characters");
      hasError = true;
    }

    // Confirm password validation
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = "Please confirm your password");
      hasError = true;
    } else if (password != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      hasError = true;
    }

    // Phone validation
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = "Phone number is required");
      hasError = true;
    } else {
      final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length < 10 || digitsOnly.length > 15) {
        setState(
          () => _phoneError = "Enter a valid phone number (10-15 digits)",
        );
        hasError = true;
      }
    }

    // DOB validation
    if (_selectedDate == null) {
      setState(() => _dobError = "Date of birth is required");
      hasError = true;
    }

    // Gender validation
    if (_selectedGender == null) {
      setState(() => _genderError = "Please select your gender");
      hasError = true;
    }

    // Terms validation
    if (!_agreeToTerms) {
      _showErrorSnackBar("Please agree to Terms & Conditions");
      return;
    }

    if (hasError) {
      _showErrorSnackBar("Please fix the errors above");
      return;
    }

    // Check username availability
    if (_usernameError == null && username.isNotEmpty) {
      final exists = await _checkUsernameExists(username);
      if (exists) {
        setState(() => _usernameError = "Username already taken");
        _showErrorSnackBar("Username already taken");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _showInfoSnackBar("Creating account...");

      final result = await authProvider.signUpWithEmailPassword(
        name: _capitalizeName(_nameController.text.trim()),
        email: email.toLowerCase(),
        password: password,
        phone: phone.replaceAll(RegExp(r'[^0-9]'), ''),
        dob: _selectedDate,
        gender: _selectedGender ?? '',
        username: username.toLowerCase(),
        // 🔥 FIX: recoveryEmail optional hai, isliye null pass karo
        recoveryEmail: '',
      );

      if (result['success'] == true) {
        _showSuccessSnackBar('✅ Account created! Please verify your email.');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationScreen(email: email.toLowerCase()),
            ),
          );
        }
      } else {
        _showErrorSnackBar('❌ ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signInWithGoogle();
      if (result['success'] == true) {
        _showSuccessSnackBar('✅ Google sign up successful!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showErrorSnackBar('❌ ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Google sign up failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _dobFocusNode.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedGender != null &&
        _agreeToTerms &&
        _nameError == null &&
        _emailError == null &&
        _usernameError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _phoneError == null &&
        _dobError == null &&
        _genderError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // Error Message
              if (_signupError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _signupError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.download_for_offline_rounded,
                      color: AppColors.lightSurface,
                      size: 50,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Center(
                child: Text(
                  "Join our community today",
                  style: TextStyle(color: AppColors.textMain, fontSize: 16),
                ),
              ),

              const SizedBox(height: 30),

              // Form Fields
              _buildTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                hint: "Full Name",
                icon: Icons.person_outline,
                error: _nameError,
                success: _nameSuccess,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: "Email Address",
                icon: Icons.email_outlined,
                error: _emailError,
                success: _emailSuccess,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
              ),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                hint: "Username",
                icon: Icons.alternate_email,
                error: _usernameError,
                success: _usernameSuccess,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                onChanged: (value) => _onUsernameChanged(value),
                suffixWidget: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),

              const SizedBox(height: 15),

              _buildPasswordField(),

              const SizedBox(height: 15),

              _buildConfirmPasswordField(),

              const SizedBox(height: 15),

              _buildTextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                hint: "Phone Number",
                icon: Icons.phone_outlined,
                error: _phoneError,
                success: _phoneSuccess,
                keyboardType: TextInputType.phone,
                textCapitalization: TextCapitalization.none,
              ),

              const SizedBox(height: 15),

              _buildDateOfBirthField(),

              const SizedBox(height: 15),

              _buildGenderSection(),

              const SizedBox(height: 20),

              _buildTermsSection(),

              const SizedBox(height: 25),

              // Submit Button
              _isFormValid() ? _buildSignUpButton() : _buildDisabledButton(),

              const SizedBox(height: 20),

              _buildDivider(),

              const SizedBox(height: 20),

              _buildGoogleSignInButton(),

              const SizedBox(height: 25),

              _buildSignInLink(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    String? error,
    String? success,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    void Function(String)? onChanged,
    Widget? suffixWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: error != null
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: AppColors.textMain, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          errorText: error,
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
          suffixIcon:
              suffixWidget ??
              (success != null
                  ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : null),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: _passwordError != null
            ? Border.all(color: Colors.red, width: 1.5)
            : (_passwordController.text.isNotEmpty && _passwordError == null
                  ? Border.all(color: Colors.green, width: 1.0)
                  : null),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textMain, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                hintText: "Password",
                hintStyle: const TextStyle(color: Colors.grey),
                errorText: _passwordError,
                errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                suffixIcon:
                    _passwordController.text.isNotEmpty &&
                        _passwordError == null
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textMain,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: _showPasswordRequirements,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    bool passwordsMatch =
        _doPasswordsMatch() && _confirmPasswordController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: _confirmPasswordError != null
            ? Border.all(color: Colors.red, width: 1.5)
            : (passwordsMatch
                  ? Border.all(color: Colors.green, width: 1.0)
                  : null),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(color: AppColors.textMain, fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                hintText: "Confirm Password",
                hintStyle: const TextStyle(color: Colors.grey),
                errorText: _confirmPasswordError,
                errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                suffixIcon: passwordsMatch
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textMain,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ],
      ),
    );
  }

  bool _doPasswordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  Widget _buildDateOfBirthField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: _dobError != null
            ? Border.all(color: Colors.red, width: 1.5)
            : null,
      ),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextField(
            controller: _dobController,
            style: const TextStyle(color: AppColors.textMain, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              hintText: "Date of Birth",
              hintStyle: const TextStyle(color: Colors.grey),
              errorText: _dobError,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textMain,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            "Gender",
            style: TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (_genderError != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              _genderError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Row(
          children: [
            Expanded(child: _genderButton("Male", Icons.male)),
            const SizedBox(width: 10),
            Expanded(child: _genderButton("Female", Icons.female)),
            const SizedBox(width: 10),
            Expanded(child: _genderButton("Other", Icons.transgender)),
          ],
        ),
      ],
    );
  }

  Widget _genderButton(String gender, IconData icon) {
    bool isSelected = _selectedGender == gender;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedGender = gender;
          _genderError = null;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            gender,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: const Text.rich(
              TextSpan(
                style: TextStyle(color: AppColors.textMain),
                children: [
                  TextSpan(text: "I agree to the "),
                  TextSpan(
                    text: "Terms & Conditions",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: " and "),
                  TextSpan(
                    text: "Privacy Policy",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.lightSurface,
                ),
              )
            : const Text(
                "Create Account",
                style: TextStyle(
                  color: AppColors.lightSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDisabledButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Create Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_translate, color: Colors.red),
            ),
            const SizedBox(width: 10),
            const Text(
              "Sign up with Google",
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text("Or", style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: "Already have an account? ",
                style: TextStyle(color: AppColors.textMain),
              ),
              TextSpan(
                text: "Sign In",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
