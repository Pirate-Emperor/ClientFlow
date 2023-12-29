import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.lightBlue,
          onPrimary: Colors.white,
          surface: Colors.lightBlue,
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
      ),
      home: const SalesReportPage(),
    );
  }
}

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late Future<List<SalesData>> salesData;
  DateTimeRange? _selectedDateRange;
  int selectedButtonIndex = -1;
  bool isSortedAscending = false;
  String _loggedInUsername = '';

  final List<String> _sortingMethods = [
    'By Date (Ascending)',
    'By Date (Descending)',
    'By Total Sales (Low to High)',
    'By Total Sales (High to Low)',
    'By Total Quantity (Low to High)',
    'By Total Quantity (High to Low)',
    'By Total Orders (Low to High)',
    'By Total Orders (High to Low)',
  ];

  String _selectedMethod = 'By Date (Ascending)';

  @override
  void initState() {
    super.initState();
    salesData = Future.value([]);
    _loadUsername().then((_) {
      setState(() {
        selectedButtonIndex = 3;
        _selectedDateRange = DateTimeRange(
          start: DateTime(2019),
          end: DateTime.now(),
        );
      });
      salesData = fetchSalesData(_selectedDateRange);
    });
  }

  Future<void> _loadUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<SalesData>> fetchSalesData(DateTimeRange? dateRange) async {
    if (_loggedInUsername.isEmpty) {
      return [];
    }

    // Format date range
    String startDate =
        DateFormat('yyyy-MM-dd').format(dateRange?.start ?? DateTime(2019));
    String endDate =
        DateFormat('yyyy-MM-dd').format(dateRange?.end ?? DateTime.now());

    String sortOrder = isSortedAscending ? 'ASC' : 'DESC';

    // Prepare the API URL with the appropriate query parameters
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_report_page/get_sales_report_page.php?username=$_loggedInUsername&startDate=$startDate&endDate=$endDate&sortOrder=$sortOrder');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> salesData = jsonData['data'];

          // Map the API data to the SalesData model
          return salesData.map((data) {
            return SalesData(
              day: DateFormat('EEEE').format(DateTime.parse(data['Date'])),
              date: DateTime.parse(data['Date']),
              totalSales: (data['TotalSales'] as num).toDouble(),
              totalQuantity: (data['TotalQty'] as num).toDouble(),
              totalOrders: (data['TotalOrders'] as num).toInt(),
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

  void queryAllData() {
    setState(() {
      _selectedDateRange = DateTimeRange(
        start: DateTime(2019),
        end: DateTime.now(),
      );
      selectedButtonIndex = 3;
      salesData = fetchSalesData(_selectedDateRange);
    });
  }

  void toggleSortOrder() {
    setState(() {
      isSortedAscending = !isSortedAscending;
      salesData = fetchSalesData(_selectedDateRange);
    });
  }

  void setDateRange(int days, int selectedIndex) {
    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(days: days));
    setState(() {
      _selectedDateRange = DateTimeRange(start: start, end: now);
      isSortedAscending = false;
      salesData = fetchSalesData(_selectedDateRange);
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
      salesData = fetchSalesData(_selectedDateRange);
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
                    setState(() {
                      _selectedDateRange = picked;
                      selectedButtonIndex = -1;
                      salesData = fetchSalesData(_selectedDateRange);
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
    final screenWidth = MediaQuery.of(context).size.width;
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
            const Text('Sales Report', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.03,
              horizontal: screenWidth * 0.05,
            ),
            child: _buildFilterButtonAndDateRangeSelection(),
          ),
          Expanded(
            child: FutureBuilder<List<SalesData>>(
              future: salesData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data available'));
                } else {
                  List<SalesData> sortedData = _getSortedData(snapshot.data!);
                  return ListView.builder(
                    itemCount: sortedData.length,
                    itemBuilder: (context, index) {
                      final item = sortedData[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenWidth * 0.02,
                        ),
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
                          child: ListTile(
                            title: Text(
                              DateFormat('dd-MM-yyyy').format(item.date!),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sales: ${_formatCurrency(item.totalSales!)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF0175FF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Quantity: ${item.totalQuantity!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Colors.black, //33B44F
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Orders: ${item.totalOrders}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
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

  List<SalesData> _getSortedData(List<SalesData> data) {
    if (_selectedMethod == 'By Date (Ascending)') {
      data.sort((a, b) => a.date!.compareTo(b.date!));
    } else if (_selectedMethod == 'By Date (Descending)') {
      data.sort((a, b) => b.date!.compareTo(a.date!));
    } else if (_selectedMethod == 'By Total Sales (Low to High)') {
      data.sort((a, b) => a.totalSales!.compareTo(b.totalSales!));
    } else if (_selectedMethod == 'By Total Sales (High to Low)') {
      data.sort((a, b) => b.totalSales!.compareTo(a.totalSales!));
    } else if (_selectedMethod == 'By Total Quantity (Low to High)') {
      data.sort((a, b) => a.totalQuantity!.compareTo(b.totalQuantity!));
    } else if (_selectedMethod == 'By Total Quantity (High to Low)') {
      data.sort((a, b) => b.totalQuantity!.compareTo(a.totalQuantity!));
    } else if (_selectedMethod == 'By Total Orders (Low to High)') {
      data.sort((a, b) => a.totalOrders!.compareTo(b.totalOrders!));
    } else if (_selectedMethod == 'By Total Orders (High to Low)') {
      data.sort((a, b) => b.totalOrders!.compareTo(a.totalOrders!));
    }
    return data;
  }

  String _formatCurrency(double amount) {
    final NumberFormat formatter =
        NumberFormat.currency(symbol: 'RM', decimalDigits: 3, locale: 'en_US');
    return formatter.format(amount);
  }
}

class SalesData {
  final String? day;
  final DateTime? date;
  final double? totalSales;
  final double? totalQuantity;
  final int? totalOrders;

  SalesData(
      {this.day,
      this.date,
      this.totalSales,
      this.totalQuantity,
      this.totalOrders});
}
