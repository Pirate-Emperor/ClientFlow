import 'package:flutter/material.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.white),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications),
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
            Text(
              'Fong Yuan Hung Imp and Exp Sdn Bhd (622210-M)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No.7, Lorong 1, Muara Tabuan Light Industrial Estate,',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Off Jalan Setia Raja, 93450, Kuching, Sarawak,',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Malaysia.',
              style: TextStyle(fontSize: 16),
            ),
            Divider(
              color: Colors.grey,
              thickness: 1.0,
              height: 20.0,
            ),
            SizedBox(height: 16),
            Text(
              'TEL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('+60-82362333, 3626666, 362999'),
            SizedBox(height: 8),
            Text(
              'FAX:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('+60-82365180, 3630302, 370227'),
            SizedBox(height: 8),
            Text(
              'EMAIL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('FYHKCH@HOTMAIL.COM'),
            SizedBox(height: 16),
            Divider(
              color: Colors.grey,
              thickness: 1.0,
              height: 20.0,
            ),
            Text(
              'BUSINESS HOURS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('MONDAY - FRIDAY: 8AM - 5PM'),
            Text('SATURDAY: 8AM - 12.30PM'),
            Text('SUNDAY: CLOSED'),
            Text('PUBLIC HOLIDAY: CLOSED'),
          ],
        ),
      ),
    );
  }
}
