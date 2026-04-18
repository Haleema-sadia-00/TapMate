import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/Screen/home/other_user_profile_screen.dart';
import 'package:tapmate/Screen/home/storage_selection_dialog.dart';
import 'package:tapmate/Screen/services/platform_downloader.dart';
import 'package:tapmate/Screen/services/search_service.dart';
import '../../auth_provider.dart';
import '../../theme_provider.dart';
import 'package:tapmate/Screen/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchDiscoverScreen extends StatefulWidget {
  const SearchDiscoverScreen({super.key});

  @override
  State<SearchDiscoverScreen> createState() => _SearchDiscoverScreenState();
}

class _SearchDiscoverScreenState extends State<SearchDiscoverScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearching = false;
  bool _showResults = false;
  String _activeTab = 'all'; // 'all', 'users', 'videos'
  bool _isDownloading = false;

  // Data lists
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _trendingPosts = [];
  List<String> _trendingSearches = [];

  // Debounce for real-time search
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else if (_showResults) {
        setState(() {
          _showResults = false;
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isGuest) {
        _searchHistory = await _searchService.getSearchHistory();
      }

      _trendingPosts = await _searchService.getTrendingPosts();
      _trendingSearches = await _searchService.getTrendingSearches();

    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _showResults = true;
      _searchResults.clear();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isGuest) {
        await _searchService.saveSearchHistory(query);
        _searchHistory = await _searchService.getSearchHistory();
      }

      List<Map<String, dynamic>> allResults = [];

      if (_activeTab == 'all' || _activeTab == 'users') {
        final users = await _searchService.searchUsers(query);
        allResults.addAll(users);
      }

      if (_activeTab == 'all' || _activeTab == 'videos') {
        final posts = await _searchService.searchPosts(query);
        allResults.addAll(posts);
      }

      allResults.sort((a, b) {
        if (a['type'] == 'user' && b['type'] != 'user') return -1;
        if (a['type'] != 'user' && b['type'] == 'user') return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _searchResults = allResults;
        });
      }

    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showResults = false;
      _searchResults.clear();
      _activeTab = 'all';
    });
  }

  void _clearSearchHistory() async {
    try {
      await _searchService.clearSearchHistory();
      if (mounted) {
        setState(() {
          _searchHistory.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Search history cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  void _deleteSearchItem(String query) async {
    try {
      await _searchService.deleteSearchItem(query);
      if (mounted) {
        setState(() {
          _searchHistory.remove(query);
        });
      }
    } catch (e) {
      print('Error deleting search item: $e');
    }
  }

  // 🔥 REAL DOWNLOAD with Storage Selection
  void _downloadContent(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => StorageSelectionDialog(
        platformName: content['platform'] ?? 'Unknown',
        contentId: content['id'],
        contentTitle: content['title'] ?? content['caption'] ?? 'Unknown',
        onDeviceStorageSelected: (path, format, quality) {
          Navigator.pop(context);
          _startDownload(content, path, format, quality, true);
        },
        onAppStorageSelected: (format, quality) {
          Navigator.pop(context);
          _startDownload(content, null, format, quality, false);
        },
      ),
    );
  }

  // 🔥 FIXED: Direct download without DownloadProgressScreen
  Future<void> _startDownload(Map<String, dynamic> content, String? path, String format, String quality, bool isDeviceStorage) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final videoUrl = content['video_url'] ?? content['url'];
    final platform = content['platform'] ?? 'Unknown';
    final title = content['title'] ?? content['caption'] ?? '${platform} Video';

    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL not available'), backgroundColor: Colors.red),
      );
      setState(() => _isDownloading = false);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Starting download for "$title"...'),
          ],
        ),
      ),
    );

    try {
      final downloader = PlatformDownloader();

      final result = await downloader.downloadVideo(
        platformId: platform.toLowerCase(),
        videoUrl: videoUrl,
        videoTitle: title,
        format: format,
        quality: quality,
        customPath: path,
        onProgress: (progress) {
          print('Download progress: ${(progress.progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (mounted) Navigator.pop(context);

      if (result.success) {
        // Save to download history
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('download_history') ?? [];
        final newEntry = jsonEncode({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'platform': platform,
          'title': title,
          'filePath': result.filePath,
          'size': result.fileSize ?? 0,
          'timestamp': DateTime.now().toIso8601String(),
          'storageType': isDeviceStorage ? 'device' : 'app',
        });
        history.add(newEntry);
        await prefs.setStringList('download_history', history);

        if (mounted) {
          if (isDeviceStorage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Download saved to: ${path ?? "Selected folder"}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Download complete! View in Library')),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/download_library'),
                      child: const Text('VIEW', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: ${result.message}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _viewUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          userId: userId,
          userName: '',
          userAvatar: '👤',
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context, bool isGuest, bool isDarkMode) {
    final isLocked = isGuest && (label == 'Message' || label == 'Profile');

    return GestureDetector(
      onTap: isLocked
          ? () => _showLockedFeatureDialog(label)
          : () {
        if (label == 'Home') {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (label == 'Search') {
          Navigator.pushReplacementNamed(context, '/search');
        } else if (label == 'Feed') {
          Navigator.pushReplacementNamed(context, '/feed');
        } else if (label == 'Message') {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (label == 'Profile') {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : (isDarkMode ? Colors.grey[600] : Colors.grey),
                size: 24,
              ),
              if (isLocked)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.textMain : AppColors.lightSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 10,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : (isDarkMode ? Colors.grey[600] : Colors.grey),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGuest = authProvider.isGuest;
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : AppColors.lightSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.secondary, AppColors.primary],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (route) => false,
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.lightSurface,
                          size: 22,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _showResults ? "Search Results" : "Search",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_searchController.text.isNotEmpty) {
                            _performSearch(_searchController.text);
                          }
                        },
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.lightSurface,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Tabs
            if (_showResults)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _buildSearchTab('All', 'all'),
                    const SizedBox(width: 10),
                    _buildSearchTab('Users', 'users'),
                    const SizedBox(width: 10),
                    _buildSearchTab('Videos', 'videos'),
                  ],
                ),
              ),

            // Body Content
            Expanded(
              child: _showResults
                  ? _buildSearchResults(isGuest, isDarkMode)
                  : _buildDiscoverySection(isGuest, isDarkMode),
            ),

            // Bottom Navigation
            SafeArea(
              top: false,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightSurface,
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
                    _buildNavItem(Icons.home_rounded, 'Home', false, context, isGuest, isDarkMode),
                    _buildNavItem(Icons.search_rounded, 'Search', true, context, isGuest, isDarkMode),
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
    );
  }

  Widget _buildSearchTab(String label, String value) {
    bool isActive = _activeTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = value;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppColors.primary : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isGuest, bool isDarkMode) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search users, videos...",
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: isDarkMode ? AppColors.lightSurface : AppColors.textMain,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: AppColors.primary),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
          ),
        ),

        // Results List
        Expanded(
          child: _isSearching
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _searchResults.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
                const SizedBox(height: 20),
                Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Try a different search term',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final item = _searchResults[index];
              if (item['type'] == 'user') {
                return _buildUserResultCard(item, isGuest, isDarkMode);
              } else {
                return _buildVideoResultCard(item, isGuest, isDarkMode);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(bool isGuest, bool isDarkMode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search users, videos...",
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: isDarkMode ? AppColors.lightSurface : AppColors.textMain,
                      ),
                      onSubmitted: (value) => _performSearch(value),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20, color: AppColors.primary),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Searches
            if (!isGuest && _searchHistory.isNotEmpty) ...[
              _buildRecentSearchesSection(isDarkMode),
              const SizedBox(height: 20),
            ],

            // Trending Videos
            if (_trendingPosts.isNotEmpty) ...[
              _buildTrendingSection(isGuest, isDarkMode),
              const SizedBox(height: 20),
            ],

            // Trending Searches
            if (_trendingSearches.isNotEmpty) ...[
              _buildTrendingSearchesSection(isDarkMode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchesSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                ),
              ),
              if (_searchHistory.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ..._searchHistory.take(5).map((search) => _buildRecentSearchItem(search, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String search, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.text = search;
                });
                _performSearch(search);
              },
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      search,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _deleteSearchItem(search),
            child: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.grey[400] : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(bool isGuest, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Trending Videos",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _trendingPosts.length,
              itemBuilder: (context, index) {
                return _buildTrendingVideoCard(_trendingPosts[index], isGuest, isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSearchesSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Trending Searches",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trendingSearches.map((trend) {
              return _buildTrendingChip(trend, isDarkMode);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(String trend, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchController.text = trend;
        });
        _performSearch(trend);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Text(
          trend,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildUserResultCard(Map<String, dynamic> user, bool isGuest, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _viewUserProfile(user['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: user['profilePic'] != null && user['profilePic'].toString().isNotEmpty
                  ? NetworkImage(user['profilePic'])
                  : null,
              child: user['profilePic'] == null || user['profilePic'].toString().isEmpty
                  ? Text(
                user['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(fontSize: 20, color: AppColors.primary),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user['username'] ?? 'username'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user['bio'] != null && user['bio'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user['bio'],
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (user['isPrivate'] == true)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoResultCard(Map<String, dynamic> video, bool isGuest, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(
                      video['thumbnailUrl'] ?? video['thumbnail_url'] ?? 'https://picsum.photos/400/400',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(video['platform'] ?? 'YouTube'),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    video['platform'] ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.lightSurface,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video['caption'] ?? video['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _viewUserProfile(video['userId']),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        backgroundImage: video['user_profile_pic'] != null && video['user_profile_pic'].toString().isNotEmpty
                            ? NetworkImage(video['user_profile_pic'])
                            : null,
                        child: video['user_profile_pic'] == null || video['user_profile_pic'].toString().isEmpty
                            ? Text(
                          video['user_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary),
                        )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          video['user_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Download Button
                if (video['canDownload'] == true && !isGuest)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadContent(video),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        "Download",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.lightSurface,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingVideoCard(Map<String, dynamic> video, bool isGuest, bool isDarkMode) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    video['thumbnailUrl'] ?? video['thumbnail_url'] ?? 'https://picsum.photos/300/200',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['caption'] ?? video['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.lightSurface : AppColors.accent,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 10, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        video['likes']?.toString() ?? '0',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Locked'),
        content: Text('Sign up to access $feature and all premium features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Sign Up', style: TextStyle(color: AppColors.lightSurface)),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return AppColors.primary;
    }
  }
}