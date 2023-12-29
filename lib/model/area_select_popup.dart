import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clientflow/event_logger.dart';
import 'package:clientflow/utility_function.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AreaSelectPopUp extends StatefulWidget {
  const AreaSelectPopUp({super.key});

  @override
  State<AreaSelectPopUp> createState() => _AreaSelectPopUpState();
}

class _AreaSelectPopUpState extends State<AreaSelectPopUp> {
  late Map<int, String> area = {};
  static late int selectedAreaId;
  late int salesmanId;

  Future<void> setAreaId(int areaId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('areaId', areaId);
    setState(() {
      selectedAreaId = areaId;
    });

    // Log the event when an area is selected
    String selectedAreaName = area[areaId] ?? 'Unknown Area';
    await EventLogger.logEvent(
      salesmanId,
      'Area selected: $selectedAreaName',
      'Area Selection',
      leadId: null,
    );
  }

  Future<void> fetchAreaFromDb() async {
    Map<int, String> areaMap = {};
    const String apiUrl = 'https://haluansama.com/crm-sales/api/area/get_area.php';
    try {
      // Call the API to fetch areas
      final response = await http.get(Uri.parse('$apiUrl?status=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Ensure the data is in the expected format
          if (data['data'] is List) {
            for (var row in data['data']) {
              if (row is Map<String, dynamic>) { // Ensure row is of correct type
                int id = row['id'] is int ? row['id'] : int.tryParse(row['id'].toString()) ?? 0;
                String area = row['area'] is String ? row['area'] : '';
                areaMap[id] = area;
              }
            }

            setState(() {
              area = areaMap; // Assuming 'area' is defined in your state
            });

            // Retrieve the currently selected areaId from preferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            int? storedAreaId = prefs.getInt('areaId');

            // Set selectedAreaId to the stored areaId if available, otherwise set it to the first areaId from the query
            if (storedAreaId != null && areaMap.containsKey(storedAreaId)) {
              setState(() {
                selectedAreaId = storedAreaId; // Assuming 'selectedAreaId' is defined in your state
              });
            } else if (areaMap.isNotEmpty) {
              setState(() {
                selectedAreaId = areaMap.keys.first;
                // Store the initial selectedAreaId in SharedPreferences
                prefs.setInt('areaId', selectedAreaId);
              });
            }
          } else {
            developer.log('Error: data["data"] is not a List', error: 'Expected a list but got ${data['data']}');
          }
        } else {
          // Handle error case
          developer.log('Error: ${data['message']}', error: data['message']);
        }
      } else {
        developer.log('Failed to load areas: ${response.statusCode}', error: response.body);
      }
    } catch (e) {
      developer.log('Error fetching area: $e', error: e);
    }
  }

  @override
  void initState() {
    super.initState();
    selectedAreaId = -1;
    fetchAreaFromDb();
    _initializeSalesmanId();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: area.entries.map((entry) {
        int areaId = entry.key;
        String areaName = entry.value;

        return RadioListTile<int>(
          title: Text(
            areaName,
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: areaId,
          groupValue: selectedAreaId,
          onChanged: (selectedAreaId) {
            setAreaId(selectedAreaId!);
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    );
  }
}
