import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class EventLogger {
  static Future<void> logEvent(
      int salesmanId, String activityDescription, String activityType,
      {int? leadId}) async {
    final apiUrl =
        Uri.parse('https://haluansama.com/crm-sales/api/event_logger/update_log_event.php');

    try {
      final response = await http.post(apiUrl, body: {
        'salesmanId': salesmanId.toString(),
        'activityDescription': activityDescription,
        'activityType': activityType,
        'leadId': leadId?.toString(),
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          developer.log('Event logged successfully');
        } else {
          developer.log('Error logging event: ${jsonData['message']}');
        }
      } else {
        developer
            .log('Failed to log event. Server error: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error logging event: $e');
    }
  }
}
