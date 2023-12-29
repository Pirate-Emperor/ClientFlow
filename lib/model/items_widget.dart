import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mysql1/mysql1.dart';
import 'package:clientflow/item_screen.dart';
import 'package:clientflow/utility_function.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class ItemsWidget extends StatefulWidget {
  final int? brandId;
  final int? subCategoryId;
  final List<int>? subCategoryIds;
  final List<int>? brandIds;
  final String sortOrder;
  final bool isFeatured;

  const ItemsWidget({
    super.key,
    this.brandId,
    this.subCategoryId,
    this.subCategoryIds,
    this.brandIds,
    required this.sortOrder,
    required this.isFeatured,
  });

  @override
  _ItemsWidgetState createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 40;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final products = await getProductData(offset: _offset, limit: _limit);
      setState(() {
        if (products.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(products);
          _offset += _limit;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle errors if needed
    }
  }

  Future<List<Map<String, dynamic>>> getProductData({
    required int offset,
    required int limit,
  }) async {
    try {
      // Construct the query parameters
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      // Add optional filter parameters only if they are not null and not empty
      if (widget.sortOrder.isNotEmpty)
        queryParams['sortOrder'] = widget.sortOrder;
      if (widget.isFeatured) queryParams['isFeatured'] = 'true';
      if (widget.brandId != null)
        queryParams['brandId'] = widget.brandId.toString();
      if (widget.subCategoryId != null)
        queryParams['subCategoryId'] = widget.subCategoryId.toString();
      if (widget.subCategoryIds != null && widget.subCategoryIds!.isNotEmpty)
        queryParams['subCategoryIds'] = widget.subCategoryIds!.join(',');
      if (widget.brandIds != null && widget.brandIds!.isNotEmpty)
        queryParams['brandIds'] = widget.brandIds!.join(',');

      final uri = Uri.https('haluansama.com',
          '/crm-sales/api/product/get_products.php', queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List<dynamic>;

        return products.map((product) {
          // Parse the price_by_uom JSON string
          Map<String, dynamic> priceByUom =
              jsonDecode(product['price_by_uom'] as String? ?? '{}');

          // Get the first price and variant count from the first area (ID "1")
          String firstPrice = '0.000';
          int variantCount = 0;
          if (priceByUom.containsKey('1')) {
            var firstArea = priceByUom['1'];
            if (firstArea is Map && firstArea.isNotEmpty) {
              firstPrice = firstArea.values.first.toString();
              variantCount = firstArea.length;
            }
          }

          return {
            'id': product['id'] is int
                ? product['id']
                : int.tryParse(product['id'].toString()) ?? 0,
            'product_name': product['product_name'] as String? ?? '',
            'photo1': product['photo1'] as String? ?? '',
            'photo2': product['photo2'] as String?,
            'photo3': product['photo3'] as String?,
            'description':
                _sanitizeHtml(product['description'] as String? ?? ''),
            'price_by_uom': product['price_by_uom'] as String? ?? '',
            'featured': product['featured'] as String? ?? '',
            'first_price': firstPrice,
            'variant_count': variantCount,
          };
        }).toList();
      } else {
        developer.log(
            'Error fetching product data: Server responded with status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('Error fetching product data: $e');
      return [];
    }
  }

  String _sanitizeHtml(String html) {
    try {
      final document = html_parser.parse(html);
      return document.body?.text ?? '';
    } catch (e) {
      developer.log('Error sanitizing HTML content: $e');
      return html;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Two items per row
        childAspectRatio:
            MediaQuery.of(context).size.width < 2000 ? 0.60 : 0.70,
      ),
      itemCount: _products.length +
          (_hasMore ? 4 : 0), // Add four shimmer placeholders
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          // Display four shimmer effects in a 2x2 grid
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }

        // If products are available, display them here
        final product = _products[index];
        final productId = product['id'] as int;
        final productName = product['product_name'] as String;
        final localPath = product['photo1'] as String;
        final localPath2 = product['photo2'] as String?;
        final localPath3 = product['photo3'] as String?;
        Blob itemDescription =
            UtilityFunction.stringToBlob(product['description']);

        final photoUrl1 = "https://haluansama.com/crm-sales/$localPath";
        final photoUrl2 = localPath2 != null
            ? "https://haluansama.com/crm-sales/$localPath2"
            : '';
        final photoUrl3 = localPath3 != null
            ? "https://haluansama.com/crm-sales/$localPath3"
            : '';

        final containerSize = (MediaQuery.of(context).size.width - 40) / 2;

        return GestureDetector(
          onTap: () {
            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemScreen(
                    productId: productId,
                    itemAssetNames: [photoUrl1, photoUrl2, photoUrl3],
                    productName: productName,
                    itemDescription: itemDescription,
                    priceByUom: product['price_by_uom'].toString(),
                  ),
                ),
              );
            } catch (e) {
              developer.log('Error navigating to ItemScreen: $e');
            }
          },
          child: Container(
            padding:
                const EdgeInsets.only(left: 6, right: 6, top: 8, bottom: 2),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(
                  blurStyle: BlurStyle.normal,
                  color: Color.fromARGB(75, 117, 117, 117),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    try {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemScreen(
                            productId: productId,
                            itemAssetNames: [photoUrl1, photoUrl2, photoUrl3],
                            productName: productName,
                            itemDescription: itemDescription,
                            priceByUom: product['price_by_uom'].toString(),
                          ),
                        ),
                      );
                    } catch (e) {
                      developer.log('Error navigating to ItemScreen: $e');
                    }
                  },
                  child: Container(
                    height: containerSize,
                    width: containerSize,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: const Color.fromARGB(255, 0, 76, 135),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl1,
                      height: containerSize,
                      width: containerSize,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: containerSize,
                          width: containerSize,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error_outline),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      Container(
                        width: containerSize,
                        padding: const EdgeInsets.only(top: 8),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Text(
                                      productName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromARGB(
                                            255, 25, 23, 49),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: containerSize,
                        padding: const EdgeInsets.only(top: 8),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Text(
                                      textAlign: TextAlign.left,
                                      'RM ${product['first_price']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xff0175FF),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    child: Text(
                                      textAlign: TextAlign.left,
                                      '${product['variant_count']} Variants',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
