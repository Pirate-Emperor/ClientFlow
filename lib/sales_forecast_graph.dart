import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class SalesForecastGraph extends StatefulWidget {
  const SalesForecastGraph({super.key});

  @override
  _SalesForecastGraphState createState() => _SalesForecastGraphState();
}

class _SalesForecastGraphState extends State<SalesForecastGraph> {
  Future<List<SalesForecast>>? salesForecasts;
  String loggedInUsername = '';
  double salesConversionRate = 0.0;
  double averageOrderValue = 0.0;
  double prevAverageOrderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserDetails().then((_) {
      if (mounted) {
        setState(() {
          // Call the API to update the sales target before fetching data
          updateSalesTargetsInDatabase(); // Add this function call
          salesForecasts = fetchSalesForecasts();
          fetchSalesConversionRate();
          fetchAverageOrderValue();
        });
      }
    });
  }

  Future<void> updateSalesTargetsInDatabase() async {
    final apiUrl = Uri.parse(
      'https://haluansama.com/crm-sales/api/sales_forecast_graph/update_sales_target_table.php?username=$loggedInUsername',
    );

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          developer.log('Sales targets updated successfully');
        } else {
          developer
              .log('Failed to update sales targets: ${jsonData['message']}');
        }
      } else {
        developer.log('Error: Failed to update sales targets');
      }
    } catch (e) {
      developer.log('Error updating sales targets: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        loggedInUsername = prefs.getString('username') ?? '';
      });
    }
  }

  Future<List<SalesForecast>> fetchSalesForecasts() async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/get_sales_forecast.php?username=$loggedInUsername');

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> forecastData = jsonData['data'];

          List<SalesForecast> forecasts = forecastData.map((row) {
            final salesmanId = row['salesman_id'] as int;
            final salesmanName = row['salesman_name'] as String;
            final purchaseMonth = row['purchase_month'] as int;
            final purchaseYear = row['purchase_year'] as int;
            final totalSales = (row['total_sales'] as num).toDouble();
            final cartQuantity = (row['cart_quantity'] as num).toInt();

            return SalesForecast(
              salesmanId: salesmanId,
              salesmanName: salesmanName,
              purchaseMonth: purchaseMonth,
              purchaseYear: purchaseYear,
              totalSales: totalSales,
              cartQuantity: cartQuantity,
              previousMonthSales: 0.0,
              previousCartQuantity: 0,
            );
          }).toList();

          await createNewMonthRow();

          if (forecasts.isNotEmpty) {
            forecasts[0] = SalesForecast(
              salesmanId: forecasts[0].salesmanId,
              salesmanName: forecasts[0].salesmanName,
              purchaseMonth: forecasts[0].purchaseMonth,
              purchaseYear: forecasts[0].purchaseYear,
              totalSales: forecasts[0].totalSales,
              cartQuantity: forecasts[0].cartQuantity,
              previousMonthSales:
                  forecasts.length > 1 ? forecasts[1].totalSales : 0.0,
              previousCartQuantity:
                  forecasts.length > 1 ? forecasts[1].cartQuantity : 0,
            );
          }

          return forecasts;
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      developer.log('Error fetching sales forecasts: $e');
      return [];
    }
  }

  Future<void> createNewMonthRow() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/update_new_month_row.php?username=$loggedInUsername&currentMonth=$currentMonth&currentYear=$currentYear');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          developer.log('New month row created successfully.');
        } else {
          developer
              .log('Failed to create new month row: ${jsonData['message']}');
        }
      } else {
        developer.log('Failed to create new month row.');
      }
    } catch (e) {
      developer.log('Error creating new month row: $e');
    }
  }

  // Fetch Sales Conversion Rate from the new API
  Future<void> fetchSalesConversionRate() async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/get_sales_conversation_rate.php?username=$loggedInUsername');

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            salesConversionRate =
                double.parse(jsonData['data']['conversion_rate'].toString());
          });
        } else {
          developer.log('Failed to fetch conversion rate');
        }
      } else {
        developer.log('Error: Failed to fetch conversion rate');
      }
    } catch (e) {
      developer.log('Error fetching conversion rate: $e');
    }
  }

// Fetch Average Order Value (AOV) from the new API
  Future<void> fetchAverageOrderValue() async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/get_average_order_value.php?username=$loggedInUsername');

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            averageOrderValue =
                double.parse(jsonData['data']['avg_order_value'].toString());
            prevAverageOrderValue = double.parse(
                jsonData['data']['prev_avg_order_value'].toString());
          });
        } else {
          developer.log('Failed to fetch AOV');
        }
      } else {
        developer.log('Error: Failed to fetch AOV');
      }
    } catch (e) {
      developer.log('Error fetching AOV: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<SalesForecast>>(
                future: salesForecasts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // Even if snapshot has no data, we will still render the UI with default values
                    final data = snapshot.data ??
                        [
                          SalesForecast(
                            salesmanId: 0,
                            salesmanName: 'No Data',
                            purchaseMonth: DateTime.now().month,
                            purchaseYear: DateTime.now().year,
                            totalSales: 0.0,
                            cartQuantity: 0,
                            previousMonthSales: 0.0,
                            previousCartQuantity: 0,
                          )
                        ];

                    // If there's no data, or data contains zero values, we show default values in the UI
                    final currentMonthData = data.firstWhere(
                      (forecast) =>
                          forecast.purchaseMonth == DateTime.now().month,
                      orElse: () => SalesForecast(
                        salesmanId: 0,
                        salesmanName: 'No Data',
                        purchaseMonth: DateTime.now().month,
                        purchaseYear: DateTime.now().year,
                        totalSales: 0.0,
                        cartQuantity: 0,
                        previousMonthSales: 0.0,
                        previousCartQuantity: 0,
                      ),
                    );
                    return EditableSalesTargetCard(
                      currentSales: currentMonthData.totalSales,
                      predictedTarget: salesConversionRate,
                      cartQuantity: currentMonthData.cartQuantity,
                      stockNeeded: averageOrderValue.toInt(),
                      previousMonthSales: currentMonthData.previousMonthSales,
                      previousCartQuantity:
                          currentMonthData.previousCartQuantity,
                      loggedInUsername: loggedInUsername,
                      averageOrderValue: averageOrderValue,
                      prevAverageOrderValue: prevAverageOrderValue,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditableSalesTargetCard extends StatefulWidget {
  final double currentSales;
  final double predictedTarget;
  final int cartQuantity;
  final int stockNeeded;
  final double previousMonthSales;
  final int previousCartQuantity;
  final String loggedInUsername;
  final double averageOrderValue;
  final double prevAverageOrderValue;

  const EditableSalesTargetCard({
    super.key,
    required this.currentSales,
    required this.predictedTarget,
    required this.cartQuantity,
    required this.stockNeeded,
    required this.previousMonthSales,
    required this.previousCartQuantity,
    required this.loggedInUsername,
    required this.averageOrderValue,
    required this.prevAverageOrderValue,
  });

  @override
  _EditableSalesTargetCardState createState() =>
      _EditableSalesTargetCardState();
}

class _EditableSalesTargetCardState extends State<EditableSalesTargetCard> {
  late final NumberFormat _currencyFormat;
  late String _salesTarget;

  @override
  void initState() {
    super.initState();
    _currencyFormat =
        NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2);
    _salesTarget = _currencyFormat.format(0);
    _fetchSalesTarget();
  }

  Future<void> _fetchSalesTarget() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Construct the API URL with the necessary parameters
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/get_sales_target.php?username=${widget.loggedInUsername}&purchaseMonth=$currentMonth&purchaseYear=$currentYear');

    try {
      // Make a GET request to fetch the sales target from the API
      final response = await http.get(apiUrl);

      // Check if the request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Check if the response is successful and contains the sales target
        if (jsonData['status'] == 'success') {
          final salesTarget = double.parse(jsonData['sales_target'].toString());
          setState(() {
            _salesTarget = _currencyFormat.format(salesTarget);
          });
        } else {
          // Handle case where no sales target is found
          developer.log('Error: ${jsonData['message']}');
        }
      } else {
        // Handle unsuccessful responses (e.g., server issues, 404, etc.)
        developer.log(
            'Failed to load sales target, status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any errors that occur during the API call
      developer.log('Error fetching sales target: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double salesTargetValue = 0.0;
    try {
      salesTargetValue =
          double.parse(_salesTarget.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      salesTargetValue = 1.0;
    }

    double progressValue =
        (widget.currentSales / salesTargetValue).clamp(0.0, 1.0);

    double completionPercentage =
        (widget.currentSales / salesTargetValue) * 100;
    completionPercentage = completionPercentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: 240,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Container(
              decoration: BoxDecoration(
                  image: const DecorationImage(
                    opacity: 0.8,
                    image: ResizeImage(
                        AssetImage('asset/Data_Analytics_stamp.png'),
                        width: 150,
                        height: 150),
                    alignment: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      blurStyle: BlurStyle.normal,
                      color: Color.fromARGB(75, 117, 117, 117),
                      spreadRadius: 0.1,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                  gradient: const LinearGradient(colors: [
                    Color.fromRGBO(150, 218, 255, 0.882),
                    Colors.white
                  ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: Text(
                                'Sales Target',
                                style: GoogleFonts.inter(
                                    textStyle:
                                        const TextStyle(letterSpacing: -0.8),
                                    fontSize: 20.0,
                                    color: const Color(0xff085ABE),
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.grey[800]),
                            onPressed: _editSalesTarget,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Spacer(),
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _salesTarget,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.inter(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff085ABE)),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Current: ${NumberFormat.currency(locale: 'en_MY', symbol: 'RM', decimalDigits: 2).format(widget.currentSales)}',
                                style: GoogleFonts.inter(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w400,
                                    color: const Color.fromARGB(255, 0, 0, 0)),
                              ),
                              const SizedBox(height: 4.0),
                              SizedBox(
                                width: 180,
                                child: LinearProgressIndicator(
                                  value: progressValue,
                                  minHeight: 20.0,
                                  backgroundColor:
                                      const Color.fromRGBO(112, 112, 112, 0.37),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xff23C197)),
                                ),
                              ),
                              Text(
                                '${completionPercentage.toStringAsFixed(0)}% Complete',
                                textAlign: TextAlign.start,
                                style: GoogleFonts.inter(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                    color: const Color.fromRGBO(0, 0, 0, 1)),
                              ),
                              const SizedBox(height: 8.0),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.95,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.10,
              children: [
                InfoBox(
                  label: 'Monthly Revenue',
                  value: NumberFormat.currency(
                          locale: 'en_MY', symbol: 'RM', decimalDigits: 2)
                      .format(widget.currentSales),
                  currentValue: widget.currentSales,
                  previousValue: widget.previousMonthSales,
                  isUp: widget.currentSales >= widget.previousMonthSales,
                  isDown: widget.currentSales < widget.previousMonthSales,
                  backgroundColor1: const Color.fromARGB(52, 33, 72, 212),
                  backgroundColor2: const Color(0xFFFFFFFF),
                  borderColor: const Color(0xFF4566DD),
                  textColor: const Color(0xFF4566DD),
                  fromLastMonthTextColor: Colors.black87,
                ),
                InfoBox(
                  label: 'Sales Conversion Rate',
                  value: '${widget.predictedTarget.toStringAsFixed(1)}%',
                  currentValue: widget.predictedTarget,
                  previousValue: widget.previousMonthSales,
                  isUp: widget.predictedTarget >= widget.previousMonthSales,
                  isDown: widget.predictedTarget < widget.previousMonthSales,
                  backgroundColor1: const Color.fromARGB(186, 255, 237, 211),
                  backgroundColor2: const Color(0xFFFFFFFF),
                  borderColor: const Color.fromARGB(248, 255, 166, 0),
                  textColor: const Color(0xFFFEAF20),
                  fromLastMonthTextColor: Colors.black87,
                ),
                InfoBox(
                  label: 'Stock Sold',
                  value: '${widget.cartQuantity}',
                  currentValue: widget.cartQuantity.toDouble(),
                  previousValue: widget.previousCartQuantity.toDouble(),
                  isUp: widget.cartQuantity >= widget.previousCartQuantity,
                  isDown: widget.cartQuantity < widget.previousCartQuantity,
                  backgroundColor1: const Color(0x3029C194),
                  backgroundColor2: const Color(0xFFFFFFFF),
                  borderColor: const Color(0xFF29C194),
                  textColor: const Color(0xFF29C194),
                  fromLastMonthTextColor: Colors.black,
                ),
                InfoBox(
                  label: 'Average Order Value (AOV)',
                  value: NumberFormat.currency(
                          locale: 'en_MY', symbol: 'RM', decimalDigits: 2)
                      .format(widget.averageOrderValue),
                  currentValue: widget.averageOrderValue,
                  previousValue: widget.prevAverageOrderValue,
                  isUp:
                      widget.averageOrderValue >= widget.prevAverageOrderValue,
                  isDown:
                      widget.averageOrderValue < widget.prevAverageOrderValue,
                  backgroundColor1: const Color(0x30D563E3),
                  backgroundColor2: const Color(0xFFFFFFFF),
                  borderColor: const Color(0xFFD563E3),
                  textColor: const Color(0xFFD563E3),
                  fromLastMonthTextColor: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editSalesTarget() async {
    final newSalesTarget = await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Edit Sales Target'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New Sales Target'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newSalesTarget != null) {
      setState(() {
        _salesTarget = _currencyFormat.format(double.parse(newSalesTarget));
      });

      await updateSalesTargetInDatabase(double.parse(newSalesTarget));
    }
  }

  Future<void> updateSalesTargetInDatabase(double newSalesTarget) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_forecast_graph/update_sales_target.php'
        '?username=${widget.loggedInUsername}&newSalesTarget=$newSalesTarget&purchaseMonth=$currentMonth&purchaseYear=$currentYear');

    try {
      // Make the HTTP GET request
      final response = await http.get(apiUrl);

      // Check the status code of the response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Check if the API returned a success status
        if (jsonData['status'] == 'success') {
          developer.log('Sales target updated successfully');
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to update sales target');
      }
    } catch (e) {
      developer.log('Error updating sales target: $e');
    }
  }
}

class InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final double currentValue;
  final double? previousValue;
  final double? previousPrediction;
  final bool isUp;
  final bool isDown;
  final Color backgroundColor1;
  final Color backgroundColor2;
  final Color borderColor;
  final Color textColor;
  final Color fromLastMonthTextColor;

  const InfoBox({
    super.key,
    required this.label,
    required this.value,
    required this.currentValue,
    this.previousValue,
    this.previousPrediction,
    this.isUp = false,
    this.isDown = false,
    required this.backgroundColor1,
    required this.backgroundColor2,
    required this.borderColor,
    required this.textColor,
    required this.fromLastMonthTextColor,
  });

  @override
  Widget build(BuildContext context) {
    double previous = previousValue ?? 0.0;
    double prediction = previousPrediction ?? 0.0;
    double change = 0.0;

    if (label == 'Monthly Revenue') {
      if (previous != 0.0) {
        change = ((currentValue - previous) / previous) * 100;
      }
    } else if (label == 'Stock Sold') {
      if (previous != 0.0) {
        change = ((currentValue - previous) / previous) * 100;
      }
    }

    change = change.clamp(-100.0, 100.0);
    bool isIncrease = change >= 0;

    Color increaseColor = isIncrease
        ? const Color.fromARGB(255, 0, 117, 6)
        : const Color.fromARGB(255, 255, 0, 0);

    Widget icon;
    switch (label) {
      case 'Monthly Revenue':
        icon = const Icon(Icons.monetization_on, color: Colors.black);
        break;
      case 'Sales Conversion Rate':
        icon = const Icon(Icons.gps_fixed, color: Colors.black);
        break;
      case 'Stock Sold':
        icon = const Icon(Icons.outbox, color: Colors.black);
        break;
      case 'Average Order Value (AOV)':
        icon = const Icon(Icons.inbox, color: Colors.black);
        break;
      default:
        icon = const SizedBox.shrink();
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 4,
          ),
        ),
        gradient: LinearGradient(
            colors: [backgroundColor1, backgroundColor2],
            stops: const [0.05, 0.80],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 6),
          if ((label == 'Monthly Revenue' &&
                  currentValue != 0 &&
                  previous != 0) ||
              (label == 'Stock Sold' &&
                  currentValue != 0 &&
                  previous != 0)) ...[
            Expanded(
              child: Text(
                '${isIncrease ? '▲' : '▼'} ${change.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isIncrease ? increaseColor : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                softWrap: true,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                'From Last Month',
                style: TextStyle(
                  color: fromLastMonthTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SalesForecast {
  final int salesmanId;
  final String salesmanName;
  final int purchaseMonth;
  final int purchaseYear;
  final double totalSales;
  final int cartQuantity;
  final double previousMonthSales;
  final int previousCartQuantity;
  final double predictedTarget;
  final int stockNeeded;

  SalesForecast({
    required this.salesmanId,
    required this.salesmanName,
    required this.purchaseMonth,
    required this.purchaseYear,
    required this.totalSales,
    required this.cartQuantity,
    required this.previousMonthSales,
    required this.previousCartQuantity,
    this.predictedTarget = 0.0,
    this.stockNeeded = 0,
  });
}
