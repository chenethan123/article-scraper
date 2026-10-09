import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/article.dart';
import '../config/scraper_config.dart';
import '../utils/content_analyzer.dart';

class RssScraper {
  final http.Client _client = http.Client();
  final ContentAnalyzer _analyzer = ContentAnalyzer();

  Future<List<Article>> scrapeAllFeeds() async {
    List<Article> allArticles = [];
    
    for (var entry in ScraperConfig.rssFeeds.entries) {
      try {
        final articles = await scrapeFeed(entry.value, entry.key);
        allArticles.addAll(articles);
        
        // Rate limiting
        await Future.delayed(ScraperConfig.requestDelay);
      } catch (e) {
        print('Error scraping ${entry.key}: $e');
      }
    }
    
    return _filterAndRankArticles(allArticles);
  }

  Future<List<Article>> scrapeFeed(String feedUrl, String sourceName) async {
    try {
      final response = await _client.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent': 'ArticleScraper/1.0 (Financial News Aggregator)',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch RSS feed: ${response.statusCode}');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      
      List<Article> articles = [];
      
      for (var item in items.take(ScraperConfig.maxArticlesPerSource)) {
        try {
          final article = _parseRssItem(item, sourceName);
          if (article != null) {
            articles.add(article);
          }
        } catch (e) {
          print('Error parsing RSS item: $e');
        }
      }
      
      return articles;
    } catch (e) {
      print('Error scraping RSS feed $feedUrl: $e');
      return [];
    }
  }

  Article? _parseRssItem(XmlElement item, String sourceName) {
    final title = item.findElements('title').first.text.trim();
    final link = item.findElements('link').first.text.trim();
    final description = item.findElements('description').firstOrNull?.text.trim() ?? '';
    
    // Parse publication date
    DateTime publishedAt = DateTime.now();
    final pubDateElement = item.findElements('pubDate').firstOrNull;
    if (pubDateElement != null) {
      try {
        publishedAt = DateTime.parse(pubDateElement.text);
      } catch (e) {
        // Try alternative date formats
        try {
          publishedAt = _parseRssDate(pubDateElement.text);
        } catch (e) {
          // Use current time as fallback
        }
      }
    }

    // Extract author if available
    String? author;
    final authorElement = item.findElements('author').firstOrNull ??
                         item.findElements('dc:creator').firstOrNull;
    if (authorElement != null) {
      author = authorElement.text.trim();
    }

    // Clean and analyze content
    final cleanContent = _cleanHtmlContent(description);
    if (cleanContent.length < ScraperConfig.minContentLength) {
      return null;
    }

    final keywords = _analyzer.extractKeywords(title + ' ' + cleanContent);
    final relevanceScore = _analyzer.calculateRelevanceScore(
      title + ' ' + cleanContent,
      keywords,
    );

    return Article(
      title: title,
      content: cleanContent,
      url: link,
      source: sourceName,
      publishedAt: publishedAt,
      author: author,
      keywords: keywords,
      relevanceScore: relevanceScore,
    );
  }

  DateTime _parseRssDate(String dateString) {
    // Handle RFC 2822 format (common in RSS)
    final patterns = [
      RegExp(r'(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})'),
      RegExp(r'(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})'),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(dateString);
      if (match != null) {
        try {
          return DateTime.parse(dateString);
        } catch (e) {
          continue;
        }
      }
    }
    
    return DateTime.now();
  }

  String _cleanHtmlContent(String htmlContent) {
    // Remove HTML tags and decode entities
    return htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<Article> _filterAndRankArticles(List<Article> articles) {
    return articles
        .where((article) => 
            article.relevanceScore >= ScraperConfig.minRelevanceScore &&
            article.content.length >= ScraperConfig.minContentLength &&
            article.content.length <= ScraperConfig.maxContentLength)
        .toList()
      ..sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
  }

  void dispose() {
    _client.close();
  }
}
