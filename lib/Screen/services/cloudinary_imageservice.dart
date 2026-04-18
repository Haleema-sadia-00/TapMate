
// lib/Screen/services/cloudinary_service.dart

import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryService {
  // ✅ Your Cloudinary credentials
  final String cloudName = 'dvxejhpau';
  final String uploadPreset = 'tapmate fyp'; // ⚠️ Note: Spaces not allowed!

  final Dio _dio = Dio();

  // ✅ Method to upload image to Cloudinary
  Future<String?> uploadImage(File imageFile) async {
    try {
      print('📤 Uploading to Cloudinary...');

      String url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': uploadPreset,
      });

      Response response = await _dio.post(url, data: formData);

      if (response.statusCode == 200) {
        String imageUrl = response.data['secure_url'];
        print('✅ Image uploaded to Cloudinary: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Cloudinary upload failed: ${response.data}');
        return null;
      }
    } catch (e) {
      print('❌ Cloudinary error: $e');
      return null;
    }
  }
}