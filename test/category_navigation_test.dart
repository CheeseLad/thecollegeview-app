import 'package:flutter_test/flutter_test.dart';
import 'package:thecollegeview/models/category.dart';

void main() {
  test('News categories are grouped into parent/subcategory navigation', () {
    final categories = Category.fromJsonList([
      {'id': 1, 'name': 'News', 'parent': 0},
      {'id': 10, 'name': 'DCU News', 'parent': 1},
      {'id': 11, 'name': 'Uni News', 'parent': 1},
      {'id': 12, 'name': 'National News', 'parent': 1},
    ]);

    expect(categories.length, 1);
    expect(categories.first.name, 'News');
    expect(
      categories.first.subcategories.map((category) => category.name).toList(),
      ['DCU News', 'Uni News', 'National News'],
    );
  });
}
