import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clientflow/data/category_data.dart';
import 'package:clientflow/data/sub_category_data.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() {
    return _CategoryScreenState();
  }
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<CategoryData> _categories = [];
  late List<List<SubCategoryData>> _subCategories = [];
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = await fetchCategories();
    _subCategories = await fetchAllSubCategories();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: Text(
          'Categories',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 76, 135),
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isExpanded = index == _expandedIndex;
                return ExpansionTile(
                  title: Text(
                    _categories[index].category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedIndex = expanded ? index : -1;
                    });
                  },
                  children: [
                    if (isExpanded)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subCategories[index].length,
                        itemBuilder: (context, subIndex) {
                          return ListTile(
                            title: Text(
                              _subCategories[index][subIndex].subCategory,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(
                                  context, _subCategories[index][subIndex].id);
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
    );
  }
}
