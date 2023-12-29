import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:clientflow/cart_item.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:clientflow/model/cart_model.dart';
import 'package:clientflow/utility_function.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';

class ItemVariationsScreen extends StatefulWidget {
  const ItemVariationsScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.itemAssetName,
    required this.priceByUom,
    required this.onCartUpdate, // Add this line
  });

  final int productId;
  final String productName;
  final String itemAssetName;
  final String priceByUom;
  final VoidCallback onCartUpdate; // Add this line

  @override
  State<ItemVariationsScreen> createState() => _ItemVariationsScreenState();
}


class _ItemVariationsScreenState extends State<ItemVariationsScreen> {
  late Map<String, dynamic> priceData;
  late Map<String, int> quantityMap = {};
  late CartItem? cartItem;
  List<TextEditingController> textControllers = [];

  @override
  void initState() {
    super.initState();
    priceData = jsonDecode(widget.priceByUom);
    initializeQuantityMap();
    initializeTextControllers();
  }

  void initializeQuantityMap() {
    for (var uom in priceData.keys) {
      quantityMap[uom] = quantityMap[uom] ?? 1;
    }
  }

  void updateCartCountInNavBar() {
    // Trigger navigation bar to refresh cart item count
    setState(() {});
  }

  void initializeTextControllers() {
    textControllers = List.generate(priceData.length, (index) {
      final uom = priceData.keys.elementAt(index);
      return TextEditingController(text: quantityMap[uom].toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Item Variations',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xff0175FF),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: ListView.builder(
        itemCount: priceData.length,
        itemBuilder: (context, idx) {
          final uom = priceData.keys.elementAt(idx);
          final price = priceData[uom];
          final currentQuantity = quantityMap[uom] ?? 1;
          final isUnavailable = price == 0;
          TextEditingController textController = textControllers[idx];

          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Opacity(
                  opacity: isUnavailable ? 0.5 : 1.0,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 1,
                                color: const Color.fromARGB(255, 0, 76, 135),
                              ),
                            ),
                            child: Image.network(
                              widget.itemAssetName,
                              height: 115,
                              width: 115,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        widget.productName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        uom,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      iconSize: 28,
                                      onPressed: isUnavailable
                                          ? null
                                          : () {
                                              // Decrement quantity when minus button is pressed
                                              if (currentQuantity > 1) {
                                                setState(() {
                                                  quantityMap[uom] =
                                                      currentQuantity - 1;
                                                  textController.text =
                                                      quantityMap[uom]
                                                          .toString();
                                                });
                                              }
                                            },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    SizedBox(
                                      width:
                                          60, // Adjust the width of the TextField container
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        controller: textController,
                                        onChanged: (value) {
                                          final newValue = int.tryParse(value);
                                          if (newValue != null &&
                                              newValue > 0) {
                                            setState(() {
                                              quantityMap[uom] = newValue;
                                            });
                                          } else {
                                            // If the value is not a positive integer or is null, reset it to 1
                                            setState(() {
                                              textController.text = '1';
                                              quantityMap[uom] = 1;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      iconSize: 28,
                                      onPressed: isUnavailable
                                          ? null
                                          : () {
                                              // Increment quantity when plus button is pressed
                                              setState(() {
                                                quantityMap[uom] =
                                                    currentQuantity + 1;
                                                textController.text =
                                                    quantityMap[uom].toString();
                                              });
                                            },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.only(left: 10, bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isUnavailable
                                  ? 'RM0.000'
                                  : 'RM ${(price! * currentQuantity).toStringAsFixed(3)}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isUnavailable
                                  ? null
                                  : () async {
                                      // Create CartItem with current quantity and uom
                                      final cartItem = CartItem(
                                        buyerId:
                                            await UtilityFunction.getUserId(),
                                        productId: widget.productId,
                                        productName: widget.productName,
                                        uom: uom,
                                        quantity: currentQuantity,
                                        discount: 0,
                                        originalUnitPrice: price,
                                        unitPrice: price,
                                        total: price * currentQuantity,
                                        cancel: null,
                                        remark: null,
                                        status: 'in progress',
                                        created: DateTime.now(),
                                        modified: DateTime.now(),
                                      );

                                      // Insert CartItem into database
                                      await insertItemIntoCart(cartItem);

                                      // Show success dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => const AlertDialog(
                                          backgroundColor: Colors.green,
                                          title: Row(
                                            children: [
                                              SizedBox(width: 20),
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Item added to cart',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );

                                      // Automatically close dialog after 1 second
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        Navigator.pop(context);
                                        updateCartCountInNavBar();
                                      });

                                      // Update cart count in the navigation bar
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                backgroundColor: const Color(0xff0175FF),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                    ],
                  ),
                ),
              ),
              if (isUnavailable)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Unavailable',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> insertItemIntoCart(CartItem cartItem) async {
    int itemId = cartItem.productId;
    String uom = cartItem.uom;

    try {
      const tableName = 'cart_item';
      final condition =
          "product_id = $itemId AND uom = '$uom' AND status = 'in progress'";
      const order = '';
      const field = '*';

      final db = await DatabaseHelper.database;

      // Read data from the database based on the provided condition
      final result = await DatabaseHelper.readData(
        db,
        tableName,
        condition,
        order,
        field,
      );

      if (result.isNotEmpty) {
        final existingItem = result.first;
        final updatedQuantity = existingItem['qty'] + cartItem.quantity;

        final data = {
          'id': existingItem['id'],
          'qty': updatedQuantity,
          'modified': UtilityFunction.getCurrentDateTime(),
        };

        await DatabaseHelper.updateData(data, tableName);
        developer.log('Cart item quantity updated successfully');
      } else {
        final cartItemMap = cartItem.toMap(excludeId: true);
        await DatabaseHelper.insertData(cartItemMap, tableName);
        developer.log('New cart item inserted successfully');
      }

      // Use the CartModel to update the cart count
      Provider.of<CartModel>(context, listen: false).initializeCartCount();

    } catch (e) {
      developer.log('Error inserting or updating cart item: $e', error: e);
    }
  }

}
