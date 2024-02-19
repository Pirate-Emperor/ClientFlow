import 'package:flutter/material.dart';

class TermsandConditions extends StatelessWidget {
  const TermsandConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications, color: Colors.white),
        //     onPressed: () {
        //       // Handle notifications
        //     },
        //   ),
        // ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'Welcome to FYH Online Store',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Terms and conditions stated below apply to all visitors and users '
              'of FYH Online Store website. You are bound by these terms and '
              'conditions as long as you are on fyhstore.com.my.',
            ),
            Divider(
              color: Colors.grey,
              thickness: 1.0,
              height: 20.0,
            ),
            SizedBox(height: 16),
            Text(
              'General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'The content of terms and conditions may be changed, moved, or '
              'deleted at any time. Please be informed that Fong Yuan Hung '
              'Imp & Exp Sdn Bhd has the rights to change contents of the '
              'terms without any notice. Immediate actions against '
              'offender(s) for violating or breaching any rules & regulations '
              'stated in the terms.',
            ),
            Divider(
              color: Colors.grey,
              thickness: 1.0,
              height: 20.0,
            ),
            SizedBox(height: 16),
            Text(
              'Site Contents & Copyrights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Unless otherwise stated, all materials including images, '
              'illustrations, designs, icons, photographs, video clips, '
              'written materials, and other materials that appear as part '
              'of this site (in other words, "Contents of Site") are '
              'copyrights, trademarks, trade dress, or other intellectual '
              'properties owned, controlled, or licensed by Fong Yuan Hung '
              'Imp & Exp Sdn Bhd.',
            ),
          ],
        ),
      ),
    );
  }
}
