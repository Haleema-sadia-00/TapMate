import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/home/chat_screen.dart';
import 'package:tapmate/Screen/home/home_screen.dart';
import 'package:tapmate/Screen/home/search_screen.dart';
import 'package:tapmate/Screen/home/platform_selection_screen.dart';
import 'package:tapmate/Screen/home/library_screen.dart';
import 'package:tapmate/Screen/home/feed_screen.dart';
import 'package:tapmate/Screen/home/user_profile_screen.dart';
import 'package:tapmate/Screen/home/settings_screen.dart';
import 'package:tapmate/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'TapMate',
          theme: ThemeData(
            primaryColor: const Color(0xFFA64D79),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFA64D79),
              primary: const Color(0xFFA64D79),
              secondary: const Color(0xFF6A1E55),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primaryColor: const Color(0xFFA64D79),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFA64D79),
              primary: const Color(0xFFA64D79),
              secondary: const Color(0xFF6A1E55),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/home',
          routes: {
            '/home': (context) => const HomeScreen(),
            '/chat': (context) => const ChatScreen(),
            '/search': (context) => const SearchDiscoverScreen(),
            '/platform-selection': (context) => const PlatformSelectionScreen(),
            '/library': (context) => const LibraryScreen(),
            '/feed': (context) => const FeedScreen(),
            '/profile': (context) => const UserProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}