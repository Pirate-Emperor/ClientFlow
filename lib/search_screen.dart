import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:clientflow/item_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  List<String> _searchResults = [];

  Future<void> _performSearch(String query) async {
    final apiUrl = Uri.parse('https://haluansama.com/crm-sales/api/search_screen/get_search_products.php?query=$query');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          setState(() {
            _searchResults = List<String>.from(jsonData['data'].map((item) => item['product_name']));
          });
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      developer.log('Error performing search: $e');
    }
  }

  void _onSearchTextChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _performSearch(query);
  }

  void _navigateToItemScreen(String selectedProductName) async {
    final apiUrl = Uri.parse('https://haluansama.com/crm-sales/api/search_screen/get_product_details.php?productName=$selectedProductName');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final product = jsonData['data'];

          // Convert the description String to a Blob object
          Blob descriptionBlob = stringToBlob(product['description']);

          // Navigate to ItemScreen with product details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemScreen(
                productId: product['id'],
                productName: product['product_name'],
                itemAssetNames: [
                  'https://haluansama.com/crm-sales/${product['photo1']}',
                  'https://haluansama.com/crm-sales/${product['photo2']}',
                  'https://haluansama.com/crm-sales/${product['photo3']}',
                ],
                itemDescription: descriptionBlob,  // Pass Blob instead of String
                priceByUom: product['price_by_uom'],
              ),
            ),
          );
        } else {
          developer.log('Product not found for name: $selectedProductName');
        }
      } else {
        throw Exception('Failed to fetch product details');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
    }
  }

  // Convert the String description into a Blob object using Blob.fromString
  Blob stringToBlob(String data) {
    return Blob.fromString(data);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchTextChanged,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Perform search when the search button is pressed
              _performSearch(_searchQuery);
            },
          ),
        ],
      ),
      body: _searchResults.isEmpty
          ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'Start typing to search'
                    : 'No results found',
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final productName = _searchResults[index];
                return ListTile(
                  title: Text(productName),
                  onTap: () {
                    _navigateToItemScreen(productName);
                  },
                );
              },
            ),
    );
  }
}
