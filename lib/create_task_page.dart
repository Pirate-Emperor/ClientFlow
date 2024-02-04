import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clientflow/select_order_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateTaskPage extends StatefulWidget {
  final int id;
  final String customerName;
  final String contactNumber;
  final String emailAddress;
  final String address;
  final String lastPurchasedAmount;
  final String? existingTitle;
  final String? existingDescription;
  final DateTime? existingDueDate;
  final bool showTaskDetails;
  final bool showSalesOrderId;
  final int? taskId; // 新增taskId参数

  const CreateTaskPage({
    super.key,
    required this.id,
    required this.customerName,
    required this.contactNumber,
    required this.emailAddress,
    required this.address,
    required this.lastPurchasedAmount,
    this.existingTitle,
    this.existingDescription,
    this.existingDueDate,
    this.showTaskDetails = true,
    this.showSalesOrderId = true,
    this.taskId, // 新增taskId参数
  });

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class SalesOrderDialog extends StatefulWidget {
  final String? salesOrderId;
  final List<Map<String, dynamic>> cartItems;

  const SalesOrderDialog({
    super.key,
    required this.salesOrderId,
    required this.cartItems,
  });

  @override
  _SalesOrderDialogState createState() => _SalesOrderDialogState();
}

class _SalesOrderDialogState extends State<SalesOrderDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Sales Order Details',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.salesOrderId != null)
                Text(
                  'Sales Order ID: SO${widget.salesOrderId!.padLeft(7, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Cart Items:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    return ListTile(
                      title: Text('${item['product_name']}'),
                      trailing: Text('Qty: ${item['qty']}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  DateTime? selectedDate = DateTime.now();
  String? selectedSalesOrderId;
  String? expirationDate;
  String? createdDate;
  String? total;
  List<String> salesOrderIds = [];
  List<Map<String, dynamic>> cartItemList = [];
  String? formattedCreatedDate;
  int? quantity;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.existingDueDate ?? DateTime.now();
    titleController.text = widget.existingTitle ?? '';
    descriptionController.text = widget.existingDescription ?? '';
    fetchSalesOrderIds().then((value) {
      setState(() {
        salesOrderIds = value;
      });
    });
    _fetchSalesOrderDetails(selectedSalesOrderId);
  }

  void updateSelectedSalesOrderId(String? newId) {
    setState(() {
      selectedSalesOrderId = newId;
      if (newId != null && salesOrderIds.contains(newId)) {
        _fetchSalesOrderDetails(newId);
      } else {
        // Reset related fields if the selected ID is not valid
        createdDate = null;
        expirationDate = null;
        total = null;
        quantity = null;
        formattedCreatedDate = null;
        cartItemList = [];
      }
    });
  }

  Future<void> _navigateToSelectOrderIDPage() async {
    final selectedOrderID = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectOrderIDPage(customerName: widget.customerName),
      ),
    );

    if (selectedOrderID != null) {
      updateSelectedSalesOrderId(selectedOrderID.toString());
    }
  }

  Future<void> _fetchSalesOrderDetails(String? salesOrderId) async {
    if (salesOrderId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://haluansama.com/crm-sales/api/create_task/get_sales_order_details.php?salesOrderId=$salesOrderId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final orderDetails = data['orderDetails'];

          // Extract the data from the API response
          setState(() {
            createdDate = orderDetails['created'];
            expirationDate = orderDetails['expiration_date'];
            total = orderDetails['final_total'].toString();
            quantity = orderDetails['quantity'];
            formattedCreatedDate = _formatDate(createdDate!);
            cartItemList = List<Map<String, dynamic>>.from(orderDetails['cartItems']);
          });
        } else {
          developer.log('Error fetching sales order details: ${data['message']}');
        }
      } else {
        developer.log('Failed to fetch sales order details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching sales order details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSalesOrderDropdown(String customerName) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int buyerId = pref.getInt('id') ?? 1;

    const String apiUrl = 'https://haluansama.com/crm-sales/api/create_task/get_sales_orders_dropdown.php';

    try {
      final response = await http.get(Uri.parse('$apiUrl?buyer_id=$buyerId&customer_name=${Uri.encodeComponent(customerName)}'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else {
          developer.log('Error fetching sales orders: ${jsonResponse['message']}');
          return [];
        }
      } else {
        developer.log('Failed to fetch sales orders: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('Error fetching sales orders: $e');
      return [];
    }
  }

  Future<List<String>> fetchSalesOrderIds() async {
    try {
      List<Map<String, dynamic>> salesOrders =
          await fetchSalesOrderDropdown(widget.customerName);
      Set<String> uniqueIds = <String>{};
      for (var order in salesOrders) {
        final orderId = order['id'].toString();
        uniqueIds.add(orderId);
      }
      setState(() {
        salesOrderIds = uniqueIds.toList();
      });
    } catch (e) {
      developer.log('Error fetching sales order IDs: $e');
    }
    return salesOrderIds;
  }

  @override
  Widget build(BuildContext context) {
    // Create a NumberFormat instance with the desired format
    final formatter = NumberFormat("#,###.000", "en_US");
    // Validate and preprocess the lastPurchasedAmount
    String formattedLastPurchasedAmount = '';
    if (widget.lastPurchasedAmount.isNotEmpty) {
      String cleanedAmount =
          widget.lastPurchasedAmount.replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleanedAmount.isNotEmpty) {
        double parsedAmount = double.parse(cleanedAmount);
        formattedLastPurchasedAmount = formatter.format(parsedAmount);
      }
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Create Task',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Customer Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xff0175FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              // Use the formatted lastPurchasedAmount
                              'RM $formattedLastPurchasedAmount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              color: Color(0xff0175FF)),
                          const SizedBox(width: 10),
                          Text(
                            widget.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              color: Color(0xff0175FF)),
                          const SizedBox(width: 10),
                          Text(
                            widget.contactNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email,
                              color: Color(0xff0175FF)),
                          const SizedBox(width: 10),
                          Text(
                            widget.emailAddress,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xff0175FF)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.address,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.showTaskDetails) ...[
                  const SizedBox(height: 40),
                  const Text(
                    'Task Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'Title cannot exceed 50 digits';
                      }
                      return null;
                    },
                  ),
                  const Text(
                    '*Ignore this part if directly to Order Processing',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    validator: (value) {
                      if (value != null && value.length > 100) {
                        return 'Description cannot exceed 100 digits';
                      }
                      return null;
                    },
                  ),
                  const Text(
                    '*Ignore this part if directly to Order Processing',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                selectedDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(selectedDate!)
                                    : '',
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.showSalesOrderId) ...[
                  const SizedBox(height: 40),
                  const Text(
                    'Sales order ID',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String?>(
                          menuMaxHeight: 200,
                          value: selectedSalesOrderId,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSalesOrderId = newValue;
                            });
                            _fetchSalesOrderDetails(newValue);
                          },
                          items: ['', ...salesOrderIds].map((String? id) {
                            if (id == null || id.isEmpty) {
                              return const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Select',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            } else {
                              String formattedId = 'SO${id.padLeft(7, '0')}';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(formattedId),
                              );
                            }
                          }).toList(),
                          // validator: (value) {
                          //   if (value == null) {
                          //     return 'Please select a sales order ID';
                          //   }
                          //   return null;
                          // },
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _navigateToSelectOrderIDPage,
                            child: const Text(
                              'View Orders Details',
                              // style: TextStyle(
                              //     color: Color.fromARGB(255, 127, 127, 127)),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 24,
                            // color: Colors.grey,
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: _navigateToSelectOrderIDPage,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Color(0xff0069BA),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(5),
                  //     ),
                  //     minimumSize: const Size(120, 40),
                  //   ),
                  //   child: const Text(
                  //     'Check Orders Details',
                  //     style: TextStyle(
                  //       color: Colors.white,
                  //     ),
                  //   ),
                  // ),
                  const Text(
                    '*Select a sales order ID',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  if (selectedSalesOrderId != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // InkWell(
                        //   onTap: () => _showSalesOrderDialog(context),
                        //   child: const Text(
                        //     'View Sales Order Details',
                        //     style: TextStyle(
                        //       color: Color(0xff0069BA),
                        //       decoration: TextDecoration.underline,
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 5),
                        Text(
                          'Created date: ${formattedCreatedDate ?? ''}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Expiry date: ${expirationDate ?? ''}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        // const SizedBox(height: 16),
                        // const Text(
                        //   'Cart Items:',
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        // SizedBox(
                        //   height: 100,
                        //   child: ListView.builder(
                        //     itemCount: cartItemList.length,
                        //     itemBuilder: (context, index) {
                        //       final item = cartItemList[index];
                        //       return ListTile(
                        //         title: Text('${item['product_name']}'),
                        //         trailing: Text('Qty: ${item['qty']}'),
                        //       );
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Quantity: ',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff0175FF)),
                            ),
                            Text(quantity != null ? '$quantity items' : ''),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff0175FF)),
                            ),
                            Text(total != null ? 'RM$total' : ''),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final result = await _saveTaskToDatabase();
                          Navigator.pop(context, result);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0175FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white),
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
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<Map<String, dynamic>> _saveTaskToDatabase() async {
    String taskTitle = titleController.text.trim();
    String taskDescription = descriptionController.text.trim();
    String taskDueDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : '';
    String salesOrderId = selectedSalesOrderId ?? '';
    int? quantityInt = quantity;

    // Prepare the payload for the API request
    Map<String, dynamic> payload = {
      'taskTitle': taskTitle,
      'taskDescription': taskDescription,
      'taskDueDate': taskDueDate,
      'salesOrderId': salesOrderId,
      'quantity': quantityInt,
      'id': widget.id, // Sales lead ID
      'taskId': widget.taskId, // Task ID if updating an existing task
    };

    try {
      // Make the API request
      final response = await http.post(
        Uri.parse('https://haluansama.com/crm-sales/api/create_task/save_task_to_database.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          developer.log('Data saved successfully.');
          return {
            'salesOrderId': responseData['salesOrderId'],
            'quantity': responseData['quantity'],
            'hasTaskDetails': responseData['hasTaskDetails'],
          };
        } else {
          developer.log('Failed to save data: ${responseData['message']}');
          return {'error': responseData['message']};
        }
      } else {
        developer.log('Failed to save data: Server error');
        return {'error': 'Server error'};
      }
    } catch (e) {
      developer.log('Failed to save data: $e');
      return {'error': 'Failed to save data'};
    }
  }

  // Future<Map<String, Object?>> _saveTaskToDatabase() async {
  //   MySqlConnection conn = await connectToDatabase();

  //   String taskTitle = titleController.text;
  //   String taskDescription = descriptionController.text;
  //   String taskDueDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
  //   String salesOrderId = selectedSalesOrderId ?? '';
  //   int? quantityInt = quantity;

  //   try {
  //     await conn.query(
  //       'UPDATE sales_lead SET task_title = ?, task_description = ?, task_duedate = ?, so_id = ?, quantity = ? WHERE id = ?',
  //       [
  //         taskTitle,
  //         taskDescription,
  //         taskDueDate,
  //         salesOrderId.isEmpty ? null : salesOrderId,
  //         quantityInt,
  //         widget.id
  //       ],
  //     );
  //     developer.log('Task data saved successfully.');
  //     return {
  //       'title': titleController.text,
  //       'description': descriptionController.text,
  //       'dueDate': selectedDate,
  //       'salesOrderId': salesOrderId.isEmpty ? null : salesOrderId,
  //       'quantity': quantity,
  //     };
  //   } catch (e) {
  //     developer.log('Failed to save task data: $e');
  //     return {
  //       'error': 'Failed to save task data',
  //     };
  //   } finally {
  //     await conn.close();
  //   }
  // }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) {
      return '';
    }
    DateTime parsedDate = DateTime.parse(dateString);
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(parsedDate);
  }
}
