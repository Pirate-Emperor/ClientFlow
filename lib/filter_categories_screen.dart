import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clientflow/data/brand_data.dart';
import 'package:clientflow/data/category_data.dart';
import 'package:clientflow/data/sub_category_data.dart';

class FilterCategoriesScreen extends StatefulWidget {
  final List<int> initialSelectedSubCategoryIds;
  final List<int> initialSelectedBrandIds;

  const FilterCategoriesScreen({
    Key? key,
    required this.initialSelectedSubCategoryIds,
    required this.initialSelectedBrandIds,
  }) : super(key: key);

  @override
  _FilterCategoriesScreenState createState() => _FilterCategoriesScreenState();
}

class _FilterCategoriesScreenState extends State<FilterCategoriesScreen> {
  List<CategoryData> _categories = [];
  List<List<SubCategoryData>> _subCategories = [];
  List<BrandData> _brands = [];
  List<int> selectedSubCategoryIds = [];
  List<int> _selectedBrandIds = [];

  bool isLoading = true; // To handle loading state

  @override
  void initState() {
    super.initState();
    selectedSubCategoryIds = List.from(widget.initialSelectedSubCategoryIds);
    _selectedBrandIds = List.from(widget.initialSelectedBrandIds);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true; // Show loader while fetching data
    });

    // Fetch data in parallel using Future.wait to optimize loading
    try {
      final results = await Future.wait([
        fetchCategories(),
        fetchAllSubCategories(),
        fetchBrands(),
      ]);

      _categories = results[0] as List<CategoryData>;
      _subCategories = results[1] as List<List<SubCategoryData>>;
      _brands = results[2] as List<BrandData>;
    } catch (e) {
      // Handle error
      print('Error fetching data: $e');
    } finally {
      setState(() {
        isLoading = false; // Remove loader once data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Filter Categories',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xff0175FF),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          // Display brands
          ExpansionTile(
            title: const Text(
              'Brands',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              // Wrapping ListView.builder with Container to control height
              Container(
                height: 300, // Set a fixed height to prevent infinite space
                child: ListView.builder(
                  itemCount: _brands.length,
                  itemBuilder: (context, index) {
                    final brand = _brands[index];
                    return CheckboxListTile(
                      title: Text(brand.brand),
                      value: _selectedBrandIds.contains(brand.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            _selectedBrandIds.add(brand.id);
                          } else {
                            _selectedBrandIds.remove(brand.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Display categories with expandable subcategories
          ExpansionTile(
            title: const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: _categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;

              return ExpansionTile(
                title: Text(
                  category.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: [
                  // Wrapping ListView.builder with Container to control height
                  Container(
                    height: 200, // Set a fixed height for subcategories
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _subCategories[index].length,
                      itemBuilder: (context, subIndex) {
                        final subCategoryData =
                        _subCategories[index][subIndex];
                        return CheckboxListTile(
                          title: Text(subCategoryData.subCategory),
                          value: selectedSubCategoryIds
                              .contains(subCategoryData.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected!) {
                                selectedSubCategoryIds
                                    .add(subCategoryData.id);
                              } else {
                                selectedSubCategoryIds
                                    .remove(subCategoryData.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSubCategoryIds.clear();
                  _selectedBrandIds.clear();
                });
                Navigator.pop(context, {
                  'selectedSubCategoryIds': selectedSubCategoryIds,
                  'selectedBrandIds': _selectedBrandIds,
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 38),
                backgroundColor: const Color.fromARGB(255, 184, 10, 39),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context, {
                    'selectedSubCategoryIds': selectedSubCategoryIds,
                    'selectedBrandIds': _selectedBrandIds,
                  });
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 38),
                backgroundColor: const Color(0xff0175FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
