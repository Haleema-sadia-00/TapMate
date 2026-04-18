import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LivePlatformBrowserScreen extends StatefulWidget {
  const LivePlatformBrowserScreen({super.key});

  @override
  State<LivePlatformBrowserScreen> createState() =>
      _LivePlatformBrowserScreenState();
}

class _LivePlatformBrowserScreenState extends State<LivePlatformBrowserScreen> {
  static const String _defaultInstagramStartUrl =
      'https://www.instagram.com/reels/DTiyexWAMpY/';

  late final WebViewController _controller;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  String _platformName = 'YouTube';
  String _initialUrl = 'https://youtube.com';
  String _currentUrl = '';
  bool _hasLoadError = false;
  String _lastError = '';
  String? _lastRouteLoadKey;
  final TextEditingController _tiktokLinkController = TextEditingController();
  final TextEditingController _instagramLinkController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _hasLoadError = false;
              _lastError = '';
            });
          },
          onPageFinished: (_) {
            _refreshCurrentUrl();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) {
              return;
            }
            if (!mounted) return;
            setState(() {
              _hasLoadError = true;
              _lastError = error.description;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            if (_isInstagramPlatform && url.startsWith('instagram://')) {
              final mappedUri = _mapInstagramDeepLinkToWeb(request.url);
              unawaited(_controller.loadRequest(mappedUri));
              return NavigationDecision.prevent;
            }

            if (_isInstagramPlatform && url.startsWith('intent://')) {
              final mappedIntentUri = _mapIntentUriToInstagramWeb(request.url);
              if (mappedIntentUri != null) {
                unawaited(_controller.loadRequest(mappedIntentUri));
              }
              return NavigationDecision.prevent;
            }

            if (_isInstagramPlatform && url.startsWith('market://')) {
              return NavigationDecision.prevent;
            }

            if (url.startsWith('intent://') ||
                url.startsWith('fb://') ||
                url.startsWith('twitter://') ||
                url.startsWith('tiktok://') ||
                url.startsWith('sflvavs://') ||
                url.startsWith('market://')) {
              unawaited(
                _launchUriSafely(
                  Uri.tryParse(request.url),
                  allowFallbackToWeb: true,
                ),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      platformController.setMediaPlaybackRequiresUserGesture(false);
      final androidCookieManager = _cookieManager.platform;
      if (androidCookieManager is AndroidWebViewCookieManager) {
        unawaited(
          androidCookieManager.setAcceptThirdPartyCookies(
            platformController,
            true,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var selectedPlatform = _platformName;
    var selectedUrl = _initialUrl;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final routePlatform = args['platform']?.toString();
      final routeUrl = args['url']?.toString();

      if (routePlatform != null && routePlatform.isNotEmpty) {
        selectedPlatform = routePlatform;
      }
      if (routeUrl != null && routeUrl.isNotEmpty) {
        selectedUrl = routeUrl;
      }
    }

    final nextLoadKey =
        '${selectedPlatform.toLowerCase()}|${selectedUrl.toLowerCase()}';
    if (_lastRouteLoadKey == nextLoadKey) {
      return;
    }

    _platformName = selectedPlatform;
    _initialUrl = selectedUrl;
    _lastRouteLoadKey = nextLoadKey;

    _initialUrl = _normalizedInitialUrl();
    if (_isTikTokPlatform) {
      _controller.loadRequest(
        Uri.parse(_initialUrl),
        headers: const {
          'Referer': 'https://www.tiktok.com/',
          'Origin': 'https://www.tiktok.com',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
    } else {
      _controller.loadRequest(Uri.parse(_initialUrl));
    }
  }

  @override
  void dispose() {
    _controller.runJavaScript('''
      var videos = document.querySelectorAll('video');
      for(var i = 0; i < videos.length; i++) {
        videos[i].pause();
      }
    ''');
    _tiktokLinkController.dispose();
    _instagramLinkController.dispose();
    super.dispose();
  }

  bool get _isTikTokPlatform => _platformName.toLowerCase() == 'tiktok';
  bool get _isInstagramPlatform => _platformName.toLowerCase() == 'instagram';
  bool get _isManualLinkFallbackPlatform =>
      _isTikTokPlatform || _isInstagramPlatform;

  Uri _mapInstagramDeepLinkToWeb(String deepLink) {
    final parsed = Uri.tryParse(deepLink);
    if (parsed == null || parsed.scheme != 'instagram') {
      return Uri.parse('https://www.instagram.com/');
    }

    final host = parsed.host.toLowerCase();
    final segments = parsed.pathSegments.where((s) => s.isNotEmpty).toList();

    if ((host == 'user' || host == 'profile') &&
        parsed.queryParameters['username'] != null) {
      final username = parsed.queryParameters['username']!;
      return Uri.parse('https://www.instagram.com/$username/');
    }

    if ((host == 'reel' || host == 'reels' || host == 'p' || host == 'tv') &&
        segments.isNotEmpty) {
      return Uri.parse('https://www.instagram.com/$host/${segments.first}/');
    }

    if (host == 'stories' && segments.isNotEmpty) {
      return Uri.parse('https://www.instagram.com/stories/${segments.first}/');
    }

    return Uri.parse('https://www.instagram.com/');
  }

  Uri? _mapIntentUriToInstagramWeb(String intentUrl) {
    final fallbackMatch = RegExp(
      r'S\.browser_fallback_url=([^;]+)',
    ).firstMatch(intentUrl);
    if (fallbackMatch != null) {
      final encoded = fallbackMatch.group(1);
      if (encoded != null && encoded.isNotEmpty) {
        final decoded = Uri.decodeComponent(encoded);
        final parsedFallback = Uri.tryParse(decoded);
        if (parsedFallback != null && _isWebUri(parsedFallback)) {
          return parsedFallback;
        }
      }
    }

    final hostAndPath = intentUrl
        .replaceFirst(RegExp(r'^intent://', caseSensitive: false), '')
        .split('#')
        .first
        .trim();
    if (hostAndPath.isEmpty) return null;
    return Uri.parse('https://$hostAndPath');
  }

  Future<void> _refreshCurrentUrl() async {
    final url = await _controller.currentUrl() ?? '';
    if (!mounted) return;
    setState(() {
      _currentUrl = url;
    });
  }

  String _normalizedInitialUrl() {
    final platform = _platformName.toLowerCase();
    if (platform == 'tiktok') {
      return 'https://www.tiktok.com/?lang=en';
    }
    if (platform == 'youtube') {
      return _initialUrl.contains('youtube.com') ||
          _initialUrl.contains('youtu.be')
          ? _initialUrl
          : 'https://m.youtube.com';
    }
    if (platform == 'instagram') {
      return _initialUrl.contains('instagram.com') ||
          _initialUrl.contains('i.instagram.com')
          ? _initialUrl
          : _defaultInstagramStartUrl;
    }
    if (platform == 'facebook') {
      return _initialUrl.contains('facebook.com') ||
          _initialUrl.contains('fb.watch')
          ? _initialUrl
          : 'https://m.facebook.com/watch/';
    }
    if (platform == 'twitter') {
      return _initialUrl.contains('x.com') ||
          _initialUrl.contains('twitter.com')
          ? _initialUrl
          : 'https://x.com/explore';
    }
    return _initialUrl;
  }

  bool _isLikelyVideoUrl(String url) {
    final value = url.toLowerCase();
    final platform = _platformName.toLowerCase();

    if (platform == 'youtube') {
      return value.contains('watch?v=') ||
          value.contains('youtu.be/') ||
          value.contains('/shorts/') ||
          value.contains('/live/');
    }
    if (platform == 'instagram') {
      return value.contains('/reel/') ||
          value.contains('/reels/') ||
          value.contains('/p/') ||
          value.contains('/tv/');
    }
    if (platform == 'tiktok') {
      return value.contains('/video/') || value.contains('/@');
    }
    if (platform == 'facebook') {
      return value.contains('/reel/') ||
          value.contains('/watch/') ||
          value.contains('/videos/') ||
          value.contains('fb.watch') ||
          value.contains('watch/?v=');
    }
    if (platform == 'twitter') {
      return value.contains('/status/') || value.contains('x.com/i/status/');
    }

    return value.startsWith('http://') || value.startsWith('https://');
  }

  Future<void> _captureAndDownload() async {
    await _controller.runJavaScript('''
      var videos = document.querySelectorAll('video');
      for(var i = 0; i < videos.length; i++) {
        videos[i].pause();
      }
    ''');

    final capturedUrl = (await _controller.currentUrl()) ?? _currentUrl;
    var candidate = capturedUrl.trim();

    if (_isTikTokPlatform &&
        (candidate.isEmpty || !_isLikelyVideoUrl(candidate))) {
      candidate = _tiktokLinkController.text.trim();
    }

    if (_isInstagramPlatform &&
        (candidate.isEmpty || !_isLikelyVideoUrl(candidate))) {
      candidate = _instagramLinkController.text.trim();
    }

    if (candidate.isEmpty || !_isLikelyVideoUrl(candidate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            _isTikTokPlatform
                ? 'Open TikTok video or paste TikTok link, then tap Download.'
                : _isInstagramPlatform
                ? 'Open Instagram public reel/post or paste its link, then tap Download.'
                : 'Open a $_platformName video post first, then tap Download.',
          ),
        ),
      );
      return;
    }

    final sanitizedUrl = _sanitizeShareUrl(candidate);

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/youtube_downloader',
      arguments: {
        'url': sanitizedUrl,
        'platform': _platformName,
        'autoDownload': true,
        'capturedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _pasteTikTokLinkFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (!mounted) return;

    if (value.isEmpty) {
      _showLaunchError('Clipboard is empty. Copy a TikTok link and try again.');
      return;
    }

    _tiktokLinkController.text = value;
    setState(() {});
  }

  Future<void> _pasteInstagramLinkFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (!mounted) return;

    if (value.isEmpty) {
      _showLaunchError(
        'Clipboard is empty. Copy an Instagram link and try again.',
      );
      return;
    }

    final lower = value.toLowerCase();
    if (!lower.contains('instagram.com')) {
      _showLaunchError('Please paste a valid Instagram reel/post link.');
      return;
    }

    _instagramLinkController.text = value;
    setState(() {});
  }

  String _sanitizeShareUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final filtered = Map<String, String>.from(uri.queryParameters)
      ..remove('igshid')
      ..remove('utm_source')
      ..remove('utm_medium')
      ..remove('utm_campaign')
      ..remove('feature')
      ..remove('si');

    return uri
        .replace(queryParameters: filtered.isEmpty ? null : filtered)
        .toString();
  }

  Future<void> _openCurrentInExternalApp() async {
    final candidate = _currentUrl.isNotEmpty ? _currentUrl : _initialUrl;
    await _launchUriSafely(Uri.tryParse(candidate), allowFallbackToWeb: true);
  }

  Future<void> _resetInstagramSession() async {
    await _cookieManager.clearCookies();
    await _controller.clearCache();
    try {
      await _controller.runJavaScript(
        'window.localStorage.clear(); window.sessionStorage.clear();',
      );
    } catch (_) {
      // Best effort only
    }
    await _controller.loadRequest(Uri.parse(_defaultInstagramStartUrl));
  }

  Future<void> _launchUriSafely(
      Uri? uri, {
        required bool allowFallbackToWeb,
      }) async {
    if (uri == null) {
      _showLaunchError('Invalid link');
      return;
    }

    try {
      if (_isWebUri(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showLaunchError('Could not open link in external app/browser.');
        }
        return;
      }

      final canOpenDeepLink = await canLaunchUrl(uri);
      if (canOpenDeepLink) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showLaunchError('Could not open deep link.');
        }
        return;
      }

      if (allowFallbackToWeb) {
        final fallback = Uri.parse(_normalizedInitialUrl());
        final launched = await launchUrl(
          fallback,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showLaunchError(
            'No app found for deep link, and web fallback failed.',
          );
        }
      } else {
        _showLaunchError('No app found to handle this deep link.');
      }
    } catch (_) {
      if (allowFallbackToWeb) {
        try {
          final fallback = Uri.parse(_normalizedInitialUrl());
          final launched = await launchUrl(
            fallback,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            _showLaunchError('Failed to open external browser.');
          }
        } catch (_) {
          _showLaunchError('Failed to open link.');
        }
      } else {
        _showLaunchError('Failed to open link.');
      }
    }
  }

  bool _isWebUri(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  void _showLaunchError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownUrl = _currentUrl.isNotEmpty ? _currentUrl : _initialUrl;

    return Scaffold(
      // 🔥 APP BAR WITH HIDDEN TITLE (only back button and actions)
      appBar: AppBar(
        // 🔥 NO TITLE - hide kiya
        title: null,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Optional: Add back button if needed
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
        ),
        actions: [
          if (_isInstagramPlatform)
            IconButton(
              onPressed: _resetInstagramSession,
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset Instagram session',
            ),
          IconButton(
            onPressed: _refreshCurrentUrl,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh link',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_platformName.toLowerCase() == 'tiktok')
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TikTok may block embedded WebView on some devices. If video does not load, use Open Externally then paste link.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_hasLoadError)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.58),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 34,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_platformName page not available in in-app browser',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastError.isNotEmpty
                            ? _lastError
                            : 'Network or site restriction in embedded WebView.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isTikTokPlatform
                              ? _pasteTikTokLinkFromClipboard
                              : _isInstagramPlatform
                              ? _pasteInstagramLinkFromClipboard
                              : _openCurrentInExternalApp,
                          icon: const Icon(Icons.paste),
                          label: Text(
                            _isTikTokPlatform
                                ? 'Paste TikTok Link'
                                : _isInstagramPlatform
                                ? 'Paste Instagram Link'
                                : 'Open Externally',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasLoadError = false;
                            _lastError = '';
                          });
                          _controller.loadRequest(
                            Uri.parse(_normalizedInitialUrl()),
                          );
                        },
                        child: const Text('Retry In-App'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Download button
          Positioned(
            bottom: 60,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _captureAndDownload,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
          ),
        ],
      ),
    );
  }
}