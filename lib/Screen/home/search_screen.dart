import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapmate/auth_provider.dart';
import 'storage_selection_dialog.dart';
import 'download_progress_screen.dart';

class SearchDiscoverScreen extends StatefulWidget {
  const SearchDiscoverScreen({super.key});

  @override
  State<SearchDiscoverScreen> createState() => _SearchDiscoverScreenState();
}

class _SearchDiscoverScreenState extends State<SearchDiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  // State variables
  String _selectedPlatform = "All";
  bool _isSearching = false;
  bool _showResults = false;

  // Platform options
  final List<String> platforms = ["All", "YouTube", "TikTok", "Instagram", "Facebook", "Twitter"];

  // Sample trending searches
  final List<String> trending = [
    "Cooking tutorials",
    "Travel vlogs",
    "Music videos",
    "Dance challenges",
    "Gaming highlights",
    "Fitness workouts",
  ];

  // Sample search results
  final List<Map<String, dynamic>> _searchResults = [
    {
      "id": "1",
      "title": "Cooking Pasta Tutorial",
      "channel": "Chef's Kitchen",
      "views": "1.2M views",
      "duration": "8:45",
      "platform": "YouTube",
      "thumbnail": "👨‍🍳",
      "uploaded": "2 days ago",
      "url": "https://youtube.com/video1",
      "canDownload": true,
    },
    {
      "id": "2",
      "title": "Morning Workout Routine",
      "channel": "Fitness Pro",
      "views": "850K views",
      "duration": "5:30",
      "platform": "TikTok",
      "thumbnail": "💪",
      "uploaded": "1 day ago",
      "url": "https://tiktok.com/video2",
      "canDownload": true,
    },
    {
      "id": "3",
      "title": "Tokyo Travel Vlog 2024",
      "channel": "Travel Diary",
      "views": "2.5M views",
      "duration": "15:20",
      "platform": "YouTube",
      "thumbnail": "✈️",
      "uploaded": "1 week ago",
      "url": "https://youtube.com/video3",
      "canDownload": true,
    },
    {
      "id": "4",
      "title": "Music Mix 2024",
      "channel": "DJ Sounds",
      "views": "3.1M views",
      "duration": "12:45",
      "platform": "Instagram",
      "thumbnail": "🎵",
      "uploaded": "3 days ago",
      "url": "https://instagram.com/video4",
      "canDownload": true,
    },
  ];

  // Trending videos for discovery section
  final List<Map<String, dynamic>> _trendingVideos = [
    {
      "id": "t1",
      "title": "Dance Challenge Viral",
      "channel": "Dance Crew",
      "views": "5.2M views",
      "duration": "1:45",
      "platform": "TikTok",
      "thumbnail": "💃",
      "trending": true,
      "canDownload": true,
    },
    {
      "id": "t2",
      "title": "Tech Review Latest Phone",
      "channel": "Tech Guru",
      "views": "1.8M views",
      "duration": "12:30",
      "platform": "YouTube",
      "thumbnail": "📱",
      "trending": true,
      "canDownload": true,
    },
    {
      "id": "t3",
      "title": "Funny Cat Compilation",
      "channel": "Animal Planet",
      "views": "4.3M views",
      "duration": "7:15",
      "platform": "Instagram",
      "thumbnail": "🐱",
      "trending": true,
      "canDownload": true,
    },
  ];

  // Search history
  List<String> _searchHistory = ["Workout routine", "Cooking pasta", "Travel vlog Paris"];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isGuest = authProvider.isGuest;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Gradient Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B1C32),
                    Color(0xFF6A1E55),
                    Color(0xFFA64D79),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B1C32).withOpacity(0.3),
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
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _showResults ? "Search Results" : "Search & Discover",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Platform Filter Chips - FIXED height
            if (!_showResults)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                height: 50, // Reduced height
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: platforms.map((platform) {
                    bool isSelected = _selectedPlatform == platform;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(platform),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPlatform = platform;
                          });
                          if (_searchController.text.isNotEmpty) {
                            _performSearch(_searchController.text);
                          }
                        },
                        selectedColor: const Color(0xFFA64D79),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF3B1C32),
                          fontSize: 13, // Reduced font size
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFA64D79)
                                : Colors.grey[300]!,
                            width: isSelected ? 0 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Body Content - FIXED layout
            Expanded(
              child: _showResults
                  ? _buildSearchResults(isGuest)
                  : _buildDiscoverySection(isGuest),
            ),

            // Bottom Navigation Bar - FIXED with SafeArea
            SafeArea(
              top: false,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                    _buildNavItem(Icons.home_rounded, 'Home', false, context, isGuest),
                    _buildNavItem(Icons.explore_rounded, 'Discover', true, context, isGuest),
                    _buildNavItem(Icons.feed_rounded, 'Feed', false, context, isGuest),
                    _buildNavItem(Icons.message_rounded, 'Message', false, context, isGuest),
                    _buildNavItem(Icons.person_rounded, 'Profile', false, context, isGuest),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search Results View
  Widget _buildSearchResults(bool isGuest) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF6A1E55)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search videos, channels...",
                      hintStyle: TextStyle(color: Colors.black38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _showResults = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),

        // Search Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Results for '${_searchController.text}'",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B1C32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_selectedPlatform != "All")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA64D79).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPlatform,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA64D79),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Search Results List
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFA64D79)))
              : _searchResults.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 20),
                const Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B1C32),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Try a different search term',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final video = _searchResults[index];
              return _buildVideoResultCard(video, isGuest, index);
            },
          ),
        ),
      ],
    );
  }

  // Discovery Section
  Widget _buildDiscoverySection(bool isGuest) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF6A1E55)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search videos, channels...",
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) => _performSearch(value),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trending Now Section
            _buildTrendingSection(isGuest),
            const SizedBox(height: 20),

            // Recent Searches
            _buildRecentSearchesSection(),
            const SizedBox(height: 20),

            // Trending Searches
            _buildTrendingSearchesSection(),
            const SizedBox(height: 20),

            // Browse Categories
            _buildCategoriesSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Trending Section
  Widget _buildTrendingSection(bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFA64D79), size: 22),
              SizedBox(width: 8),
              Text(
                "Trending Videos",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B1C32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _trendingVideos.length,
              itemBuilder: (context, index) {
                return _buildTrendingVideoCard(_trendingVideos[index], isGuest);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Recent Searches Section
  Widget _buildRecentSearchesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B1C32),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchHistory.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Search history cleared"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  "Clear",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA64D79),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_searchHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No recent searches",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Column(
              children: _searchHistory.map((search) {
                return _buildRecentSearchItem(search);
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Trending Searches Section
  Widget _buildTrendingSearchesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFA64D79), size: 22),
              SizedBox(width: 8),
              Text(
                "Trending Searches",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B1C32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: trending.map((trend) {
              return _buildTrendingChip(trend);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Categories Section
  Widget _buildCategoriesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Browse Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B1C32),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _CategoryCard(Icons.music_note_rounded, "Music", "1.2k"),
                _CategoryCard(Icons.sports_esports_rounded, "Gaming", "890k"),
                _CategoryCard(Icons.book_rounded, "Education", "650k"),
                _CategoryCard(Icons.movie_filter_rounded, "Movies", "1.8k"),
                _CategoryCard(Icons.fitness_center_rounded, "Fitness", "540k"),
                _CategoryCard(Icons.travel_explore_rounded, "Travel", "720k"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Video Result Card
  Widget _buildVideoResultCard(Map<String, dynamic> video, bool isGuest, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3B1C32).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with duration
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFA64D79).withOpacity(0.3),
                      const Color(0xFFA64D79).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    video["thumbnail"] as String,
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    video["duration"] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPlatformColor(video["platform"] as String),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    video["platform"] as String,
                    style: const TextStyle(
                      color: Colors.white,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video["title"] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B1C32),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        video["channel"] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video["views"] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        video["uploaded"] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Download Button
                if (video["canDownload"] == true)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGuest
                          ? () => _showGuestDownloadDialog(context)
                          : () => _showDownloadDialog(video),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        "Download",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA64D79),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "Download unavailable for this video",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
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

  // Trending Video Card
  Widget _buildTrendingVideoCard(Map<String, dynamic> video, bool isGuest) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3B1C32).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFA64D79).withOpacity(0.3),
                  const Color(0xFFA64D79).withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                video["thumbnail"] as String,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video["title"] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B1C32),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  video["channel"] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video["duration"] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Trending",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Download Button
                if (video["canDownload"] == true)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isGuest
                          ? () => _showGuestDownloadDialog(context)
                          : () => _showDownloadDialog(video),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA64D79),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Download",
                        style: TextStyle(fontSize: 12),
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

  // Helper Widgets
  Widget _buildRecentSearchItem(String search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
                  const Icon(Icons.history, size: 18, color: Color(0xFF6A1E55)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      search,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B1C32),
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
            onTap: () {
              setState(() {
                _searchHistory.remove(search);
              });
            },
            child: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingChip(String trend) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFA64D79), width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Text(
          trend,
          style: const TextStyle(
            color: Color(0xFF6A1E55),
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context, bool isGuest) {
    final isLocked = isGuest && (label == 'Message' || label == 'Profile');

    return GestureDetector(
      onTap: isLocked
          ? () => _showLockedFeatureDialog(context, label)
          : () {
        if (label == "Home") {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (label == "Discover") {
          Navigator.pushReplacementNamed(context, '/search');
        } else if (label == "Feed") {
          Navigator.pushReplacementNamed(context, '/feed');
        } else if (label == "Message") {
          Navigator.pushReplacementNamed(context, '/chat');
        } else if (label == "Profile") {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFA64D79) : Colors.grey,
                size: 24,
              ),
              if (isLocked)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
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
              color: isActive ? const Color(0xFFA64D79) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Functions
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Add to search history
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSearching = false;
    });
  }

  void _showDownloadDialog(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => StorageSelectionDialog(
        platformName: video["platform"] as String,
        contentId: video["id"] as String,
        contentTitle: video["title"] as String,
        onDeviceStorageSelected: (path, format, quality) {
          Navigator.pop(context);
          _startDownload(video, path, format, quality, true);
        },
        onAppStorageSelected: (format, quality) {
          Navigator.pop(context);
          _startDownload(video, null, format, quality, false);
        },
      ),
    );
  }

  void _startDownload(Map<String, dynamic> video, String? path, String format, String quality, bool isDeviceStorage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProgressScreen(
          platformName: video["platform"] as String,
          contentTitle: '${video["title"]} ($format - $quality)',
          storagePath: path,
          isDeviceStorage: isDeviceStorage,
          fromPlatformScreen: false, // ✅ Add this
          sourcePlatform: 'search',
        ),
      ),
    );
  }

  void _showGuestDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text('Please sign in to download videos. Guest users can only browse content.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA64D79),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedFeatureDialog(BuildContext context, String feature) {
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
              backgroundColor: const Color(0xFFA64D79),
            ),
            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'tiktok': return const Color(0xFF000000);
      case 'instagram': return const Color(0xFFE4405F);
      case 'facebook': return const Color(0xFF1877F2);
      case 'twitter': return const Color(0xFF1DA1F2);
      default: return const Color(0xFFA64D79);
    }
  }
}

// Reusable Widgets
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;

  const _CategoryCard(this.icon, this.title, this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: const Color(0xFFA64D79),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B1C32),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "$count videos",
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6A1E55),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}