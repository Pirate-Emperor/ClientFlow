import 'package:flutter/material.dart';
import "package:google_fonts/google_fonts.dart";

class CategoryButton extends StatelessWidget {
  const CategoryButton(
      {super.key, required this.buttonNames, required this.onTap});

  final String buttonNames;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              backgroundColor: Colors.white),
          child: Text(
            buttonNames,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 25, 23, 49),
            ),
          )),
    );
  }
}
