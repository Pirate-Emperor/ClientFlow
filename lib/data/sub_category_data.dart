import 'dart:convert';
import 'package:http/http.dart' as http;
import 'category_data.dart';

class SubCategoryData {
  final int id;
  final int categoryId;
  final String subCategory;

  SubCategoryData({
    required this.id,
    required this.categoryId,
    required this.subCategory,
  });

  factory SubCategoryData.fromJson(Map<String, dynamic> json) {
    return SubCategoryData(
      id: json['id'],
      categoryId: json['category_id'],
      subCategory: json['sub_category'],
    );
  }
}

// Fetch subcategories for a specific category from the API
Future<List<SubCategoryData>> fetchSubCategories(int categoryId) async {
  final response = await http.get(
    Uri.parse('https://haluansama.com/crm-sales/api/sub_category/get_sub_categories.php?category_id=$categoryId'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      List<dynamic> subCategoryList = data['data'];
      return subCategoryList
          .map((json) => SubCategoryData.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load sub-categories: ${data['message']}');
    }
  } else {
    throw Exception('Failed to load sub-categories');
  }
}

// Fetch subcategories for all categories
Future<List<List<SubCategoryData>>> fetchAllSubCategories() async {
  final categories = await fetchCategories();
  final subCategories = <List<SubCategoryData>>[];

  for (var category in categories) {
    final subCategoryList = await fetchSubCategories(category.id);
    subCategories.add(subCategoryList);
  }

  return subCategories;
}
