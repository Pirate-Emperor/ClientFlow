import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemBottomNavBar extends StatelessWidget {
  const ItemBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: EdgeInsets.zero,
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Row(
        children: [
          Container(
            color: const Color.fromARGB(255, 4, 124, 189),
            width: 146,
            height: 82,
            child: InkWell(
              splashColor: Colors.blueAccent,
              onTap: () {},
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                  ),
                  const Icon(
                    Icons.share,
                    size: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Share',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 138,
          ),
          ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                backgroundColor: const Color.fromARGB(255, 4, 124, 189),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: Text(
                'Add To Cart',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ))
        ],
      ));
  }
}
