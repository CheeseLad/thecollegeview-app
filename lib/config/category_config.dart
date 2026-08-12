import 'dart:convert';

import 'package:flutter/services.dart';

class CategoryConfig {
  const CategoryConfig({
    required this.includeIds,
    required this.dropdowns,
  });

  final List<int> includeIds;
  final List<CategoryDropdown> dropdowns;

  factory CategoryConfig.fromJson(Map<String, dynamic> json) {
    final includeIds = (json['includeIds'] as List? ?? const [])
        .map((id) => int.tryParse(id.toString()) ?? 0)
        .where((id) => id > 0)
        .toList();

    final dropdowns = (json['dropdowns'] as List? ?? const [])
        .map((entry) => CategoryDropdown.fromJson(entry as Map<String, dynamic>))
        .toList();

    return CategoryConfig(
      includeIds: includeIds,
      dropdowns: dropdowns,
    );
  }

  static Future<CategoryConfig> load() async {
    final raw = await rootBundle.loadString('assets/config/category_config.json');
    final decoded = jsonDecode(raw);
    return CategoryConfig.fromJson(decoded as Map<String, dynamic>);
  }
}

class CategoryDropdown {
  const CategoryDropdown({
    required this.parentId,
    required this.subcategories,
  });

  final int parentId;
  final List<int> subcategories;

  factory CategoryDropdown.fromJson(Map<String, dynamic> json) {
    return CategoryDropdown(
      parentId: int.tryParse((json['parentId'] ?? 0).toString()) ?? 0,
      subcategories: ((json['subcategories'] as List?) ?? const [])
          .map((id) => int.tryParse(id.toString()) ?? 0)
          .where((id) => id > 0)
          .toList(),
    );
  }
}
