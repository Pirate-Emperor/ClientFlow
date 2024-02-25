import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  const CustomTabBar({super.key});

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  int _selectedIndex = 0; // The index of the selected item

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Background color for the whole row
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => _buildTabItem(index)),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    List<String> tabNames = [
      'All',
      'Featured products',
      'Most popular',
      'New products'
    ];
    bool isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index; // Update the selected index
        });
        // Perform any additional actions when a tab is selected
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : Colors.transparent, // Selected item has blue background
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        child: Text(
          tabNames[index],
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.black, // Selected item has white text
          ),
        ),
      ),
    );
  }
}
