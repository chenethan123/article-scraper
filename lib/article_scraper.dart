import 'dart:convert';
import 'dart:io';
import 'models/article.dart';
import 'services/rss_scraper.dart';
import 'config/scraper_config.dart';
import 'utils/content_analyzer.dart';

class ArticleScraper {
  final RssScraper _rssScraper = RssScraper();
  final ContentAnalyzer _analyzer = ContentAnalyzer();

  ArticleScraper();

  /// Scrape articles from RSS sources only (no NewsAPI)
  Future<List<Article>> scrapeAllSources({
    List<String>? specificTickers,
  }) async {
    List<Article> allArticles = [];

    print('Starting RSS-only article scraping...');

    // Scrape RSS feeds with MarketAI filtering
    print('Scraping RSS feeds with comprehensive financial filtering...');
    try {
      final rssArticles = await _rssScraper.scrapeAllFeeds();
      allArticles.addAll(rssArticles);
      print('Found ${rssArticles.length} articles from RSS feeds');
    } catch (e) {
      print('Error scraping RSS feeds: $e');
    }

    // Remove duplicates and sort by relevance
    final uniqueArticles = _removeDuplicates(allArticles);
    uniqueArticles.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    print('Total unique articles found: ${uniqueArticles.length}');
    return uniqueArticles;
  }

  /// Scrape articles for specific stock tickers (RSS-only)
  Future<List<Article>> scrapeForTickers(List<String> tickers) async {
    return scrapeAllSources(specificTickers: tickers);
  }

  /// Get articles filtered by relevance score (RSS-only)
  Future<List<Article>> getHighRelevanceArticles({
    double minScore = 0.5,
    int maxArticles = 50,
  }) async {
    final articles = await scrapeAllSources();
    return articles
        .where((article) => article.relevanceScore >= minScore)
        .take(maxArticles)
        .toList();
  }

  /// Export articles to JSON file (compatible with MarketAI)
  Future<void> exportToJson(List<Article> articles, String filePath) async {
    final jsonData = {
      'timestamp': DateTime.now().toIso8601String(),
      'total_articles': articles.length,
      'articles': articles.map((article) => article.toJson()).toList(),
    };

    final file = File(filePath);
    await file.writeAsString(json.encode(jsonData));
    print('Exported ${articles.length} articles to $filePath');
  }

  /// Get articles summary for quick overview
  Map<String, dynamic> getArticlesSummary(List<Article> articles) {
    final sourceCount = <String, int>{};
    final keywordCount = <String, int>{};
    double totalRelevance = 0;

    for (final article in articles) {
      sourceCount[article.source] = (sourceCount[article.source] ?? 0) + 1;
      totalRelevance += article.relevanceScore;
      
      for (final keyword in article.keywords) {
        keywordCount[keyword] = (keywordCount[keyword] ?? 0) + 1;
      }
    }

    final topKeywords = keywordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_articles': articles.length,
      'average_relevance': articles.isNotEmpty ? totalRelevance / articles.length : 0,
      'sources': sourceCount,
      'top_keywords': topKeywords.take(10).map((e) => {
        'keyword': e.key,
        'count': e.value,
      }).toList(),
      'date_range': articles.isNotEmpty ? {
        'earliest': articles.map((a) => a.publishedAt).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
        'latest': articles.map((a) => a.publishedAt).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
      } : null,
    };
  }

  List<Article> _removeDuplicates(List<Article> articles) {
    final seen = <String>{};
    return articles.where((article) {
      final key = '${article.title.toLowerCase()}_${article.source}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
  }

  void dispose() {
    _rssScraper.dispose();
  }
}
