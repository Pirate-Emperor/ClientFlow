import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const ProductReport(),
    );
  }
}

class ProductReport extends StatefulWidget {
  const ProductReport({super.key});

  @override
  _ProductReportState createState() => _ProductReportState();
}

class _ProductReportState extends State<ProductReport> {
  late Future<List<Product>> products;
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;
  bool isSortedAscending = true;
  String loggedInUsername = '';

  final List<String> _sortingMethods = [
    'By Name (A to Z)',
    'By Name (Z to A)',
    'By Total Sales (Low to High)',
    'By Total Sales (High to Low)',
    'By Total Quantity Sold (Low to High)',
    'By Total Quantity Sold (High to Low)',
    'By Last Sold (Oldest to Newest)',
    'By Last Sold (Newest to Oldest)',
  ];

  String _selectedMethod = 'By Name (A to Z)';

  @override
  void initState() {
    super.initState();
    products = Future.value([]);
    _loadPreferences().then((_) {
      setState(() {
        selectedButtonIndex = 3;
      });
      products = fetchProducts(null);
    });
  }

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<Product>> fetchProducts(DateTimeRange? dateRange) async {
    if (loggedInUsername.isEmpty) {
      return [];
    }

    String formattedStartDate = dateRange != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.start)
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(2019));

    String formattedEndDate = dateRange != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.end)
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    String sortOrder = isSortedAscending ? 'ASC' : 'DESC';
    String orderByField = _getOrderByField();

    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/top_selling_product_page/get_top_selling_products_report.php?username=$loggedInUsername&startDate=$formattedStartDate&endDate=$formattedEndDate&sortOrder=$sortOrder&orderByField=$orderByField');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> productData = jsonData['data'];

          return productData.map((data) {
            return Product(
              id: data['ProductID'],
              brandId: data['BrandID'],
              productName: data['ProductName'],
              brandName: data['BrandName'],
              unitOfMeasure: data['UnitOfMeasure'],
              totalSales: (data['TotalSalesValue'] as num).toDouble(),
              totalQuantitySold: (data['TotalQuantitySold'] as num).toInt(),
              lastSold: DateTime.parse(data['SaleDate']).toLocal(),
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      developer.log('Error fetching products: $e');
      return [];
    }
  }

  void queryAllData() {
    setState(() {
      _selectedDateRange = null;
      selectedButtonIndex = 3;
      products = fetchProducts(null);
    });
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      products = fetchProducts(_selectedDateRange);
    });
  }

  setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now().toUtc();
    final DateTime start = now.subtract(Duration(days: days));
    setState(() {
      _selectedDateRange = DateTimeRange(
          start: DateTime(start.year, start.month, start.day, 0, 0, 0).toUtc(),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc());
      isSortedAscending = false;
      products = fetchProducts(_selectedDateRange);
      selectedButtonIndex = selectedIndex;
    });
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _sortingMethods.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ListTile(
                title: Text(
                  _sortingMethods[index],
                  style: TextStyle(
                    fontWeight: _selectedMethod == _sortingMethods[index]
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedMethod == _sortingMethods[index]
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
                trailing: _selectedMethod == _sortingMethods[index]
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedMethod = _sortingMethods[index];
                  });
                  Navigator.pop(context);
                  _sortResults();
                },
              ),
            );
          },
        );
      },
    );
  }

  void _sortResults() {
    setState(() {
      products = fetchProducts(_selectedDateRange);
    });
  }

  String _getOrderByField() {
    switch (_selectedMethod) {
      case 'By Name (A to Z)':
      case 'By Name (Z to A)':
        return 'ProductName';
      case 'By Total Sales (Low to High)':
      case 'By Total Sales (High to Low)':
        return 'TotalSalesValue';
      case 'By Total Quantity Sold (Low to High)':
      case 'By Total Quantity Sold (High to Low)':
        return 'TotalQuantitySold';
      case 'By Last Sold (Oldest to Newest)':
      case 'By Last Sold (Newest to Oldest)':
        return 'SaleDate';
      default:
        return 'ProductName';
    }
  }

  Widget _buildFilterButtonAndDateRangeSelection() {
    final bool isCustomRangeSelected = selectedButtonIndex == -1;

    String formattedDate;
    if (selectedButtonIndex == 3) {
      formattedDate = 'Filter Date';
    } else if (_selectedDateRange != null) {
      formattedDate =
          '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}';
    } else {
      formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 5.0),
              child: TextButton.icon(
                onPressed: () async {
                  final DateTimeRange? picked = await showRangePickerDialog(
                    context: context,
                    minDate: DateTime(2019),
                    maxDate: DateTime.now(),
                    selectedRange: _selectedDateRange,
                  );
                  if (picked != null && picked != _selectedDateRange) {
                    DateTime adjustedStartDate = DateTime(picked.start.year,
                        picked.start.month, picked.start.day, 0, 0, 0);
                    DateTime adjustedEndDate = DateTime(picked.end.year,
                        picked.end.month, picked.end.day, 23, 59, 59);

                    setState(() {
                      _selectedDateRange = DateTimeRange(
                          start: adjustedStartDate, end: adjustedEndDate);
                      selectedButtonIndex = -1;
                      products = fetchProducts(_selectedDateRange);
                    });
                  }
                },
                icon: Icon(
                  Icons.calendar_today,
                  color: isCustomRangeSelected ? Colors.white : Colors.black,
                ),
                label: Text(
                  formattedDate,
                  style: TextStyle(
                    color: isCustomRangeSelected ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (isCustomRangeSelected) {
                        return const Color(0xFF047CBD);
                      }
                      return const Color(0xFFD9D9D9);
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (isCustomRangeSelected) {
                        return Colors.white;
                      }
                      return Colors.black;
                    },
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showSortingOptions(context),
              icon: const Icon(Icons.sort, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              _buildTimeFilterButton(
                  'All', () => queryAllData(), selectedButtonIndex == 3),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 7 days', () => setDateRange(7, 0),
                  selectedButtonIndex == 0),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 30 days', () => setDateRange(30, 1),
                  selectedButtonIndex == 1),
              const SizedBox(width: 10),
              _buildTimeFilterButton('Last 90 days', () => setDateRange(90, 2),
                  selectedButtonIndex == 2),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimeFilterButton(
      String text, VoidCallback onPressed, bool isSelected) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            return isSelected
                ? const Color(0xff0175FF)
                : const Color.fromARGB(255, 255, 255, 255);
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF999999)),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title:
            const Text('Product Report', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: _buildFilterButtonAndDateRangeSelection(),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  List<Product> sortedData = _getSortedData(snapshot.data!);
                  return ListView.builder(
                    itemCount: sortedData.length,
                    itemBuilder: (context, index) {
                      final product = sortedData[index];
                      final serialNumber = index + 1; // Assign serial number here
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.circular(4.0),
                              boxShadow: const [
                                BoxShadow(
                                  blurStyle: BlurStyle.normal,
                                  color: Color.fromARGB(75, 117, 117, 117),
                                  spreadRadius: 0.1,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ExpansionTile(
                              backgroundColor: Colors.transparent,
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$serialNumber. ', // Display the serial number here
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      product.productName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '      UOM: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            product.unitOfMeasure,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '     Total Sales: ${product.totalSalesDisplay}',
                                      style: const TextStyle(
                                        color: Color(0xFF0175FF),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '     Total Quantity Sold: ${product.totalQuantitySold}',
                                      style: const TextStyle(
                                        color: Color(0xFF004072),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 239, 245, 248),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '      Product ID: ${product.id}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Brand Name: ${product.brandName}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              '      Last Sold: ${DateFormat('dd-MM-yyyy').format(product.lastSold)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(color: Colors.transparent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _getSortedData(List<Product> data) {
    switch (_selectedMethod) {
      case 'By Name (A to Z)':
        data.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'By Name (Z to A)':
        data.sort((a, b) => b.productName.compareTo(a.productName));
        break;
      case 'By Total Sales (Low to High)':
        data.sort((a, b) => a.totalSales.compareTo(b.totalSales));
        break;
      case 'By Total Sales (High to Low)':
        data.sort((a, b) => b.totalSales.compareTo(a.totalSales));
        break;
      case 'By Total Quantity Sold (Low to High)':
        data.sort((a, b) => a.totalQuantitySold.compareTo(b.totalQuantitySold));
        break;
      case 'By Total Quantity Sold (High to Low)':
        data.sort((a, b) => b.totalQuantitySold.compareTo(a.totalQuantitySold));
        break;
      case 'By Last Sold (Oldest to Newest)':
        data.sort((a, b) => a.lastSold.compareTo(b.lastSold));
        break;
      case 'By Last Sold (Newest to Oldest)':
        data.sort((a, b) => b.lastSold.compareTo(a.lastSold));
        break;
    }
    return data;
  }
}

class Product {
  final int id;
  final int brandId;
  final String productName;
  final String brandName;
  final String unitOfMeasure;
  final double totalSales;
  final int totalQuantitySold;
  final DateTime lastSold;

  Product({
    required this.id,
    required this.brandId,
    required this.productName,
    required this.brandName,
    required this.unitOfMeasure,
    required this.totalSales,
    required this.totalQuantitySold,
    required this.lastSold,
  });

  String get totalSalesDisplay =>
      NumberFormat.currency(symbol: 'RM', decimalDigits: 3, locale: 'en_US')
          .format(totalSales);
}
