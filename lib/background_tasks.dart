import 'package:clientflow/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Get the logged-in salesman_id
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? salesmanId = prefs.getInt('id');

    if (salesmanId == null) {
      // If no salesman is logged in, don't process any tasks
      return Future.value(true);
    }

    switch (task) {
      case "fetchSalesOrderStatus":
        await checkOrderStatusAndNotify(salesmanId);
        break;
      case "checkTaskDueDates":
        await checkTaskDueDatesAndNotify(salesmanId);
        break;
      case "checkNewSalesLeads":
        await checkNewSalesLeadsAndNotify(salesmanId);
        break;
    }
    return Future.value(true);
  });
}
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case "fetchSalesOrderStatus":
//         await checkOrderStatusAndNotify();
//         break;
//       case "checkTaskDueDates":
//         await checkTaskDueDatesAndNotify();
//         break;
//       case "checkNewSalesLeads":
//         await checkNewSalesLeadsAndNotify();
//         break;
//     }
//     return Future.value(true);
//   });
// }

Future<void> checkOrderStatusAndNotify(int salesmanId) async {
  final String baseUrl =
      'https://haluansama.com/crm-sales/api/background_tasks/get_order_status.php?salesman_id=$salesmanId';

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        final notifications = responseData['notifications'] as List;
        for (var notification in notifications) {
          await showLocalNotification(
            'Order Status Changed',
            'Order for ${notification['customer_name']} has changed from ${notification['old_status']} to ${notification['new_status']}.',
          );
        }
        developer.log('Notifications processed: ${notifications.length}');
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception('Failed to check order status: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error checking order status and notifying: $e');
  }
}

// Future<void> checkOrderStatusAndNotify() async {
//   developer.log('Starting checkOrderStatusAndNotify');

//   try {
//     final apiUrl = Uri.parse(
//         'https://haluansama.com/crm-sales/api/background_tasks/get_order_status.php');
//     final response = await http.get(apiUrl);

//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         for (var row in jsonData['data']) {
//           var orderId = row['id'];
//           var customerName = row['customer_company_name'];
//           var salesmanId = row['buyer_id'];
//           var currentStatus = row['status'];
//           var lastCheckedStatus = row['last_checked_status'];

//           if (orderId == null ||
//               customerName == null ||
//               currentStatus == null ||
//               lastCheckedStatus == null) {
//             developer.log('Skipping row due to null values');
//             continue;
//           }

//           if (currentStatus != lastCheckedStatus) {
//             developer.log(
//                 'Status changed from $lastCheckedStatus to $currentStatus for order $orderId');
//             await _generateNotification(
//                 LeadItem(
//                   id: orderId,
//                   salesmanId: salesmanId,
//                   customerName: customerName,
//                   description: '',
//                   createdDate: DateTime.now().toString(),
//                   amount: '',
//                   contactNumber: '',
//                   emailAddress: '',
//                   stage: '',
//                   addressLine1: '',
//                   status: currentStatus,
//                 ),
//                 currentStatus, // newStatus
//                 lastCheckedStatus // oldStatus
//                 );
//           } else {
//             developer.log('No status change for order $orderId');
//           }
//         }
//       } else {
//         developer.log('Error: ${jsonData['message']}');
//       }
//     } else {
//       developer.log('Failed to load order status');
//     }
//   } catch (e) {
//     developer.log('Error in checkOrderStatusAndNotify: $e');
//   }
//   developer.log('Finished checkOrderStatusAndNotify');
// }

Future<void> checkTaskDueDatesAndNotify(int salesmanId) async {
  developer.log('Starting checkTaskDueDatesAndNotify');

  try {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/get_task_due_dates.php?salesman_id=$salesmanId');
    final response = await http.get(apiUrl);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        for (var row in jsonData['data']) {
          var taskTitle = row['title'];
          var dueDate = DateTime.parse(row['due_date']);
          var leadId = row['lead_id'].toString();
          var salesmanId = row['salesman_id'].toString();
          var customerName = row['customer_name'];

          var notificationTitle = 'Task Due Soon';
          var notificationBody =
              'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}';

          await _generateTaskandSalesLeadNotification(
              int.parse(salesmanId),
              notificationTitle,
              notificationBody,
              int.parse(leadId),
              'TASK_DUE_SOON');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      throw Exception('Failed to load task due dates: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error in checkTaskDueDatesAndNotify: $e');
  }
  developer.log('Finished checkTaskDueDatesAndNotify');
}

// Future<void> checkTaskDueDatesAndNotify() async {
//   developer.log('Starting checkTaskDueDatesAndNotify');

//   try {
//     final apiUrl = Uri.parse(
//         'https://haluansama.com/crm-sales/api/background_tasks/get_task_due_dates.php');
//     final response = await http.get(apiUrl);

//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         for (var row in jsonData['data']) {
//           var taskTitle = row['title'];
//           var dueDate = DateTime.parse(row['due_date']);
//           var leadId = row['lead_id'];
//           var salesmanId = row['salesman_id'];
//           var customerName = row['customer_name'];

//           var notificationTitle = 'Task Due Soon';
//           var notificationBody =
//               'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}';

//           await _generateTaskandSalesLeadNotification(
//               salesmanId,
//               'Task Due Soon',
//               'Task "$taskTitle" for $customerName is due on ${dueDate.toString().split(' ')[0]}',
//               leadId,
//               'TASK_DUE_SOON');
//         }
//       } else {
//         developer.log('Error: ${jsonData['message']}');
//       }
//     } else {
//       developer.log('Failed to load task due dates');
//     }
//   } catch (e) {
//     developer.log('Error in checkTaskDueDatesAndNotify: $e');
//   }
//   developer.log('Finished checkTaskDueDatesAndNotify');
// }

Future<void> checkNewSalesLeadsAndNotify(int salesmanId) async {
  developer.log('Starting checkNewSalesLeadsAndNotify for salesman_id: $salesmanId');

  try {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/background_tasks/get_new_sales_leads.php?salesman_id=$salesmanId');
    developer.log("Calling API with URL: $apiUrl"); // Add this log
    final response = await http.get(apiUrl);

    developer.log("API Response Status Code: ${response.statusCode}"); // Add this log
    developer.log("API Response Body: ${response.body}"); // Add this log

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        developer.log('Found ${jsonData['data'].length} new sales leads today');

        for (var lead in jsonData['data']) {
          // Convert string IDs to integers
          var leadId = lead['id'].toString();
          var customerName = lead['customer_name'];
          var salesmanId = lead['salesman_id'].toString();

          var notificationTitle = 'New Sales Lead';
          var notificationBody =
              'A new sales lead for $customerName has been created today.';

          await _generateTaskandSalesLeadNotification(
              int.parse(salesmanId),
              notificationTitle,
              notificationBody,
              int.parse(leadId),
              'NEW_SALES_LEAD');
        }
      } else {
        developer.log('Error: ${jsonData['message']}');
      }
    } else {
      throw Exception('Failed to load new sales leads: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error in checkNewSalesLeadsAndNotify: $e');
  }
  developer.log('Finished checkNewSalesLeadsAndNotify');
}

// Future<void> checkNewSalesLeadsAndNotify() async {
//   developer.log('Starting checkNewSalesLeadsAndNotify');

//   try {
//     final apiUrl = Uri.parse(
//         'https://haluansama.com/crm-sales/api/background_tasks/get_new_sales_leads.php');
//     final response = await http.get(apiUrl);

//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         for (var row in jsonData['data']) {
//           var leadId = row['id'];
//           var customerName = row['customer_name'];
//           var salesmanId = row['salesman_id'];

//           var notificationTitle = 'New Sales Lead';
//           var notificationBody =
//               'A new sales lead for $customerName has been created today.';

//           await _generateTaskandSalesLeadNotification(salesmanId,
//               notificationTitle, notificationBody, leadId, 'NEW_SALES_LEAD');
//         }
//       } else {
//         developer.log('Error: ${jsonData['message']}');
//       }
//     } else {
//       developer.log('Failed to load new sales leads');
//     }
//   } catch (e) {
//     developer.log('Error in checkNewSalesLeadsAndNotify: $e');
//   }
//   developer.log('Finished checkNewSalesLeadsAndNotify');
// }

// Generate status change notification
Future<void> _generateNotification(
    LeadItem leadItem, String newStatus, String oldStatus) async {
  const String baseUrl =
      'https://haluansama.com/crm-sales/api/background_tasks/update_notification.php';

  final Map<String, String> queryParameters = {
    'order_id': leadItem.id.toString(),
    'salesman_id': leadItem.salesmanId.toString(),
    'customer_name': leadItem.customerName,
    'new_status': newStatus,
    'old_status': oldStatus,
  };

  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        developer.log('Notification generated successfully');

        // Show local notification
        await showLocalNotification(
          'Order Status Changed',
          'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
        );
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception(
          'Failed to generate notification: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error generating notification: $e');
  }
}

// Future<void> _generateNotification(
//     LeadItem leadItem, String newStatus, String oldStatus) async {
//   try {
//     // API URL for generating notifications
//     final apiUrl = Uri.parse(
//         'https://haluansama.com/crm-sales/api/background_tasks/update_notification.php');

//     // Prepare the POST request
//     final response = await http.post(apiUrl, body: {
//       'salesmanId': leadItem.salesmanId.toString(),
//       'title': 'Order Status Changed',
//       'description':
//           'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
//       'relatedLeadId': leadItem.id.toString(),
//       'type': 'ORDER_STATUS_CHANGED',
//     });

//     // Handle the response
//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         await showLocalNotification(
//           'Order Status Changed',
//           'Order for ${leadItem.customerName} has changed from $oldStatus to $newStatus.',
//         );
//         developer.log('Notification sent: ${jsonData['message']}');
//       } else {
//         developer.log('Error generating notification: ${jsonData['message']}');
//       }
//     } else {
//       developer.log('Failed to generate notification');
//     }
//   } catch (e) {
//     developer.log('Error generating notification: $e');
//   }
// }

Future<void> _generateTaskandSalesLeadNotification(int salesmanId, String title,
    String description, int leadId, String type) async {
  const String baseUrl =
      'https://haluansama.com/crm-sales/api/background_tasks/update_task_lead_notification.php';

  final Map<String, String> queryParameters = {
    'salesman_id': salesmanId.toString(),
    'title': title,
    'description': description,
    'lead_id': leadId.toString(),
    'type': type,
  };

  final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        developer.log('Notification generated successfully');

        // Show local notification
        await showLocalNotification(title, description);
      } else {
        throw Exception(responseData['message']);
      }
    } else {
      throw Exception(
          'Failed to generate notification: ${response.statusCode}');
    }
  } catch (e) {
    developer.log('Error generating task notification: $e');
  }
}

// Future<void> _generateTaskandSalesLeadNotification(int salesmanId, String title,
//     String description, int leadId, String type) async {
//   try {
//     // API URL for generating task/lead notifications
//     final apiUrl = Uri.parse(
//         'https://haluansama.com/crm-sales/api/background_tasks/update_task_lead_notification.php');

//     // Prepare the POST request
//     final response = await http.post(apiUrl, body: {
//       'salesmanId': salesmanId.toString(),
//       'title': title,
//       'description': description,
//       'leadId': leadId.toString(),
//       'type': type,
//     });

//     // Handle the response
//     if (response.statusCode == 200) {
//       final jsonData = json.decode(response.body);
//       if (jsonData['status'] == 'success') {
//         await showLocalNotification(title, description);
//         developer.log('Notification sent: ${jsonData['message']}');
//       } else {
//         developer.log('Error generating notification: ${jsonData['message']}');
//       }
//     } else {
//       developer.log('Failed to generate notification');
//     }
//   } catch (e) {
//     developer.log('Error generating task/lead notification: $e');
//   }
// }

Future<void> showLocalNotification(String title, String body) async {
  // Check if notification permission is granted
  if (await Permission.notification.isGranted) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'clientflow_notifications', // channelId
      'Sales Navigator Notifications', // channelName
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show notification
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'notification',
    );
  } else {
    // Request permission if not granted
    await Permission.notification.request();
    developer.log('Notification permission was requested.');
  }
}
