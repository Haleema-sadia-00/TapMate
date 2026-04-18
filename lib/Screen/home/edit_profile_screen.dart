import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:tapmate/Screen/services/cloudinary_imageservice.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _profileImage;
  String? _profileImageUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  String? _selectedGender;
  String? _error;
  bool _isPrivate = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say', 'Custom'];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();

    _loadUserData();
  }

  void _loadUserData() {
    try {
      final userData = widget.userData ?? {};

      _nameController.text = userData['name'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _websiteController.text = userData['website'] ?? '';

      _profileImageUrl = userData['profile_pic'];
      _selectedGender = userData['gender'] ?? 'Prefer not to say';
      _isPrivate = userData['is_private'] ?? false;

      print('📸 Loaded profile image URL: $_profileImageUrl');
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // --- Image Selection Helper ---
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _profileImage = File(image.path);
                      _profileImageUrl = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (photo != null) {
                    setState(() {
                      _profileImage = File(photo.path);
                      _profileImageUrl = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Current Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                    _profileImageUrl = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Upload to Cloudinary ---
  Future<String?> _uploadImageToCloudinary() async {
    if (_profileImage == null) return _profileImageUrl;

    try {
      setState(() => _isUploading = true);

      String? imageUrl = await _cloudinaryService.uploadImage(_profileImage!);

      if (imageUrl != null) {
        print('✅ Uploaded to Cloudinary: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('Cloudinary upload failed');
      }
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      setState(() {
        _error = 'Failed to upload image: $e';
      });
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- Save Logic ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadImageToCloudinary();
      }

      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim(),
        'username': _usernameController.text.trim().isEmpty
            ? user.email?.split('@').first ?? 'user'
            : _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'website': _websiteController.text.trim(),
        'gender': _selectedGender ?? 'Prefer not to say',
        'is_private': _isPrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String? finalProfilePic = _profileImageUrl;

      if (imageUrl != null) {
        updateData['profile_pic'] = imageUrl;
        finalProfilePic = imageUrl;
        setState(() {
          _profileImageUrl = imageUrl;
          _profileImage = null;
        });
        print('✅ Saving new profile picture (Cloudinary): $imageUrl');
      } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        updateData['profile_pic'] = _profileImageUrl;
        finalProfilePic = _profileImageUrl;
        print('✅ Keeping existing profile picture: $_profileImageUrl');
      } else {
        updateData['profile_pic'] = '';
        finalProfilePic = '';
        print('⚠️ No profile picture to save');
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      print('✅ Profile data saved to Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, {
          'success': true,
          'profile_pic': finalProfilePic,
          'name': updateData['name'],
          'username': updateData['username'],
          'bio': updateData['bio'],
        });
      }
    } catch (e) {
      print('❌ Save error: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    String name = _nameController.text.trim();
    if (name.isEmpty) return 'U';
    final List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // --- UI Build Helper ---
  Widget _buildProfileContent() {
    // New image selected
    if (_profileImage != null) {
      return Image.file(
        _profileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }

    // Existing Cloudinary URL
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error loading Cloudinary image: $error');
          return _initialsWidget();
        },
      );
    }

    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        _getInitials(),
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Gender selection bottom sheet
  Future<void> _showGenderPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Gender',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._genderOptions.map((gender) => ListTile(
                leading: Radio<String>(
                  value: gender,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                    Navigator.pop(context);
                  },
                  activeColor: AppColors.primary,
                ),
                title: Text(
                  gender,
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: isDarkMode ? Colors.white : AppColors.textMain,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textMain,
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploading) ? null : _saveProfile,
            child: _isLoading || _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Profile Image
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: _buildProfileContent(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap to change profile photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              TextFormField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textMain,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textMain,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }
                  if (value.contains(' ')) {
                    return 'Username cannot contain spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself...',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 15),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 15),

              // Website/Links Field
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Website / Link',
                  hintText: 'https://yourwebsite.com',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : AppColors.textMain,
                ),
              ),
              const SizedBox(height: 15),

              // Private Account Toggle
              SwitchListTile(
                title: const Text('Private Account'),
                subtitle: Text(
                  _isPrivate
                      ? 'Only followers can see your posts'
                      : 'Anyone can follow you',
                ),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 15),

              // Gender Selection Field
              GestureDetector(
                onTap: _showGenderPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedGender ?? 'Prefer not to say',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : AppColors.textMain,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}