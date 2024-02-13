import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'order_status_report_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Sales Orders Status',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const OrderStatusWidget(),
              ),
              const SizedBox(height: 32),
              const InProgressOrdersWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderStatusWidget extends StatelessWidget {
  const OrderStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12.0, left: 16.0),
          child: Text(
            'Order Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const OrderStatusReportPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
            child: const OrderStatusIndicator(),
          ),
        ),
      ],
    );
  }
}

class OrderStatusIndicator extends StatefulWidget {
  const OrderStatusIndicator({super.key});

  @override
  _OrderStatusIndicatorState createState() => _OrderStatusIndicatorState();
}

class _OrderStatusIndicatorState extends State<OrderStatusIndicator> {
  int complete = 0;
  int pending = 0;
  int voided = 0;
  DateTimeRange dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    loadUsernameAndFetchData();
  }

  Future<void> loadUsernameAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? '';
    setState(() {
      loggedInUsername = username;
    });
    await fetchDataForDateRange(dateRange);
  }

  Future<void> fetchDataForDateRange(DateTimeRange selectedDateRange) async {
    if (loggedInUsername.isEmpty) {
      return;
    }

    DateTime adjustedStartDate = DateTime(
      selectedDateRange.start.year,
      selectedDateRange.start.month,
      selectedDateRange.start.day,
      0,
      0,
      0,
    );

    DateTime adjustedEndDate = DateTime(
      selectedDateRange.end.year,
      selectedDateRange.end.month,
      selectedDateRange.end.day,
      23,
      59,
      59,
    );

    String formattedStartDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(adjustedStartDate);
    String formattedEndDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(adjustedEndDate);

    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/order_status_graph/get_order_status_graph.php?username=$loggedInUsername&startDate=$formattedStartDate&endDate=$formattedEndDate');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          int completeOrders = 0;
          int pendingOrders = 0;
          int voidedOrders = 0;

          final List<dynamic> statuses = jsonData['data'];

          for (var row in statuses) {
            String status = row['status'] as String;
            int count = row['Total'] as int;

            if (status == 'Complete') {
              completeOrders += count;
            } else if (status == 'Pending') {
              pendingOrders += count;
            } else if (status == 'Void') {
              voidedOrders += count;
            }
          }

          setState(() {
            complete = completeOrders;
            pending = pendingOrders;
            voided = voidedOrders;
          });
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching order status data: $e');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedRange = await showRangePickerDialog(
      context: context,
      minDate: DateTime(2019),
      maxDate: DateTime.now(),
      selectedRange: dateRange,
    );

    if (pickedRange != null && pickedRange != dateRange) {
      DateTime adjustedStartDate = DateTime(
        pickedRange.start.year,
        pickedRange.start.month,
        pickedRange.start.day,
        0,
        0,
        0,
      );

      DateTime adjustedEndDate = DateTime(
        pickedRange.end.year,
        pickedRange.end.month,
        pickedRange.end.day,
        23,
        59,
        59,
      );

      setState(() {
        dateRange =
            DateTimeRange(start: adjustedStartDate, end: adjustedEndDate);
      });

      await fetchDataForDateRange(dateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _selectDateRange(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 24.0),
                const SizedBox(width: 8),
                Text(
                  "${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.arrow_drop_down, size: 24.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$pending',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Orders Pending',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            CustomPaint(
              size: const Size(200, 200),
              painter: OrderStatusPainter(
                complete: complete,
                pending: pending,
                voided: voided,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIndicator(
                'Complete', const Color(0xFF487C08), complete),
            _buildStatusIndicator('Pending', Colors.blue, pending),
            _buildStatusIndicator('Void', Colors.red, voided),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, Color color, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brightness_1, color: color, size: 12),
          const SizedBox(width: 4),
          Text('$label $value'),
        ],
      ),
    );
  }
}

class OrderStatusPainter extends CustomPainter {
  final int complete;
  final int pending;
  final int voided;
  final double lineWidth;

  OrderStatusPainter({
    required this.complete,
    required this.pending,
    required this.voided,
    this.lineWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - lineWidth / 2;
    final total = complete + pending + voided;

    // Default grey color for zero status values
    final noDataColor = Colors.grey;

    Paint paintComplete = Paint()
      ..color = complete == 0 && pending == 0 && voided == 0
          ? noDataColor // Use grey for all zero values
          : const Color(0xFF487C08) // Original color if not zero
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    Paint paintPending = Paint()
      ..color = complete == 0 && pending == 0 && voided == 0
          ? noDataColor // Use grey for all zero values
          : Colors.blue // Original color if not zero
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    Paint paintVoided = Paint()
      ..color = complete == 0 && pending == 0 && voided == 0
          ? noDataColor // Use grey for all zero values
          : Colors.red // Original color if not zero
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    double startAngle = -3.141592653589793238462643383279502884197 / 2;
    const sweepAngle = 2 * 3.141592653589793238462643383279502884197;

    if (total == 0) {
      // If all statuses are 0, draw the entire chart in the `noDataColor`
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = noDataColor
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineWidth,
      );
    } else {
      // Draw the segments for non-zero values
      double completeSweep = sweepAngle * (complete / total);
      double pendingSweep = sweepAngle * (pending / total);
      double voidedSweep = sweepAngle * (voided / total);

      // Draw complete orders
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        completeSweep,
        false,
        paintComplete,
      );

      // Draw pending orders
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + completeSweep,
        pendingSweep,
        false,
        paintPending,
      );

      // Draw voided orders
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + completeSweep + pendingSweep,
        voidedSweep,
        false,
        paintVoided,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class InProgressOrdersWidget extends StatelessWidget {
  const InProgressOrdersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'In Progress Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<InProgressOrder>>(
          future: fetchInProgressOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...snapshot.data!.map((order) => Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              order.date,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                '${order.status} Orders',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )),
                  ],
                ),
              );
            } else {
              return const Text('No data');
            }
          },
        ),
      ],
    );
  }

  Future<List<InProgressOrder>> fetchInProgressOrders() async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/order_status_graph/get_in_progress_orders.php');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          List<InProgressOrder> inProgressOrders = [];

          for (var row in jsonData['data']) {
            inProgressOrders.add(
              InProgressOrder(
                row['created'].toString(),
                row['status'].toString(),
              ),
            );
          }

          return inProgressOrders;
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load in-progress orders');
      }
    } catch (e) {
      print('Error fetching in-progress orders: $e');
      return [];
    }
  }
}

class InProgressOrder {
  final String date;
  final String status;

  InProgressOrder(this.date, this.status);
}
