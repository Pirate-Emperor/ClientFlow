import 'dart:core';
import 'package:mysql1/mysql1.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class UtilityFunction{
  static String calculateExpirationDate() {
    // Initialize the time zone data
    tzdata.initializeTimeZones();

    // Specify the time zone for Kuala Lumpur
    final kualaLumpur = tz.getLocation('Asia/Kuala_Lumpur');

    // Get today's date in the Kuala Lumpur time zone
    final now = tz.TZDateTime.now(kualaLumpur);

    // Calculate expiration date by adding 7 days
    final expirationDate = now.add(const Duration(days: 7));

    // Format expiration date in 'yyyy-MM-dd' format
    String formattedExpirationDate = DateFormat('yyyy-MM-dd').format(expirationDate);

    return formattedExpirationDate;
  }

  static Future<double> retrieveTax(String taxType) async {
    double defaultTaxInPercent = 0.0; // Default tax percentage (0.0 = 0%)
    const String apiUrl = 'https://haluansama.com/crm-sales/api/utility_function/get_tax.php';

    try {
      // Prepare the API request
      final Uri apiUri = Uri.parse('$apiUrl?tax_type=$taxType');
      final response = await http.get(apiUri);

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Retrieve tax_in_percent from the response
          int taxInPercent = data['tax_in_percent'] ?? 0;

          // Calculate final tax percentage (divide taxInPercent by 100)
          double finalTaxPercent = taxInPercent / 100.0;

          return finalTaxPercent;
        } else {
          // If no tax data found, return the default tax percentage
          developer.log('Error retrieving tax: ${data['message']}');
          return defaultTaxInPercent;
        }
      } else {
        // Handle non-200 status codes
        developer.log('Failed to retrieve tax, status code: ${response.statusCode}');
        return defaultTaxInPercent;
      }
    } catch (e, stackTrace) {
      // Log the error if something goes wrong
      developer.log('Error retrieving tax: $e', error: e, stackTrace: stackTrace);
      return defaultTaxInPercent;
    }
  }

  static String getCurrentDateTime() {
    // Initialize the time zone data
    tzdata.initializeTimeZones();

    // Specify the time zone for Kuala Lumpur
    final kualaLumpur = tz.getLocation('Asia/Kuala_Lumpur');

    // Get the current time in the Kuala Lumpur time zone
    final now = tz.TZDateTime.now(kualaLumpur);

    // Format date and time components
    String formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    return formattedDateTime;
  }

  // Function to retrieve area name by ID from the API
  static Future<String> getAreaNameById(int id) async {
    String areaName = '';
    const String apiUrl = 'https://haluansama.com/crm-sales/api/utility_function/get_area.php';

    try {
      // Prepare the API request
      final Uri apiUri = Uri.parse('$apiUrl?id=$id');
      final response = await http.get(apiUri);

      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Retrieve area name from the response
          areaName = data['area'];
        } else {
          // Log error message if area not found
          developer.log('Error retrieving area name: ${data['message']}');
        }
      } else {
        // Handle non-200 status codes
        developer.log('Failed to retrieve area name, status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Log the error if something goes wrong
      developer.log('Error retrieving area name: $e', error: e, stackTrace: stackTrace);
    }

    return areaName;
  }

  static Future<int> getUserId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int userId = pref.getInt('id') as int;
    return userId;
  }

  static Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
  }

  static Future<int> getNumberOfItemsInCart() async {
    final userId = await UtilityFunction.getUserId();

    try {
      const tableName = 'cart_item';
      final condition = "buyer_id = $userId AND status = 'in progress'";

      final db = await DatabaseHelper.database;

      final itemCount = await DatabaseHelper.countData(
        db,
        tableName,
        condition,
      );

      return itemCount;
    } catch (e) {
      developer.log('Error fetching count of cart items: $e', error: e);
      return 0;
    }
  }
}
