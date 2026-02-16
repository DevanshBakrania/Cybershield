import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

import '../../core/theme.dart';
import '../../services/news_service.dart';
import '../../storage/hive_boxes.dart';

class SecurityFeedScreen extends StatefulWidget {
  final String username;

  const SecurityFeedScreen({
    super.key,
    required this.username,
  });

  @override
  State<SecurityFeedScreen> createState() => _SecurityFeedScreenState();
}

class _SecurityFeedScreenState extends State<SecurityFeedScreen>
    with SingleTickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;

  late Box _savedNewsBox;

  // Filter States
  bool _filterTHN = true;
  bool _filterWired = true;
  bool _filterCisa = true;

  // Data Lists
  List<NewsItem> _liveNews = [];
  List<NewsItem> _savedNews = [];
  List<NewsItem> _displayList = [];

  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // ✅ USER-SCOPED BOX
    _savedNewsBox = HiveBoxes.getSavedNews(widget.username);

    _loadLiveNews();
    _loadSavedNews();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _searchQuery = "";
        _searchCtrl.clear();
        _updateDisplayList();
      });
    }
  }

  // ---------------- DATA ----------------

  Future<void> _loadLiveNews() async {
    setState(() => _isLoading = true);

    final news = await _newsService.getThreats(
      showTHN: _filterTHN,
      showWired: _filterWired,
      showCisa: _filterCisa,
    );

    if (!mounted) return;

    setState(() {
      _liveNews = news;
      _updateDisplayList();
      _isLoading = false;
    });
  }

  void _loadSavedNews() {
    if (!_savedNewsBox.isOpen) return;

    final rawList = _savedNewsBox.values.toList();

    _savedNews = rawList
        .map((e) => NewsItem.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  void _updateDisplayList() {
    final source =
        _tabController.index == 0 ? _liveNews : _savedNews;

    if (_searchQuery.isEmpty) {
      _displayList = List.from(source);
    } else {
      _displayList = source
          .where((item) =>
              item.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  // ---------------- ACTIONS ----------------

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toggleBookmark(NewsItem item) {
    final existingKey = _savedNewsBox.keys.firstWhere(
      (k) => _savedNewsBox.get(k)?['title'] == item.title,
      orElse: () => null,
    );

    if (existingKey != null) {
      _savedNewsBox.delete(existingKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Removed from Saved Intel"),
          duration: Duration(milliseconds: 500),
        ),
      );
    } else {
      _savedNewsBox.add(item.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Intel Saved to Database"),
          backgroundColor: CyberTheme.neonGreen,
          duration: Duration(milliseconds: 500),
        ),
      );
    }

    _loadSavedNews();
    if (_tabController.index == 1) {
      _updateDisplayList();
    }
    setState(() {});
  }

  bool _isBookmarked(NewsItem item) {
    return _savedNews.any((saved) => saved.title == item.title);
  }

  // ---------------- FILTER SHEET ----------------

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CyberTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Text(
                    "FEED CONFIGURATION",
                    style: TextStyle(
                      color: CyberTheme.neonGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFilterSwitch(
                "Threat Intel (THN, Krebs, Unit42)",
                _filterTHN,
                (v) => setSheetState(() => _filterTHN = v),
              ),
              _buildFilterSwitch(
                "Exploits & Malware (DB, Bleeping)",
                _filterWired,
                (v) => setSheetState(() => _filterWired = v),
              ),
              _buildFilterSwitch(
                "Vulns & Mobile (CISA, NVD)",
                _filterCisa,
                (v) => setSheetState(() => _filterCisa = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.neonGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _loadLiveNews();
                  },
                  child: const Text(
                    "APPLY & REFRESH",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSwitch(
    String title,
    bool isActive,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      trailing: Switch(
        value: isActive,
        activeThumbColor: CyberTheme.neonGreen,
        inactiveTrackColor: Colors.grey.shade800,
        onChanged: onChanged,
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("GLOBAL INTEL", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CyberTheme.neonGreen,
          labelColor: CyberTheme.neonGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "LIVE FEED"),
            Tab(text: "SAVED INTEL"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: CyberTheme.neonGreen),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadLiveNews,
          ),
        ],
      ),
      body: Column(
        children: [
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
                hintText: _tabController.index == 0
                    ? "Search Live Threats..."
                    : "Search Saved Intel...",
                filled: true,
                fillColor: CyberTheme.surface,
                prefixIcon: const Icon(Icons.search,
                    color: CyberTheme.neonGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _tabController.index == 0
                ? const Center(
                    child: CircularProgressIndicator(
                        color: CyberTheme.neonGreen))
                : _displayList.isEmpty
                    ? Center(
                        child: Text(
                          _tabController.index == 0
                              ? "No Connection"
                              : "No Saved Intel",
                          style:
                              const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: _displayList.length,
                        itemBuilder: (ctx, i) {
                          final item = _displayList[i];
                          return Column(
                            children: [
                              item.isCritical
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

  // ---------------- CARDS ----------------

  Widget _buildHeroCard(NewsItem item) {
    final isSaved = _isBookmarked(item);

    return GestureDetector(
      onTap: () => _launchURL(item.link),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CyberTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: CyberTheme.dangerRed, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: CyberTheme.dangerRed),
                const SizedBox(width: 8),
                const Text(
                  "CRITICAL THREAT",
                  style: TextStyle(
                      color: CyberTheme.dangerRed,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: isSaved
                        ? CyberTheme.neonGreen
                        : Colors.grey,
                  ),
                  onPressed: () => _toggleBookmark(item),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardCard(NewsItem item) {
    final isSaved = _isBookmarked(item);

    return GestureDetector(
      onTap: () => _launchURL(item.link),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CyberTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: Icon(
                isSaved
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color:
                    isSaved ? CyberTheme.neonGreen : Colors.grey,
              ),
              onPressed: () => _toggleBookmark(item),
            ),
          ],
        ),
      ),
    );
  }
}
