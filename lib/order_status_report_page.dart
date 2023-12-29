// ignore_for_file: unused_import, unused_element, use_build_context_synchronously, library_private_types_in_public_api, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:clientflow/Components/navigation_bar.dart';
import 'package:clientflow/cart_item.dart';
import 'package:clientflow/customer_list.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:clientflow/order_details_page.dart';
import 'package:clientflow/utility_function.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'customer.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:clientflow/model/cart_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Order',
      theme: ThemeData(
        primaryColor: const Color(0xff0175FF),
        hintColor: const Color(0xff0175FF),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const OrderStatusReportPage(),
    );
  }
}

class OrderStatusReportPage extends StatefulWidget {
  const OrderStatusReportPage({super.key});

  @override
  _OrderStatusReportPageState createState() => _OrderStatusReportPageState();
}

class _OrderStatusReportPageState extends State<OrderStatusReportPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  DateTimeRange? dateRange;
  int? selectedDays;
  int selectedButtonIndex = 3;
  bool isSortedAscending = false;
  String loggedInUsername = '';
  Customer? selectedCustomer;
  int currentPageIndex = 1;
  String searchQuery = '';
  List<Map<String, dynamic>> filteredOrders = [];
  final List<String> _sortingMethods = [
    'By Creation Date (Ascending)',
    'By Creation Date (Descending)',
    'By Amount (Low to High)',
    'By Amount (High to Low)',
  ];

  String _selectedMethod = 'By Creation Date (Descending)';

  final Map<String, bool> _statusFilters = {
    'Void': false,
    'Pending': false,
    'Confirm': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      if (mounted) {
        _loadSalesOrders(days: selectedDays, dateRange: dateRange);
      }
    });
  }

  Future<void> insertItemIntoCart(CartItem cartItem) async {
    int itemId = cartItem.productId;
    String uom = cartItem.uom;

    try {
      const tableName = 'cart_item';
      final condition =
          "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";
      const order = '';
      const field = '*';

      final db = await DatabaseHelper.database;
      final result = await DatabaseHelper.readData(
        db,
        tableName,
        condition,
        order,
        field,
      );

      if (result.isNotEmpty) {
        final existingItem = result.first;
        final updatedQuantity = existingItem['qty'] + cartItem.quantity;
        final data = {
          'id': existingItem['id'],
          'qty': updatedQuantity,
          'modified': UtilityFunction.getCurrentDateTime(),
        };

        await DatabaseHelper.updateData(data, tableName);
        developer.log('Cart item quantity updated successfully');
      } else {
        final cartItemMap = cartItem.toMap(excludeId: true);
        await DatabaseHelper.insertData(cartItemMap, tableName);
        developer.log('New cart item inserted successfully');
      }
    } catch (e) {
      developer.log('Error inserting or updating cart item: $e', error: e);
    }
  }

  Future<void> insertAllItemsIntoCart(List<Map<String, dynamic>> items) async {
    try {
      for (var item in items) {
        final cartItem = CartItem(
          buyerId: await UtilityFunction.getUserId(),
          productId: item['product_id'],
          productName: item['product_name'],
          uom: item['uom'],
          quantity: item['qty'],
          discount: 0,
          originalUnitPrice: item['ori_unit_price'],
          unitPrice: item['ori_unit_price'],
          total: item['ori_unit_price'] * item['qty'],
          cancel: null,
          remark: null,
          status: 'in progress',
          created: DateTime.now(),
          modified: DateTime.now(),
        );
        await insertItemIntoCart(cartItem);
      }
      developer.log('All items copied to cart successfully');
    } catch (e) {
      developer.log('Error copying all items to cart: $e', error: e);
    }
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInUsername = prefs.getString('username') ?? '';
  }

  Future<void> _selectCustomer() async {
    final Customer? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerList(),
      ),
    );

    if (result != null) {
      setState(() {
        selectedCustomer = result;
        _loadSalesOrders(days: selectedDays, dateRange: dateRange);
      });
    }
  }

  void _updateSelectedCustomer(Customer customer) {
    setState(() {
      selectedCustomer = customer;
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    });
  }

  Future<void> _loadSalesOrders({int? days, DateTimeRange? dateRange}) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      Uri apiUrl = Uri.parse(
          'https://haluansama.com/crm-sales/api/sales_order/get_sales_orders.php');

      // Add query parameters for username
      Map<String, String> queryParams = {
        'username': loggedInUsername,
      };

      // Add filters for date range or days
      if (dateRange != null) {
        String startDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.start);
        String endDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.end);
        queryParams.addAll({
          'start_date': startDate,
          'end_date': endDate,
        });
      } else if (days != null) {
        queryParams['days'] = days.toString();
      }

      // Add customer filter if selected
      if (selectedCustomer != null) {
        queryParams['customer_id'] = selectedCustomer!.id.toString();
      }

      // Add status filters
      String statusFilters = _statusFilters.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .join(',');
      if (statusFilters.isNotEmpty) {
        queryParams['status_filters'] = statusFilters;
      }

      String sortField = _getOrderByField();
      String sortMethod = isSortedAscending ? 'ASC' : 'DESC';
      queryParams['sort_field'] = sortField;
      queryParams['sort_method'] = sortMethod;

      apiUrl = apiUrl.replace(queryParameters: queryParams);

      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          List<Map<String, dynamic>> fetchedOrders =
              List<Map<String, dynamic>>.from(jsonData['data']);

          setState(() {
            orders = fetchedOrders;
            filteredOrders = orders;
            developer.log('Loaded ${orders.length} orders');
          });
        } else {
          throw Exception(
              'Failed to load sales orders: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data from server');
      }
    } catch (e, stackTrace) {
      developer.log('Error loading sales orders: $e',
          error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getOrderByField() {
    switch (_selectedMethod) {
      case 'By Amount (Low to High)':
      case 'By Amount (High to Low)':
        return 'final_total';
      default:
        return 'created';
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      const tableName = 'cart';
      final data = {
        'id': orderId,
        'status': status,
        'modified': UtilityFunction.getCurrentDateTime(),
      };

      await DatabaseHelper.updateData(data, tableName);
      developer.log('Order status updated successfully');
      _loadSalesOrders(days: selectedDays, dateRange: dateRange);
    } catch (e) {
      developer.log('Error updating order status: $e', error: e);
    }
  }

  Future<void> _showItemSelectionDialog(
      List<Map<String, dynamic>> items) async {
    List<bool> checkedItems = List<bool>.filled(items.length, false);
    bool selectAll = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            var mediaQuery = MediaQuery.of(context);
            var screenHeight = mediaQuery.size.height;
            var screenWidth = mediaQuery.size.width;

            int selectedCount = checkedItems.where((item) => item).length;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(15),
                ),
                width: screenWidth * 0.95,
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Copy Items To Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.grey, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '   Select Items: $selectedCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF004072),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            selectAll ? 'Unselect All' : 'Select All',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              selectAll = !selectAll;
                              for (int i = 0; i < checkedItems.length; i++) {
                                checkedItems[i] = selectAll;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (items.length == 1)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[0]['product_name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.045,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'UOM: ${items[0]['uom']}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Qty: ${items[0]['qty']}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        leading: Checkbox(
                          value: checkedItems[0],
                          onChanged: (bool? value) {
                            if (mounted) {
                              setState(() {
                                checkedItems[0] = value!;
                                if (!value) selectAll = false;
                              });
                            }
                          },
                        ),
                      ),
                    if (items.length > 1)
                      Flexible(
                        child: SizedBox(
                          height: items.length <= 3 ? null : screenHeight * 0.5,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: items.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var item = entry.value;
                                    return Column(
                                      children: [
                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['product_name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth * 0.045,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'UOM: ${item['uom']}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(
                                                    height:
                                                        screenHeight * 0.005),
                                                Text(
                                                  'Qty: ${item['qty']}',
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.04,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          value: checkedItems[index],
                                          onChanged: (bool? value) {
                                            if (mounted) {
                                              setState(() {
                                                checkedItems[index] = value!;
                                                if (!value) selectAll = false;
                                              });
                                            }
                                          },
                                        ),
                                        if (index != items.length - 1)
                                          const Divider(color: Colors.grey),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: const Color(0xFF33B44F),
                          ),
                          child: const Text(
                            'Copy to cart',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          onPressed: () async {
                            for (int i = 0; i < items.length; i++) {
                              if (checkedItems[i]) {
                                final item = items[i];
                                final oriUnitPrice =
                                    (item['ori_unit_price'] ?? 0.0).toDouble();
                                final qty = (item['qty'] ?? 0).toInt();
                                final total = oriUnitPrice * qty;

                                final cartItem = CartItem(
                                  buyerId: await UtilityFunction.getUserId(),
                                  productId: item['product_id'],
                                  productName: item['product_name'],
                                  uom: item['uom'],
                                  quantity: qty,
                                  discount: 0,
                                  originalUnitPrice: oriUnitPrice,
                                  unitPrice: oriUnitPrice,
                                  total: total,
                                  cancel: null,
                                  remark: null,
                                  status: 'in progress',
                                  created: DateTime.now(),
                                  modified: DateTime.now(),
                                );
                                await insertItemIntoCart(cartItem);
                              }
                            }

                            Provider.of<CartModel>(context, listen: false)
                                .initializeCartCount();

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selected items copied to cart',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                duration: Duration(seconds: 3),
                                backgroundColor: Color(0xFF487C08),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sortingMethods.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              _sortingMethods[index],
                              style: TextStyle(
                                fontWeight:
                                    _selectedMethod == _sortingMethods[index]
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
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: _statusFilters.keys.map((String key) {
                          return CheckboxListTile(
                            title: Text(key),
                            value: _statusFilters[key],
                            onChanged: (bool? value) {
                              setState(() {
                                _statusFilters[key] = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF047CBD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _loadSalesOrders(
                              days: selectedDays, dateRange: dateRange);
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _sortResults() {
    setState(() {
      orders.sort((a, b) {
        switch (_selectedMethod) {
          case 'By Creation Date (Ascending)':
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(a['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(b['created_date']));
          case 'By Creation Date (Descending)':
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(b['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(a['created_date']));
          case 'By Amount (Low to High)':
            return a['final_total'].compareTo(b['final_total']);
          case 'By Amount (High to Low)':
            return b['final_total'].compareTo(a['final_total']);
          default:
            return DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse(a['created_date'])
                .compareTo(
                    DateFormat('dd/MM/yyyy HH:mm:ss').parse(b['created_date']));
        }
      });
    });
  }

  int _calculateTotalQuantity(Map<String, dynamic> order) {
    int totalQuantity = 0;
    if (order.containsKey('items') && order['items'] is List) {
      for (final item in order['items']) {
        totalQuantity += (item['qty'] as num).toInt();
      }
    } else {
      developer.log('Order ${order['id']} does not contain valid items.');
    }
    developer.log('Total quantity for order ${order['id']}: $totalQuantity');
    return totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sales Order Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0175FF),
      ),
      body: Column(
        children: <Widget>[
          _buildFilterSection(),
          Expanded(child: _buildSalesOrderList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _buildCustomerPicker(),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
          child: Text(
            'Filter by',
            style: GoogleFonts.inter(
              textStyle: const TextStyle(letterSpacing: -0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color.fromARGB(255, 25, 23, 49),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateRangePicker(),
              IconButton(
                onPressed: () => _showSortingOptions(context),
                icon: const Icon(Icons.sort, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickAccessDateButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomerPicker() {
    return Row(
      children: [
        // Search bar on the left
        Expanded(
          child: _buildSearchBar(),
        ),
        const SizedBox(width: 16.0),
        // Select customer icon only on the right, always blue
        InkWell(
          onTap: _selectCustomer,
          child: Container(
            height: 50.0,
            width: 50.0,
            decoration: BoxDecoration(
              color: const Color(0xff0175FF),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  final TextEditingController _searchController = TextEditingController();
  Widget _buildSearchBar() {
    return Container(
      height: 50.0,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search Sales Order',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _filterSalesOrders(value);
              },
            ),
          ),

          // The clear button is now at the end of the search bar
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _filterSalesOrders('');
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  void _filterSalesOrders(String query) {
    setState(() {
      searchQuery = query;

      // Filter orders based on the query
      filteredOrders = orders.where((order) {
        String orderId = order['id'].toString();
        String formattedOrderId = 'S${orderId.padLeft(7, '0')}';
        String creationDate = '';

        // Check if order has 'created_date'
        if (order['created_date'] != null) {
          DateTime dateTime =
              DateFormat('dd/MM/yyyy').parse(order['created_date']);
          creationDate = DateFormat('dd-MM-yyyy').format(dateTime);
        }

        // Company name and other fields to filter
        String companyName = order['company_name']?.toString() ?? '';

        // Return true if any of the fields match the query
        return formattedOrderId.toLowerCase().contains(query.toLowerCase()) ||
            orderId.contains(query) ||
            companyName.toLowerCase().contains(query.toLowerCase()) ||
            creationDate.contains(query);
      }).toList();
    });
  }

  Widget _buildQuickAccessDateButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildDateButton('All', null, 3),
          const SizedBox(width: 10),
          _buildDateButton('Last 7 days', 7, 0),
          const SizedBox(width: 10),
          _buildDateButton('Last 30 days', 30, 1),
          const SizedBox(width: 10),
          _buildDateButton('Last 90 days', 90, 2),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final bool isCustomRangeSelected = dateRange != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          alignment: Alignment.centerLeft,
          height: 43,
          decoration: BoxDecoration(
            color: const Color(0x503290E7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton.icon(
            onPressed: () => _selectDateRange(context),
            icon: Icon(
              Icons.calendar_today,
              color: isCustomRangeSelected
                  ? Colors.black
                  : Theme.of(context).iconTheme.color,
            ),
            label: Text(
              isCustomRangeSelected
                  ? '${DateFormat('dd/MM/yyyy').format(dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange!.end)}'
                  : 'Filter Date',
              style: TextStyle(
                color: isCustomRangeSelected
                    ? Colors.black
                    : Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(String text, int? days, int index) {
    bool isSelected = selectedButtonIndex == index;
    return TextButton(
      onPressed: () {
        setState(() {
          selectedButtonIndex = index;
          if (days != null) {
            DateTime now = DateTime.now();
            DateTime startDate = now.subtract(Duration(days: days));
            DateTime endDate = now;
            DateTimeRange newRange =
                DateTimeRange(start: startDate, end: endDate);

            dateRange = newRange;
            _loadSalesOrders(days: days, dateRange: newRange);
          } else {
            dateRange = null;
            _loadSalesOrders();
          }
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xff0175FF)
            : const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF999999)),
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? newDateRange = await showRangePickerDialog(
      context: context,
      minDate: DateTime(DateTime.now().year - 5),
      maxDate: DateTime.now(),
      selectedRange: dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );

    if (newDateRange != null) {
      DateTime startOfDay = DateTime(newDateRange.start.year,
          newDateRange.start.month, newDateRange.start.day, 0, 0, 0);
      DateTime endOfDay = DateTime(newDateRange.end.year,
          newDateRange.end.month, newDateRange.end.day, 23, 59, 59);

      setState(() {
        dateRange = DateTimeRange(start: startOfDay, end: endOfDay);
        selectedDays = null;
        _loadSalesOrders(dateRange: dateRange);
      });
    }
  }

  Widget _buildSalesOrderList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text(
          'No data found',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (final item in filteredOrders) {
      String orderId = item['id'].toString();
      if (!groupedOrders.containsKey(orderId)) {
        groupedOrders[orderId] = [];
      }
      groupedOrders[orderId]!.add(item);
    }

    List<String> orderIds = groupedOrders.keys.toList();

    return ListView.builder(
      itemCount: orderIds.length,
      itemBuilder: (context, index) {
        String orderId = orderIds[index];
        List<Map<String, dynamic>> items = groupedOrders[orderId]!;
        Map<String, dynamic> firstItem = items.first;

        return _buildSalesOrderItem(
          index: index,
          orderNumber: orderId,
          companyName: firstItem['company_name'] ?? 'Unknown Company',
          creationDate: firstItem['created_date'] != null
              ? DateFormat('dd/MM/yyyy').parse(firstItem['created_date'])
              : DateTime.now(),
          amount: '${firstItem['final_total']?.toStringAsFixed(3) ?? '0.000'}',
          status: firstItem['status'] ?? 'Unknown Status',
          items: items,
        );
      },
    );
  }

  Widget _buildSalesOrderItem({
    required int index,
    required String orderNumber,
    required String companyName,
    required DateTime creationDate,
    required String amount,
    required String status,
    required List<Map<String, dynamic>> items,
  }) {
    String getDisplayStatus(String status) {
      if (status == 'in progress') {
        return 'Pending';
      }
      return status;
    }

    Color getStatusColor(String displayStatus) {
      switch (displayStatus) {
        case 'Confirm':
          return const Color(0xFF33B44F);
        case 'Pending':
          return const Color.fromARGB(255, 255, 194, 82);
        case 'Void':
          return const Color(0xFFE81717);
        default:
          return Colors.grey;
      }
    }

    Widget getStatusLabel(String status) {
      String displayStatus = getDisplayStatus(status);

      return Container(
        alignment: Alignment.center,
        height: 32,
        width: 98,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: getStatusColor(displayStatus),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayStatus,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    // Safely attempt to parse orderNumber
    String formattedOrderNumber = 'S${orderNumber.padLeft(7, '0')}';
    int? orderId = int.tryParse(orderNumber);

    if (orderId == null) {
      // Handle invalid number, log an error or show a fallback UI
      developer.log('Invalid order number: $orderNumber');
      return Container();
    }

    return GestureDetector(
      onTap: () async {
        bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsPage(
              cartID: orderId,
              fromOrderConfirmation: false,
              fromSalesOrder: false,
            ),
          ),
        );
        if (result == true) {
          _loadSalesOrders(days: selectedDays, dateRange: dateRange);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order number and company name
                        Text(
                          '${index + 1}. $formattedOrderNumber',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          companyName,
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(letterSpacing: -0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Creation date
                        Text(
                          'Created on: ${DateFormat('dd-MM-yyyy').format(creationDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Amount and copy button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RM $amount',
                              style: const TextStyle(
                                color: Color(0xFF0175FF),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                await _showItemSelectionDialog(items);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status label
                    Positioned(
                      right: 6,
                      child: getStatusLabel(status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Expansion tile for items
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  elevation: 4,
                  color: const Color(0xFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    iconColor: Colors.blueAccent,
                    collapsedIconColor: Colors.grey,
                    title: const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      // Product name
                                      Text(
                                        item['product_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // UOM and Quantity
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'UOM: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              item['uom'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Qty: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            item['qty']?.toString() ?? '0',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
