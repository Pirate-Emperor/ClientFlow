import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountSetting extends StatefulWidget {
  const AccountSetting({super.key});

  @override
  _AccountSettingState createState() {
    return _AccountSettingState();
  }
}

class _AccountSettingState extends State<AccountSetting> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  int salesmanId = 0;

  @override
  void initState() {
    super.initState();
    getSalesmanInfo();
  }

  // Get salesman information from shared preferences at initialization time
  void getSalesmanInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('salesmanName') ?? '';
    String phoneNumber = prefs.getString('contactNumber') ?? '';
    String email = prefs.getString('email') ?? '';

    // Retrieve salesman ID from SharedPreferences
    int id = prefs.getInt('id') ?? 0;

    setState(() {
      nameController.text = name;
      phoneNumberController.text = phoneNumber;
      emailController.text = email;
      salesmanId = id;
    });
  }

  // The function used to update salesman info in database
  Future<void> updateSalesmanDetailsInDatabase() async {
    String newName = nameController.text;
    String newPhoneNumber = phoneNumberController.text;
    String newEmail = emailController.text;

    try {
      // Prepare API URL
      final url = Uri.parse('https://haluansama.com/crm-sales/api/salesman/update_salesman_details.php');

      // Make POST request to API with salesman details
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'salesmanId': salesmanId,
          'newName': newName,
          'newPhoneNumber': newPhoneNumber,
          'newEmail': newEmail,
        }),
      );

      // Parse the API response
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Save updated details to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('salesmanName', newName);
        prefs.setString('contactNumber', newPhoneNumber);
        prefs.setString('email', newEmail);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salesman details updated successfully.'),
          ),
        );
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      developer.log('Error updating salesman details: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update salesman details. Please try again.'),
        ),
      );
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Account Setting',
          style: TextStyle(color: Colors.white),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications),
        //     onPressed: () {
        //       // Handle notifications
        //     },
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salesman Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                Container(
                  margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: const BorderSide(color: Colors.red, width: 2),
                        ),
                        minimumSize: const Size(120, 40)),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Apply button
                Container(
                  margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      updateSalesmanDetailsInDatabase();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0175FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        minimumSize: const Size(120, 40)),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
