import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// Theme Colors
const Color primaryColor = Color(0xFFA64D79);
const Color secondaryColor = Color(0xFF6A1E55);
const Color darkPurple = Color(0xFF3B1C32);

class StorageSelectionDialog extends StatefulWidget {
  final String platformName;
  final String contentId;
  final Function(String?) onDeviceStorageSelected;
  final Function() onAppStorageSelected;

  const StorageSelectionDialog({
    super.key,
    required this.platformName,
    required this.contentId,
    required this.onDeviceStorageSelected,
    required this.onAppStorageSelected,
  });

  @override
  State<StorageSelectionDialog> createState() => _StorageSelectionDialogState();
}

class _StorageSelectionDialogState extends State<StorageSelectionDialog> {
  bool _isSelectingPath = false;

  Future<void> _selectDevicePath() async {
    if (!mounted) return;

    setState(() {
      _isSelectingPath = true;
    });

    try {
      // DIRECT APPROACH: Try directory picking first
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      setState(() {
        _isSelectingPath = false;
      });

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        widget.onDeviceStorageSelected(selectedDirectory);
      } else {
        // User cancelled directory selection, try file picking as fallback
        await _selectFileAsFallback();
      }
    } catch (e) {
      // If directory picker fails, try file picker as fallback
      await _selectFileAsFallback();
    }
  }

  Future<void> _selectFileAsFallback() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      setState(() {
        _isSelectingPath = false;
      });

      if (result != null && result.files.single.path != null) {
        // Get the directory from the file path
        String filePath = result.files.single.path!;
        String directory = filePath.substring(0, filePath.lastIndexOf('/'));
        widget.onDeviceStorageSelected(directory);
      } else {
        // User cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Path selection cancelled'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSelectingPath = false;
      });

      if (mounted) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Error'),
              ],
            ),
            content: Text(
              'Unable to access device storage.\n\n'
                  'Error: ${e.toString()}\n\n'
                  'Please ensure:\n'
                  '• Storage permissions are granted\n'
                  '• You\'re using a supported platform\n'
                  '• Try using App Storage instead',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent closing dialog while selecting path
        return !_isSelectingPath;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [secondaryColor, primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Storage',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkPurple,
                          ),
                        ),
                        Text(
                          'Choose where to save ${widget.platformName} content',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Device Storage Option
              _buildStorageOption(
                icon: Icons.phone_android,
                title: 'Device Storage',
                subtitle: 'Save to your device storage',
                color: primaryColor,
                onTap: _isSelectingPath ? null : _selectDevicePath,
                isLoading: _isSelectingPath,
              ),

              const SizedBox(height: 15),

              // App Storage Option
              _buildStorageOption(
                icon: Icons.folder,
                title: 'App Storage',
                subtitle: 'Save to TapMate downloads folder',
                color: secondaryColor,
                onTap: widget.onAppStorageSelected,
                isLoading: false,
              ),

              const SizedBox(height: 20),

              // Cancel Button
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
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
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
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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