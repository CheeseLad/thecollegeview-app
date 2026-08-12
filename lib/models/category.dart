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
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: HtmlUtils.decodeHtmlEntities(json['name']),
      parent: json['parent'],
      subcategories: [],
    );
  }

  static List<Category> fromJsonList(List<dynamic> jsonList) {
    final categories = jsonList.map((data) => Category.fromJson(data)).toList();

    final Map<int, Category> categoryMap = {
      for (var category in categories) category.id: category
    };

    for (final category in categories) {
      final parentId = category.parent;
      if (parentId != null && parentId != 0 && categoryMap.containsKey(parentId)) {
        categoryMap[parentId]!.subcategories.add(category);
      }
    }

    return categories.where((category) => category.parent == null || category.parent == 0).toList();
  }
}
