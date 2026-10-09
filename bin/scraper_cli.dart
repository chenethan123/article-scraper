import 'dart:io';
import 'package:args/args.dart';
import 'package:article_scraper/article_scraper.dart';
import 'package:article_scraper/exports/sheets_exporter.dart';
import 'package:article_scraper/models/article.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output file path for JSON export')
    ..addOption('tickers', help: 'Comma-separated list of stock tickers to focus on')
    ..addOption('min-score', help: 'Minimum relevance score (0.0-1.0)', defaultsTo: '0.3')
    ..addOption('max-articles', help: 'Maximum number of articles to return', defaultsTo: '100')
    ..addOption('sheet-id',
        help: 'Google Sheet ID to append articles to (or set GOOGLE_SHEET_ID)')
    ..addOption('credentials',
        help: 'Service account JSON key file (or set GOOGLE_SERVICE_ACCOUNT_FILE)',
        defaultsTo: 'service_account.json')
    ..addOption('worksheet', help: 'Worksheet (tab) name', defaultsTo: 'Articles')
    ..addFlag('summary', abbr: 's', help: 'Show summary statistics', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false);

  try {
    final results = parser.parse(arguments);

    if (results['help']) {
      print('Article Scraper - Financial News Aggregator');
      print('');
      print('Usage: dart bin/scraper_cli.dart [options]');
      print('');
      print(parser.usage);
      print('');
      print('Examples:');
      print('  dart bin/scraper_cli.dart -o articles.json');
      print('  dart bin/scraper_cli.dart --tickers AAPL,TSLA --min-score 0.5');
      print('  dart bin/scraper_cli.dart --summary');
      print('  dart bin/scraper_cli.dart --sheet-id <ID> --credentials service_account.json');
      return;
    }

    final scraper = ArticleScraper();
    final minScore = double.parse(results['min-score']);
    final maxArticles = int.parse(results['max-articles']);
    
    List<String>? tickers;
    if (results['tickers'] != null) {
      tickers = results['tickers'].split(',').map((s) => s.trim().toUpperCase()).toList();
    }

    print('🔍 Starting article scraping...');
    print('Configuration:');
    print('  - Min relevance score: $minScore');
    print('  - Max articles: $maxArticles');
    if (tickers != null) print('  - Focus tickers: ${tickers.join(', ')}');
    print('');

    List<Article> articles;
    
    if (tickers != null) {
      articles = await scraper.scrapeForTickers(tickers);
    } else {
      articles = await scraper.scrapeAllSources(
        specificTickers: tickers,
      );
    }

    // Filter by relevance score and limit results
    articles = articles
        .where((article) => article.relevanceScore >= minScore)
        .take(maxArticles)
        .toList();

    print('✅ Scraping completed!');
    print('Found ${articles.length} relevant articles');
    print('');

    if (results['summary']) {
      final summary = scraper.getArticlesSummary(articles);
      print('📊 Summary Statistics:');
      print('  - Total articles: ${summary['total_articles']}');
      print('  - Average relevance: ${(summary['average_relevance'] * 100).toStringAsFixed(1)}%');
      print('  - Sources: ${summary['sources'].length}');
      print('');
      
      print('🏷️  Top Keywords:');
      for (var keyword in summary['top_keywords'].take(5)) {
        print('  - ${keyword['keyword']}: ${keyword['count']} mentions');
      }
      print('');
      
      print('📰 Articles by Source:');
      summary['sources'].forEach((source, count) {
        print('  - $source: $count articles');
      });
      print('');
    }

    final sheetId = results['sheet-id'] ?? Platform.environment['GOOGLE_SHEET_ID'];
    if (sheetId != null && sheetId.isNotEmpty) {
      final credentials = results.wasParsed('credentials')
          ? results['credentials']
          : Platform.environment['GOOGLE_SERVICE_ACCOUNT_FILE'] ?? results['credentials'];
      final sheet = SheetsExporter(spreadsheetId: sheetId, worksheet: results['worksheet']);
      try {
        await sheet.connect(credentials);
        await sheet.appendArticles(articles);
        print('📄 Google Sheet updated');
      } finally {
        sheet.close();
      }
      print('');
    }

    if (results['output'] != null) {
      await scraper.exportToJson(articles, results['output']);
      print('💾 Articles exported to ${results['output']}');
    } else {
      print('📋 Recent Articles:');
      for (var i = 0; i < articles.take(5).length; i++) {
        final article = articles[i];
        print('${i + 1}. ${article.title}');
        print('   Source: ${article.source} | Score: ${(article.relevanceScore * 100).toStringAsFixed(1)}%');
        print('   URL: ${article.url}');
        print('');
      }
      
      if (articles.length > 5) {
        print('... and ${articles.length - 5} more articles');
        print('Use -o option to export all articles to JSON');
      }
    }

    scraper.dispose();
    
  } catch (e) {
    print('❌ Error: $e');
    print('');
    print('Use --help for usage information');
    exit(1);
  }
}
