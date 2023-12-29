import 'package:flutter/material.dart';
import 'package:clientflow/order_status_graph.dart';
import 'package:clientflow/sales_report_graph.dart';
import 'package:clientflow/sales_report_page.dart';
import 'package:clientflow/top_selling_product_graph.dart';
import 'package:clientflow/top_selling_product_report_page.dart';
import 'package:clientflow/predicted_product_stocks.dart';
import 'package:clientflow/customer_sales_prediction.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clientflow/sales_forecast_graph.dart';
import 'customer_graph.dart';
import 'customer_report_page.dart';
import 'sales_order_page.dart';

class DataAnalyticsPage extends StatelessWidget {
  const DataAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data Analytics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0175FF),
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Stack(
              children: [
                Container(
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    child: Image.asset(
                      'asset/SALEFORECASE_LABEL.png',
                      width: 700,
                      height: 78,
                      fit: BoxFit.cover,
                    )),
                Container(
                  height: 78,
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        'Sales Forecast',
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(letterSpacing: -0.8),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const CustomerSalesPredictionPage()),
                  );
                },
                child: const SizedBox(
                  height: 590,
                  child: SalesForecastGraph(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalesReportPage()),
                  );
                },
                child: const SizedBox(
                  height: 425,
                  child: SalesReport(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerReport()),
                  );
                },
                child: const CustomersGraph(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProductReport()),
                  );
                },
                child: const SizedBox(
                  height: 427,
                  child: TopSellingProductsPage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const CustomerSalesPredictionPage()),
                  );
                },
                child: const SizedBox(
                  height: 452,
                  child: PredictedProductsTarget(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SalesOrderPage()),
                  );
                },
                child: const SizedBox(
                  height: 420,
                  child: OrderStatusWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
