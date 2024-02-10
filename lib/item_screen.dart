import "package:flutter/material.dart";
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mysql1/mysql1.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:clientflow/item_variations_screen.dart';
import "package:google_fonts/google_fonts.dart";
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ItemScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final List<String> itemAssetNames;
  final Blob itemDescription;
  final String priceByUom;

  const ItemScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.itemAssetNames,
    required this.itemDescription,
    required this.priceByUom,
  });

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  late int _areaId;
  String _uom = '';
  double _price = 0.0;
  late Map<int, Map<String, double>> _priceData;
  late String _priceDataByArea;
  int _selectedImageIndex = 0;
  int cartCount = 0;

  Future<void> getAreaId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _areaId = prefs.getInt('areaId') ?? 1;
    });
    await getPriceData();
  }

  void retrievePriceByUomUsingAreaId() {
    if (_priceData.containsKey(_areaId)) {
      Map<String, double> areaData = _priceData[_areaId]!;
      if (areaData.isNotEmpty) {
        MapEntry<String, double> firstEntry = areaData.entries.first;
        _uom = firstEntry.key;
        _price = firstEntry.value;
        _priceDataByArea = jsonEncode(areaData);
      } else {
        developer.log('No data found for area ID: $_areaId');
      }
    } else {
      developer.log('Area ID $_areaId not found in price data.');
    }
  }

  Future<void> getPriceData() async {
    try {
      Map<String, dynamic> decodedData = jsonDecode(widget.priceByUom);
      _priceData = {};

      decodedData.forEach((key, value) {
        int areaId = int.tryParse(key) ?? 1;
        if (value is Map<String, dynamic>) {
          Map<String, double> areaPrices = {};
          value.forEach((uom, price) {
            if (price is String) {
              double parsedPrice =
                  double.tryParse(price.replaceAll(',', '')) ?? 0.0;
              areaPrices[uom] = parsedPrice;
            }
          });
          _priceData[areaId] = areaPrices;
        }
      });

      retrievePriceByUomUsingAreaId();
    } catch (e) {
      developer.log('Error decoding price data: $e');
    }
  }

  // Function to fetch the cart count from the database
  Future<void> fetchCartCount() async {
    final count = await DatabaseHelper.getCartItemCount(); // Replace with your logic
    setState(() {
      cartCount = count; // Update the state variable
    });
  }

  // Function to update cart count when called from ItemVariationsScreen
  void updateCartCount() {
    fetchCartCount(); // Re-fetch the cart count
  }

  Future<void> initializeData() async {
    await getAreaId();
  }

  @override
  void initState() {
    super.initState();
    initializeData();
    fetchCartCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 34,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff0175FF),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 6,
                ),
              ],
              border: Border.all(
                width: 1,
                color: const Color.fromARGB(255, 0, 76, 135),
              ),
            ),
            child: CachedNetworkImage(
              imageUrl: widget.itemAssetNames[_selectedImageIndex],
              height: 400,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error_outline),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemAssetNames.length,
              itemBuilder: (context, index) {
                final assetName = widget.itemAssetNames[index];

                // Check if the assetName is empty or 'null' placeholder
                if (assetName.isEmpty ||
                    assetName == 'https://haluansama.com/crm-sales/null') {
                  return const SizedBox
                      .shrink(); // Shrinks if the assetName is empty
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Image.network(
                      assetName,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 300,
                      child: Text(
                        widget.productName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: Text(
                        _uom,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 25, 23, 49),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                /*IconButton(
                  iconSize: 40,
                  onPressed: () {},
                  icon: const Icon(Icons.shortcut_sharp),
                ), */
              ],
            ),
          ),
          const Divider(
            height: 24,
            thickness: 1,
            color: Color.fromARGB(255, 202, 202, 202),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Text(
              "Item Variations",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 25, 23, 49),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Card(
              color: Colors.white,
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return ItemVariationsScreen(
                        productId: widget.productId,
                        productName: widget.productName,
                        itemAssetName: widget.itemAssetNames[0],
                        priceByUom: _priceDataByArea,
                        onCartUpdate: updateCartCount,
                      );
                    }),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.productName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 25, 23, 49),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_uom: RM ${_price.toStringAsFixed(3)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 25, 23, 49),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 30,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return ItemVariationsScreen(
                                productId: widget.productId,
                                productName: widget.productName,
                                itemAssetName: widget.itemAssetNames[0],
                                priceByUom: _priceDataByArea,
                                onCartUpdate: updateCartCount,
                              );
                            }),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(
            height: 24,
            thickness: 1,
            color: Color.fromARGB(255, 202, 202, 202),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            child: Text(
              "Item Descriptions",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 25, 23, 49),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10, top: 14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 28),
              child: HtmlWidget(
                widget.itemDescription.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
