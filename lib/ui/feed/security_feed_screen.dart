import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../services/news_service.dart';
import '../../storage/hive_boxes.dart';

class SecurityFeedScreen extends StatefulWidget {
  const SecurityFeedScreen({super.key});
  @override
  State<SecurityFeedScreen> createState() => _SecurityFeedScreenState();
}

class _SecurityFeedScreenState extends State<SecurityFeedScreen> with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;

  // Filter States (Mapped to new Service Categories)
  bool _filterTHN = true;   // Now: Threat Intel
  bool _filterWired = true; // Now: Exploits & Malware
  bool _filterCisa = true;  // Now: Vulns & Mobile

  // Data Lists
  List<NewsItem> _liveNews = []; // From Internet
  List<NewsItem> _savedNews = []; // From Database
  List<NewsItem> _displayList = []; // What we actually show

  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadLiveNews();
    _loadSavedNews();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _searchQuery = ""; // Clear search on tab switch
        _searchCtrl.clear();
        _updateDisplayList();
      });
    }
  }

  // --- DATA LOADING ---

  Future<void> _loadLiveNews() async {
    setState(() => _isLoading = true);
    // Logic preserved: Passing the 3 booleans to the service
    final news = await _newsService.getThreats(
      showTHN: _filterTHN,
      showWired: _filterWired,
      showCisa: _filterCisa,
    );
    if (mounted) {
      setState(() {
        _liveNews = news;
        _updateDisplayList();
        _isLoading = false;
      });
    }
  }

  void _loadSavedNews() {
    // Ensuring we access the Hive box correctly via the static helper
    if (HiveBoxes.savedNews.isOpen) {
      final rawList = HiveBoxes.savedNews.values.toList();
      _savedNews = rawList.map((e) => NewsItem.fromMap(Map<dynamic, dynamic>.from(e))).toList();
      // Reverse to show newest saved first
      _savedNews = _savedNews.reversed.toList();
    }
  }

  void _updateDisplayList() {
    // 1. Choose Source (Live vs Saved)
    List<NewsItem> source = _tabController.index == 0 ? _liveNews : _savedNews;

    // 2. Apply Search
    if (_searchQuery.isEmpty) {
      _displayList = List.from(source);
    } else {
      _displayList = source.where((item) {
        return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  // --- ACTIONS ---

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _toggleBookmark(NewsItem item) {
    // Check if already saved (by title)
    final existingKey = HiveBoxes.savedNews.keys.firstWhere(
          (k) => HiveBoxes.savedNews.get(k)['title'] == item.title,
      orElse: () => null,
    );

    if (existingKey != null) {
      // Remove
      HiveBoxes.savedNews.delete(existingKey);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Saved Intel"), duration: Duration(milliseconds: 500)));
    } else {
      // Add
      HiveBoxes.savedNews.add(item.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Intel Saved to Database"),
              backgroundColor: CyberTheme.neonGreen, // ✅ Fixed Color
              duration: Duration(milliseconds: 500)
          )
      );
    }

    _loadSavedNews();
    if (_tabController.index == 1) _updateDisplayList(); // Refresh list immediately if on saved tab
    setState(() {}); // Refresh UI icons
  }

  bool _isBookmarked(NewsItem item) {
    return _savedNews.any((saved) => saved.title == item.title);
  }

  // --- FILTER SHEET LOGIC (RESTORED & UPDATED LABELS) ---

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface, // ✅ Fixed Color
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("FEED CONFIGURATION", style: TextStyle(color: CyberTheme.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5)), // ✅ Fixed Color
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              // Updated labels to reflect the NEW 15+ sources we added
              _buildFilterSwitch("Threat Intel (THN, Krebs, Unit42)", _filterTHN, (v) => setSheetState(() => _filterTHN = v)),
              _buildFilterSwitch("Exploits & Malware (DB, Bleeping)", _filterWired, (v) => setSheetState(() => _filterWired = v)),
              _buildFilterSwitch("Vulns & Mobile (CISA, NVD)", _filterCisa, (v) => setSheetState(() => _filterCisa = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CyberTheme.neonGreen, // ✅ Fixed Color
                      foregroundColor: Colors.black
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _loadLiveNews(); // RELOAD FEED WITH NEW FILTERS
                  },
                  child: const Text("APPLY & REFRESH", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSwitch(String title, bool isActive, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Switch(
        value: isActive,
        activeColor: CyberTheme.neonGreen, // ✅ Fixed Color
        inactiveTrackColor: Colors.grey.shade800,
        onChanged: onChanged,
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("GLOBAL INTEL", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CyberTheme.neonGreen, // ✅ Fixed Color
          labelColor: CyberTheme.neonGreen,     // ✅ Fixed Color
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "LIVE FEED"),
            Tab(text: "SAVED INTEL"),
          ],
        ),
        actions: [
          // 1. FILTER BUTTON
          IconButton(
            icon: const Icon(Icons.tune, color: CyberTheme.neonGreen), // ✅ Fixed Color
            onPressed: _showFilterSheet,
          ),
          // 2. REFRESH BUTTON
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadLiveNews,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _updateDisplayList();
              }),
              decoration: InputDecoration(
                hintText: _tabController.index == 0 ? "Search Live Threats..." : "Search Saved Intel...",
                hintStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.search, color: CyberTheme.neonGreen), // ✅ Fixed Color
                filled: true,
                fillColor: CyberTheme.surface, // ✅ Fixed Color
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading && _tabController.index == 0
                ? const Center(child: CircularProgressIndicator(color: CyberTheme.neonGreen)) // ✅ Fixed Color
                : _displayList.isEmpty
                ? Center(child: Text(_tabController.index == 0 ? "No Connection" : "No Saved Intel", style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _displayList.length,
              itemBuilder: (ctx, i) {
                final item = _displayList[i];
                bool showDateHeader = false;

                // Logic for Date Headers
                if (i == 0) {
                  showDateHeader = true;
                } else {
                  final prevItem = _displayList[i - 1];
                  // Safe substring check for standard RSS dates
                  if (item.date.length > 5 && prevItem.date.length > 5) {
                    if (item.date.substring(0, 5) != prevItem.date.substring(0, 5)) {
                      showDateHeader = true;
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader && _tabController.index == 0)
                      _buildDateHeader(item.date),

                    (item.isCritical)
                        ? _buildHeroCard(item)
                        : _buildStandardCard(item),

                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    // Tries to grab just the "Mon, 03 Feb" part safely
    String display = date.length >= 10 ? date.substring(0, 11).toUpperCase() : date.toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(display, style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(NewsItem item) {
    bool isSaved = _isBookmarked(item);
    return GestureDetector(
      onTap: () => _launchURL(item.link),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CyberTheme.surface, // ✅ Fixed Color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CyberTheme.dangerRed, width: 1.5), // ✅ Fixed Color
          boxShadow: [
            BoxShadow(color: CyberTheme.dangerRed.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 1) // ✅ Fixed Color
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: CyberTheme.dangerRed, size: 20), // ✅ Fixed Color
                const SizedBox(width: 8),
                const Text("CRITICAL THREAT", style: TextStyle(color: CyberTheme.dangerRed, fontWeight: FontWeight.bold, letterSpacing: 1)), // ✅ Fixed Color
                const Spacer(),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? CyberTheme.neonGreen : Colors.grey), // ✅ Fixed Color
                  onPressed: () => _toggleBookmark(item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: item.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: CyberTheme.dangerRed, borderRadius: BorderRadius.circular(4)), // ✅ Fixed Color
                child: Text(tag, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardCard(NewsItem item) {
    bool isSaved = _isBookmarked(item);
    return GestureDetector(
      onTap: () => _launchURL(item.link),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberTheme.surface, // ✅ Fixed Color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(item.source, style: const TextStyle(color: CyberTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12)), // ✅ Fixed Color
                ),
                Row(
                  children: [
                    Text(item.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _toggleBookmark(item),
                      child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? CyberTheme.neonGreen : Colors.grey, size: 20), // ✅ Fixed Color
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: item.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: CyberTheme.neonGreen.withValues(alpha: 0.1), // ✅ Fixed Color
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: CyberTheme.neonGreen.withValues(alpha: 0.3)) // ✅ Fixed Color
                  ),
                  child: Text(tag, style: const TextStyle(color: CyberTheme.neonGreen, fontSize: 10)), // ✅ Fixed Color
                )).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}