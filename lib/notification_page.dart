// ignore_for_file: unused_import, unused_local_variable

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'package:clientflow/home_page.dart';
import 'package:clientflow/utility_function.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  final RemoteMessage? message;

  const NotificationsPage({super.key, this.message});
  static const route = '/notification-page';

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  late int salesmanId;

  @override
  void initState() {
    super.initState();
    developer
        .log("NotificationsPage initialized with message: ${widget.message}");
    _initializeSalesmanId().then((_) => _fetchNotifications());
  }

  Future<void> _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  Future<void> _fetchNotifications() async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/notification_page/get_notifications.php?salesmanId=$salesmanId');
    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          setState(() {
            notifications = List<Map<String, dynamic>>.from(jsonData['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = jsonData['message'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load notifications';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching notifications: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/notification_page/update_delete_notification.php');

    try {
      final response = await http.post(apiUrl, body: {
        'notificationId': notificationId.toString(),
      });

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          notifications.removeWhere(
              (notification) => notification['id'] == notificationId);
        });
      } else {
        developer.log('Error deleting notification: ${jsonData['message']}');
      }
    } catch (e) {
      developer.log('Error deleting notification: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final apiUrl = Uri.parse(
        'https://haluansama.com/crm-sales/api/notification_page/update_mark_as_read.php');

    try {
      final response = await http.post(apiUrl, body: {
        'notificationId': notificationId.toString(),
      });

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          var notification =
              notifications.firstWhere((n) => n['id'] == notificationId);
          notification['read_status'] = 1;
        });
      } else {
        developer
            .log('Error marking notification as read: ${jsonData['message']}');
      }
    } catch (e) {
      developer.log('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final RemoteMessage? message =
        ModalRoute.of(context)!.settings.arguments as RemoteMessage?;

    if (message != null) {
      developer.log(
          "Building NotificationsPage with message: ${message.notification?.title}");
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff0175FF),
          title: const Text(
            'Notifications',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : notifications.isEmpty
                    ? const Center(child: Text('No notifications'))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) =>
                            _buildNotificationItem(notifications[index]),
                      ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    String? notificationType = notification['type'];
    int? relatedId = notification['related_lead_id'];

    switch (notificationType) {
      // Navigate to order processing stage
      case 'ORDER_STATUS_CHANGED':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(initialIndex: 3),
          ),
        );
        break;
      // Navigate to negociation stage
      case 'TASK_DUE_SOON':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(initialIndex: 2),
          ),
        );
        break;
      // Navigate to opportunities stage
      case 'NEW_SALES_LEAD':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(initialIndex: 0),
          ),
        );
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(notification['id']);
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification['read_status'] == 0
                ? Colors.blue[50]
                : Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_on_outlined,
                    color: notification['read_status'] == 0
                        ? Colors.blue
                        : const Color(0xff0069BA),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notification['title'] ?? 'No Title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: notification['read_status'] == 0
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification['description'] ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: notification['read_status'] == 0
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification['created_at'] != null
                    ? DateFormat('yyyy-MM-dd HH:mm')
                        .format(DateTime.parse(notification['created_at']))
                    : 'Unknown Date',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
