import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Top Selling Products',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TopSellingProductsPage(),
    );
  }
}

class TopSellingProductsPage extends StatefulWidget {
  const TopSellingProductsPage({super.key});

  @override
  _TopSellingProductsPageState createState() => _TopSellingProductsPageState();
}

class _TopSellingProductsPageState extends State<TopSellingProductsPage> {
  List<Product> products = [];
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      _loadTopProducts();
    });
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<void> _loadTopProducts() async {
    // Ensure username is loaded before making the request
    if (loggedInUsername.isEmpty) {
      return;
    }

    // Prepare API endpoint
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/top_selling_product_graph/get_top_selling_products.php?username=$loggedInUsername');

    try {
      // Call the API to fetch top-selling products
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> productData = jsonData['data'];

          // Map the API data to the Product model
          final List<Product> fetchedProducts = productData.map((data) {
            return Product(
              data['product_name'] as String,
              (data['total_qty_sold'] as num).toInt(),
              (data['total_sales'] as num).toDouble(),
            );
          }).toList();

          // Update the UI
          setState(() {
            products = fetchedProducts;
          });
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e, stackTrace) {
      developer.log('Error fetching top products: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity =
        products.fold<int>(0, (max, p) => p.quantity > max ? p.quantity : max);

    // Show placeholders when no products are available
    final displayedProducts = products.isNotEmpty
        ? products
        : List.generate(5, (index) => Product('No Product', 0, 0.0));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Selling Products',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('Product Name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(
                          child: Text('Quantity',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      Expanded(
                          child: Text('Sales Order',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];
                      final double maxBarWidth =
                          MediaQuery.of(context).size.width * 0.8;
                      final double normalizedQuantity = maxQuantity != 0
                          ? product.quantity / maxQuantity
                          : 0.0; // Avoid division by 0
                      final double barWidth = normalizedQuantity * maxBarWidth;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 5),
                        child: Stack(
                          children: <Widget>[
                            Container(
                              alignment: Alignment.centerLeft,
                              color: Colors.blue.withOpacity(0.2),
                              height: 55,
                              width: barWidth,
                            ),
                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${product.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatSalesOrder(product.salesOrder),
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey.shade300,
                      height: 1,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSalesOrder(double salesOrder) {
    final formatter = NumberFormat.currency(symbol: 'RM', decimalDigits: 0);
    return formatter.format(salesOrder);
  }
}

class Product {
  String name;
  int quantity;
  double salesOrder;

  Product(this.name, this.quantity, this.salesOrder);
}
