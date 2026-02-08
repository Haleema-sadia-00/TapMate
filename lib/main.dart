import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart';
import 'package:tapmate/Screen/Auth/splashscreen.dart';
import 'package:tapmate/Screen/home/chat_screen.dart';
import 'package:tapmate/Screen/home/home_screen.dart';
import 'package:tapmate/Screen/home/platform_selection_screen.dart';
import 'package:tapmate/Screen/home/library_screen.dart';
import 'package:tapmate/Screen/home/feed_screen.dart';
import 'package:tapmate/Screen/home/search_screen.dart';
import 'package:tapmate/Screen/home/settings_screen.dart';
import 'package:tapmate/Screen/home/user_profile_screen.dart';
import 'package:tapmate/theme_provider.dart';
import 'package:tapmate/auth_provider.dart';
import 'package:tapmate/utils/guide_manager.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
        onFinish: () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;
      if (userId.isNotEmpty && userId != 'guest') {
        GuideManager.completeGuideForUser(userId);
      }
      if (authProvider.isNewSignUp == true) {
        authProvider.clearNewSignUpFlag();
      }
    },
    builder: (context) {
    return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
    return MaterialApp(
    title: 'TapMate',
    debugShowCheckedModeBanner: false,

    // 🎨 LIGHT THEME - "Professional Teal & Beige"
    theme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,

    colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    surface: AppColors.lightSurface,
    background: AppColors.lightBg,
    onPrimary: Colors.white,
    onSurface: AppColors.textMain,
    onBackground: AppColors.textMain,
    ),

    appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.accent,
    elevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    ),
    iconTheme: IconThemeData(color: AppColors.accent),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    ),

    inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.secondary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
    ),

    cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: AppColors.primary, width: 1),
    ),
    ),

    textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 32),
    bodyLarge: TextStyle(color: AppColors.primary, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.secondary, fontSize: 14),
    ),
    ),

    // 🌃 DARK THEME - "Elegant Charcoal & Burnt Orange"
    darkTheme: ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,

    colorScheme: ColorScheme.dark(
    primary: AppColors.secondary,
    secondary: AppColors.accent,
    tertiary: AppColors.softBeige,
    surface: AppColors.darkSurface,
    background: AppColors.darkBg,
    onPrimary: AppColors.primary,
    onSurface: AppColors.textOnDark,
    onBackground: AppColors.textOnDark,
    ),

    appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.darkBg,
    foregroundColor: AppColors.accent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    ),
    iconTheme: IconThemeData(color: AppColors.accent),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    ),

    inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.secondary, width: 2),
    ),
    ),

    cardTheme: CardThemeData(
    color: AppColors.darkSurface,
    elevation: 4,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.secondary.withOpacity(0.4)),
    ),
    ),

    textTheme: const TextTheme(
    displayLarge: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(color: AppColors.textOnDark),
    bodyMedium: TextStyle(color: AppColors.softBeige),
    ),
    ),

    themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    home: const SplashScreen(),
    routes: {
      '/home': (context) => const HomeScreen(),
      '/chat': (context) => const ChatScreen(),
      '/search': (context) => const SearchDiscoverScreen(),
      '/platform-selection': (context) => const PlatformSelectionScreen(),
      '/library': (context) => const LibraryScreen(),
      '/feed': (context) => const FeedScreen(),
      '/profile': (context) => const UserProfileScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/login': (context) => const LoginScreen(),
    }, ); }, ); }, ); } }
