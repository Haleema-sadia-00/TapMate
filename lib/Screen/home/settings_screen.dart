import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/theme_provider.dart';
import 'package:tapmate/utils/guide_manager.dart';
import 'package:tapmate/auth_provider.dart';
import 'package:tapmate/Screen/home/home_screen.dart';
import 'package:tapmate/Screen/Auth/LoginScreen.dart'; // IMPORT ADDED
import 'package:showcaseview/showcaseview.dart';

// Theme Colors
const Color primaryColor = Color(0xFFA64D79);
const Color secondaryColor = Color(0xFF6A1E55);
const Color darkPurple = Color(0xFF3B1C32);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _dataSaver = false;
  bool _cloudSyncEnabled = false;
  bool _autoBackup = false;
  String _language = 'English';
  double _storageUsed = 2.4; // GB
  double _storageTotal = 25.0; // GB

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Sync local state with provider
    if (_darkMode != isDarkMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _darkMode = isDarkMode;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [darkPurple, secondaryColor, primaryColor],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkPurple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section
                    _buildSectionTitle('Account', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Change your profile information',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showChangePasswordDialog(isDarkMode);
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.email_outlined,
                        title: 'Email Settings',
                        subtitle: 'Manage email preferences',
                        isDarkMode: isDarkMode,
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Cloud & Sync Section
                    _buildSectionTitle('Cloud & Sync', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSwitchTile(
                        icon: Icons.cloud_sync,
                        title: 'Cloud Sync',
                        subtitle: 'Sync your data across devices',
                        value: _cloudSyncEnabled,
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _cloudSyncEnabled = value;
                          });
                          if (value) {
                            _showCloudSyncDialog(isDarkMode);
                          }
                        },
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        icon: Icons.backup,
                        title: 'Auto Backup',
                        subtitle: 'Automatically backup your content',
                        value: _autoBackup,
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _autoBackup = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.cloud_download,
                        title: 'Backup Now',
                        subtitle: 'Create a backup of your data',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showBackupDialog(isDarkMode);
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.restore,
                        title: 'Restore Backup',
                        subtitle: 'Restore from previous backup',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showRestoreDialog(isDarkMode);
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // App Settings
                    _buildSectionTitle('App Settings', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Enable push notifications',
                        value: _notificationsEnabled,
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Switch to dark theme',
                        value: _darkMode,
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                          // Apply dark mode immediately using Provider
                          Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Dark mode enabled!' : 'Dark mode disabled!'),
                              backgroundColor: primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        icon: Icons.data_saver_off,
                        title: 'Data Saver',
                        subtitle: 'Reduce data usage',
                        value: _dataSaver,
                        isDarkMode: isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _dataSaver = value;
                          });
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: _language,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showLanguageSelector(isDarkMode);
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Storage & Data
                    _buildSectionTitle('Storage & Data', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSettingsTile(
                        icon: Icons.storage,
                        title: 'App Storage',
                        subtitle: '${_storageUsed.toStringAsFixed(1)} GB / ${_storageTotal.toStringAsFixed(0)} GB used',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showStorageDetails(isDarkMode);
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.delete_outline,
                        title: 'Clear Cache',
                        subtitle: 'Free up storage space',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showClearCacheDialog(isDarkMode);
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // App Tour
                    _buildSectionTitle('App Tour', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSettingsTile(
                        icon: Icons.tour_outlined,
                        title: 'Take Tour Again',
                        subtitle: 'Restart the guided onboarding tour',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showRestartTourDialog(isDarkMode);
                        },
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // About & Support
                    _buildSectionTitle('About & Support', isDarkMode),
                    _buildSettingsCard(isDarkMode: isDarkMode, children: [
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with TapMate',
                        isDarkMode: isDarkMode,
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _showAboutDialog(isDarkMode);
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        isDarkMode: isDarkMode,
                        onTap: () {},
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms',
                        isDarkMode: isDarkMode,
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () {
                          _showLogoutDialog(isDarkMode);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : darkPurple,
          ),
        ),
    );
  }

  Widget _buildSettingsCard({required bool isDarkMode, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : darkPurple.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : darkPurple,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: isDarkMode ? Colors.grey[400] : darkPurple),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : darkPurple,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }

  void _showCloudSyncDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cloud Sync',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Text(
          'Cloud sync will automatically sync your downloads, settings, and preferences across all your devices.',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cloud sync enabled!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Enable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Backup Now',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Text(
          'This will create a backup of all your downloads, settings, and preferences to the cloud.',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup(isDarkMode);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Backup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performBackup(bool isDarkMode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 20),
            Text(
              'Creating backup...',
              style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
            ),
          ],
        ),
      ),
    );

    // Simulate backup process
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showRestoreDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restore Backup',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Text(
          'Select a backup to restore from. This will replace your current data.',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restore functionality coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStorageDetails(bool isDarkMode) {
    final percentage = (_storageUsed / _storageTotal) * 100;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Storage Usage',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageItem('Videos', 1.8, isDarkMode),
            const SizedBox(height: 10),
            _buildStorageItem('Images', 0.4, isDarkMode),
            const SizedBox(height: 10),
            _buildStorageItem('Cache', 0.2, isDarkMode),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : darkPurple,
                    ),
                  ),
                  Text(
                    '${_storageUsed.toStringAsFixed(1)} GB / ${_storageTotal.toStringAsFixed(0)} GB',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: _storageUsed / _storageTotal,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% used',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, double size, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        Text(
          '$size GB',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : darkPurple),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : darkPurple),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : darkPurple),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Change', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : darkPurple,
              ),
            ),
            const SizedBox(height: 20),
            _buildLanguageOption('English', isDarkMode),
            _buildLanguageOption('Spanish', isDarkMode),
            _buildLanguageOption('French', isDarkMode),
            _buildLanguageOption('German', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, bool isDarkMode) {
    final isSelected = _language == language;
    return ListTile(
      title: Text(
        language,
        style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: primaryColor)
          : null,
      onTap: () {
        setState(() {
          _language = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showClearCacheDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Cache',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Text(
          'This will free up 0.2 GB of storage. Continue?',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _storageUsed -= 0.2;
                if (_storageUsed < 0) _storageUsed = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'About TapMate',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.0',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
            ),
            const SizedBox(height: 10),
            Text(
              'TapMate - Download and share videos from any platform',
              style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
            ),
            const SizedBox(height: 10),
            Text(
              '© 2024 TapMate. All rights reserved.',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out',
          style: TextStyle(color: isDarkMode ? Colors.white : darkPurple),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog
              Navigator.pop(context);

              // Get auth provider and logout
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();

              // Navigate directly to LoginScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // settings_screen.dart میں یہ method شامل کریں
  void _showRestartTourDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.tour_outlined, color: primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Take Tour Again',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : darkPurple,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will restart the guided onboarding tour. You\'ll see highlights for all key features of TapMate.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : darkPurple,
            fontSize: 15,
            fontFamily: 'Roboto',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Roboto',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              // If guest, prompt to sign up instead of starting tour
              if (authProvider.isGuest) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: primaryColor),
                        const SizedBox(width: 10),
                        Text('Guests cannot take the tour', style: TextStyle(color: isDarkMode ? Colors.white : darkPurple)),
                      ],
                    ),
                    content: Text(
                      'Create an account to see the full guided tour and learn how to use TapMate.',
                      style: TextStyle(color: isDarkMode ? Colors.grey[300] : darkPurple),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Maybe Later')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                return;
              }

              // Reset per-user guide flag
              final userId = authProvider.userId;
              await GuideManager.resetGuideForUser(userId);

              // Navigate to home and remove other routes so HomeScreen will start the tour
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Tour',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

