// lib/screens/HomeScreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'platform_selection_screen.dart';
import '../../auth_provider.dart';
import '../../theme_provider.dart';
import '../../utils/guide_manager.dart';
import 'onboarding_guide.dart';

// Theme Colors
const Color primaryColor = Color(0xFFA64D79);
const Color secondaryColor = Color(0xFF6A1E55);
const Color darkPurple = Color(0xFF3B1C32);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKeys for showcase widgets
  final GlobalKey _downloadCardKey = GlobalKey();
  final GlobalKey _floatingButtonKey = GlobalKey();
  final GlobalKey _profileIconKey = GlobalKey();
  final GlobalKey _statsSectionKey = GlobalKey();
  final GlobalKey _libraryButtonKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _navigationBarKey = GlobalKey();

  late OnboardingGuideKeys _guideKeys;

  @override
  void initState() {
    super.initState();
    _guideKeys = OnboardingGuideKeys(
      floatingButtonKey: _floatingButtonKey,
      profileIconKey: _profileIconKey,
      downloadCardKey: _downloadCardKey,
      statsSectionKey: _statsSectionKey,
      libraryButtonKey: _libraryButtonKey,
      settingsButtonKey: _settingsButtonKey,
      navigationBarKey: _navigationBarKey,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboardingStatus();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final hasCompleted = await GuideManager.hasCompletedGuide();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!hasCompleted && mounted) {
      // Wait for UI to render
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        final keys = _guideKeys.getAllKeys().where((key) => key != null).cast<GlobalKey>().toList();
        if (keys.isNotEmpty) {
          ShowCaseWidget.of(context).startShowCase(keys);
          // Mark as completed after showing
          await GuideManager.completeGuide();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGuest = authProvider.isGuest;
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: ShowCaseWidget(
        onFinish: () {
          GuideManager.completeGuide();
        },
        builder: (context) => Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF3B1C32),
                                  Color(0xFF6A1E55),
                                  Color(0xFFA64D79),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B1C32).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'TapMate',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.7,
                                          child: Text(
                                            'Download and share videos from any platform',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Roboto',
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Profile Icon with showcase
                                    if (!isGuest)
                                      buildShowcase(
                                        key: _profileIconKey,
                                        title: 'Profile Icon',
                                        description: 'Tap here to view and edit your profile',
                                        isDarkMode: isDarkMode,
                                        isLocked: false,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(context, '/profile');
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      // Locked profile icon for guests
                                      GestureDetector(
                                        onTap: () => showLockedFeatureDialog(context, 'Profile', isDarkMode),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Icon(
                                                  Icons.lock,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Ready to Download Card with showcase
                                buildShowcase(
                                  key: _downloadCardKey,
                                  title: 'Download Card',
                                  description: 'Get started with downloads from here. This card shows you\'re ready to download videos!',
                                  isDarkMode: isDarkMode,
                                  isLocked: false,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.download_rounded,
                                            color: Color(0xFFA64D79),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Ready to Download',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'Roboto',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isGuest
                                                    ? 'Sign up to unlock downloads'
                                                    : 'Tap the floating button to start',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontFamily: 'Roboto',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Stats Section with showcase
                          buildShowcase(
                            key: _statsSectionKey,
                            title: 'Stats Section',
                            description: 'Track your downloads, storage usage, and cloud uploads. Monitor your activity at a glance!',
                            isDarkMode: isDarkMode,
                            isLocked: isGuest && false, // Stats are visible but some features locked
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  _buildEqualStatCard(
                                    icon: Icons.download_done_rounded,
                                    title: 'Total Downloads',
                                    value: isGuest ? '0' : '247',
                                    color: const Color(0xFFA64D79),
                                    isGuest: isGuest,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildEqualStatCard(
                                    icon: Icons.storage_rounded,
                                    title: 'Storage Used',
                                    value: isGuest ? '0 GB' : '2.4 GB',
                                    color: const Color(0xFF6A1E55),
                                    isGuest: isGuest,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildEqualStatCard(
                                    icon: Icons.cloud_upload_rounded,
                                    title: 'Cloud Uploads',
                                    value: isGuest ? '0' : '89',
                                    color: const Color(0xFF3B1C32),
                                    isGuest: isGuest,
                                    isLocked: isGuest,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Quick Actions Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A1E55),
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildShowcase(
                                        key: _libraryButtonKey,
                                        title: 'Library Button',
                                        description: 'View and manage all downloaded videos. Access your collection anytime!',
                                        isDarkMode: isDarkMode,
                                        isLocked: isGuest,
                                        child: _buildEqualQuickAction(
                                          icon: Icons.video_library_rounded,
                                          label: 'Library',
                                          subtitle: 'Manage your downloads',
                                          color: const Color(0xFFA64D79),
                                          isLocked: isGuest,
                                          onTap: () {
                                            if (isGuest) {
                                              showLockedFeatureDialog(context, 'Library', isDarkMode);
                                            } else {
                                              Navigator.pushNamed(context, '/library');
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: buildShowcase(
                                        key: _settingsButtonKey,
                                        title: 'Settings Button',
                                        description: 'Customize app preferences and dark mode. Personalize your TapMate experience!',
                                        isDarkMode: isDarkMode,
                                        isLocked: false,
                                        child: _buildEqualQuickAction(
                                          icon: Icons.settings_rounded,
                                          label: 'Settings',
                                          subtitle: 'App preferences',
                                          color: const Color(0xFF6A1E55),
                                          isLocked: false,
                                          onTap: () {
                                            Navigator.pushNamed(context, '/settings');
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Recent Downloads Section - Show empty state for guests
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF3B1C32).withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      color: Color(0xFFA64D79),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Recent Downloads',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xFF6A1E55),
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (isGuest)
                                  _buildEmptyState(
                                    icon: Icons.video_library_outlined,
                                    title: 'No downloads yet',
                                    subtitle: 'Sign up to start downloading videos and build your library!',
                                    isDarkMode: isDarkMode,
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildDownloadItem('Video_001.mp4', '12 MB', Icons.video_file_rounded, isDarkMode),
                                      _buildDownloadItem('Short_Clip.mp4', '8 MB', Icons.movie_rounded, isDarkMode),
                                      _buildDownloadItem('Tutorial.mp4', '45 MB', Icons.school_rounded, isDarkMode),
                                      _buildDownloadItem('Music_Video.mp4', '32 MB', Icons.music_video_rounded, isDarkMode),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Navigation Bar with showcase
                  buildShowcase(
                    key: _navigationBarKey,
                    title: 'Navigation Bar',
                    description: 'Navigate between different app sections. Home, Discover, Feed, Messages, and Profile are all here!',
                    isDarkMode: isDarkMode,
                    isLocked: false,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(Icons.home_rounded, 'Home', true, context, isGuest, isDarkMode),
                          _buildNavItem(Icons.explore_rounded, 'Discover', false, context, isGuest, isDarkMode),
                          _buildNavItem(Icons.feed_rounded, 'Feed', false, context, isGuest, isDarkMode),
                          _buildNavItem(Icons.message_rounded, 'Message', false, context, isGuest, isDarkMode),
                          _buildNavItem(Icons.person_rounded, 'Profile', false, context, isGuest, isDarkMode),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Action Button (with showcase, hidden for guests but shown with lock)
            Positioned(
              right: 20,
              bottom: 80,
              child: buildShowcase(
                key: _floatingButtonKey,
                title: 'Floating Download Button',
                description: 'Tap this button to select a platform and download videos. This is your main download hub!',
                isDarkMode: isDarkMode,
                isLocked: isGuest,
                child: FloatingActionButton(
                  onPressed: () {
                    if (isGuest) {
                      showLockedFeatureDialog(context, 'Download', isDarkMode);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlatformSelectionScreen(),
                        ),
                      );
                    }
                  },
                  backgroundColor: isGuest ? Colors.grey : const Color(0xFFA64D79),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 28,
                      ),
                      if (isGuest)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : darkPurple,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isGuest,
    bool isLocked = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 130,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF3B1C32).withOpacity(0.1),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isLocked ? Colors.grey : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey : color,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (isLocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEqualQuickAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required bool isLocked,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[50] : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey[200] : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isLocked ? Colors.grey : color,
                          size: 20,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isLocked ? Colors.grey : color.withOpacity(0.6),
                        size: 14,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.grey : const Color(0xFF6A1E55),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadItem(String title, String size, IconData icon, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFA64D79).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFA64D79),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  size,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFA64D79).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Completed',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFFA64D79),
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    BuildContext context,
    bool isGuest,
    bool isDarkMode,
  ) {
    final isDisabled = isGuest && (label == 'Message' || label == 'Profile');

    return GestureDetector(
      onTap: isDisabled
          ? () {
              showLockedFeatureDialog(context, label, isDarkMode);
            }
          : () {
              if (label == 'Home') {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (label == 'Discover') {
                Navigator.pushReplacementNamed(context, '/search');
              } else if (label == 'Feed') {
                Navigator.pushReplacementNamed(context, '/feed');
              } else if (label == 'Message') {
                Navigator.pushReplacementNamed(context, '/chat');
              } else if (label == 'Profile') {
                Navigator.pushReplacementNamed(context, '/profile');
              }
            },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFFA64D79) : (isDarkMode ? Colors.grey[600] : Colors.grey),
                  size: 24,
                ),
                if (isDisabled)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(
                      Icons.lock,
                      size: 12,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFFA64D79) : (isDarkMode ? Colors.grey[600] : Colors.grey),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
