import '../config/scraper_config.dart';

class ContentAnalyzer {
  
  List<String> extractKeywords(String content) {
    final words = content.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();

    final keywordCounts = <String, int>{};
    
    // Count occurrences of comprehensive market-related keywords
    for (final keyword in ScraperConfig.marketKeywords) {
      final keywordLower = keyword.toLowerCase();
      int count = 0;
      
      // Direct matches
      if (content.toLowerCase().contains(keywordLower)) {
        count += keywordLower.split(' ').length; // Multi-word keywords get higher weight
      }
      
      // Word-level matches for single words
      if (!keywordLower.contains(' ')) {
        count += words.where((word) => 
            word == keywordLower || 
            word.contains(keywordLower) ||
            keywordLower.contains(word)).length;
      }
      
      if (count > 0) {
        keywordCounts[keyword] = count;
      }
    }

    // Check for priority stock tickers with company names
    for (final ticker in ScraperConfig.priorityTickers) {
      int count = 0;
      final companyName = ScraperConfig.tickerToCompany[ticker];
      
      // Ticker symbol matches
      if (content.toUpperCase().contains('\$${ticker}') ||
          content.toUpperCase().contains('${ticker} ') ||
          content.toUpperCase().contains(' ${ticker}') ||
          words.any((word) => word.toUpperCase() == ticker)) {
        count += 2; // Higher weight for ticker symbols
      }
      
      // Company name matches
      if (companyName != null && content.toLowerCase().contains(companyName.toLowerCase())) {
        count += 1;
      }
      
      if (count > 0) {
        keywordCounts[ticker] = count;
      }
    }

    // Return keywords sorted by frequency
    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedKeywords.map((e) => e.key).take(15).toList(); // Increased to 15 for broader coverage
  }

  double calculateRelevanceScore(String content, List<String> keywords) {
    double score = 0.0;
    final contentLower = content.toLowerCase();
    
    // More nuanced scoring system matching MarketAI's approach
    
    // 1. Base score from comprehensive market keywords
    int keywordMatches = 0;
    for (final keyword in ScraperConfig.marketKeywords) {
      final keywordLower = keyword.toLowerCase();
      if (contentLower.contains(keywordLower)) {
        // Multi-word keywords get higher weight
        final weight = keywordLower.contains(' ') ? 0.15 : 0.08;
        score += weight;
        keywordMatches++;
      }
    }
    
    // 2. Higher score for priority tickers and company names
    for (final ticker in ScraperConfig.priorityTickers) {
      final companyName = ScraperConfig.tickerToCompany[ticker];
      
      // Ticker symbol matches
      if (contentLower.contains(ticker.toLowerCase()) ||
          content.toUpperCase().contains('\$${ticker}') ||
          content.toUpperCase().contains('${ticker} ')) {
        score += 0.25;
      }
      
      // Company name matches
      if (companyName != null && contentLower.contains(companyName.toLowerCase())) {
        score += 0.2;
      }
    }
    
    // 3. Title/headline bonus (first 150 chars)
    final titlePortion = content.length > 150 ? content.substring(0, 150) : content;
    final titleLower = titlePortion.toLowerCase();
    
    int titleKeywords = 0;
    for (final keyword in ScraperConfig.marketKeywords) {
      if (titleLower.contains(keyword.toLowerCase())) {
        score += 0.12;
        titleKeywords++;
      }
    }
    
    // 4. Economic query pattern matching
    for (final query in ScraperConfig.economicQueries) {
      final queryTerms = query.toLowerCase().split(' or ');
      for (final term in queryTerms) {
        final cleanTerm = term.trim().replaceAll(RegExp(r'[^\w\s]'), '');
        if (cleanTerm.isNotEmpty && contentLower.contains(cleanTerm)) {
          score += 0.1;
          break; // Only count once per query pattern
        }
      }
    }
    
    // 5. Density bonus - reward articles with multiple financial terms
    if (keywordMatches > 3) {
      score += 0.1;
    }
    if (keywordMatches > 6) {
      score += 0.1;
    }
    
    // 6. Title density bonus
    if (titleKeywords > 1) {
      score += 0.15;
    }
    
    // Normalize score to 0-1 range with smoother scaling
    return score > 1.0 ? 1.0 : score;
  }

  bool isFinanciallyRelevant(String content) {
    final relevanceScore = calculateRelevanceScore(content, extractKeywords(content));
    return relevanceScore >= ScraperConfig.minRelevanceScore;
  }

  String extractSummary(String content, {int maxLength = 200}) {
    if (content.length <= maxLength) return content;
    
    // Find the first sentence that ends near the max length
    final sentences = content.split(RegExp(r'[.!?]+'));
    String summary = '';
    
    for (final sentence in sentences) {
      if (summary.length + sentence.length > maxLength) {
        break;
      }
      summary += sentence + '. ';
    }
    
    return summary.trim();
  }
}
