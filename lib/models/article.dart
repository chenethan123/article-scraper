class Article {
  final String title;
  final String content;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String? author;
  final String? imageUrl;
  final List<String> keywords;
  final double relevanceScore;

  Article({
    required this.title,
    required this.content,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.author,
    this.imageUrl,
    this.keywords = const [],
    this.relevanceScore = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'imageUrl': imageUrl,
      'keywords': keywords,
      'relevanceScore': relevanceScore,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? '',
      publishedAt: DateTime.parse(json['publishedAt']),
      author: json['author'],
      imageUrl: json['imageUrl'],
      keywords: List<String>.from(json['keywords'] ?? []),
      relevanceScore: (json['relevanceScore'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'Article(title: $title, source: $source, publishedAt: $publishedAt)';
  }
}
