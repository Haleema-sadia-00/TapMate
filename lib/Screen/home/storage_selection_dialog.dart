import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:tapmate/Screen/constants/app_colors.dart';

class StorageSelectionDialog extends StatefulWidget {
  final String platformName;
  final String contentId;
  final String contentTitle;
  final Function(String? path, String format, String quality) onDeviceStorageSelected;
  final Function(String format, String quality) onAppStorageSelected;

  const StorageSelectionDialog({
    super.key,
    required this.platformName,
    required this.contentId,
    required this.contentTitle,
    required this.onDeviceStorageSelected,
    required this.onAppStorageSelected,
  });

  @override
  State<StorageSelectionDialog> createState() => _StorageSelectionDialogState();
}

class _StorageSelectionDialogState extends State<StorageSelectionDialog> with SingleTickerProviderStateMixin {
  bool _isSelectingPath = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDevicePath() async {
    if (!mounted) return;

    setState(() => _isSelectingPath = true);

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select download location',
      );

      // ✅ Close dialog FIRST, then call callback
      if (mounted) {
        Navigator.pop(context);
      }

      if (selectedDirectory != null && mounted) {
        widget.onDeviceStorageSelected(selectedDirectory, 'mp4', 'best');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog('Error selecting path: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSelectingPath = false);
      }
    }
  }

  void _handleAppStorage() async {
    // ✅ Close dialog FIRST, then call callback
    if (mounted) {
      Navigator.pop(context);
    }
    widget.onAppStorageSelected('mp4', 'best');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Storage',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select where to save your download',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              _buildStorageOption(
                icon: Icons.phone_android,
                title: 'Device Storage',
                subtitle: 'Select a folder on your device',
                color: AppColors.primary,
                onTap: _isSelectingPath ? null : _selectDevicePath,
                isLoading: _isSelectingPath,
              ),
              const SizedBox(height: 12),

              _buildStorageOption(
                icon: Icons.folder,
                title: 'App Storage',
                subtitle: 'Save to TapMate Library\n(Visible only inside app)',
                color: AppColors.secondary,
                onTap: _handleAppStorage,
                isLoading: false,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSelectingPath ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}