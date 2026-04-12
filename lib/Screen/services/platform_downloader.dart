import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'platform_auth_service.dart';

class PlatformDownloader {
  static const String backendBaseUrl = String.fromEnvironment(
    'TAPMATE_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static final PlatformDownloader _instance = PlatformDownloader._internal();
  factory PlatformDownloader() => _instance;
  PlatformDownloader._internal();

  // Current download progress
  final Map<String, DownloadProgress> _downloads = {};

  // Stream for download progress
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  // 📥 Download video from platform
  Future<DownloadResult> downloadVideo({
    required String platformId,
    required String videoUrl,
    required String videoTitle,
    required String format,
    required String quality,
    String? customPath,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    // Check permissions
    if (!await _checkStoragePermission()) {
      return DownloadResult(
        success: false,
        message: 'Storage permission denied',
      );
    }

    // Keep auth service in place for platforms that may require login in future.
    if (_requiresAuth(platformId)) {
      final token = await PlatformAuthService().getAuthToken(platformId);
      if (token == null) {
        return DownloadResult(
          success: false,
          message: 'Not authenticated to $platformId',
        );
      }
    }

    // Generate download ID
    final downloadId = '${platformId}_${DateTime.now().millisecondsSinceEpoch}';

    // Get download directory
    final downloadDir = await _getDownloadDirectory(platformId, customPath);
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    // Generate filename
    final filename = _generateFilename(videoTitle, format, quality);
    final filePath = '${downloadDir.path}/$filename';

    try {
      // Start download
      final progress = DownloadProgress(
        id: downloadId,
        platformId: platformId,
        title: videoTitle,
        format: format,
        quality: quality,
        status: DownloadStatus.downloading,
        progress: 0,
        speed: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        filePath: filePath,
      );

      _downloads[downloadId] = progress;
      _progressController.add(progress);
      onProgress?.call(progress);

      if (platformId.toLowerCase() == 'youtube') {
        return await _downloadYouTubeVideo(
          downloadId: downloadId,
          videoUrl: videoUrl,
          quality: quality,
          filePath: filePath,
          onProgress: onProgress,
        );
      }

      if (platformId.toLowerCase() == 'instagram' ||
          platformId.toLowerCase() == 'tiktok' ||
          platformId.toLowerCase() == 'facebook' ||
          platformId.toLowerCase() == 'twitter') {
        return await _downloadViaBackend(
          downloadId: downloadId,
          videoUrl: videoUrl,
          quality: quality,
          filePath: filePath,
          onProgress: onProgress,
        );
      }

      return await _simulateDownload(downloadId, filePath, onProgress: onProgress);

    } catch (e) {
      return DownloadResult(
        success: false,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  Future<DownloadResult> _downloadViaBackend({
    required String downloadId,
    required String videoUrl,
    required String quality,
    required String filePath,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final client = http.Client();
    IOSink? sink;

    try {
      final createResponse = await client.post(
        Uri.parse('$backendBaseUrl/api/download'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'url': videoUrl,
          'quality': quality == 'best' ? 'best' : 'best',
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () => throw TimeoutException('Backend request timed out'));

      if (createResponse.statusCode != 200) {
        String detail = createResponse.body;
        try {
          final errorBody = json.decode(createResponse.body) as Map<String, dynamic>;
          detail = errorBody['detail']?.toString() ?? createResponse.body;
        } catch (_) {}
        throw Exception('Backend download request failed (${createResponse.statusCode}): $detail');
      }

      final createBody = json.decode(createResponse.body) as Map<String, dynamic>;
      final taskId = createBody['task_id']?.toString();
      final backendFilename = createBody['filename']?.toString();

      if (taskId == null || taskId.isEmpty) {
        throw Exception('Backend did not return task_id');
      }

      final resolvedPath = _pathWithOptionalFilename(filePath, backendFilename);
      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId]!.filePath = resolvedPath;
      }

      final request = http.Request('GET', Uri.parse('$backendBaseUrl/api/file/$taskId'));
      final streamResponse = await client.send(request);
      if (streamResponse.statusCode != 200) {
        throw Exception('Backend file fetch failed (${streamResponse.statusCode})');
      }

      final outputFile = File(resolvedPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      sink = outputFile.openWrite();

      final total = streamResponse.contentLength ?? 0;
      int downloaded = 0;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in streamResponse.stream) {
        if (!_downloads.containsKey(downloadId)) {
          break;
        }

        sink.add(chunk);
        downloaded += chunk.length;

        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        final speedBytes = elapsed > 0 ? downloaded / elapsed : 0;

        final progress = _downloads[downloadId]!;
        progress.downloadedBytes = downloaded;
        progress.totalBytes = total;
        progress.progress = total > 0 ? downloaded / total : 0;
        progress.speed = speedBytes / (1024 * 1024);

        _progressController.add(progress);
        onProgress?.call(progress);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!_downloads.containsKey(downloadId)) {
        return DownloadResult(success: false, message: 'Download cancelled');
      }

      final completed = _downloads[downloadId]!;
      completed.status = DownloadStatus.completed;
      completed.progress = 1.0;
      if (completed.totalBytes == 0) {
        completed.totalBytes = downloaded;
      }
      completed.downloadedBytes = downloaded;
      _progressController.add(completed);
      onProgress?.call(completed);

      return DownloadResult(
        success: true,
        message: 'Download completed',
        filePath: resolvedPath,
        fileSize: downloaded,
      );
    } catch (e) {
      if (_downloads.containsKey(downloadId)) {
        final failed = _downloads[downloadId]!;
        failed.status = DownloadStatus.failed;
        _progressController.add(failed);
        onProgress?.call(failed);
      }

      return DownloadResult(
        success: false,
        message: '❌ Download failed: ${e.toString().contains('timed out') ? 'Connection timed out' : e.toString().contains('Connection') ? 'Cannot connect to backend' : 'Backend error'}. Backend: $backendBaseUrl',
      );
    } finally {
      await sink?.flush();
      await sink?.close();
      client.close();
    }
  }

  String _pathWithOptionalFilename(String fallbackPath, String? filename) {
    if (filename == null || filename.trim().isEmpty) {
      return fallbackPath;
    }

    final safe = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (safe.isEmpty) {
      return fallbackPath;
    }

    final fallbackFile = File(fallbackPath);
    return '${fallbackFile.parent.path}/$safe';
  }

  // 🎯 Simulate download (replace with real implementation)
  Future<DownloadResult> _simulateDownload(
    String downloadId,
    String filePath, {
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final totalSteps = 100;
    for (int i = 0; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 50));

      if (_downloads.containsKey(downloadId)) {
        final progress = _downloads[downloadId]!;
        progress.progress = i / totalSteps;
        progress.downloadedBytes = (i / totalSteps * 1024 * 1024 * 10).toInt(); // 10 MB total
        progress.totalBytes = 1024 * 1024 * 10;
        progress.speed = 2.5; // MB/s

        _progressController.add(progress);
        onProgress?.call(progress);
      }
    }

    // Mark as completed
    if (_downloads.containsKey(downloadId)) {
      final progress = _downloads[downloadId]!;
      progress.status = DownloadStatus.completed;
      progress.progress = 1.0;
      _progressController.add(progress);
      onProgress?.call(progress);
    }

    // Create dummy file
    final file = File(filePath);
    await file.writeAsString('Dummy video content for $downloadId');

    return DownloadResult(
      success: true,
      message: 'Download completed',
      filePath: filePath,
      fileSize: 1024 * 1024 * 10,
    );
  }

  Future<DownloadResult> _downloadYouTubeVideo({
    required String downloadId,
    required String videoUrl,
    required String quality,
    required String filePath,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final yt = YoutubeExplode();
    IOSink? sink;

    try {
      final video = await yt.videos.get(videoUrl);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final muxedStreams = manifest.muxed.sortByVideoQuality();

      if (muxedStreams.isEmpty) {
        throw Exception('No downloadable stream available for this video.');
      }

      final streamInfo = _selectBestStream(muxedStreams, quality);
      final finalPath = _replaceFileExtension(filePath, streamInfo.container.name);

      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId]!.totalBytes = streamInfo.size.totalBytes;
        _downloads[downloadId]!.filePath = finalPath;
        _progressController.add(_downloads[downloadId]!);
        onProgress?.call(_downloads[downloadId]!);
      }

      final outputFile = File(finalPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      sink = outputFile.openWrite();
      final stream = yt.videos.streamsClient.get(streamInfo);

      int downloaded = 0;
      final total = streamInfo.size.totalBytes;
      final stopwatch = Stopwatch()..start();

      await for (final chunk in stream) {
        if (!_downloads.containsKey(downloadId)) {
          break;
        }

        sink.add(chunk);
        downloaded += chunk.length;

        final elapsed = stopwatch.elapsedMilliseconds / 1000;
        final speedBytes = elapsed > 0 ? downloaded / elapsed : 0;

        final progress = _downloads[downloadId]!;
        progress.downloadedBytes = downloaded;
        progress.totalBytes = total;
        progress.progress = total > 0 ? downloaded / total : 0;
        progress.speed = speedBytes / (1024 * 1024);

        _progressController.add(progress);
        onProgress?.call(progress);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!_downloads.containsKey(downloadId)) {
        return DownloadResult(
          success: false,
          message: 'Download cancelled',
        );
      }

      final completed = _downloads[downloadId]!;
      completed.status = DownloadStatus.completed;
      completed.progress = 1.0;
      completed.downloadedBytes = completed.totalBytes;
      _progressController.add(completed);
      onProgress?.call(completed);

      return DownloadResult(
        success: true,
        message: 'Download completed',
        filePath: finalPath,
        fileSize: completed.totalBytes,
      );
    } catch (e) {
      if (_downloads.containsKey(downloadId)) {
        final failed = _downloads[downloadId]!;
        failed.status = DownloadStatus.failed;
        _progressController.add(failed);
        onProgress?.call(failed);
      }

      return DownloadResult(
        success: false,
        message: 'YouTube download failed: ${e.toString()}',
      );
    } finally {
      await sink?.flush();
      await sink?.close();
      yt.close();
    }
  }

  MuxedStreamInfo _selectBestStream(List<MuxedStreamInfo> streams, String quality) {
    final targetHeight = int.tryParse(quality.toLowerCase().replaceAll(RegExp(r'[^0-9]'), ''));
    if (targetHeight == null) {
      return streams.last;
    }

    MuxedStreamInfo? exactMatch;
    MuxedStreamInfo? lowerBest;
    for (final stream in streams) {
      final qualityLabel = stream.qualityLabel;
      final height = int.tryParse(
        qualityLabel.toLowerCase().replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (height == null) {
        continue;
      }

      if (height == targetHeight) {
        exactMatch = stream;
      }
      if (height <= targetHeight) {
        lowerBest = stream;
      }
    }

    return exactMatch ?? lowerBest ?? streams.first;
  }

  String _replaceFileExtension(String filePath, String extension) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) {
      return '$filePath.$extension';
    }
    return '${filePath.substring(0, dotIndex)}.$extension';
  }

  // 🔐 Check if platform requires auth
  bool _requiresAuth(String platformId) {
    final authRequired = <String>[];
    return authRequired.contains(platformId);
  }

  // 📁 Get download directory
  Future<Directory> _getDownloadDirectory(String platformId, String? customPath) async {
    if (customPath != null && customPath.isNotEmpty) {
      return Directory(customPath);
    }

    if (Platform.isAndroid) {
      final publicDownloadDir = Directory('/storage/emulated/0/Download/TapMate/$platformId');
      return publicDownloadDir;
    }

    // Use app's download directory
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/TapMate_Downloads/$platformId');
  }

  // 📝 Generate filename
  String _generateFilename(String title, String format, String quality) {
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cleanTitle}_${quality}_$timestamp.$format';
  }

  // ✅ Check storage permission
  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS handles differently
  }

  // Pause download
  void pauseDownload(String downloadId) {
    if (_downloads.containsKey(downloadId)) {
      _downloads[downloadId]!.status = DownloadStatus.paused;
      _progressController.add(_downloads[downloadId]!);
    }
  }

  // Resume download
  void resumeDownload(String downloadId) {
    if (_downloads.containsKey(downloadId)) {
      _downloads[downloadId]!.status = DownloadStatus.downloading;
      _progressController.add(_downloads[downloadId]!);
      // TODO: Resume actual download
    }
  }

  // Cancel download
  void cancelDownload(String downloadId) {
    if (_downloads.containsKey(downloadId)) {
      final cancelledDownload = _downloads[downloadId];
      _downloads[downloadId]!.status = DownloadStatus.cancelled;
      _progressController.add(_downloads[downloadId]!);
      _downloads.remove(downloadId);

      // Delete partial file
      final file = File(cancelledDownload?.filePath ?? '');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  void dispose() {
    _progressController.close();
  }
}

// Models
class DownloadProgress {
  final String id;
  final String platformId;
  final String title;
  final String format;
  final String quality;
  DownloadStatus status;
  double progress;
  double speed; // MB/s
  int downloadedBytes;
  int totalBytes;
  String filePath;

  DownloadProgress({
    required this.id,
    required this.platformId,
    required this.title,
    required this.format,
    required this.quality,
    required this.status,
    required this.progress,
    required this.speed,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.filePath,
  });
}

enum DownloadStatus {
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadResult {
  final bool success;
  final String message;
  final String? filePath;
  final int? fileSize;

  DownloadResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileSize,
  });
}