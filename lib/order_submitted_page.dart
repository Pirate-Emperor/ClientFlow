import 'package:flutter/material.dart';
import 'package:clientflow/cart_page.dart';
import 'package:clientflow/home_page.dart';
import 'package:clientflow/order_details_page.dart';

class OrderSubmittedPage extends StatefulWidget {
  final int salesOrderId;

  const OrderSubmittedPage({Key? key, required this.salesOrderId})
      : super(key: key);

  @override
  _OrderSubmittedPageState createState() => _OrderSubmittedPageState();
}

class _OrderSubmittedPageState extends State<OrderSubmittedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Order Submitted',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 90.0),
              Expanded( // Ensures it takes available space within the parent
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // Scales text to fit within its parent
                    child: Text(
                      'Thank you for your order.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER ID',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  'SO${widget.salesOrderId.toString().padLeft(7, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16.0, right: 16.0),
                  child: Text(
                    'Our administrator will respond to your order within two working days.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        const Color(0xff0175FF)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(
                      const Size(130.0, 40.0),
                    ),
                  ),
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(
                          cartID: widget.salesOrderId,
                          fromOrderConfirmation: true,
                          fromSalesOrder: false,
                        ),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      const Color(0xffffffff),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: const BorderSide(
                          color: Color(0xff0175FF),
                          width: 1.0,
                        ),
                      ),
                    ),
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown, // Scales down text to prevent overflow
                    child: Text(
                      'View Order',
                      style: TextStyle(
                        color: Color(0xff0175FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
