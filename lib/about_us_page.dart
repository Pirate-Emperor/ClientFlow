import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'About Us',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 20, left: 70),
              margin: const EdgeInsets.only(bottom: 20),
              child: Image.asset(
                'asset/logo/logo_fyh.png',
                width: 200,
                height: 100,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our company Fong Yuan Hung Import and Export Sdn. Bhd. was '
              'established back in 1980, it has been 40 years in the business. '
              'We specialised in mechanical scales, digital scales, hardware tools, '
              'power tools, food processing machineries, agriculture tools and equipments, '
              'industrial tools and machineries, construction tools and materials, '
              'automotive products etc.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are a major importer, distributor, and wholesaler. Our market '
              'covers the whole East Malaysia (Sarawak and Sabah). Over the years, '
              'we have imported products from more than 10 different countries, '
              'including China, Taiwan, South Korea, Thailand, Vietnam, Philippines, '
              'India, United Kingdom, Australia, and New Zealand. We import around '
              '10-15 (20\') containers of goods and products annually.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'We are continuing to expand our product offerings to further satisfy the '
              'demand of our market. Feel free to explore our website for the full '
              'range of products we offer. Potential customers are more than welcome '
              'to contact us if you are interested in our line of business.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
