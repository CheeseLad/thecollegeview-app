import '../utils/html_utils.dart';

class Category {
  final int id;
  final String name;
  final int? parent;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    this.parent,
    List<Category>? subcategories,
  }) : subcategories = subcategories ?? [];

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: HtmlUtils.decodeHtmlEntities(json['name'] ?? ''),
      parent: json['parent'],
      subcategories: [],
    );
  }
}
