import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:clientflow/customer_details_page.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:clientflow/home_page.dart';

class CreateLeadPage extends StatefulWidget {
  final Function(LeadItem) onCreateLead;
  final int salesmanId;

  const CreateLeadPage(
      {super.key, required this.onCreateLead, required this.salesmanId});

  @override
  _CreateLeadPageState createState() => _CreateLeadPageState();
}

class _CreateLeadPageState extends State<CreateLeadPage> {
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailAddressController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Create Lead',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Details',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.contacts, color: Color(0xff0175FF)),
                      onPressed: _selectCustomer,
                    ),
                  ],
                ),
                TextFormField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter customer/company name',
                    prefixIcon: Icon(
                      Icons.person,
                      color: Color(0xff0175FF),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer/company name';
                    }
                    if (value.length > 100) {
                      return 'Customer/company name cannot exceed 100 characters';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: contactNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Enter contact number',
                    prefixIcon: Icon(Icons.phone, color: Color(0xff0175FF)),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    if (value.length > 11) {
                      return 'Contact number cannot exceed 11 digits';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: emailAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Enter email address',
                    prefixIcon: Icon(Icons.email, color: Color(0xff0175FF)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Enter address',
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xff0175FF)),
                  ),
                  maxLength: 200,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    List<String> words = value.split(' ');
                    if (words.length > 200) {
                      return 'Address cannot exceed 200 words';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                const Text(
                  'Others',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return 'Please enter description';
                    }
                    if (value != null && value.length > 100) {
                      return 'Description cannot exceed 100 characters';
                    }
                    return null;
                  },
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Predicted sales',
                          hintText: 'RM',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isEmpty) {
                            return 'Please enter predicted sales';
                          }
                          if (value != null && double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (value != null && value.length > 50) {
                            return 'Predicted sales cannot exceed 50 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
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
                      onPressed: () {
                        // if (_formKey.currentState!.validate()) {
                        //   // Call the onCreateLead function with entered values
                        //   widget.onCreateLead(
                        //     customerNameController.text,
                        //     descriptionController.text,
                        //     amountController.text,
                        //   );
                        //   _saveLeadToDatabase();
                        //   Navigator.pop(context);
                        // }
                        if (_formKey.currentState!.validate()) {
                          _saveLeadToDatabase();
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
                        'Create',
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

  Future<void> _selectCustomer() async {
    final selectedCustomer = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerDetails()),
    );
    if (selectedCustomer != null) {
      setState(() {
        customerNameController.text = selectedCustomer.companyName;
        contactNumberController.text = selectedCustomer.contactNumber;
        emailAddressController.text = selectedCustomer.email;
        addressController.text = selectedCustomer.addressLine1;
      });
    }
  }

  // Future<void> _saveLeadToDatabase() async {
  //   MySqlConnection conn = await connectToDatabase();

  //   Map<String, dynamic> leadData = {
  //     'salesman_id': widget.salesmanId,
  //     'customer_name': customerNameController.text,
  //     'contact_number': contactNumberController.text,
  //     'email_address': emailAddressController.text,
  //     'address': addressController.text,
  //     'description': descriptionController.text,
  //     'predicted_sales': amountController.text,
  //     'stage': 'Opportunities',
  //     'previous_stage': 'Opportunities',
  //     'so_id': null,
  //     'created_date': DateTime.now().toString(), // Current date as created_date
  //   };

  //   if (leadData['description'].length > 255) {
  //     developer.log('The description cannot exceed 255 characters.');
  //     return;
  //   }

  //   // Save data to database
  //   var result = await conn.query(
  //       'INSERT INTO sales_lead (salesman_id, customer_name, contact_number, email_address, address, description, predicted_sales, stage, previous_stage, so_id, created_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
  //       [
  //         leadData['salesman_id'],
  //         leadData['customer_name'],
  //         leadData['contact_number'],
  //         leadData['email_address'],
  //         leadData['address'],
  //         leadData['description'],
  //         leadData['predicted_sales'],
  //         leadData['stage'],
  //         leadData['previous_stage'],
  //         leadData['so_id'],
  //         leadData['created_date']
  //       ]);

  //   if (result.affectedRows == 1) {
  //     int? leadId = result.insertId; // Get new inserted lead_id
  //     developer.log('Lead data saved successfully,lead_id: $leadId');

  //     // Log the event
  //     await conn.query(
  //         'INSERT INTO event_log (salesman_id, activity_description, activity_type, datetime, lead_id) VALUES (?, ?, ?, ?, ?)',
  //         [
  //           leadData['salesman_id'],
  //           'Created new lead for customer: ${leadData['customer_name']}',
  //           'Create Lead',
  //           DateTime.now().toString(),
  //           leadId
  //         ]);
  //     developer.log('Event Logging Successful,lead_id: $leadId');
  //   } else {
  //     developer.log('Failure to save lead data');
  //   }

  //   await conn.close();
  // }

  Future<void> _saveLeadToDatabase() async {
    final String baseUrl =
        'https://haluansama.com/crm-sales/api/sales_lead/update_new_lead_to_database.php';

    final Map<String, String> queryParameters = {
      'salesman_id': widget.salesmanId.toString(),
      'customer_name': customerNameController.text,
      'contact_number': contactNumberController.text,
      'email_address': emailAddressController.text,
      'address': addressController.text,
      'description': descriptionController.text,
      'predicted_sales': amountController.text,
    };

    final Uri uri =
        Uri.parse(baseUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          int leadId = responseData['lead_id'];
          developer.log('Lead data saved successfully, lead_id: $leadId');

          // You might want to update your local state or navigate to a different screen here

          // Create a new LeadItem
          LeadItem newLead = LeadItem(
            id: leadId,
            salesmanId: widget.salesmanId,
            customerName: customerNameController.text,
            description: descriptionController.text,
            createdDate: DateTime.now().toString(),
            amount: 'RM${amountController.text}',
            contactNumber: contactNumberController.text,
            emailAddress: emailAddressController.text,
            stage: 'Opportunities',
            addressLine1: addressController.text,
            salesOrderId: '',
          );

          // Call the onCreateLead callback with the new LeadItem
          widget.onCreateLead(newLead);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );

          // Return to HomePage
          Navigator.pop(context);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to save lead: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error saving lead data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save lead: $e')),
      );
    }
  }

  // Future<void> _saveLeadToDatabase() async {
  //   MySqlConnection conn = await connectToDatabase();

  //   Map<String, dynamic> leadData = {
  //     'salesman_id': widget.salesmanId,
  //     'customer_name': customerNameController.text,
  //     'contact_number': contactNumberController.text,
  //     'email_address': emailAddressController.text,
  //     'address': addressController.text,
  //     'description': descriptionController.text,
  //     'predicted_sales': amountController.text,
  //     'stage': 'Opportunities', // Add the default stage for new leads
  //     'previous_stage': 'Opportunities',
  //     'so_id': null,
  //     'created_date':
  //         DateTime.now().toString(), // Add the current date as created_date
  //   };

  //   // Validate description length
  //   if (leadData['description'].length > 255) {
  //     developer.log('Description cannot exceed 255 characters.');
  //     return;
  //   }

  //   // Save data to database
  //   bool success = await saveData(conn, 'sales_lead', leadData);
  //   if (success) {
  //     developer.log('Lead data saved successfully.');
  //   } else {
  //     developer.log('Failed to save lead data.');
  //   }

  //   await conn.close();
  // }
}
