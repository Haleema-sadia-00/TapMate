// lib/Screen/models/download_item.dart

import 'dart:convert';

class DownloadItem {
  final String id;
  final String platform;
  final String title;
  final String filePath;
  final int size;
  final DateTime timestamp;
  final String storageType; // 'app' or 'device'

  DownloadItem({
    required this.id,
    required this.platform,
    required this.title,
    required this.filePath,
    required this.size,
    required this.timestamp,
    required this.storageType,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      platform: json['platform'],
      title: json['title'],
      filePath: json['filePath'],
      size: json['size'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      storageType: json['storageType'] ?? 'app',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'title': title,
      'filePath': filePath,
      'size': size,
      'timestamp': timestamp.toIso8601String(),
      'storageType': storageType,
    };
  }
}