import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clientflow/customer_Insights.dart';
import 'package:clientflow/home_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ClosedLeadItem extends StatelessWidget {
  final LeadItem leadItem;
  final String formattedCreatedDate;
  final String expirationDate;
  final String total;
  final String quantity;

  const ClosedLeadItem({
    super.key,
    required this.leadItem,
    required this.formattedCreatedDate,
    required this.expirationDate,
    required this.total,
    required this.quantity,
  });

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    String formattedSalesOrderId = leadItem.salesOrderId != null
        ? 'SO${leadItem.salesOrderId!.padLeft(7, '0')}'
        : '';
    double formattedTotal = double.parse(total);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerInsightsPage(
              customerName: leadItem.customerName,
            ),
          ),
        );
      },
      child: Container(
        height: 278,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Color.fromARGB(75, 117, 117, 117),
                spreadRadius: 0.1,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ]),
        margin: const EdgeInsets.only(left: 8, right: 8, top: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text(
                  //   leadItem.customerName.length > 15
                  //       ? '${leadItem.customerName.substring(0, 15)}...'
                  //       : leadItem.customerName,
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 20,
                  //   ),
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  Flexible(
                    child: Text(
                      leadItem.customerName,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(letterSpacing: -0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 25, 23, 49),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          // Perform an action based on the selected value
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'view details',
                            child: Text('View details'),
                          ),
                        ],
                        child: const Icon(Icons.more_horiz_outlined,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: leadItem.contactNumber.isNotEmpty
                        ? () => _launchURL('tel:${leadItem.contactNumber}' as Uri)
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            leadItem.contactNumber.isNotEmpty
                                ? leadItem.contactNumber
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: leadItem.emailAddress.isNotEmpty
                        ? () => _launchURL('mailto:${leadItem.emailAddress}' as Uri)
                        : null,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email,
                          color: Color(0xff0175FF),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          child: Text(
                            leadItem.emailAddress.isNotEmpty
                                ? leadItem.emailAddress
                                : 'Unavailable',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                formattedSalesOrderId,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xff0175FF)),
              ),
              const SizedBox(
                height: 8,
              ),
              Text('Created date: $formattedCreatedDate'),
              Text('Expiry date: $expirationDate'),
              const SizedBox(height: 8),
              Text(
                leadItem.quantity != null
                    ? 'Quantity: ${leadItem.quantity} items      Total: RM${_formatCurrency(formattedTotal)}'
                    : 'Quantity: Unknown      Total: RM${_formatCurrency(formattedTotal)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created on: ${leadItem.createdDate}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
