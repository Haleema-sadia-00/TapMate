import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String? videoUrl;    // For network video (Chat)
  final String? filePath;    // For local file (Library)

  const VideoPlayerScreen({
    super.key,
    this.videoUrl,
    this.filePath,
  }) : assert(videoUrl != null || filePath != null, 'Either videoUrl or filePath must be provided');

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isNetworkVideo = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if it's network video or local file
      if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        // Network video (Chat screen)
        _isNetworkVideo = true;
        _controller = VideoPlayerController.network(widget.videoUrl!);
        await _controller.initialize();
        await _controller.play();

        _controller.addListener(() {
          if (mounted) {
            setState(() {
              _position = _controller.value.position;
              _duration = _controller.value.duration;
              _isPlaying = _controller.value.isPlaying;
            });
          }
        });

        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
          _isPlaying = true;
        });
      }
      else if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        // Local file (Library screen)
        _isNetworkVideo = false;
        final file = File(widget.filePath!);

        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video file not found'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          }
          return;
        }

        _controller = VideoPlayerController.file(file);
        await _controller.initialize();
        await _controller.setLooping(false);

        _controller.addListener(() {
          if (mounted) {
            setState(() {
              _position = _controller.value.position;
              _duration = _controller.value.duration;
              _isPlaying = _controller.value.isPlaying;
            });
          }
        });

        setState(() {
          _isInitialized = true;
          _duration = _controller.value.duration;
        });
      } else {
        throw Exception('No valid video source provided');
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not play this video'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Different UI for network vs local video
    if (_isNetworkVideo) {
      // Chat screen style - with close button and FAB
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: _isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _isInitialized
                  ? VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                ),
              )
                  : const SizedBox(),
            ),
          ],
        ),
        floatingActionButton: _isInitialized
            ? FloatingActionButton(
          onPressed: () {
            setState(() {
              _isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
        )
            : null,
      );
    } else {
      // Library screen style - with full controls
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Video Player'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isInitialized
            ? Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                children: [
                  // Progress Bar
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: Colors.grey[800]!,
                      backgroundColor: Colors.grey[900]!,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                        onPressed: () {
                          final newPosition = _controller.value.position - const Duration(seconds: 10);
                          _controller.seekTo(newPosition);
                        },
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPlaying ? _controller.pause() : _controller.play();
                            });
                          },
                          iconSize: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                        onPressed: () {
                          final newPosition = _controller.value.position + const Duration(seconds: 10);
                          _controller.seekTo(newPosition);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Time display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Text(' / ', style: TextStyle(color: Colors.white)),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
            : const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
  }
}