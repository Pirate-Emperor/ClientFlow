import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class CustomersGraph extends StatefulWidget {
  const CustomersGraph({super.key});

  @override
  _CustomersGraphState createState() => _CustomersGraphState();
}

class _CustomersGraphState extends State<CustomersGraph> {
  late Future<List<Customer>> customers;
  String loggedInUsername = '';

  @override
  void initState() {
    super.initState();
    customers = _loadUserDetails().then((_) => fetchCustomersFromApi());
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUsername = prefs.getString('username') ?? '';
    });
  }

  Future<List<Customer>> fetchCustomersFromApi() async {
    final apiUrl =
        'https://haluansama.com/crm-sales/api/customer_graph/get_top_customers.php?username=$loggedInUsername';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          List<dynamic> customerData = jsonData['data'];
          return customerData.map((data) {
            final totalValue = (data['total_cart_value'] as num).toDouble();
            final percentageOfTotal =
                (data['percentage_of_total'] as num).toDouble();
            return Customer(
              data['company_name'].toString(),
              totalValue,
              percentageOfTotal,
            );
          }).toList();
        } else {
          throw Exception('API Error: ${jsonData['message']}');
        }
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      developer.log('Error fetching customers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Top Customers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Customer>>(
          future: customers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              // If no data or an empty list is returned, we show 5 placeholder customers
              final customerData =
                  (snapshot.data == null || snapshot.data!.isEmpty)
                      ? List.generate(
                          5, (index) => Customer('No Customer', 0.0, 0.0))
                      : snapshot.data!;

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...customerData.map((customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomerBar(customer: customer),
                        )),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class CustomerBar extends StatelessWidget {
  final Customer customer;

  const CustomerBar({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Calculate the percentage (ensure it's valid, or set to 0)
    double percentage = customer.percentageOfTotal.isNaN ||
            customer.percentageOfTotal.isInfinite
        ? 0
        : customer.percentageOfTotal / 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Customer name: Shows "No Customer" for placeholder
              Text(
                customer.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Display "RM 0" if no data
              Text(
                customer
                    .totalSalesDisplay, // Will display RM 0 for placeholders
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // The progress bar for percentage
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage, // 0 if no valid percentage
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Customer {
  final String name;
  final double totalValue;
  final double percentageOfTotal;

  Customer(this.name, this.totalValue, this.percentageOfTotal);

  String get totalSalesDisplay =>
      'RM ${NumberFormat("#,##0", "en_US").format(totalValue)}';
}
