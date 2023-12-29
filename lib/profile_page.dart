import 'package:flutter/material.dart';
import 'package:clientflow/chatbot_page.dart';
import 'package:clientflow/data_analytics_page.dart';
import 'package:workmanager/workmanager.dart';
import 'about_us_page.dart';
import 'account_setting_page.dart';
import 'contact_us_page.dart';
import 'package:clientflow/recent_order_page.dart';
import 'terms_and_conditions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Components/navigation_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? salesmanName;
  int currentPageIndex = 4;
  @override
  void initState() {
    super.initState();
    _getSalesmanName();
  }

  // Use the didChangeDependencies function to recapture salesperson names
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getSalesmanName();
  }

  Future<void> _getSalesmanName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      salesmanName = prefs.getString('salesmanName') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xff0175FF),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              // Display salesman name
              Container(
                  alignment: Alignment.center,
                  child: Text(
                    '$salesmanName',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  )),
              const SizedBox(height: 20),
              buildProfileOption('Account Setting', Icons.settings, context),
              buildProfileOption('Reports', Icons.analytics, context),
              buildProfileOption('Recent Order', Icons.shopping_bag, context),
              buildProfileOption(
                  'Terms & Condition', Icons.description, context),
              buildProfileOption('Contact Us', Icons.phone, context),
              buildProfileOption('About Us', Icons.info, context),
              // buildProfileOption('Chatbot', Icons.chat, context),
              const SizedBox(height: 20),
              buildLogoutButton(), // add Logout button
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  Widget buildProfileOption(String title, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // check button title
        if (title == 'Account Setting') {
          Navigator.push(
            // Navigate to account setting page
            context,
            MaterialPageRoute(builder: (context) => const AccountSetting()),
          ).then((value) {
            if (value == true) {
              _getSalesmanName();
            }
          });
        }
        if (title == 'Reports') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataAnalyticsPage()),
          );
        }
        if (title == 'Recent Order') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const RecentOrder(
                      customerId: 0,
                    )),
          );
        }
        if (title == 'Terms & Condition') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TermsandConditions()),
          );
        }
        if (title == 'Contact Us') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactUs()),
          );
        }
        if (title == 'About Us') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutUs()),
          );
        }
        // if (title == 'Chatbot') {
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (context) => const ChatScreen()),
        //   );
        // }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(),
        child: ListTile(
          leading: Icon(
            icon,
            color: const Color(0xff0175FF),
          ),
          title: Text(title),
        ),
      ),
    );
  }

  Widget buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.only(left: 100, right: 100),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Cancel all background tasks
          await Workmanager().cancelAll();

          // Clearing data in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Navigate to the login page
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            'Log Out',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
