import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerSalesReport extends StatefulWidget {
  final int customerId;

  const CustomerSalesReport({super.key, required this.customerId});

  @override
  _CustomerSalesReportState createState() => _CustomerSalesReportState();
}

class _CustomerSalesReportState extends State<CustomerSalesReport> {
  final Map<String, List<SalesData>> _salesDataMap = {};
  String _selectedInterval = '3D';

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    await _fetchData('3D');
    await _fetchData('5D');
    await _fetchData('1M');
    await _fetchData('1Y');
    await _fetchData('5Y');
  }

  Future<void> _fetchData(String interval) async {
    if (widget.customerId == 0) {
      return;
    }

    List<SalesData> fetchedData;
    switch (interval) {
      case '3D':
        fetchedData =
            await fetchCustomerSalesData('ThreeDays', widget.customerId);
        break;
      case '5D':
        fetchedData =
            await fetchCustomerSalesData('FiveDays', widget.customerId);
        break;
      case '1M':
        fetchedData =
            await fetchCustomerSalesData('FourMonths', widget.customerId);
        break;
      case '1Y':
        fetchedData = await fetchCustomerSalesData('Year', widget.customerId);
        break;
      case '5Y':
        fetchedData =
            await fetchCustomerSalesData('FiveYears', widget.customerId);
        break;
      default:
        fetchedData = [];
    }

    if (mounted) {
      setState(() {
        _salesDataMap[interval] = fetchedData;
      });
    }
  }

  Future<List<SalesData>> fetchCustomerSalesData(
      String reportType, int customerId) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/customer_insight_graph/get_customer_graph.php?reportType=$reportType&customerId=$customerId');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          return jsonData['data'].map<SalesData>((row) {
            DateTime? date;
            try {
              if (reportType == 'FiveYears') {
                date = DateTime.utc(row['Year']);
              } else if (reportType == 'FourMonths' || reportType == 'Year') {
                date = DateFormat('yyyy-MM').parseUtc(row['Date'] ?? '');
              } else {
                date = DateFormat('yyyy-MM-dd')
                    .parseUtc(row['FormattedDate'] ?? '');
              }
            } catch (e) {
              date = null;
            }
            return SalesData(
              date: date?.toLocal() ?? DateTime.now(),
              totalSales: (row['TotalSales'] as num).toDouble(),
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching customer sales data: $e');
      return [];
    }
  }

  void _refreshData() async {
    await _fetchData(_selectedInterval);
  }

  Widget _buildQuickAccessButton(String interval) {
    final bool isSelected = _selectedInterval == interval;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedInterval = interval;
          _refreshData();
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected
                ? const Color(0xFF047CBD)
                : const Color(0xFFD9D9D9);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            return isSelected ? Colors.white : Colors.black;
          },
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      child: Text(interval, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAccessButton('3D'),
                const SizedBox(width: 10),
                _buildQuickAccessButton('5D'),
                const SizedBox(width: 10),
                _buildQuickAccessButton('1M'),
                const SizedBox(width: 10),
                _buildQuickAccessButton('1Y'),
                const SizedBox(width: 10),
                _buildQuickAccessButton('5Y'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _salesDataMap[_selectedInterval] != null
              ? _salesDataMap[_selectedInterval]!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 4.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 18),
                            height: MediaQuery.of(context).size.height * 0.52,
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
                            child: LineChart(
                              sampleData(_salesDataMap[_selectedInterval]!),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text('No data available'),
                    )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
      ],
    );
  }

  LineChartData sampleData(List<SalesData> salesData) {
    List<FlSpot> spots = salesData
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.totalSales))
        .toList();

    double maxYValue = salesData.map((e) => e.totalSales).reduce(math.max);
    double topPadding = maxYValue <= 100 ? 40 : (maxYValue * 0.2);
    double maxY = maxYValue + topPadding;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: maxY / 6,
        getDrawingHorizontalLine: (value) => FlLine(
          color: const Color(0xffe7e8ec),
          strokeWidth: 1,
        ),
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        leftTitles: SideTitles(
          showTitles: true,
          getTitles: (value) {
            if (value >= 1000) {
              return '${(value / 1000).toStringAsFixed(1)}K';
            } else {
              return value.toInt().toString();
            }
          },
          interval: maxY / 6,
          reservedSize: 40,
          margin: 8,
        ),
        bottomTitles: SideTitles(
          showTitles: true,
          getTitles: (value) {
            if (salesData.isEmpty) return '';

            int index = value.toInt();
            if (_selectedInterval == '3D' || _selectedInterval == '5D') {
              if (index >= 0 && index < salesData.length) {
                return DateFormat('EEE').format(salesData[index].date);
              }
            } else if (_selectedInterval == '1M') {
              if (index >= 0 && index < salesData.length) {
                return DateFormat('MMM yy').format(salesData[index].date);
              }
            } else if (_selectedInterval == '1Y') {
              int interval = (salesData.length / 4).round();
              if (index % interval == 0 || index == salesData.length - 1) {
                return DateFormat('MMM yy').format(salesData[index].date);
              }
            } else if (_selectedInterval == '5Y') {
              if (index >= 0 && index < salesData.length) {
                return salesData[index].date.year.toString();
              }
            }
            return '';
          },
          reservedSize: 22,
          margin: 8,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 1),
          left: BorderSide(color: Colors.grey, width: 1),
          right: BorderSide.none,
          top: BorderSide.none,
        ),
      ),
      minX: 0,
      maxX: salesData.length.toDouble() - 1,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          colors: [Colors.blue],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            colors: [Colors.blue.withOpacity(0.3)],
            cutOffY: 0,
            applyCutOffY: true,
          ),
          aboveBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueAccent,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
            DateTime date = salesData[spot.spotIndex].date;
            String formattedDate;
            if (_selectedInterval == '3D' || _selectedInterval == '5D') {
              formattedDate = DateFormat('dd-MM-yyyy').format(date);
            } else if (_selectedInterval == '1M' || _selectedInterval == '1Y') {
              formattedDate = DateFormat('MMM yyyy').format(date);
            } else if (_selectedInterval == '5Y') {
              formattedDate = date.year.toString();
            } else {
              formattedDate = DateFormat('yyyy-MM-dd').format(date);
            }

            String formattedSales =
                'RM${spot.y.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

            return LineTooltipItem(
              'Date: $formattedDate\nSales: $formattedSales',
              const TextStyle(color: Colors.white),
            );
          }).toList(),
        ),
        handleBuiltInTouches: true,
      ),
    );
  }
}

class SalesData {
  final DateTime date;
  final double totalSales;

  SalesData({
    required this.date,
    required this.totalSales,
  });
}
