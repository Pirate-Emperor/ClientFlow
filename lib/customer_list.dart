import 'package:flutter/material.dart';
import 'package:clientflow/customer_insights.dart';
import 'customer.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  _CustomerListState createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  int? selectedIndex;
  late Customer selectedCustomer;
  String searchQuery = ''; // Store the search query
  List<Customer> customers = [];
  List<Customer> filteredCustomers = [];
  bool isLoading = false;
  bool hasMore = true;
  int limit = 10;
  int offset = 0;
  int totalCustomers = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreCustomers();
  }

  Future<List<Customer>> fetchCustomers(int limit, int offset) async {
    List<Customer> fetchedCustomers = [];
    final String apiUrl =
        'https://haluansama.com/crm-sales/api/customer/get_customers.php?limit=$limit&offset=$offset';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(response.body); // Decode JSON into a Map

        // Extract total customers count from responseData
        totalCustomers = responseData['total_customers'] ?? 0;

        // Extract the list of customers from the 'customers' key
        final List<dynamic> customerList = responseData['customers'] ?? [];

        for (var item in customerList) {
          final Map<String, dynamic> customerData =
          item as Map<String, dynamic>;
          fetchedCustomers.add(Customer(
            id: customerData['id'] is int
                ? customerData['id']
                : int.tryParse(customerData['id'].toString()) ?? 0,
            companyName: customerData['company_name'] as String? ?? '',
            addressLine1: customerData['address_line_1'] as String? ?? '',
            addressLine2: customerData['address_line_2'] as String? ?? '',
            contactNumber: customerData['contact_number'] as String? ?? '',
            email: customerData['email'] as String? ?? '',
            customerRate: customerData['customer_rate'] as String? ?? '',
            discountRate: customerData['discount_rate'] is int
                ? customerData['discount_rate']
                : int.tryParse(customerData['discount_rate'].toString()) ?? 0,
          ));
        }
      } else {
        developer.log('Error fetching customers: ${response.reasonPhrase}');
      }
    } catch (e) {
      developer.log('Error fetching customers: $e', error: e);
    }
    return fetchedCustomers;
  }

  Future<void> _loadMoreCustomers() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    final fetchedCustomers = await fetchCustomers(limit, offset);

    setState(() {
      isLoading = false;
      if (fetchedCustomers.length < limit) {
        hasMore = false;
      }
      offset += limit;
      customers.addAll(fetchedCustomers);

      // Update the total customers count
      filteredCustomers = customers;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      searchQuery = query;
      filteredCustomers = customers
          .where((customer) =>
      customer.companyName
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          customer.email.toLowerCase().contains(query.toLowerCase()) ||
          customer.contactNumber.contains(query) ||
          customer.addressLine1.contains(query) ||
          customer.addressLine2.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Customer Details',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
              child: Text(
                'Select a customer',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff191731),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search customer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  _filterCustomers(query); // Filter customers as you type
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Total Customers: $totalCustomers',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff191731),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (!isLoading &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                    _loadMoreCustomers();
                  }
                  return true;
                },
                child: ListView.builder(
                  itemCount: filteredCustomers.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filteredCustomers.length) {
                      return _buildLoadingIndicator();
                    }
                    final customer = filteredCustomers[index];
                    final isSelected = selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = isSelected ? null : index;
                          selectedCustomer = isSelected ? Customer() : customer;

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                              builder: (context) => CustomerInsightsPage(
                                customerName: customer.companyName,
                              ),
                            ),
                          );
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 6.0, right: 6.0, bottom: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: const BorderDirectional(
                                top: BorderSide(
                                    color: Color.fromARGB(
                                        255, 231, 231, 231),
                                    width: 2)),
                            color: isSelected
                                ? const Color(0xfff8f9fa)
                                : const Color.fromARGB(255, 255, 255, 255),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.companyName,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff0175FF),
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '${customer.customerRate}: ${customer.discountRate.toString()}% Discount',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff317E33),
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${customer.addressLine1}${customer.addressLine2.isNotEmpty ? '\n${customer.addressLine2}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xff191731),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      customer.contactNumber,
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff191731),
                                      ),
                                    ),
                                    Text(
                                      customer.email,
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff191731),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
