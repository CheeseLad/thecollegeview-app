class PageContent {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String link;
  final String slug;

  PageContent({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.link,
    required this.slug,
  });

  factory PageContent.fromJson(Map<String, dynamic> json) {
    return PageContent(
      id: json['id'] ?? 0,
      title: json['title']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      excerpt: json['excerpt']?['rendered'] ?? '',
      link: json['link'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
