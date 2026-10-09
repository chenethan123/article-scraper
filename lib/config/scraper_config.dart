class ScraperConfig {
  // Comprehensive financial/market keywords matching MarketAI's filtering system
  static const List<String> marketKeywords = [
    // Financial metrics
    'earnings', 'revenue', 'profit', 'loss', 'sales', 'income',
    'eps', 'ebitda', 'margin', 'growth', 'decline', 'cash flow',
    
    // Market terms
    'stock', 'share', 'market', 'trading', 'price', 'valuation',
    'market cap', 'volume', 'volatility', 'index', 'futures',
    
    // Economic indicators
    'inflation', 'deflation', 'gdp', 'unemployment', 'jobs report',
    'consumer price index', 'cpi', 'ppi', 'retail sales', 'housing',
    'manufacturing', 'services', 'pmi', 'economic growth',
    
    // Federal Reserve & monetary policy
    'federal reserve', 'fed', 'interest rates', 'rate cut', 'rate hike',
    'monetary policy', 'quantitative easing', 'tapering', 'fomc',
    'jerome powell', 'central bank', 'treasury yields',
    
    // Corporate actions
    'merger', 'acquisition', 'ipo', 'dividend', 'buyback', 
    'split', 'spinoff', 'restructuring', 'bankruptcy', 'delisting',
    
    // Analyst coverage
    'analyst', 'rating', 'upgrade', 'downgrade', 'price target',
    'recommendation', 'outlook', 'forecast', 'consensus',
    
    // Regulatory/Legal
    'sec', 'filing', 'regulation', 'lawsuit', 'settlement',
    'investigation', 'compliance', 'antitrust', 'sanctions',
    
    // Business fundamentals
    'guidance', 'outlook', 'strategy', 'partnership', 'contract',
    'product launch', 'expansion', 'layoffs', 'hiring', 'supply chain',
    
    // Global economic factors
    'trade war', 'tariffs', 'brexit', 'recession', 'recovery',
    'stimulus', 'bailout', 'debt ceiling', 'budget', 'fiscal policy',
    
    // Sector-specific
    'technology', 'healthcare', 'energy', 'finance', 'real estate',
    'commodities', 'oil prices', 'gold', 'crypto', 'bitcoin',
    
    // Market indices and exchanges
    'nasdaq', 'dow', 'sp500', 's&p', 'nyse', 'wall street',
    'dow jones', 'russell', 'vix', 'bond', 'treasury',
    
    // Investment terms
    'investment', 'portfolio', 'hedge fund', 'mutual fund', 'etf',
    'pension fund', 'institutional investor', 'retail investor'
  ];

  // Specific stock tickers to prioritize (matching MarketAI focus)
  static const List<String> priorityTickers = [
    'AAPL', 'MSFT', 'AMZN', 'TSLA', 'NVDA', 'SPY'
  ];

  // Expanded RSS feeds matching MarketAI's trusted domains
  static const Map<String, String> rssFeeds = {
    // Major financial news
    'Reuters Business': 'https://feeds.reuters.com/reuters/businessNews',
    'Bloomberg Markets': 'https://feeds.bloomberg.com/markets/news.rss',
    'MarketWatch': 'https://feeds.marketwatch.com/marketwatch/topstories/',
    'Yahoo Finance': 'https://feeds.finance.yahoo.com/rss/2.0/headline',
    'CNBC': 'https://www.cnbc.com/id/100003114/device/rss/rss.html',
    'Financial Times': 'https://www.ft.com/rss/home/us',
    'Wall Street Journal': 'https://feeds.a.dj.com/rss/RSSMarketsMain.xml',
    
    // Investment & analysis
    'Seeking Alpha': 'https://seekingalpha.com/feed.xml',
    'The Motley Fool': 'https://www.fool.com/feeds/index.aspx',
    'Barron\'s': 'https://www.barrons.com/xml/rss/3_7014.xml',
    'Morningstar': 'https://www.morningstar.com/rss/news',
    'Zacks': 'https://www.zacks.com/rss/articles.xml',
    
    // Business news
    'Business Insider': 'https://www.businessinsider.com/rss',
    'Forbes': 'https://www.forbes.com/real-time/feed2/',
    'Fortune': 'https://fortune.com/feed/',
    'The Street': 'https://www.thestreet.com/feeds/stocks.xml',
    
    // Economic news
    'Federal Reserve': 'https://www.federalreserve.gov/feeds/press_all.xml',
    'Bureau of Labor Statistics': 'https://www.bls.gov/feed/news_release/rss.xml',
    
    // Tech & innovation
    'TechCrunch': 'https://techcrunch.com/feed/',
    'VentureBeat': 'https://venturebeat.com/feed/',
    'Ars Technica': 'https://feeds.arstechnica.com/arstechnica/index',
    
    // Alternative sources
    'Axios': 'https://api.axios.com/feed/',
    'NPR Business': 'https://feeds.npr.org/1006/rss.xml',
    'BBC Business': 'http://feeds.bbci.co.uk/news/business/rss.xml',
    'CNN Business': 'http://rss.cnn.com/rss/money_latest.rss',
    
    // Sector-specific
    'Energy News': 'https://www.energycentral.com/rss.xml',
    'Healthcare Finance': 'https://www.healthcarefinancenews.com/rss.xml',
    'Real Estate News': 'https://www.housingwire.com/feed/',
    
    // Global markets
    'Financial Times Global': 'https://www.ft.com/rss/home/global',
    'Reuters World Markets': 'https://feeds.reuters.com/reuters/worldNews',
    'Bloomberg Global': 'https://feeds.bloomberg.com/politics/news.rss',
  };

  // RSS-only scraping - no NewsAPI integration needed

  // Rate limiting - optimized for speed
  static const Duration requestDelay = Duration(milliseconds: 100); // Reduced from 500ms
  static const int maxConcurrentRequests = 10; // Increased from 5
  static const int maxArticlesPerSource = 50;

  // Content filtering - more permissive to capture broader financial content
  static const int minContentLength = 50;
  static const int maxContentLength = 15000;
  static const double minRelevanceScore = 0.2; // Lower threshold for broader coverage
  
  // Economic query patterns matching MarketAI's comprehensive approach
  static const List<String> economicQueries = [
    'Federal Reserve OR Fed OR interest rates OR inflation OR GDP OR unemployment OR economic data OR recession OR economic growth OR monetary policy',
    'stock market OR Wall Street OR NYSE OR NASDAQ OR S&P 500 OR Dow Jones OR market volatility OR trading volume OR market cap',
    'earnings OR merger OR acquisition OR IPO OR bankruptcy OR SEC OR regulatory OR lawsuit OR investigation OR dividend OR buyback OR guidance',
    'global economy OR international trade OR tariffs OR trade war OR economic recovery OR stimulus OR supply chain OR commodities OR oil prices',
    'Federal Reserve OR Fed OR Jerome Powell OR FOMC OR rate cut OR rate hike OR quantitative easing OR treasury yields'
  ];
  
  // Company name mappings for better search results
  static const Map<String, String> tickerToCompany = {
    'AAPL': 'Apple Inc',
    'MSFT': 'Microsoft',
    'AMZN': 'Amazon',
    'TSLA': 'Tesla',
    'NVDA': 'NVIDIA',
    'SPY': 'S&P 500',
  };
}
