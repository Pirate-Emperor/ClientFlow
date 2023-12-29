import 'package:flutter/material.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class EditItemPage extends StatefulWidget {
  final int? itemId;
  final String itemName;
  final String itemUom;
  final String itemPhoto;
  double itemPrice;

  EditItemPage({
    super.key,
    required this.itemName,
    required this.itemId,
    required this.itemUom,
    required this.itemPhoto,
    required this.itemPrice,
  });

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  double discountPercentage = 0.0;
  TextEditingController priceController = TextEditingController();
  TextEditingController discountController = TextEditingController();
  bool repriceAuthority = false;
  bool discountAuthority = false;

  @override
  void initState() {
    super.initState();
    checkRepricingAuthority();
  }

  void calculateDiscountedPrice() async {
    double discountAmount = widget.itemPrice * (discountPercentage / 100);
    double discountedPrice = widget.itemPrice - discountAmount;

    await updateItemPrice(discountedPrice);
  }

  Future<void> updateItemPrice(double newPrice) async {
    try {
      int itemId = widget.itemId ?? 0;

      Map<String, dynamic> updateData = {
        'id': itemId,
        'unit_price': newPrice,
        'discount': discountPercentage,
      };

      int rowsAffected =
          await DatabaseHelper.updateData(updateData, 'cart_item');
      if (rowsAffected > 0) {
        setState(() {
          if (newPrice >= 0.00) {
            widget.itemPrice = newPrice;
          } else {
            widget.itemPrice = 0.00;
          }
        });
      } else {
        developer.log('Failed to update item price');
      }
    } catch (e) {
      developer.log('Error updating item price: $e', error: e);
    }
  }

  Future<void> checkRepricingAuthority() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    if (pref.getString('repriceAuthority') == 'Yes') {
      repriceAuthority = true;
    }

    if (pref.getString('discountAuthority') == 'Yes') {
      discountAuthority = true;
    }
  }

  void updatePriceAndAuthority() {
    // Parse input values from text controllers
    double inputPrice = priceController.text.trim().isNotEmpty
        ? double.parse(priceController.text)
        : 0.0;
    double inputDiscount = discountController.text.trim().isNotEmpty
        ? double.parse(discountController.text)
        : 0.0;

    // Check if discount is within the valid range
    if (inputDiscount < 0.0 || inputDiscount >= 100.0) {
      showAlertDialog('Discount must be between 0% and 100%', Colors.red);
      return;
    }

    // Determine if input values are provided and user has corresponding authority
    bool hasRepriceAuthority = repriceAuthority && inputPrice > 0.0;
    bool hasDiscountAuthority = discountAuthority && inputDiscount > 0.0;

    if (priceController.text.trim().isNotEmpty &&
        discountController.text.trim().isNotEmpty &&
        hasRepriceAuthority &&
        hasDiscountAuthority) {
      setState(() {
        widget.itemPrice = inputPrice;
        discountPercentage = inputDiscount;
      });
      calculateDiscountedPrice();
      showAlertDialog('Price updated', Colors.green);
    } else if (priceController.text.trim().isNotEmpty &&
        discountController.text.trim().isEmpty &&
        hasRepriceAuthority) {
      setState(() {
        widget.itemPrice = inputPrice;
      });
      updateItemPrice(inputPrice);
      showAlertDialog('Price updated', Colors.green);
    } else if (priceController.text.trim().isEmpty &&
        discountController.text.trim().isNotEmpty &&
        hasDiscountAuthority) {
      setState(() {
        discountPercentage = inputDiscount;
      });
      calculateDiscountedPrice();
      showAlertDialog('Price updated', Colors.green);
    } else {
      showAlertDialog('You do not have authority to reprice item', Colors.red);
    }
  }

  void showAlertDialog(String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: color,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 4),
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Automatically close dialog after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'Edit Item',
          style: TextStyle(color: Color(0xffF8F9FA)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, widget.itemPrice);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xffcde5f2),
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: SizedBox(
                            width: 90,
                            child: widget.itemPhoto.isNotEmpty
                                ? Image.network(
                                    'https://haluansama.com/crm-sales/${widget.itemPhoto}',
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'asset/no_image.jpg',
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 200,
                                child: Text(
                                  widget.itemName,
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              SizedBox(
                                width: 220,
                                child: Text(
                                  widget.itemUom,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        const Text(
                          'Unit Price (RM)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: (widget.itemPrice).toStringAsFixed(3),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 50.0),
                        Expanded(
                          child: SizedBox(
                            height: 36.0,
                            child: TextField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0%',
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      priceController.clear();
                      discountController.clear();
                    });
                  },
                  style: ButtonStyle(
                    padding:WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(
                      const Size(120.0, 40.0),
                    ),
                    backgroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 46.0),
                ElevatedButton(
                  onPressed: () {
                    updatePriceAndAuthority();
                  },
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 20.0),
                    ),
                    minimumSize: WidgetStateProperty.all<Size>(
                      const Size(120.0, 40.0),
                    ),
                    backgroundColor: WidgetStateProperty.all<Color>(
                      const Color(0xff0175FF),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
