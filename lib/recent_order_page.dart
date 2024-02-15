import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:clientflow/item_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecentOrder extends StatefulWidget {
  const RecentOrder({
    super.key,
    required this.customerId,
  });

  final int customerId;
  @override
  _RecentOrderState createState() => _RecentOrderState();
}

class _RecentOrderState extends State<RecentOrder> {
  bool _isGridView = false;
  int _userId = 0;
  final bool _isAscending = true;
  int numberOfItems = 0;

  // Define sorting methods
  final List<String> _sortingMethods = [
    'By Name (A to Z)',
    'By Name (Z to A)',
    'Uploaded Date (Old to New)',
    'Uploaded Date (New to Old)',
    'By Price (Low to High)',
    'By Price (High to Low)'
  ];

  // Selected sorting method
  String _selectedMethod = 'By Name (A to Z)';

  // To cache the fetched data
  List<Map<String, dynamic>>? _fetchedData;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchRecentOrders();
  }

  void _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('id') ?? 0;
    setState(() {
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Recent Order',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: () {
                        _showSortingOptions(context);
                      },
                    ),
                    Text(_selectedMethod),
                    const SizedBox(width: 10),
                    Text('$numberOfItems item(s)'),
                  ],
                ),
                IconButton(
                  icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  // Show sorting options
  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _sortingMethods.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_sortingMethods[index]),
              onTap: () {
                setState(() {
                  _selectedMethod = _sortingMethods[index];
                });
                Navigator.pop(context);
                _sortResults(_fetchedData!);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent orders found.'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildListItem(item);
            },
          );
        }
      },
    );
  }

  Widget _buildGridView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No recent orders found.'));
        } else {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return _buildGridItem(item);
            },
          );
        }
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return FutureBuilder<String>(
      future: _fetchProductPhoto(item['product_name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 20,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: (snapshot.data != null &&
                              Uri.parse(snapshot.data!).isAbsolute)
                          ? Image.network(
                              snapshot.data!,
                              height: 100,
                              width: 100,
                            )
                          : Image.asset(
                              'asset/no_image.jpg',
                              height: 100,
                              width: 100,
                            ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigateToItemScreen(item['product_name']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0175FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'View Item',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
    return FutureBuilder<String>(
      future: _fetchProductPhoto(item['product_name']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 20, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(20, 30),
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(''),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (snapshot.data != null && Uri.parse(snapshot.data!).isAbsolute)
                    ? Image.network(
                        snapshot.data!,
                        height: 70,
                        width: 70,
                      )
                    : Image.asset(
                        'asset/no_image.jpg',
                        height: 70,
                        width: 70,
                      ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['product_name'],
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _navigateToItemScreen(item['product_name']);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(20, 30),
                    backgroundColor: const Color(0xff0175FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('View Item',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  void _navigateToItemScreen(String selectedProductName) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/recent_order_page/get_product_details.php?productName=$selectedProductName');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final product = jsonData['data'][0];

          int productId = product['id'];
          String productName = product['product_name'];
          List<String> itemAssetNames = [
            'https://haluansama.com/crm-sales/${product['photo1']}',
            'https://haluansama.com/crm-sales/${product['photo2']}',
            'https://haluansama.com/crm-sales/${product['photo3']}',
          ];

          // Convert the String description into Blob
          String descriptionString =
              product['description']; // Assuming it's a String from the API
          Blob descriptionBlob =
              Blob.fromString(descriptionString); // Convert to Blob

          String priceByUom = product['price_by_uom'];

          // Navigate to ItemScreen and pass the Blob instead of String
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemScreen(
                productId: productId,
                productName: productName,
                itemAssetNames: itemAssetNames,
                itemDescription: descriptionBlob, // Pass as Blob
                priceByUom: priceByUom,
              ),
            ),
          );
        } else {
          print('Error: ${jsonData['message']}');
        }
      } else {
        print('Failed to load product data');
      }
    } catch (e) {
      print('Error fetching product data: $e');
    }
  }

  Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
  }

  Future<List<Map<String, dynamic>>> _fetchRecentOrders() async {
    if (_fetchedData != null) {
      return _fetchedData!;
    }

    // Constructing the API URL to pass correct parameters
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/recent_order_page/get_recent_orders.php?userId=$_userId&customerId=${widget.customerId}');

    print(apiUrl); // To check if the URL is correctly constructed

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          _fetchedData = List<Map<String, dynamic>>.from(jsonData['data']);
          setState(() {
            numberOfItems = _fetchedData!.length;
          });
          _sortResults(_fetchedData!); // Ensure sorting happens
          return _fetchedData!;
        } else {
          print('Error: ${jsonData['message']}');
        }
      } else {
        print('Failed to load recent orders');
      }
    } catch (e) {
      print('Error fetching recent orders: $e');
    }

    return [];
  }

  void _sortResults(List<Map<String, dynamic>> results) {
    if (_selectedMethod == 'By Name (A to Z)') {
      results.sort((a, b) {
        if (_isAscending) {
          return a['product_name'].compareTo(b['product_name']);
        } else {
          return b['product_name'].compareTo(a['product_name']);
        }
      });
    } else if (_selectedMethod == 'By Name (Z to A)') {
      results.sort((a, b) {
        if (_isAscending) {
          return b['product_name'].compareTo(a['product_name']);
        } else {
          return a['product_name'].compareTo(b['product_name']);
        }
      });
    } else if (_selectedMethod == 'Uploaded Date (Old to New)') {
      results.sort((a, b) {
        if (_isAscending) {
          return a['product_id'].compareTo(b['product_id']);
        } else {
          return b['product_id'].compareTo(a['product_id']);
        }
      });
    } else if (_selectedMethod == 'Uploaded Date (New to Old)') {
      results.sort((a, b) {
        if (_isAscending) {
          return b['product_id'].compareTo(a['product_id']);
        } else {
          return a['product_id'].compareTo(b['product_id']);
        }
      });
    } else if (_selectedMethod == 'By Price (Low to High)') {
      results.sort((a, b) {
        if (_isAscending) {
          return a['total'].compareTo(b['total']);
        } else {
          return b['total'].compareTo(a['total']);
        }
      });
    } else if (_selectedMethod == 'By Price (High to Low)') {
      results.sort((a, b) {
        if (_isAscending) {
          return b['total'].compareTo(a['total']);
        } else {
          return a['total'].compareTo(b['total']);
        }
      });
    }
  }

  Future<String> _fetchProductPhoto(String productName) async {
    // Construct the API URL to pass the product name
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/recent_order_page/get_product_photo.php?productName=$productName');

    print(apiUrl); // Print URL to check if it's correct

    try {
      final response = await http.get(apiUrl);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Check if the API returned success status
        if (jsonData['status'] == 'success' && jsonData['photo1'] != null) {
          String photoPath = jsonData['photo1'];

          // Check if photoPath starts with "photo/" and replace it with "asset/photo/"
          if (photoPath.startsWith('photo/')) {
            photoPath =
                'https://haluansama.com/crm-sales/photo/${photoPath.substring(6)}';
          }

          return photoPath;
        } else {
          // If no photo found or an error occurred, return the default image path
          print('Error: ${jsonData['message']}');
          return 'asset/no_image.jpg';
        }
      } else {
        // If the request failed, log the error and return the default image path
        print('Failed to load product photo');
        return 'asset/no_image.jpg';
      }
    } catch (e) {
      // Log any exceptions that occur
      developer.log('Error fetching product photo: $e', error: e);
      return 'asset/no_image.jpg';
    }
  }
}
