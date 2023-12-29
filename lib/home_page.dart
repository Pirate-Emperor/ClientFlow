import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:clientflow/Components/navigation_bar.dart';
import 'package:clientflow/background_tasks.dart';
import 'package:clientflow/create_lead_page.dart';
import 'package:clientflow/create_task_page.dart';
import 'package:intl/intl.dart';
import 'package:clientflow/customer_Insights.dart';
import 'dart:async';
import 'package:clientflow/notification_page.dart';
import 'package:clientflow/sales_lead_closed_widget.dart';
import 'package:clientflow/sales_lead_eng_widget.dart';
import 'package:clientflow/sales_lead_nego_widget.dart';
import 'package:clientflow/sales_lead_orderprocessing_widget.dart';
import 'package:clientflow/utility_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

final List<String> tabbarNames = [
  'Opportunities',
  'Engagement',
  'Negotiation',
  'Order Processing',
  'Closed',
];

// Auto update salesman performance
class SalesmanPerformanceUpdater {
  Timer? _timer;

  void startPeriodicUpdate(int salesmanId) {
    // Update every hour
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _updateSalesmanPerformance(salesmanId);
    });
  }

  void stopPeriodicUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    final String apiUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_salesman_performance.php?salesman_id=$salesmanId';

    try {
      // Make the POST request to the API with the salesmanId
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'salesman_id': salesmanId.toString()},
      );

      // Check if the response status is successful
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          developer.log('Salesman performance updated successfully.');
        } else {
          developer
              .log('Failed to update performance: ${jsonResponse['message']}');
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating salesman performance: $e');
    }
  }
}

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<LeadItem> leadItems = [];
  List<LeadItem> engagementLeads = [];
  List<LeadItem> negotiationLeads = [];
  List<LeadItem> orderProcessingLeads = [];
  List<LeadItem> closedLeads = [];

  Map<int, DateTime> latestModifiedDates = {};
  Map<int, double> latestTotals = {};
  late int salesmanId;

  bool _isLoading = true; // Track loading state
  late SalesmanPerformanceUpdater _performanceUpdater;

  late TabController _tabController;
  String _sortBy = 'created_date';
  bool _sortAscending = true;
  bool _isButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeSalesmanId();
    _performanceUpdater = SalesmanPerformanceUpdater();
    // _fetchLeadItems();
    // _cleanAndValidateLeadData().then((_) => _fetchLeadItems());
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false; // Set loading state to false when data is loaded
      });
    });
    _tabController = TabController(
      length: tabbarNames.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      setState(() {
        _isButtonVisible =
            _tabController.index == 0; // Show button only on first tab
      });
    });
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    developer.log('Initialized salesmanId: $id');
    setState(() {
      salesmanId = id;
    });
    _performanceUpdater.startPeriodicUpdate(salesmanId);
    await _cleanAndValidateLeadData();
    await _fetchLeadItems();
  }

  void _sortLeads(List<LeadItem> leads) {
    setState(() {
      leads.sort((a, b) {
        switch (_sortBy) {
          case 'created_date':
            return _sortAscending
                ? a.createdDate.compareTo(b.createdDate)
                : b.createdDate.compareTo(a.createdDate);
          case 'predicted_sales':
            double aAmount = double.parse(a.amount.substring(2));
            double bAmount = double.parse(b.amount.substring(2));
            return _sortAscending
                ? aAmount.compareTo(bAmount)
                : bAmount.compareTo(aAmount);
          case 'customer_name':
            return _sortAscending
                ? a.customerName.compareTo(b.customerName)
                : b.customerName.compareTo(a.customerName);
          default:
            return 0;
        }
      });
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Created Date'),
                onTap: () {
                  _updateSortCriteria('created_date');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Predicted Sales'),
                onTap: () {
                  _updateSortCriteria('predicted_sales');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Customer Name'),
                onTap: () {
                  _updateSortCriteria('customer_name');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSortCriteria(String newSortBy) {
    setState(() {
      if (_sortBy == newSortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSortBy;
        _sortAscending = true;
      }
      _sortLeads(leadItems);
      _sortLeads(engagementLeads);
      _sortLeads(negotiationLeads);
      _sortLeads(orderProcessingLeads);
      _sortLeads(closedLeads);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _performanceUpdater.stopPeriodicUpdate();
    super.dispose();
  }

  // Update salesman performance by calling the sql Stored Procedure
  Future<void> _updateSalesmanPerformance(int salesmanId) async {
    final String apiUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_salesman_performance.php?salesman_id=$salesmanId';

    try {
      // Make the POST request to the API with the salesmanId
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'salesman_id': salesmanId.toString()},
      );

      // Check if the response status is successful
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          developer.log('Salesman performance updated successfully.');
        } else {
          developer
              .log('Failed to update performance: ${jsonResponse['message']}');
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating salesman performance: $e');
    }
  }

  // Get average closed value by calling the sql function
  Future<double> _getAverageClosedValue(
      int salesmanId, String startDate, String endDate) async {
    final String apiUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/get_average_closed_value.php?salesman_id=$salesmanId&start_date=$startDate&end_date=$endDate';

    try {
      // Make the POST request to the API with the salesmanId, startDate, and endDate
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'salesman_id': salesmanId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      // Check if the response status is successful
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['averageClosedValue'];
        } else {
          developer.log(
              'Failed to get average closed value: ${jsonResponse['message']}');
          return 0;
        }
      } else {
        developer.log('Server error: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      developer.log('Error getting average closed value: $e');
      return 0;
    }
  }

  // // Get stage duration by calling the sql function
  // Future<int> getStageDuration(int leadId, String stage) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     var results = await conn.query(
  //         'SELECT calculate_stage_duration(?, ?) AS duration', [leadId, stage]);
  //     if (results.isNotEmpty) {
  //       return results.first['duration'] as int;
  //     }
  //     return 0;
  //   } catch (e) {
  //     developer.log('Error calculating stage duration: $e');
  //     return 0;
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _cleanAndValidateLeadData() async {
    developer
        .log('Starting _cleanAndValidateLeadData for salesman_id: $salesmanId');
    final url = Uri.parse(
        'https://haluansama.com/crm-sales/api/sales_lead/clean_validate_leads.php?salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        developer.log('_cleanAndValidateLeadData response: ${response.body}');
        if (data['status'] == 'success') {
          developer.log('Lead data cleaned and validated successfully.');
        } else {
          developer.log('Error: ${data['message']}');
        }
      } else {
        developer
            .log('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error making API call: $e');
    }
  }

  // Future<void> _cleanAndValidateLeadData() async {
  //   final url = Uri.parse(
  //       'https://haluansama.com/crm-sales/api/sales_lead/clean_validate_leads.php?salesman_id=$salesmanId');

  //   try {
  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       if (data['status'] == 'success') {
  //         developer.log('Lead data cleaned and validated successfully.');
  //       } else {
  //         developer.log('Error: ${data['message']}');
  //       }
  //     } else {
  //       developer
  //           .log('Failed to load data. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     developer.log('Error making API call: $e');
  //   }
  // }

  // Auto generate lead item from cart
  Future<void> _fetchLeadItems() async {
    if (!mounted) return;
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/get_sales_lead_automatically.php?salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final leads = data['leads'] as List;

          for (var lead in leads) {
            var customerName = lead['customer_name'];
            var description = lead['description'];
            var total = double.parse(lead['total']);
            var createdDate = lead['created_date'];
            var contactNumber = lead['contact_number'] ?? '';
            var emailAddress = lead['email_address'] ?? '';
            var addressLine1 = lead['address'] ?? '';

            // If the INSERT operation is successful, add the leadItem to the list
            setState(() {
              leadItems.add(LeadItem(
                id: lead['id'],
                salesmanId: salesmanId,
                customerName: customerName,
                description: description,
                createdDate: createdDate,
                amount: 'RM${total.toStringAsFixed(2)}',
                contactNumber: contactNumber,
                emailAddress: emailAddress,
                stage: 'Opportunities',
                addressLine1: addressLine1,
                salesOrderId: '',
              ));
            });

            developer.log("Created new lead for customer: $customerName");
          }
        } else {
          developer.log('Error fetching lead items: ${data['message']}');
        }
      } else {
        developer.log('Error fetching lead items: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching lead items: $e');
    }

    await _fetchCreateLeadItems();

    _sortLeads(leadItems);
    _sortLeads(engagementLeads);
    _sortLeads(negotiationLeads);
    _sortLeads(orderProcessingLeads);
    _sortLeads(closedLeads);
    developer.log("Finished _fetchLeadItems");
  }

  Future<void> _fetchCreateLeadItems() async {
    final apiUrl = dotenv.env['API_URL'];
    const offset = 0;
    const limit = 100;

    try {
      // Make the HTTP request to the API
      final response = await http.get(Uri.parse(
          '$apiUrl/sales_lead/get_sales_leads.php?salesman_id=$salesmanId&offset=$offset&limit=$limit'));

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final salesLeads = data['salesLeads'] as List;

          // Clear existing lead lists (uncomment if necessary)
          leadItems.clear();
          engagementLeads.clear();
          negotiationLeads.clear();
          orderProcessingLeads.clear();
          closedLeads.clear();

          for (var item in salesLeads) {
            // Ensure the created date is formatted correctly
            String createdDate = item['created_date'] != null
                ? DateFormat('MM/dd/yyyy')
                    .format(DateTime.parse(item['created_date']))
                : DateFormat('MM/dd/yyyy').format(DateTime.now());

            // Map the lead item data
            final leadItem = LeadItem(
              id: item['id'] != null ? item['id'] as int : 0,
              salesmanId: salesmanId,
              customerName: item['customer_name'] as String,
              description: item['description'] ?? '',
              createdDate: createdDate,
              amount: 'RM${item['predicted_sales']}',
              contactNumber: item['contact_number'] ?? '',
              emailAddress: item['email_address'] ?? '',
              stage: item['stage'] as String,
              addressLine1: item['address'] ?? '',
              salesOrderId: item['so_id']?.toString(),
              previousStage: item['previous_stage']?.toString(),
              quantity: item['quantity'] != null ? item['quantity'] as int : 0,
              engagementStartDate: item['engagement_start_date'] != null
                  ? DateTime.parse(item['engagement_start_date'])
                  : null,
              negotiationStartDate: item['negotiation_start_date'] != null
                  ? DateTime.parse(item['negotiation_start_date'])
                  : null,
            );

            // Add the lead item to the appropriate list based on its stage
            setState(() {
              if (leadItem.stage == 'Opportunities') {
                leadItems.add(leadItem);
              } else if (leadItem.stage == 'Engagement') {
                engagementLeads.add(leadItem);
              } else if (leadItem.stage == 'Negotiation') {
                negotiationLeads.add(leadItem);
              } else if (leadItem.stage == 'Order Processing') {
                orderProcessingLeads.add(leadItem);
              } else if (leadItem.stage == 'Closed') {
                closedLeads.add(leadItem);
              }
            });
          }
        } else {
          developer.log('Error: ${data['message']}');
        }
      } else {
        developer.log('Error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching sales_lead items: $e');
    }
  }

  // Future<void> _fetchCreateLeadItems(MySqlConnection conn) async {
  //   try {
  //     Results results = await conn
  //         .query('SELECT * FROM sales_lead WHERE salesman_id = $salesmanId');
  //     for (var row in results) {
  //       var customerName = row['customer_name'] as String;
  //       var description = row['description'] as String? ?? '';
  //       var amount = row['predicted_sales'].toString();
  //       var createdDate = row['created_date'] != null
  //           ? DateFormat('MM/dd/yyyy').format(row['created_date'])
  //           : DateFormat('MM/dd/yyyy').format(DateTime.now());
  //       var stage = row['stage'].toString();
  //       var contactNumber = row['contact_number'].toString();
  //       var emailAddress = row['email_address'].toString();
  //       var addressLine1 = row['address'].toString();
  //       var salesOrderId = row['so_id']?.toString();
  //       var previousStage = row['previous_stage']?.toString();
  //       var quantity = row['quantity'];
  //       // 添加这两行来获取 engagement_start_date 和 negotiation_start_date
  //       var engagementStartDate = row['engagement_start_date'] as DateTime?;
  //       var negotiationStartDate = row['negotiation_start_date'] as DateTime?;
  //
  //       var leadItem = LeadItem(
  //         id: row['id'] as int, // 添加这一行
  //         salesmanId: salesmanId,
  //         customerName: customerName,
  //         description: description,
  //         createdDate: createdDate,
  //         amount: 'RM$amount',
  //         contactNumber: contactNumber,
  //         emailAddress: emailAddress,
  //         stage: stage,
  //         addressLine1: addressLine1,
  //         salesOrderId: salesOrderId,
  //         previousStage: previousStage,
  //         quantity: quantity,
  //         engagementStartDate: engagementStartDate, // 添加这行
  //         negotiationStartDate: negotiationStartDate, // 添加这行
  //       );
  //
  //       setState(() {
  //         if (stage == 'Opportunities') {
  //           leadItems.add(leadItem);
  //         } else if (stage == 'Engagement') {
  //           engagementLeads.add(leadItem);
  //         } else if (stage == 'Negotiation') {
  //           negotiationLeads.add(leadItem);
  //         } else if (stage == 'Order Processing') {
  //           orderProcessingLeads.add(leadItem);
  //         } else if (stage == 'Closed') {
  //           closedLeads.add(leadItem);
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     developer.log('Error fetching sales_lead items: $e');
  //   }
  // }

  Future<String> _fetchCustomerName(int customerId) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/get_customer_name.php?customer_id=$customerId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          return data['company_name'];
        } else {
          developer.log('Error fetching customer name: ${data['message']}');
          return 'Unknown';
        }
      } else {
        developer
            .log('Error fetching customer name: HTTP ${response.statusCode}');
        return 'Unknown';
      }
    } catch (e) {
      developer.log('Error fetching customer name: $e');
      return 'Unknown';
    }
  }

  Future<void> _updateSalesOrderId(
      LeadItem leadItem, String salesOrderId) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse('$apiUrl/sales_lead/update_sales_order_id.php');

    try {
      final response = await http.post(
        url,
        body: {
          'lead_id': leadItem.id.toString(),
          'sales_order_id': salesOrderId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          developer.log('Sales order ID updated successfully');
        } else {
          developer.log('Error updating sales order ID: ${data['message']}');
        }
      } else {
        developer
            .log('Error updating sales order ID: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating sales order ID: $e');
    }
  }

  Future<void> _moveFromNegotiationToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_sales_lead_from_negotiation_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            negotiationLeads.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
            // leadItem.stage = 'Order Processing';
            // leadItem.previousStage = responseData['previous_stage'];
            // orderProcessingLeads.add(leadItem);
          });

          // Call other update functions
          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesOrderId(leadItem, salesOrderId);
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Successfully moved lead to Order Processing stage')),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  // Future<void> _moveFromNegotiationToOrderProcessing(
  //     LeadItem leadItem, String salesOrderId, int? quantity) async {
  //   setState(() {
  //     negotiationLeads.remove(leadItem);
  //     leadItem.salesOrderId = salesOrderId;
  //     leadItem.quantity = quantity;
  //   });
  // // Log the event
  //   await EventLogger.logEvent(
  //       salesmanId,
  //       'Moved lead from Negotiation stage to Order Processing stage',
  //       'Stage Movement',
  //       leadId: leadItem.id);
  //   await _updateLeadStage(leadItem, 'Order Processing');
  //   await _updateSalesOrderId(leadItem, salesOrderId);
  //   await _updateSalesmanPerformance(salesmanId);
  // }

  Future<void> _moveToEngagement(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_sales_lead_to_engagement.php?lead_id=${leadItem.id}&salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          leadItem.contactNumber = data['contact_number'];
          leadItem.emailAddress = data['email_address'];

          setState(() {
            leadItems.remove(leadItem);
            engagementLeads.add(leadItem);
          });

          await _updateLeadStage(leadItem, 'Engagement');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Lead moved to Engagement stage successfully');
        } else {
          developer
              .log('Error moving lead to Engagement stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Engagement stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Engagement stage: $e');
    }
  }

  Future<void> _moveToNegotiation(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_sales_lead_to_negotiation.php?lead_id=${leadItem.id}&salesman_id=$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          leadItem.contactNumber = data['contact_number'];
          leadItem.emailAddress = data['email_address'];

          setState(() {
            leadItems.remove(leadItem);
            negotiationLeads.add(leadItem);
          });

          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Lead moved to Negotiation stage successfully');
        } else {
          developer.log(
              'Error moving lead to Negotiation stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Negotiation stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Negotiation stage: $e');
    }
  }

  Future<void> _moveFromEngagementToNegotiation(LeadItem leadItem) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
            '$apiUrl/sales_lead/update_sales_lead_from_engagement_to_negotiation.php')
        .replace(queryParameters: {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    });

    try {
      // Call the main API to move the lead
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // If successful, update the local state
          setState(() {
            engagementLeads.remove(leadItem);
            negotiationLeads.add(leadItem);
          });

          // Call other APIs
          await _updateLeadStage(leadItem, 'Negotiation');
          await _updateSalesmanPerformance(salesmanId);

          developer.log('Successfully moved lead to Negotiation stage');
        } else {
          developer.log(
              'Error moving lead to Negotiation stage: ${data['message']}');
        }
      } else {
        developer.log(
            'Error moving lead to Negotiation stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Negotiation stage: $e');
    }
  }

  // Future<void> _moveFromOrderProcessingToClosed(LeadItem leadItem) async {
  //   setState(() {
  //     orderProcessingLeads.remove(leadItem);
  //     closedLeads.add(leadItem);
  //   });
  //   // Log the event
  //   await EventLogger.logEvent(
  //       salesmanId,
  //       'Moved lead from Order Processing stage to Closed stage',
  //       'Stage Movement',
  //       leadId: leadItem.id);
  //   await _updateLeadStage(leadItem, 'Closed');
  //   await _updateSalesmanPerformance(salesmanId);
  // }

  Future<void> _moveFromOrderProcessingToClosed(LeadItem leadItem) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_sales_lead_from_order_processing_to_closed.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            orderProcessingLeads.remove(leadItem);
            leadItem.stage = 'Closed';
            leadItem.previousStage = responseData['previous_stage'];
            closedLeads.add(leadItem);
          });

          // Update salesman performance
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully moved lead to Closed stage')),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Closed stage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Closed stage: $e')),
      );
    }
  }

  // Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
  //   setState(() {
  //     leadItem.previousStage = leadItem.stage;
  //     leadItem.stage = stage;
  //   });
  //   await _updateLeadStageInDatabase(leadItem);
  // }

  Future<void> _updateLeadStage(LeadItem leadItem, String stage) async {
    final apiUrl = dotenv.env['API_URL'];
    final url = Uri.parse(
        '$apiUrl/sales_lead/update_lead_stage.php?lead_id=${leadItem.id}&stage=$stage');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            leadItem.previousStage = leadItem.stage;
            leadItem.stage = stage;
            if (stage == 'Negotiation' &&
                leadItem.negotiationStartDate == null) {
              leadItem.negotiationStartDate = DateTime.now();
            } else if (stage == 'Engagement' &&
                leadItem.engagementStartDate == null) {
              leadItem.engagementStartDate = DateTime.now();
            }
          });

          developer.log(
              'Successfully updated lead stage to $stage for lead ${leadItem.id}');
        } else {
          developer.log('Error updating stage: ${data['message']}');
        }
      } else {
        developer.log('Error updating stage: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error updating stage: $e');
    }
  }

  Future<void> _moveToCreateTaskPage(
      BuildContext context, LeadItem leadItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: leadItem.id,
          customerName: leadItem.customerName,
          contactNumber: leadItem.contactNumber,
          emailAddress: leadItem.emailAddress,
          address: leadItem.addressLine1,
          lastPurchasedAmount: leadItem.amount,
          showTaskDetails: false,
        ),
      ),
    );
    if (result != null && result['salesOrderId'] != null) {
      setState(() {
        leadItems.remove(leadItem);
        leadItem.salesOrderId = result['salesOrderId'];
        leadItem.quantity = result['quantity'];
        closedLeads.add(leadItem);
      });
      await _updateLeadStage(leadItem, 'Closed');
    }
  }

  Future<void> _navigateToCreateTaskPage(
      BuildContext context, LeadItem leadItem, bool showTaskDetails) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTaskPage(
          id: leadItem.id,
          customerName: leadItem.customerName,
          contactNumber: leadItem.contactNumber,
          emailAddress: leadItem.emailAddress,
          address: leadItem.addressLine1,
          lastPurchasedAmount: leadItem.amount,
          showTaskDetails: showTaskDetails,
        ),
      ),
    );

    if (result != null && result['error'] == null) {
      // If the user selects a sales order ID, move the LeadItem to OrderProcessingLeadItem
      if (result['salesOrderId'] != null) {
        String salesOrderId = result['salesOrderId'] as String;
        int? quantity = result['quantity'];
        await _moveFromOpportunitiesToOrderProcessing(
            leadItem, salesOrderId, quantity);
        setState(() {
          leadItems.remove(leadItem);
          orderProcessingLeads.add(leadItem);
        });
      }
    }
  }

  // Future<void> _moveFromOpportunitiesToOrderProcessing(
  //     LeadItem leadItem, String salesOrderId, int? quantity) async {
  //   setState(() {
  //     leadItems.remove(leadItem);
  //     leadItem.salesOrderId = salesOrderId;
  //     leadItem.quantity = quantity;
  //   });
  //   // Log the event
  //   await EventLogger.logEvent(
  //       salesmanId,
  //       'Moved lead from Opportunities stage to Order Processing stage',
  //       'Stage Movement',
  //       leadId: leadItem.id);
  //   await _updateLeadStage(leadItem, 'Order Processing');
  //   await _updateSalesOrderId(leadItem, salesOrderId);
  //   await _updateSalesmanPerformance(salesmanId);
  // }

  Future<void> _moveFromOpportunitiesToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_sales_lead_from_opportunities_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            leadItems.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
            leadItem.stage = 'Order Processing';
            leadItem.previousStage = responseData['previous_stage'];
          });

          // Update salesman performance
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Successfully moved lead to Order Processing stage')),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  // Future<void> _updateLeadStageInDatabase(LeadItem leadItem) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.query(
  //       'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE id = ?',
  //       [leadItem.stage, leadItem.previousStage, leadItem.id],
  //     );
  //   } catch (e) {
  //     developer.log('Error updating stage: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  // Future<void> _updateLeadStageInDatabase(LeadItem leadItem) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     String query;
  //     List<Object> params;
  //
  //     if (leadItem.stage == 'Negotiation') {
  //       query = '''
  //       UPDATE sales_lead
  //       SET stage = ?, previous_stage = ?, negotiation_start_date = NOW()
  //       WHERE id = ?
  //     ''';
  //       params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
  //     } else if (leadItem.stage == 'Engagement') {
  //       query = '''
  //       UPDATE sales_lead
  //       SET stage = ?, previous_stage = ?, engagement_start_date = NOW()
  //       WHERE id = ?
  //     ''';
  //       params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
  //     } else {
  //       query =
  //           'UPDATE sales_lead SET stage = ?, previous_stage = ? WHERE id = ?';
  //       params = [leadItem.stage, leadItem.previousStage ?? '', leadItem.id];
  //     }
  //
  //     await conn.query(query, params);
  //
  //     developer.log(
  //         'Successfully updated lead stage to ${leadItem.stage} for lead ${leadItem.id}');
  //   } catch (e) {
  //     developer.log('Error updating stage: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  // Future<void> _onDeleteEngagementLead(LeadItem leadItem) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.transaction((ctx) async {
  //       // Delete related tasks
  //       await ctx.query('DELETE FROM tasks WHERE lead_id = ?', [leadItem.id]);

  //       // Delete related notifications
  //       await ctx.query('DELETE FROM notifications WHERE related_lead_id = ?',
  //           [leadItem.id]);

  //       // Delete the sales_lead record
  //       await ctx.query('DELETE FROM sales_lead WHERE id = ?', [leadItem.id]);

  //       // Delete the corresponding record in the event_log table
  //       await ctx
  //           .query('DELETE FROM event_log WHERE lead_id = ?', [leadItem.id]);

  //       // Logging a new "Lead Deleted" event
  //       await ctx.query(
  //           'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), NULL)',
  //           [salesmanId, 'Deleted Engagement lead', 'Lead Deleted']);
  //     });

  //     setState(() {
  //       engagementLeads.remove(leadItem);
  //     });

  //     // Call _updateSalesmanPerformance function
  //     await _updateSalesmanPerformance(salesmanId);

  //     developer.log('Engagement lead deleted and event logged successfully');
  //   } catch (e) {
  //     developer.log('Error deleting engagement lead: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _onDeleteEngagementLead(LeadItem leadItem) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/delete_engagement_lead.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            engagementLeads.remove(leadItem);
          });

          // Call _updateSalesmanPerformance API
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully deleted Engagement lead')),
          );
          developer
              .log('Engagement lead deleted and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting engagement lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting Engagement lead: $e')),
      );
    }
  }

  // Future<void> _onDeleteNegotiationLead(LeadItem leadItem) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.transaction((ctx) async {
  //       // Delete related tasks
  //       await ctx.query('DELETE FROM tasks WHERE lead_id = ?', [leadItem.id]);

  //       // Delete related notifications
  //       await ctx.query('DELETE FROM notifications WHERE related_lead_id = ?',
  //           [leadItem.id]);

  //       // Delete the sales_lead record
  //       await ctx.query('DELETE FROM sales_lead WHERE id = ?', [leadItem.id]);

  //       // Delete the corresponding record in the event_log table
  //       await ctx
  //           .query('DELETE FROM event_log WHERE lead_id = ?', [leadItem.id]);

  //       // Logging a new "Lead Deleted" event
  //       await ctx.query(
  //           'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), NULL)',
  //           [salesmanId, 'Deleted Negotiation lead', 'Lead Deleted']);
  //     });

  //     setState(() {
  //       negotiationLeads.remove(leadItem);
  //     });

  //     // Call _updateSalesmanPerformance function
  //     await _updateSalesmanPerformance(salesmanId);

  //     developer.log('Negotiation lead deleted and event logged successfully');
  //   } catch (e) {
  //     developer.log('Error deleting negotiation lead: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _onDeleteNegotiationLead(LeadItem leadItem) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/delete_negotiation_lead.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            negotiationLeads.remove(leadItem);
          });

          // Call _updateSalesmanPerformance function
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully deleted Negotiation lead')),
          );

          developer
              .log('Negotiation lead deleted and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to delete lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error deleting negotiation lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting Negotiation lead: $e')),
      );
    }
  }

  // void _onDeleteEngagementLead(LeadItem leadItem) {
  //   setState(() {
  //     engagementLeads.remove(leadItem);
  //   });
  //   // Log the event
  //   EventLogger.logEvent(salesmanId, 'Deleted Engagement lead', 'Lead Deleted',
  //       leadId: leadItem.id);
  //   _updateSalesmanPerformance(salesmanId);
  // }

  // void _onDeleteNegotiationLead(LeadItem leadItem) {
  //   setState(() {
  //     negotiationLeads.remove(leadItem);
  //   });
  //   // Log the event
  //   EventLogger.logEvent(salesmanId, 'Deleted Negotiation lead', 'Lead Deleted',
  //       leadId: leadItem.id);
  //   _updateSalesmanPerformance(salesmanId);
  // }

  Future<void> _onUndoEngagementLead(
      LeadItem leadItem, String previousStage) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_engagement_to_previous_stage.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'previous_stage': previousStage,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            engagementLeads.remove(leadItem);
            leadItem.stage = previousStage;
            leadItem.previousStage = null;
            leadItem.engagementStartDate = null;
            if (previousStage == 'Opportunities') {
              leadItems.add(leadItem);
            } else if (previousStage == 'Negotiation') {
              negotiationLeads.add(leadItem);
            }
          });

          // Call _updateSalesmanPerformance function
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully undone Engagement lead')),
          );

          developer.log('Engagement lead undone and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to undo lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error undoing engagement lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing Engagement lead: $e')),
      );
    }
  }

  // Future<void> _onUndoEngagementLead(
  //     LeadItem leadItem, String previousStage) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.query(
  //         'UPDATE sales_lead SET stage = ?, previous_stage = NULL, engagement_start_date = NULL WHERE id = ?',
  //         [previousStage, leadItem.id]);

  //     setState(() {
  //       engagementLeads.remove(leadItem);
  //       leadItem.stage = previousStage;
  //       leadItem.previousStage = null;
  //       leadItem.engagementStartDate = null;
  //       if (previousStage == 'Opportunities') {
  //         leadItems.add(leadItem);
  //       } else if (previousStage == 'Negotiation') {
  //         negotiationLeads.add(leadItem);
  //       }
  //     });

  //     // Log the event
  //     await EventLogger.logEvent(
  //         salesmanId, 'Undo Engagement lead', 'Lead Undo',
  //         leadId: leadItem.id);

  //     await _updateSalesmanPerformance(salesmanId);
  //   } catch (e) {
  //     developer.log('Error undoing engagement lead: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _onUndoNegotiationLead(
      LeadItem leadItem, String previousStage) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_negotiation_to_previous_stage.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'previous_stage': previousStage,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            negotiationLeads.remove(leadItem);
            leadItem.stage = previousStage;
            leadItem.previousStage = null;
            leadItem.negotiationStartDate = null;
            if (previousStage == 'Opportunities') {
              leadItems.add(leadItem);
            } else if (previousStage == 'Engagement') {
              engagementLeads.add(leadItem);
            }
          });

          // Call _updateSalesmanPerformance function
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully undone Negotiation lead')),
          );

          developer
              .log('Negotiation lead undone and event logged successfully');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to undo lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error undoing negotiation lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error undoing Negotiation lead: $e')),
      );
    }
  }

  // Future<void> _onUndoNegotiationLead(
  //     LeadItem leadItem, String previousStage) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.query(
  //         'UPDATE sales_lead SET stage = ?, previous_stage = NULL, negotiation_start_date = NULL WHERE id = ?',
  //         [previousStage, leadItem.id]);

  //     setState(() {
  //       negotiationLeads.remove(leadItem);
  //       leadItem.stage = previousStage;
  //       leadItem.previousStage = null;
  //       leadItem.negotiationStartDate = null;
  //       if (previousStage == 'Opportunities') {
  //         leadItems.add(leadItem);
  //       } else if (previousStage == 'Engagement') {
  //         engagementLeads.add(leadItem);
  //       }
  //     });

  //     // Log the event
  //     await EventLogger.logEvent(
  //         salesmanId, 'Undo Negotiation lead', 'Lead Undo',
  //         leadId: leadItem.id);

  //     await _updateSalesmanPerformance(salesmanId);
  //   } catch (e) {
  //     developer.log('Error undoing negotiation lead: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  // Future<void> _createLead(
  //     String customerName, String description, String amount) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.transaction((ctx) async {
  //       // 使用正确的日期格式
  //       String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  //       var result = await ctx.query(
  //           'INSERT INTO sales_lead (salesman_id, customer_name, description, created_date, predicted_sales, stage) VALUES (?, ?, ?, ?, ?, ?)',
  //           [
  //             salesmanId,
  //             customerName,
  //             description,
  //             formattedDate,
  //             amount,
  //             'Opportunities'
  //           ]);

  //       int newLeadId = result.insertId!;

  //       // 现在记录事件
  //       await ctx.query(
  //           'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), ?)',
  //           [
  //             salesmanId,
  //             'Created new lead for customer: $customerName',
  //             'Lead Accepted',
  //             newLeadId
  //           ]);

  //       LeadItem newLeadItem = LeadItem(
  //         id: newLeadId,
  //         salesmanId: salesmanId,
  //         customerName: customerName,
  //         description: description,
  //         createdDate: formattedDate,
  //         amount: 'RM$amount',
  //         contactNumber: '',
  //         emailAddress: '',
  //         stage: 'Opportunities',
  //         addressLine1: '',
  //         salesOrderId: '',
  //       );

  //       setState(() {
  //         leadItems.add(newLeadItem);
  //       });
  //     });

  //     await _updateSalesmanPerformance(salesmanId);
  //     developer.log('Lead created and event logged successfully');
  //   } catch (e) {
  //     developer.log('Error creating lead: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<void> _createLead(
      String customerName, String description, String amount) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_new_lead.php';

    final Map<String, String> queryParameters = {
      'customer_name': customerName,
      'description': description,
      'amount': amount,
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          LeadItem leadItem = LeadItem(
            id: responseData['lead_id'],
            salesmanId: salesmanId,
            customerName: customerName,
            description: description,
            createdDate: DateFormat('MM/dd/yyyy').format(DateTime.now()),
            amount: 'RM$amount',
            contactNumber: responseData['contact_number'],
            emailAddress: responseData['email_address'],
            stage: 'Opportunities',
            addressLine1: responseData['address_line_1'],
            salesOrderId: '',
          );

          setState(() {
            leadItems.add(leadItem);
          });

          await _updateSalesmanPerformance(salesmanId);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to create lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error creating lead: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lead: $e')),
      );
    }
  }

  // Future<void> _createLead(
  //     String customerName, String description, String amount) async {
  //   LeadItem leadItem = LeadItem(
  //     id: 0,
  //     salesmanId: salesmanId,
  //     customerName: customerName,
  //     description: description,
  //     createdDate: DateFormat('MM/dd/yyyy').format(DateTime.now()),
  //     amount: 'RM$amount',
  //     contactNumber: '',
  //     emailAddress: '',
  //     stage: 'Opportunities',
  //     addressLine1: '',
  //     salesOrderId: '',
  //   );

  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     Results customerResults = await conn.query(
  //       'SELECT company_name, address_line_1, contact_number, email FROM customer WHERE company_name = ?',
  //       [customerName],
  //     );
  //     if (customerResults.isNotEmpty) {
  //       var customerRow = customerResults.first;
  //       leadItem.contactNumber = customerRow['contact_number'].toString();
  //       leadItem.emailAddress = customerRow['email'].toString();
  //       leadItem.addressLine1 = customerRow['address_line_1'].toString();
  //     }
  //   } catch (e) {
  //     developer.log('Error fetching customer details: $e');
  //   } finally {
  //     await conn.close();
  //   }

  //   setState(() {
  //     leadItems.add(leadItem);
  //   });
  //   await _updateSalesmanPerformance(salesmanId);
  // }

  Future<void> _handleIgnore(LeadItem leadItem) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this sales lead?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      const String baseUrl =
          'https://haluansama.com/crm-sales/api/sales_lead/delete_opportunities_lead.php';

      final Map<String, String> queryParameters = {
        'lead_id': leadItem.id.toString(),
        'salesman_id': salesmanId.toString(),
      };

      final Uri uri =
          Uri.parse(baseUrl).replace(queryParameters: queryParameters);

      try {
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status'] == 'success') {
            setState(() {
              leadItems.remove(leadItem);
            });

            await _updateSalesmanPerformance(salesmanId);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(responseData['message'])),
            );
          } else {
            throw Exception(responseData['message']);
          }
        } else {
          throw Exception('Failed to delete lead: ${response.statusCode}');
        }
      } catch (e) {
        developer.log('Error deleting lead: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete lead: $e')),
        );
      }
    }
  }

  // Future<void> _handleIgnore(LeadItem leadItem) async {
  //   bool confirmDelete = await showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Confirm Delete'),
  //         content:
  //             const Text('Are you sure you want to delete this sales lead?'),
  //         actions: [
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //           TextButton(
  //             child: const Text('Confirm'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (confirmDelete == true) {
  //     MySqlConnection conn = await connectToDatabase();
  //     try {
  //       await conn.transaction((ctx) async {
  //         // Delete the related event_log records
  //         await ctx.query(
  //           'DELETE FROM event_log WHERE lead_id = ?',
  //           [leadItem.id],
  //         );

  //         // Delete the sales_lead record
  //         var result = await ctx.query(
  //           'DELETE FROM sales_lead WHERE id = ?',
  //           [leadItem.id],
  //         );

  //         if (result.affectedRows! > 0) {
  //           // If the deletion is successful, a new event log is inserted
  //           await ctx.query(
  //             'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, NOW(), NULL)',
  //             [salesmanId, 'Ignored lead', 'Lead Ignored'],
  //           );

  //           setState(() {
  //             leadItems.remove(leadItem);
  //           });
  //           await _updateSalesmanPerformance(salesmanId);

  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Lead successfully deleted')),
  //           );
  //         } else {
  //           throw Exception('No rows deleted for leadItem id: ${leadItem.id}');
  //         }
  //       });
  //     } catch (e) {
  //       developer.log('Error during transaction: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to delete lead: $e')),
  //       );
  //     } finally {
  //       await conn.close();
  //     }
  //   }
  // }

  void _addNewLead(LeadItem newLead) {
    setState(() {
      leadItems.add(newLead);
    });
  }

  void _handleRemoveOrderProcessingLead(LeadItem leadItem) {
    setState(() {
      orderProcessingLeads.remove(leadItem);
    });
  }

  Future<int?> _getSalesmanId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('id');
    developer.log("_getSalesmanId returned: $id"); // Add this log
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabbarNames.length,
      child: FutureBuilder<String>(
        future: _getSalesmanName(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            String salesmanName = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xff0175FF),
                title: Text(
                  'Welcome, $salesmanName',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  // PopupMenuButton<String>(
                  //   icon: Icon(
                  //     Icons.sort,
                  //     color: Colors.white,
                  //   ),
                  //   onSelected: (String result) {
                  //     setState(() {
                  //       if (result == _sortBy) {
                  //         _sortAscending = !_sortAscending;
                  //       } else {
                  //         _sortBy = result;
                  //         _sortAscending = true;
                  //       }
                  //       _sortLeads();
                  //     });
                  //   },
                  //   itemBuilder: (BuildContext context) =>
                  //       <PopupMenuEntry<String>>[
                  //     PopupMenuItem<String>(
                  //       value: 'created_date',
                  //       child: Text(
                  //           'Sort by Date ${_sortBy == 'created_date' ? (_sortAscending ? '↑' : '↓') : ''}'),
                  //     ),
                  //     PopupMenuItem<String>(
                  //       value: 'predicted_sales',
                  //       child: Text(
                  //           'Sort by Predicted Sales ${_sortBy == 'predicted_sales' ? (_sortAscending ? '↑' : '↓') : ''}'),
                  //     ),
                  //   ],
                  // ),
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: _showSortOptions,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationsPage()),
                      );
                    },
                  ),
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                        );

                        // Get the salesman ID
                        int? salesmanId = await _getSalesmanId();
                        developer.log("Retrieved salesmanId: $salesmanId");

                        if (salesmanId != null) {
                          // await checkOrderStatusAndNotify(salesmanId);
                          // await checkTaskDueDatesAndNotify(salesmanId);
                          await checkNewSalesLeadsAndNotify(salesmanId);

                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Notification check completed')),
                          );
                        } else {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Error: Salesman ID not found')),
                          );
                        }
                      },
                    ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          child: Image.asset(
                            'asset/SalesPipeline_Head2.png',
                            width: 700,
                            height: 78,
                            fit: BoxFit.cover,
                          )),
                      Container(
                        height: 78,
                        padding: const EdgeInsets.only(left: 12, bottom: 2),
                        child: Column(
                          children: [
                            const Spacer(),
                            Text(
                              'Sales Lead Pipeline',
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(letterSpacing: -0.8),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xff0175FF),
                    indicatorColor: const Color(0xff0175FF),
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Opportunities(${leadItems.length})'),
                      Tab(text: 'Engagement(${engagementLeads.length})'),
                      Tab(text: 'Negotiation(${negotiationLeads.length})'),
                      Tab(
                          text:
                              'Order Processing(${orderProcessingLeads.length})'),
                      Tab(text: 'Closed(${closedLeads.length})'),
                    ],
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildOpportunitiesTab(),
                        _isLoading ? _buildShimmerTab() : _buildEngagementTab(),
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildNegotiationTab(),
                        _isLoading
                            ? _buildShimmerTab()
                            : _buildOrderProcessingTab(),
                        _isLoading ? _buildShimmerTab() : _buildClosedTab(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: const CustomNavigationBar(),
              floatingActionButton:
                  _isButtonVisible ? _buildFloatingActionButton(context) : null,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          } else {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  // Shimmer effect for both tabs
  Widget _buildShimmerTab() {
    return ListView.builder(
      itemCount: 4, // Number of shimmer items to show while loading
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 64.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 16.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: double.infinity,
                  height: 16.0,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return AnimatedBuilder(
      animation: DefaultTabController.of(context),
      builder: (BuildContext context, Widget? child) {
        final TabController tabController = DefaultTabController.of(context);
        return tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateLeadPage(
                        salesmanId: salesmanId,
                        onCreateLead: (LeadItem newLead) {
                          setState(() {
                            leadItems.add(newLead);
                          });
                        },
                      ),
                    ),
                  ).then((_) {
                    // Refresh the data when returning from CreateLeadPage
                    setState(() {
                      _fetchLeadItems();
                    });
                  });
                },
                icon: const Icon(Icons.add, color: Colors.white),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                label: const Text('Create Lead',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: const Color(0xff0175FF),
              )
            : Container();
      },
    );
  }

  Future<String> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('salesmanName') ?? 'HomePage';
  }

  Widget _buildOpportunitiesTab() {
    if (leadItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Sales Leads created yet,\ncreate one now!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: leadItems.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              _buildLeadItem(leadItems[index]),
              // Check if it's the last item
              if (index == leadItems.length - 1)
                // Add additional padding for the last item
                const SizedBox(height: 80),
            ],
          );
        },
      );
    }
  }

  Widget _buildLeadItem(LeadItem leadItem) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerInsightsPage(
              customerName: leadItem.customerName,
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
            image: const DecorationImage(
              image: ResizeImage(AssetImage('asset/bttm_start.png'),
                  width: 128, height: 98),
              alignment: Alignment.bottomLeft,
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]),
        margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      leadItem.customerName,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 25, 23, 49),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(71, 148, 255, 223),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        leadItem.formattedAmount,
                        style: const TextStyle(
                          color: Color(0xff008A64),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                leadItem.description,
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(letterSpacing: -0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color.fromARGB(255, 25, 23, 49),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconDisabledColor: Colors.white,
                          iconEnabledColor: Colors.white),
                      isExpanded: true,
                      hint: const Text(
                        'Opportunities',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      items: tabbarNames
                          .skip(1)
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ))
                          .toList(),
                      value: leadItem.selectedValue,
                      onChanged: (String? value) {
                        if (value == 'Engagement') {
                          _moveToEngagement(leadItem);
                        } else if (value == 'Negotiation') {
                          _moveToNegotiation(leadItem);
                        } else if (value == 'Closed') {
                          _moveToCreateTaskPage(context, leadItem);
                        } else if (value == 'Order Processing') {
                          _navigateToCreateTaskPage(context, leadItem, false);
                        }
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        height: 24,
                        width: 136,
                        decoration: BoxDecoration(color: Color(0xff0175FF)),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 30,
                      ),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 8),
              // Text(leadItem.description),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    leadItem.createdDate,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ElevatedButton(
                        //   onPressed: () {
                        //     _handleIgnore(leadItem);
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: Colors.white,
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(5),
                        //       side:
                        //           const BorderSide(color: Colors.red, width: 2),
                        //     ),
                        //     minimumSize: const Size(50, 35),
                        //   ),
                        //   child: const Text('Ignore',
                        //       style: TextStyle(color: Colors.red)),
                        // ),
                        SizedBox(
                          height: 30,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(1.0)),
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side:
                                          const BorderSide(color: Colors.red))),
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color(0xffF01C54)),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _handleIgnore(leadItem);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),
                        // const SizedBox(width: 8),
                        // ElevatedButton(
                        //   onPressed: () {
                        //     _moveToEngagement(leadItem);
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: const Color(0xff0069BA),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(5),
                        //     ),
                        //     minimumSize: const Size(50, 35),
                        //   ),
                        //   child: const Text('Accept',
                        //       style: TextStyle(color: Colors.white)),
                        // ),
                        SizedBox(
                          height: 30,
                          width: 80,
                          child: TextButton(
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                  EdgeInsets.all(1.0)),
                              shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xff4566DD)))),
                              backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color(0xff4566DD)),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            onPressed: () {
                              _moveToEngagement(leadItem);
                            },
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementTab() {
    if (engagementLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No Engagement Leads yet,\nstart building relationships!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: engagementLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = engagementLeads[index];
          return EngagementLeadItem(
            leadItem: leadItem,
            onMoveToNegotiation: () =>
                _moveFromEngagementToNegotiation(leadItem),
            onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
              await _updateSalesmanPerformance(salesmanId);
              await _moveFromEngagementToOrderProcessing(
                  leadItem, salesOrderId, quantity);
              setState(() {
                engagementLeads.remove(leadItem);
                orderProcessingLeads.add(leadItem);
              });
            },
            onDeleteLead: _onDeleteEngagementLead,
            onUndoLead: _onUndoEngagementLead,
            onComplete: (leadItem) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskPage(
                    id: leadItem.id,
                    customerName: leadItem.customerName,
                    contactNumber: leadItem.contactNumber,
                    emailAddress: leadItem.emailAddress,
                    address: leadItem.addressLine1,
                    lastPurchasedAmount: leadItem.amount,
                    showTaskDetails: false,
                  ),
                ),
              );
              if (result != null && result['salesOrderId'] != null) {
                setState(() {
                  engagementLeads.remove(leadItem);
                  leadItem.salesOrderId = result['salesOrderId'];
                  leadItem.quantity = result['quantity'];
                  closedLeads.add(leadItem);
                });
                await _updateLeadStage(leadItem, 'Closed');
              }
            },
          );
        },
      );
    }
  }

  // Future<void> _moveFromEngagementToOrderProcessing(
  //     LeadItem leadItem, String salesOrderId, int? quantity) async {
  //   setState(() {
  //     engagementLeads.remove(leadItem);
  //     leadItem.salesOrderId = salesOrderId;
  //     leadItem.quantity = quantity;
  //   });
  //   // Log the event
  //   await EventLogger.logEvent(
  //       salesmanId,
  //       'Moved lead from Engagement stage to Order Processing stage',
  //       'Stage Movement',
  //       leadId: leadItem.id);
  //   await _updateLeadStage(leadItem, 'Order Processing');
  //   await _updateSalesOrderId(leadItem, salesOrderId);
  // }

  Future<void> _moveFromEngagementToOrderProcessing(
      LeadItem leadItem, String salesOrderId, int? quantity) async {
    const String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_sales_lead_from_engagement_to_order_processing.php';

    final Map<String, String> queryParameters = {
      'lead_id': leadItem.id.toString(),
      'sales_order_id': salesOrderId,
      'quantity': quantity?.toString() ?? '',
      'salesman_id': salesmanId.toString(),
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Update local state
          setState(() {
            engagementLeads.remove(leadItem);
            leadItem.salesOrderId = salesOrderId;
            leadItem.quantity = quantity;
            leadItem.stage = 'Order Processing';
            leadItem.previousStage = responseData['previous_stage'];
            // orderProcessingLeads.add(leadItem);
          });

          // Update salesman performance
          await _updateSalesmanPerformance(salesmanId);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Successfully moved lead to Order Processing stage')),
          );
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to move lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error moving lead to Order Processing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving lead to Order Processing: $e')),
      );
    }
  }

  Widget _buildNegotiationTab() {
    if (negotiationLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel, // Represents negotiations and decision-making
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No leads in negotiation,\nstart negotiating with your leads!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: negotiationLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = negotiationLeads[index];
          return NegotiationLeadItem(
            leadItem: leadItem,
            onMoveToOrderProcessing: (leadItem, salesOrderId, quantity) async {
              await _moveFromNegotiationToOrderProcessing(
                  leadItem, salesOrderId, quantity);
              await _updateSalesmanPerformance(salesmanId);
              setState(() {
                negotiationLeads.remove(leadItem);
                orderProcessingLeads.add(leadItem);
              });
            },
            onDeleteLead: _onDeleteNegotiationLead,
            onUndoLead: _onUndoNegotiationLead,
            onComplete: (leadItem) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskPage(
                    id: leadItem.id,
                    customerName: leadItem.customerName,
                    contactNumber: leadItem.contactNumber,
                    emailAddress: leadItem.emailAddress,
                    address: leadItem.addressLine1,
                    lastPurchasedAmount: leadItem.amount,
                    showTaskDetails: false,
                  ),
                ),
              );
              if (result != null && result['salesOrderId'] != null) {
                setState(() {
                  negotiationLeads.remove(leadItem);
                  leadItem.salesOrderId = result['salesOrderId'];
                  leadItem.quantity = result['quantity'];
                  closedLeads.add(leadItem);
                });
                await _updateLeadStage(leadItem, 'Closed');
              }
            },
          );
        },
      );
    }
  }

  Widget _buildOrderProcessingTab() {
    if (orderProcessingLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fact_check, // Represents order processing and verification
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No orders are being processed yet,\nstart managing your sales orders!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: orderProcessingLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = orderProcessingLeads[index];
          if (leadItem.salesOrderId == null) {
            return OrderProcessingLeadItem(
              leadItem: leadItem,
              status: 'Unknown',
              onMoveToClosed: _moveFromOrderProcessingToClosed,
              onRemoveLead: _handleRemoveOrderProcessingLead,
            );
          } else {
            return FutureBuilder<String>(
              future: _fetchSalesOrderStatus(leadItem.salesOrderId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200.0,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8.0),
                              Container(
                                width: double.infinity,
                                height: 24.0,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8.0),
                              Container(
                                width: double.infinity,
                                height: 24.0,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  String status = snapshot.data ?? 'Unknown';
                  return OrderProcessingLeadItem(
                    leadItem: leadItem,
                    status: status,
                    onMoveToClosed: _moveFromOrderProcessingToClosed,
                    onRemoveLead: _handleRemoveOrderProcessingLead,
                  );
                }
              },
            );
          }
        },
      );
    }
  }

  // Future<String> _fetchSalesOrderStatus(String salesOrderId) async {
  //   int salesOrderIdInt = int.parse(salesOrderId);
  //   try {
  //     MySqlConnection conn = await connectToDatabase();
  //     Results results = await conn.query(
  //       'SELECT status, created, expiration_date, total FROM cart WHERE id = ?',
  //       [salesOrderIdInt],
  //     );
  //     if (results.isNotEmpty) {
  //       var row = results.first;
  //       String status = row['status'].toString();
  //       String createdDate = row['created'].toString();
  //       String expirationDate = row['expiration_date'].toString();
  //       String total = row['total'].toString();
  //       return '$status|$createdDate|$expirationDate|$total';
  //     } else {
  //       return 'Unknown|Unknown|Unknown|Unknown';
  //     }
  //   } catch (e) {
  //     developer.log('Error fetching sales order status: $e');
  //     return 'Unknown|Unknown|Unknown|Unknown';
  //   }
  // }

  Future<String> _fetchSalesOrderStatus(String salesOrderId) async {
    try {
      // Replace with your actual PHP API URL
      final String apiUrl =
          'https://haluansama.com/crm-sales/api/sales_lead/get_sales_order_status.php?salesOrderId=$salesOrderId';

      // Send the GET request to the PHP API
      final response = await http.get(Uri.parse(apiUrl));

      // Check the response status
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Check if the API returned a success status
        if (jsonResponse['status'] == 'success') {
          var data = jsonResponse['data'];
          String newStatus = data['status'].toString();
          String createdDate = data['created'].toString();
          String expirationDate = data['expiration_date'].toString();
          String total = data['total'].toString();

          // Return the concatenated result
          return '$newStatus|$createdDate|$expirationDate|$total';
        } else {
          developer.log('Error: ${jsonResponse['message']}');
          return 'Unknown|Unknown|Unknown|Unknown';
        }
      } else {
        developer.log(
            'Error: Failed to fetch data from API with status code ${response.statusCode}');
        return 'Unknown|Unknown|Unknown|Unknown';
      }
    } catch (e) {
      developer.log('Error fetching sales order status: $e');
      return 'Unknown|Unknown|Unknown|Unknown';
    }
  }

  // Future<void> _generateNotification(
  //     LeadItem leadItem, String newStatus) async {
  //   MySqlConnection conn = await connectToDatabase();
  //   try {
  //     await conn.query(
  //       'INSERT INTO notifications (salesman_id, title, description, related_lead_id) VALUES (?, ?, ?, ?)',
  //       [
  //         salesmanId,
  //         'Order Status Changed',
  //         'Order for ${leadItem.customerName} has changed from Pending to Confirm.',
  //         leadItem.id,
  //       ],
  //     );

  //     // Send push notification
  //     await FirebaseApi().sendPushNotification(
  //       salesmanId.toString(),
  //       'Order Status Changed',
  //       'Order for ${leadItem.customerName} has changed from Pending to Confirm.',
  //     );

  //     // Show local notification
  //     await FirebaseApi().showLocalNotification(
  //       'Order Status Changed',
  //       'Order for ${leadItem.customerName} has changed from Pending to Confirm.',
  //     );
  //   } catch (e) {
  //     developer.log('Error generating notification: $e');
  //   } finally {
  //     await conn.close();
  //   }
  // }

  Future<Map<String, String>> _fetchSalesOrderDetails(
      String salesOrderId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://haluansama.com/crm-sales/api/sales_lead/get_sales_order_details.php?id=$salesOrderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'formattedCreatedDate':
                responseData['data']['formattedCreatedDate'].toString(),
            'expirationDate': responseData['data']['expirationDate'].toString(),
            'total': responseData['data']['total'].toString(),
            'quantity': responseData['data']['quantity'].toString(),
          };
        } else {
          developer.log('Error: ${responseData['message']}');
          return {};
        }
      } else {
        developer
            .log('HTTP request failed with status: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      developer.log('Error fetching sales order details: $e');
      return {};
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }

  Widget _buildClosedTab() {
    if (closedLeads.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all, // Represents that all leads are closed
              size: 100,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No leads are closed yet,\nkeep working towards your goals!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: closedLeads.length,
        itemBuilder: (context, index) {
          LeadItem leadItem = closedLeads[index];
          return FutureBuilder<Map<String, String>>(
            future: _fetchSalesOrderDetails(leadItem.salesOrderId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerCard();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                Map<String, String> salesOrderDetails = snapshot.data ?? {};
                return ClosedLeadItem(
                  leadItem: leadItem,
                  formattedCreatedDate:
                      salesOrderDetails['formattedCreatedDate'] ?? '',
                  expirationDate: salesOrderDetails['expirationDate'] ?? '',
                  total: salesOrderDetails['total'] ?? '',
                  quantity: salesOrderDetails['quantity'] ?? 'Unknown',
                );
              }
            },
          );
        },
      );
    }
  }
}

class LeadItem {
  final int id;
  final int? salesmanId;
  final String customerName;
  final String description;
  final String createdDate;
  final String amount;
  DateTime? engagementStartDate;
  DateTime? negotiationStartDate;
  String? selectedValue;
  String contactNumber;
  String emailAddress;
  String stage;
  String addressLine1;
  String? salesOrderId;
  String? previousStage;
  int? quantity;
  String status;
  String get formattedAmount {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return 'RM${formatter.format(double.parse(amount.substring(2)))}';
  }

  LeadItem({
    this.salesmanId,
    required this.customerName,
    required this.description,
    required this.createdDate,
    required this.amount,
    this.selectedValue,
    required this.contactNumber,
    required this.emailAddress,
    required this.stage,
    required this.addressLine1,
    this.salesOrderId,
    this.previousStage,
    this.quantity,
    required this.id,
    this.engagementStartDate,
    this.negotiationStartDate,
    this.status = 'Pending',
  });

  void moveToEngagement(Function(LeadItem) onMoveToEngagement) {
    onMoveToEngagement(this);
  }
}
