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
      title: 'Customer Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const CustomerReport(),
    );
  }
}

class CustomerReport extends StatefulWidget {
  const CustomerReport({super.key});

  @override
  _CustomerReportState createState() => _CustomerReportState();
}

class _CustomerReportState extends State<CustomerReport> {
  late Future<List<Customer>> salesData;
  bool isSortedAscending = false;
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;
  String loggedInUsername = '';

  final List<String> _sortingMethods = [
    'By Company Name (A-Z)',
    'By Company Name (Z-A)',
    'By Total Sales (Low to High)',
    'By Total Sales (High to Low)',
    'By Total Quantity (Low to High)',
    'By Total Quantity (High to Low)',
    'By Last Purchase (Ascending)',
    'By Last Purchase (Descending)',
  ];

  String _selectedMethod = 'By Company Name (A-Z)';

  @override
  void initState() {
    super.initState();
    salesData = Future.value([]);
    loadPreferences().then((_) {
      setState(() {
        _selectedDateRange = null;
        salesData = fetchSalesData(isSortedAscending, _selectedDateRange);
        selectedButtonIndex = 3;
      });
    });
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');
      bool? sorted = prefs.getBool('isSortedAscending');

      setState(() {
        loggedInUsername = username ?? '';
        isSortedAscending = sorted ?? false;
      });
    } catch (e) {
      developer.log('Error loading preferences: $e', error: e);
    }
  }

  Future<List<Customer>> fetchSalesData(
      bool isAscending, DateTimeRange? dateRange) async {
    if (loggedInUsername.isEmpty) {
      return [];
    }
    String formattedStartDate = dateRange != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.start)
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(2019));
    String formattedEndDate = dateRange != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dateRange.end)
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String orderByField = _getOrderByField();
    String sortOrder = _getSortOrder();
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/customer_report_page/get_customer_sales_report.php?username=$loggedInUsername&startDate=$formattedStartDate&endDate=$formattedEndDate&sortOrder=$sortOrder&orderByField=$orderByField');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> customerData = jsonData['data'];

          int serialNumber = 1;
          return customerData.map((data) {
            return Customer(
              id: data['Customer_ID'],
              companyName: data['Company_Name'],
              customerUsername: data['customer_username'],
              email: data['Email'],
              contactNumber: data['Contact_Number'],
              totalSales: (data['Total_Sales'] as num).toDouble(),
              totalQuantity: (data['Total_Quantity'] as num).toDouble(),
              lastPurchase: DateTime.parse(data['Last_Purchase']).toLocal(),
              serialNumber: serialNumber++,
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      developer.log('Error fetching sales data: $e');
      return [];
    }
  }

  String _getOrderByField() {
    switch (_selectedMethod) {
      case 'By Company Name (A-Z)':
        return 'Company_Name';
      case 'By Company Name (Z-A)':
        return 'Company_Name';
      case 'By Total Sales (Low to High)':
        return 'Total_Sales';
      case 'By Total Sales (High to Low)':
        return 'Total_Sales';
      case 'By Total Quantity (Low to High)':
        return 'Total_Quantity';
      case 'By Total Quantity (High to Low)':
        return 'Total_Quantity';
      case 'By Last Purchase (Ascending)':
        return 'Last_Purchase';
      case 'By Last Purchase (Descending)':
        return 'Last_Purchase';
      default:
        return 'Company_Name';
    }
  }

  String _getSortOrder() {
    switch (_selectedMethod) {
      case 'By Company Name (A-Z)':
      case 'By Total Sales (Low to High)':
      case 'By Total Quantity (Low to High)':
      case 'By Last Purchase (Ascending)':
        return 'ASC';
      case 'By Company Name (Z-A)':
      case 'By Total Sales (High to Low)':
      case 'By Total Quantity (High to Low)':
      case 'By Last Purchase (Descending)':
        return 'DESC';
      default:
        return 'ASC';
    }
  }

  List<Customer> _getSortedData(List<Customer> data) {
    if (_selectedMethod == 'By Company Name (A-Z)') {
      data.sort((a, b) => a.companyName.compareTo(b.companyName));
    } else if (_selectedMethod == 'By Company Name (Z-A)') {
      data.sort((a, b) => b.companyName.compareTo(a.companyName));
    } else if (_selectedMethod == 'By Total Sales (Low to High)') {
      data.sort((a, b) => a.totalSales.compareTo(b.totalSales));
    } else if (_selectedMethod == 'By Total Sales (High to Low)') {
      data.sort((a, b) => b.totalSales.compareTo(a.totalSales));
    } else if (_selectedMethod == 'By Total Quantity (Low to High)') {
      data.sort((a, b) => a.totalQuantity.compareTo(b.totalQuantity));
    } else if (_selectedMethod == 'By Total Quantity (High to Low)') {
      data.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    } else if (_selectedMethod == 'By Last Purchase (Ascending)') {
      data.sort((a, b) => a.lastPurchase.compareTo(b.lastPurchase));
    } else if (_selectedMethod == 'By Last Purchase (Descending)') {
      data.sort((a, b) => b.lastPurchase.compareTo(a.lastPurchase));
    }

    for (int i = 0; i < data.length; i++) {
      data[i] = Customer(
        id: data[i].id,
        companyName: data[i].companyName,
        customerUsername: data[i].customerUsername,
        email: data[i].email,
        contactNumber: data[i].contactNumber,
        totalSales: data[i].totalSales,
        totalQuantity: data[i].totalQuantity,
        lastPurchase: data[i].lastPurchase,
        serialNumber: i + 1,
      );
    }

    return data;
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isSortedAscending', isSortedAscending);
      });
      salesData = fetchSalesData(isSortedAscending, _selectedDateRange);
    });
  }

  void setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: now);
      selectedButtonIndex = selectedIndex;
      salesData = fetchSalesData(isSortedAscending, _selectedDateRange);
    });
  }

  void queryAllData() {
    setState(() {
      _selectedDateRange = null;
      selectedButtonIndex = 3;
      salesData = fetchSalesData(isSortedAscending, _selectedDateRange);
    });
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: ListView.builder(
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
          ),
        );
      },
    );
  }

  void _sortResults() {
    setState(() {
      salesData = fetchSalesData(isSortedAscending, _selectedDateRange);
    });
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
                    DateTime adjustedStartDate = DateTime(
                      picked.start.year,
                      picked.start.month,
                      picked.start.day,
                      0,
                      0,
                      0,
                    );

                    DateTime adjustedEndDate = DateTime(
                      picked.end.year,
                      picked.end.month,
                      picked.end.day,
                      23,
                      59,
                      59,
                    );

                    setState(() {
                      _selectedDateRange = DateTimeRange(
                          start: adjustedStartDate, end: adjustedEndDate);
                      selectedButtonIndex = -1;
                      salesData =
                          fetchSalesData(isSortedAscending, _selectedDateRange);
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
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (isCustomRangeSelected) {
                        return const Color(0xFF047CBD);
                      }
                      return const Color(0xFFD9D9D9);
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
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
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
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
        title: const Text('Customer Report',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: _buildFilterButtonAndDateRangeSelection(),
          ),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: salesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  List<Customer> sortedData = snapshot.data!;
                  return ListView.builder(
                    itemCount: sortedData.length,
                    itemBuilder: (context, index) {
                      final customer = sortedData[index];
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
                                    '${customer.serialNumber}. ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      customer.companyName,
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
                                    Text(
                                      '     Total Sales: ${customer.totalSalesDisplay}',
                                      style: const TextStyle(
                                          color: Color(0xFF0175FF),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '      Total Quantity: ${customer.totalQuantityDisplay}',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400),
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
                                              '      ID: ${customer.id}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Username: ${customer.customerUsername}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Email: ${customer.email}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Contact Number: ${customer.contactNumber}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '      Last Purchase: ${DateFormat('dd-MM-yyyy').format(customer.lastPurchase)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
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
}

class Customer {
  final int id;
  final String companyName;
  final String customerUsername;
  final String email;
  final String contactNumber;
  final double totalSales;
  final double totalQuantity;
  final DateTime lastPurchase;
  final int serialNumber;

  Customer({
    required this.id,
    required this.companyName,
    required this.customerUsername,
    required this.email,
    required this.contactNumber,
    required this.totalSales,
    required this.totalQuantity,
    required this.lastPurchase,
    required this.serialNumber,
  });

  String get totalSalesDisplay =>
      'RM ${NumberFormat("#,##0.000", "en_US").format(totalSales)}';
  String get totalQuantityDisplay =>
      NumberFormat("#,##0", "en_US").format(totalQuantity);
}
