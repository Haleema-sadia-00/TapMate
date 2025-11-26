import 'package:flutter/material.dart';
import 'package:tapmatefyp/screens/auth/onboarding_1.dart';
import 'package:tapmatefyp/screens/auth/splash_screen.dart';
import 'CustomScreen.dart';
import 'LoginScreen.dart';
import 'SignupScreen.dart';
import 'resetpasswordScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapMate',
      theme: ThemeData(
        primaryColor: const Color(0xFFA64D79), // Primary button color
      ),
      debugShowCheckedModeBanner: false,
      // home: const OnboardingScreen(),
      // home: const Onboarding1(),
      // home: const SplashScreen(),
    );
  }
}
