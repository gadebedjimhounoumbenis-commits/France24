class Article {
  final String title;
  final String description;
  final String link;
  final String pubDate;
  final String imageUrl;
  final String category;

  Article({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    required this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'link': link,
        'pubDate': pubDate,
        'imageUrl': imageUrl,
        'category': category,
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        link: json['link'] ?? '',
        pubDate: json['pubDate'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        category: json['category'] ?? '',
      );
}