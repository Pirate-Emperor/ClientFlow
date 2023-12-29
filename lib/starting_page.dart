import 'package:flutter/material.dart';
import 'package:clientflow/login_page.dart';

class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top right illustration
          Positioned(
            top: 0,
            right: -40,
            child: Image.asset(
              'asset/top_start.png',
              width: 300,
              height: 300,
            ),
          ),
          // Bottom left illustration
          Positioned(
            bottom: -40,
            left: 0,
            child: Image.asset(
              'asset/bttm_start.png',
              width: 250,
              height: 250,
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'asset/logo/logo_fyh.png',
                  width: 300,
                  height: 100,
                ),
                const SizedBox(height: 50),
                const Text(
                  "Let's get started.",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to LoginPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
