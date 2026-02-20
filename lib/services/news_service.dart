import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';

class NewsItem {
  final String title;
  final String link;
  final String date;
  final DateTime parsedDate;
  final String source;
  final String category; // ✨ NEW: Tracks the feed category
  final List<String> tags;
  final bool isCritical;

  NewsItem({
    required this.title,
    required this.link,
    required this.date,
    required this.parsedDate,
    required this.source,
    required this.category, // ✨ NEW
    required this.tags,
    this.isCritical = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'date': date,
      'source': source,
      'category': category, // ✨ NEW
      'tags': tags,
      'isCritical': isCritical,
    };
  }

  factory NewsItem.fromMap(Map<dynamic, dynamic> map) {
    return NewsItem(
      title: map['title'],
      link: map['link'],
      date: map['date'],
      parsedDate: DateTime.now(),
      source: map['source'],
      category: map['category'] ?? 'General Intel', // ✨ NEW: Fallback for older items
      tags: List<String>.from(map['tags']),
      isCritical: map['isCritical'] ?? false,
    );
  }
}

class NewsService {
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

  final List<String> _criticalWords = [
    "Zero-Day", "0-Day", "Critical", "Ransomware", "Exploit",
    "Breach", "Active Attack", "Unpatched", "RCE"
  ];

  final List<String> _keywords = [
    "Android", "iOS", "Malware", "Phishing", "Trojan",
    "Spyware", "Linux", "Windows", "WebView", "Bluetooth",
    "Crypto", "Banking", "Botnet", "CVE"
  ];

  Future<List<NewsItem>> getThreats({
    bool showTHN = true,
    bool showWired = true,
    bool showCisa = true,
  }) async {
    List<NewsItem> allNews = [];
    List<Future> tasks = [];

    // ✨ NEW: Passing the exact category name to group them by
    if (showTHN) {
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![0], "THN", "Threat Intel", allNews));
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![1], "KREBS", "Threat Intel", allNews));
      tasks.add(_fetchFeed(_feedCategories["Threat Intel"]![3], "UNIT42", "Threat Intel", allNews));
    }

    if (showWired) {
      tasks.add(_fetchFeed(_feedCategories["Malware"]![0], "BLEEPING", "Exploits & Malware", allNews));
      tasks.add(_fetchFeed(_feedCategories["Exploits"]![0], "DB-EXPLOIT", "Exploits & Malware", allNews));
      tasks.add(_fetchFeed(_feedCategories["Exploits"]![2], "ZDI", "Exploits & Malware", allNews));
    }

    if (showCisa) {
      tasks.add(_fetchFeed(_feedCategories["Vulnerabilities"]![0], "CISA", "Vulns & Mobile", allNews));
      tasks.add(_fetchFeed(_feedCategories["Mobile"]![0], "PROJECT0", "Vulns & Mobile", allNews));
      tasks.add(_fetchFeed(_feedCategories["Mobile"]![1], "ZIMPERIUM", "Vulns & Mobile", allNews));
    }

    await Future.wait(tasks);
    return allNews;
  }

  // ✨ NEW: Added categoryName parameter
  Future<void> _fetchFeed(String url, String sourceName, String categoryName, List<NewsItem> targetList) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
          "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        var items = document.findAllElements('item');
        if (items.isEmpty) items = document.findAllElements('entry');

        for (var node in items.take(10)) {
          String title = node.findElements('title').isNotEmpty ? node.findElements('title').single.text : "Unknown Title";
          String link = "";

          if (node.findElements('link').isNotEmpty) {
            var linkNode = node.findElements('link').first;
            link = linkNode.getAttribute('href') ?? linkNode.text;
          }

          String pubDateString = "";
          if (node.findElements('pubDate').isNotEmpty) pubDateString = node.findElements('pubDate').single.text;
          else if (node.findElements('updated').isNotEmpty) pubDateString = node.findElements('updated').single.text;
          else if (node.findElements('dc:date').isNotEmpty) pubDateString = node.findElements('dc:date').single.text;

          DateTime parsedDate = _parseFlexibleDate(pubDateString);

          final now = DateTime.now();
          final difference = DateTime(now.year, now.month, now.day).difference(DateTime(parsedDate.year, parsedDate.month, parsedDate.day)).inDays;

          String displayDate;
          if (difference == 0) {
            displayDate = "Today";
          } else if (difference == 1) {
            displayDate = "Yesterday";
          } else {
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            displayDate = "${months[parsedDate.month - 1]} ${parsedDate.day.toString().padLeft(2, '0')}, ${parsedDate.year}";
          }

          List<String> detectedTags = [];
          bool critical = false;

          for (var word in _criticalWords) {
            if (title.toLowerCase().contains(word.toLowerCase())) {
              critical = true;
              detectedTags.add(word.toUpperCase());
            }
          }
          for (var word in _keywords) {
            if (title.toLowerCase().contains(word.toLowerCase())) detectedTags.add(word.toUpperCase());
          }

          if (sourceName == "CISA" || sourceName == "DB-EXPLOIT") detectedTags.add(sourceName);

          if (title.isNotEmpty && link.isNotEmpty) {
            targetList.add(NewsItem(
              title: title.trim(),
              link: link.trim(),
              date: displayDate,
              parsedDate: parsedDate,
              source: sourceName,
              category: categoryName, // ✨ NEW: Saving the category here
              tags: detectedTags.toSet().toList(),
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

  DateTime _parseFlexibleDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
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