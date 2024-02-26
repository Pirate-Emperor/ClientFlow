import 'package:flutter/material.dart';
import 'package:clientflow/data/sort_list_data.dart';
import 'package:google_fonts/google_fonts.dart';

class SortPopUp extends StatefulWidget {
  final Function(String) onSortChanged;

  const SortPopUp({super.key, required this.onSortChanged});

  @override
  State<SortPopUp> createState() => _SortPopUp();
}

class _SortPopUp extends State<SortPopUp> {
  static String currentSortList = sortLists[0];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile(
          title: Text(
            sortLists[0],
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: sortLists[0],
          groupValue: currentSortList,
          onChanged: (value) {
            setState(() {
              currentSortList = value.toString();
            });
            widget.onSortChanged(
                currentSortList);
          },
        ),
        RadioListTile(
          title: Text(
            sortLists[1],
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: sortLists[1],
          groupValue: currentSortList,
          onChanged: (value) {
            setState(() {
              currentSortList = value.toString();
            });
            widget.onSortChanged(
                currentSortList);
          },
        ),
        RadioListTile(
          title: Text(
            sortLists[2],
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: sortLists[2],
          groupValue: currentSortList,
          onChanged: (value) {
            setState(() {
              currentSortList = value.toString();
            });
            widget.onSortChanged(
                currentSortList);
          },
        ),
        RadioListTile(
          title: Text(
            sortLists[3],
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: sortLists[3],
          groupValue: currentSortList,
          onChanged: (value) {
            setState(() {
              currentSortList = value.toString();
            });
            widget.onSortChanged(
                currentSortList);
          },
        ),
        RadioListTile(
          title: Text(
            sortLists[4],
            style: GoogleFonts.inter(
              fontSize: 18,
            ),
          ),
          value: sortLists[4],
          groupValue: currentSortList,
          onChanged: (value) {
            setState(() {
              currentSortList = value.toString();
            });
            widget.onSortChanged(
                currentSortList);
          },
        ),
      ],
    );
  }
}