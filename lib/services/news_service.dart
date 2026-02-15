import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';

class NewsItem {
  final String title;
  final String link;
  final String date; // Display date e.g. "Mon, 03 Feb"
  final DateTime parsedDate; // For sorting
  final String source;
  final List<String> tags;
  final bool isCritical; // NEW: Determines Red Card

  NewsItem({
    required this.title,
    required this.link,
    required this.date,
    required this.parsedDate,
    required this.source,
    required this.tags,
    this.isCritical = false,
  });

  // Helper to save to Database
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'date': date,
      'source': source,
      'tags': tags,
      'isCritical': isCritical,
    };
  }

  // Helper to load from Database
  factory NewsItem.fromMap(Map<dynamic, dynamic> map) {
    return NewsItem(
      title: map['title'],
      link: map['link'],
      date: map['date'],
      parsedDate: DateTime.now(), // Fallback for saved items
      source: map['source'],
      tags: List<String>.from(map['tags']),
      isCritical: map['isCritical'] ?? false,
    );
  }
}

class NewsService {
  // 🌍 MASTER FEED LIST
  static const Map<String, List<String>> _feedCategories = {
    "Threat Intel": [
      "https://feeds.feedburner.com/TheHackersNews",
      "https://krebsonsecurity.com/feed/",
      "https://www.darkreading.com/rss.xml",
      "https://unit42.paloaltonetworks.com/feed/",
      "https://www.sentinelone.com/labs/feed/",
    ],
    "Exploits": [
      "https://www.exploit-db.com/rss.xml",
      "https://packetstormsecurity.com/feeds/exploits/",
      "https://www.zerodayinitiative.com/rss/published/",
    ],
    "Malware": [
      "https://www.bleepingcomputer.com/feed/",
      "https://securelist.com/feed/",
      "https://blog.malwarebytes.com/feed/",
      "https://www.trendmicro.com/en_us/research/rss.xml",
    ],
    "Vulnerabilities": [
      "https://www.cisa.gov/uscert/ncas/alerts.xml",
      "https://nvd.nist.gov/feeds/xml/cve/misc/nvd-rss.xml",
      "https://msrc.microsoft.com/update-guide/rss",
    ],
    "Mobile": [
      "https://googleprojectzero.blogspot.com/feeds/posts/default",
      "https://blog.zimperium.com/feed/",
      "https://blog.lookout.com/rss",
    ],
  };

  // 🚨 Critical Keywords (Triggers Red Border)
  final List<String> _criticalWords = [
    "Zero-Day", "0-Day", "Critical", "Ransomware", "Exploit",
    "Breach", "Active Attack", "Unpatched", "RCE"
  ];

  // 🏷️ General Tags (For badges)
  final List<String> _keywords = [
    "Android", "iOS", "Malware", "Phishing", "Trojan",
    "Spyware", "Linux", "Windows", "WebView", "Bluetooth",
    "Crypto", "Banking", "Botnet", "CVE"
  ];

  /// Fetches threats.
  /// Note: The booleans (showTHN, etc.) are kept for backward compatibility
  /// with your UI, but we map them to our broader categories.
  Future<List<NewsItem>> getThreats({
    bool showTHN = true, // Maps to Threat Intel
    bool showWired = true, // Maps to Exploits/Malware
    bool showCisa = true, // Maps to Vulns/Mobile
  }) async {
    List<NewsItem> allNews = [];
    List<Future> tasks = [];

    // 1. Build list of URLs to fetch based on filters
    // We select the best 2-3 sources from each category to prevent timeouts
    if (showTHN) {
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![0], "THN", allNews));
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![1], "KREBS", allNews));
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![3], "UNIT42", allNews));
    }

    if (showWired) {
      tasks.add(_fetchFeed(_feedCategories["Malware"]![0], "BLEEPING", allNews));
      tasks.add(_fetchFeed(_feedCategories["Exploits"]![0], "DB-EXPLOIT", allNews));
      tasks.add(_fetchFeed(_feedCategories["Exploits"]![2], "ZDI", allNews));
    }

    if (showCisa) {
      tasks.add(_fetchFeed(_feedCategories["Vulnerabilities"]![0], "CISA", allNews));
      tasks.add(_fetchFeed(_feedCategories["Mobile"]![0], "PROJECT0", allNews));
      tasks.add(_fetchFeed(_feedCategories["Mobile"]![1], "ZIMPERIUM", allNews));
    }

    // 2. Execute all fetches in parallel
    await Future.wait(tasks);

    // 3. Sort by Date (Newest First)
    // We use the parsedDate field for accurate sorting
    allNews.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));

    return allNews;
  }

  Future<void> _fetchFeed(String url, String sourceName, List<NewsItem> targetList) async {
    try {
      // FIX: Full Browser Headers to bypass Firewall (Error 403)
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        },
      ).timeout(const Duration(seconds: 6)); // Timeout to prevent hanging

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);

        // Handle both RSS <item> and Atom <entry>
        var items = document.findAllElements('item');
        if (items.isEmpty) {
          items = document.findAllElements('entry');
        }

        // Limit to 10 items per source for faster loading
        for (var node in items.take(10)) {
          String title = node.findElements('title').isNotEmpty ? node.findElements('title').single.text : "Unknown Title";
          String link = "";

          // Link parsing (Handle Atom vs RSS)
          if (node.findElements('link').isNotEmpty) {
            var linkNode = node.findElements('link').first;
            // Atom feeds often have <link href="..." />
            link = linkNode.getAttribute('href') ?? linkNode.text;
          }

          // Date Parsing
          String pubDateString = "";
          if (node.findElements('pubDate').isNotEmpty) {
            pubDateString = node.findElements('pubDate').single.text;
          } else if (node.findElements('updated').isNotEmpty) {
            pubDateString = node.findElements('updated').single.text;
          } else if (node.findElements('dc:date').isNotEmpty) {
            pubDateString = node.findElements('dc:date').single.text;
          }

          // Parse Date for Sorting
          DateTime parsedDate = DateTime.now();
          try {
            parsedDate = _parseFlexibleDate(pubDateString);
          } catch (e) {
            // Keep default now() if parsing fails
          }

          // Clean Date String for Display (e.g., "Tue, 04 Feb")
          String displayDate = pubDateString;
          if (displayDate.length > 16) {
            // Basic cleanup for RSS standard format
            displayDate = displayDate.substring(0, 11);
          }

          // Logic: Auto-Tagging & Severity
          List<String> detectedTags = [];
          bool critical = false;

          // Check Critical
          for (var word in _criticalWords) {
            if (title.toLowerCase().contains(word.toLowerCase())) {
              critical = true;
              detectedTags.add(word.toUpperCase());
            }
          }
          // Check General Tags
          for (var word in _keywords) {
            if (title.toLowerCase().contains(word.toLowerCase())) {
              detectedTags.add(word.toUpperCase());
            }
          }

          // Source Tag
          if (sourceName == "CISA" || sourceName == "DB-EXPLOIT") {
            detectedTags.add(sourceName);
          }

          if (title.isNotEmpty && link.isNotEmpty) {
            targetList.add(NewsItem(
              title: title.trim(),
              link: link.trim(),
              date: displayDate,
              parsedDate: parsedDate,
              source: sourceName,
              tags: detectedTags.toSet().toList(), // Remove duplicates
              isCritical: critical,
            ));
          }
        }
      } else {
        debugPrint("⚠️ BLOCKED: $sourceName returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ ERROR ($sourceName): $e");
    }
  }

  // Improved Date Parser to handle multiple RSS/Atom formats
  DateTime _parseFlexibleDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      // 1. Try ISO 8601 (Atom) - e.g. 2023-10-05T14:30:00Z
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // 2. Try RFC 1123 (RSS) - e.g. Mon, 03 Feb 2026 12:00:00 GMT
        // We manually parse the parts because HttpDate can be strict
        var parts = dateStr.split(' ');
        if (parts.length >= 4) {
          int day = int.parse(parts[1]);
          int month = _getMonthIndex(parts[2]);
          int year = int.parse(parts[3]);
          return DateTime(year, month, day);
        }
      } catch (e) {
        // Fail silently
      }
    }
    return DateTime.now();
  }

  int _getMonthIndex(String m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    int index = months.indexOf(m);
    return index != -1 ? index + 1 : 1;
  }
}