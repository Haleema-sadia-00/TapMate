import 'package:flutter/material.dart';
import 'onboarding_1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Onboarding1()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🔥 ALL SOCIAL PLATFORMS GRADIENT
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF0000), // YouTube Red
              Color(0xFFE4405F), // Instagram Pink
              Color(0xFF1877F2), // Facebook Blue
              Color(0xFF000000), // TikTok Black
              Color(0xFF25D366), // WhatsApp Green
              Color(0xFF1DA1F2), // Twitter Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 🔥 MULTICOLOR GRADIENT ICON
                    Center(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFFF0000), // YT
                              Color(0xFFE4405F), // IG
                              Color(0xFF1877F2), // FB
                              Color(0xFF000000), // TT
                              Color(0xFF25D366), // WA
                            ],
                          ).createShader(bounds);
                        },
                        child: const Icon(
                          Icons.download_for_offline_outlined,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Text(
                'TapMate',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'All Social Platforms in One',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // 🔥 ALL PLATFORM ICONS ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlatformIcon('YT', Color(0xFFFF0000)), // YouTube
                  _buildPlatformIcon('IG', Color(0xFFE4405F)), // Instagram
                  _buildPlatformIcon('FB', Color(0xFF1877F2)), // Facebook
                  _buildPlatformIcon('TT', Color(0xFF000000)), // TikTok
                  _buildPlatformIcon('WA', Color(0xFF25D366)), // WhatsApp
                ],
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 PLATFORM ICON WIDGET
  Widget _buildPlatformIcon(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}