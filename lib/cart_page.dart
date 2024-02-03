import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:clientflow/Components/navigation_bar.dart';
import 'package:clientflow/edit_item_page.dart';
import 'package:clientflow/event_logger.dart';
import 'package:clientflow/item_screen.dart';
import 'package:clientflow/model/cart_model.dart';
import 'package:clientflow/order_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:clientflow/utility_function.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'customer.dart';
import 'customer_details_page.dart';
import 'cart_item.dart';
import 'db_sqlite.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPage();
}

class _CartPage extends State<CartPage> {
  // Customer Details Section
  static Customer? customer;
  static bool customerSelected = false;

  // Cart Section
  List<CartItem> cartItems = [];
  List<CartItem> selectedCartItems = [];
  late int totalCartItems = 0;
  late List<List<String>> productPhotos = [];
  double total = 0;
  double subtotal = 0;
  String formattedTotal = 'RM0.000';
  String formattedSubtotal = 'RM0.000';

  late int salesmanId;

  // Tax Section
  static double gst = 0;
  static double sst = 0;

  // Edit Cart
  bool editCart = false;
  bool isChecked = false;
  bool selectAll = false;

  List<TextEditingController> textControllers = [];

  @override
  void initState() {
    super.initState();
    loadTaxFromCacheOrApi();
    loadCartItemsAndPhotos();
    initializeTextControllers();
    _initializeSalesmanId();
  }

  void _initializeSalesmanId() async {
    final id = await UtilityFunction.getUserId();
    setState(() {
      salesmanId = id;
    });
  }

  void initializeTextControllers() {
    textControllers = List.generate(
        cartItems.length,
        (index) =>
            TextEditingController(text: cartItems[index].quantity.toString()));
  }

  Future<void> loadTaxFromCacheOrApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Try to load from cache
    gst = prefs.getDouble('gst') ?? 0;
    sst = prefs.getDouble('sst') ?? 0;

    // If not found in cache, load from API and save to cache
    if (gst == 0 || sst == 0) {
      await getTax();
    }
  }

  Future<void> getTax() async {
    gst = await UtilityFunction.retrieveTax('GST');
    sst = await UtilityFunction.retrieveTax('SST');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gst', gst);
    await prefs.setDouble('sst', sst);
  }

  Future<void> calculateTotalAndSubTotal() async {
    double calculatedSubtotal = 0;

    // Calculate total and subtotal based on cart items
    for (CartItem item in cartItems) {
      calculatedSubtotal += item.unitPrice * item.quantity;
    }

    // Calculate final total using fetched tax values
    double finalTotal = 0.000;
    if (customerSelected) {
      finalTotal = (calculatedSubtotal * (1 + gst + sst)) -
          (calculatedSubtotal * customer!.discountRate / 100);
    } else {
      finalTotal = calculatedSubtotal * (1 + gst + sst);
    }

    // Format the total and subtotal
    final formatter =
        NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);
    String formattedTotal = formatter.format(finalTotal);
    String formattedSubtotal = formatter.format(calculatedSubtotal);

    // Update state with calculated values
    setState(() {
      total = finalTotal;
      subtotal = calculatedSubtotal;
      this.formattedTotal = formattedTotal;
      this.formattedSubtotal = formattedSubtotal;
    });
  }

  Future<void> loadCartItemsAndPhotos() async {
    try {
      // Load cart items
      final List<CartItem> items = await readCartItems();

      // Fetch product photos concurrently
      final List<Future<List<String>>> photoFutures = items.map((item) async {
        final List<Map<String, dynamic>> photos =
            await getProductPhoto(item.productId);

        // Convert the dynamic map entries to List<String>, ensuring type safety
        return photos
            .map<String>((photo) => photo['photo1']?.toString() ?? '')
            .toList();
      }).toList();

      // Wait for all photo fetch requests to complete
      final List<List<String>> photosList = await Future.wait(photoFutures);

      setState(() {
        cartItems = items;
        updateCartItemsWithLatestPrices();
        totalCartItems = items.length;
        productPhotos = photosList;
        calculateTotalAndSubTotal();
      });
    } catch (e) {
      developer.log('Error loading cart items and photos: $e', error: e);
    }
  }

  Future<void> cacheCartItems(List<CartItem> cartItems) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartItemsJson = cartItems.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList('cachedCartItems', cartItemsJson);
  }

  Future<List<CartItem>> getCachedCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsJson = prefs.getStringList('cachedCartItems');

    if (cartItemsJson != null) {
      return cartItemsJson.map((json) => CartItem.fromMap(jsonDecode(json))).toList();
    }
    developer.log(cartItemsJson.toString());
    return []; // Return an empty list if there are no cached items
  }

  Future<List<CartItem>> readCartItems() async {
    // Load cached items first
    List<CartItem> cachedCartItems = await getCachedCartItems();

    // if (cachedCartItems.isNotEmpty) {
    //   return cachedCartItems; // Return cached items if available
    // }

    // Proceed to load items from the database if no cached items are found
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt('id') ?? 0;

    Database database = await DatabaseHelper.database;
    String cartItemTableName = DatabaseHelper.cartItemTableName;
    String condition = "buyer_id = $id AND status = 'in progress'";
    String order = 'created DESC';
    String field = '*';

    List<Map<String, dynamic>> queryResults = await DatabaseHelper.readData(
        database, cartItemTableName, condition, order, field);

    // Initialize text controllers after fetching items
    textControllers = List.generate(queryResults.length, (index) => TextEditingController());

    // Convert the results to CartItem objects
    List<CartItem> cartItems = queryResults.map((map) => CartItem.fromMap(map)).toList();

    // Cache the fetched cart items for future access
    await cacheCartItems(cartItems);

    return cartItems;
  }

  Future<List<Map<String, dynamic>>> getProductPhoto(int productId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://haluansama.com/crm-sales/api/product/get_prod_photo_by_prod_id.php?productId=$productId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['photos']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      developer.log('Error fetching product photo: $e');
      return [];
    }
  }

  Future<void> deleteSelectedCartItems() async {
    try {
      // Get the list of cart item IDs to be deleted
      List<int?> cartItemIds =
          selectedCartItems.map((item) => item.id).toList();

      // Delete the selected cart items from the database
      for (int? cartItemId in cartItemIds) {
        await DatabaseHelper.deleteData(
            cartItemId, DatabaseHelper.cartItemTableName);
      }

      // Log the event
      int deletedItemsCount = selectedCartItems.length;
      await EventLogger.logEvent(
        salesmanId,
        'Deleted $deletedItemsCount item(s) from cart',
        'Cart Item Deletion',
      );

      // Reload the cart items after deletion
      await loadCartItemsAndPhotos();

      // Clear the selected cart items list after successful deletion
      setState(() {
        selectedCartItems.clear();
      });

      // Show a snackbar to confirm deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedItemsCount item(s) deleted from cart'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.initializeCartCount();
    } catch (e) {
      developer.log('Error deleting selected cart items: $e', error: e);
      // Show an error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete items. Please try again.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteSingleCartItem(int? cartItemId) async {
    try {
      // Delete the selected cart item from the database
      await DatabaseHelper.deleteData(cartItemId, DatabaseHelper.cartItemTableName);

      // Log the event (you may want to adjust this based on your logging strategy)
      await EventLogger.logEvent(
        salesmanId,
        'Deleted item with ID $cartItemId from cart',
        'Cart Item Deletion',
      );

      // Reload the cart items after deletion
      await loadCartItemsAndPhotos();

      // Show a snackbar to confirm deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Update the cart count
      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.initializeCartCount();
    } catch (e) {
      developer.log('Error deleting item with ID $cartItemId: $e', error: e);
      // Show an error message if deletion fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete item. Please try again.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateItemQuantity(int? id, int quantity) async {
    try {
      int? itemId = id ?? 0;

      Map<String, dynamic> updateData = {
        'id': itemId,
        'qty': quantity,
        'total':
            cartItems.firstWhere((element) => element.id == itemId).unitPrice *
                quantity,
      };

      int rowsAffected =
          await DatabaseHelper.updateData(updateData, 'cart_item');
      if (rowsAffected > 0) {
        developer.log('Item quantity updated successfully');
      } else {
        developer.log('Failed to update item quantity');
      }
    } catch (e) {
      developer.log('Error updating item quantity: $e', error: e);
    }
  }

  void navigateToItemScreen(int selectedProductId) async {
    final apiUrl =
        'https://haluansama.com/crm-sales/api/product/get_product_by_id.php?id=$selectedProductId';

    try {
      // Make an HTTP GET request to fetch the product details
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Check if the status is success and product data is present
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['product'] != null) {
          Map<String, dynamic> product = jsonResponse['product'];

          // Extract the product details from the JSON response
          int productId = product['id'];
          String productName = product['product_name'];
          List<String> itemAssetName = [
            'https://haluansama.com/crm-sales/${product['photo1'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo2'] ?? 'null'}',
            'https://haluansama.com/crm-sales/${product['photo3'] ?? 'null'}',
          ];
          Blob description = stringToBlob(product['description']);
          String priceByUom = product['price_by_uom'] ?? '';

          // Navigate to ItemScreen and pass the necessary parameters
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemScreen(
                productId: productId,
                productName: productName,
                itemAssetNames: itemAssetName,
                itemDescription: description,
                priceByUom: priceByUom,
              ),
            ),
          );
        } else {
          developer.log(
              'Product not found or API returned error: ${jsonResponse['message']}');
        }
      } else {
        developer
            .log('Failed to fetch product details: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching product details: $e', error: e);
    }
  }

  Blob stringToBlob(String data) {
    // Create a Blob instance from the string using Blob.fromString
    Blob blob = Blob.fromString(data);

    return blob;
  }

  Future<Map<int, double>> retrieveLatestPrices(List<int> productIds) async {
    // API URL
    const String apiUrl =
        'https://haluansama.com/crm-sales/api/sales_order/get_product_prices.php';

    // Prepare the JSON body
    final Map<String, dynamic> body = {
      'customer_id': customer?.id,
      'product_ids': productIds,
    };

    // Send a POST request to the API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    // Check if the request was successful
    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'success') {
        // Create a map for latest prices
        Map<int, double> latestPrices = {};
        final pricesData = data['data'] as Map<String, dynamic>;

        // Populate the latest prices map
        pricesData.forEach((key, value) {
          // Ensure the value is a number and convert to double
          latestPrices[int.parse(key)] = (value is String)
              ? double.tryParse(value) ?? 0.0
              : value.toDouble();
        });

        return latestPrices;
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception(
          'Failed to load product prices: ${response.reasonPhrase}');
    }
  }

  // Function to update cart items with the latest prices
  Future<void> updateCartItemsWithLatestPrices() async {
    if (cartItems.isEmpty) {
      developer.log('Cart is empty. No products to update.');
      return;
    }

    // Reset previous prices for all items
    for (var item in cartItems) {
      item.previousPrice = null;
    }

    List<int> productIds = cartItems.map((item) => item.productId).toList();

    Map<int, double> latestPrices = await retrieveLatestPrices(productIds);

    setState(() {
      for (var item in cartItems) {
        if (latestPrices.containsKey(item.productId)) {
          item.previousPrice = latestPrices[item.productId]!;
        } else {
          developer
              .log('No previous price found for product ID ${item.productId}');
        }
      }
    });
  }

  // Callback function to update customer info
  void updateCustomer(Customer newCustomer) {
    setState(() {
      customer = newCustomer; // Update the customer in the cart
      calculateTotalAndSubTotal(); // Recalculate total when customer is updated
      updateCartItemsWithLatestPrices(); // Update cart items with latest prices
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
    NumberFormat.currency(locale: 'en_US', symbol: 'RM', decimalDigits: 3);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FutureBuilder<List<CartItem>>(
            future: readCartItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppBar(
                  automaticallyImplyLeading: false,
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 2),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Color(0xffF8F9FA),
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xff0175FF),
                  centerTitle: true,
                  actions: const [],
                );
              } else if (snapshot.hasError) {
                return AppBar(
                  automaticallyImplyLeading: false,
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 2),
                      Text(
                        'Error loading cart',
                        style: TextStyle(
                          color: Color(0xffF8F9FA),
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xff0175FF),
                  centerTitle: true,
                  actions: const [],
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return AppBar(
                  automaticallyImplyLeading: false,
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: 2),
                      Text(
                        'Shopping Cart',
                        style: TextStyle(
                          color: Color(0xffF8F9FA),
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xff0175FF),
                  centerTitle: true,
                  actions: const [],
                );
              }

              // If we have data, build the AppBar with cart items information
              List<CartItem> cartItems = snapshot.data!;
              return AppBar(
                automaticallyImplyLeading: false,
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 2),
                    Text(
                      'Shopping Cart',
                      style: TextStyle(
                        color: Color(0xffF8F9FA),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xff0175FF),
                centerTitle: true,
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        editCart = !editCart; // Toggle editCart state
                      });
                    },
                    child: Text(
                      editCart ? 'Done' : 'Edit', // Toggle button text
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Customer Details',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              customerSelected
                  ? CustomerInfo(
                      initialCustomer: customer!,
                      onCustomerUpdated:
                          updateCustomer, // Pass callback to update customer
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildSelectCustomerCard(context),
                    ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                ),
                child: SizedBox(
                  height: 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (editCart)
                        Checkbox(
                          value: selectAll,
                          onChanged: (bool? value) {
                            setState(() {
                              selectAll =
                                  value ?? false; // Toggle "Select All" state

                              if (selectAll) {
                                // Select all cart items
                                selectedCartItems = List.from(cartItems);
                              } else {
                                // Deselect all cart items
                                selectedCartItems.clear();
                              }
                            });
                          },
                        ),
                      Text(
                        'Cart ($totalCartItems)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Display cart items dynamically
              if (cartItems.isEmpty)
                Container(
                  color: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.only(
                      top: 16.0,
                      bottom: 16.0,
                      right: 72.0,
                      left: 16.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'No products are in the cart yet',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(cartItems.length, (index) {
                    CartItem item = cartItems[index];
                    List<String> itemPhotos =
                        productPhotos.isNotEmpty ? productPhotos[index] : [];
                    bool isSelected = selectedCartItems.contains(item);
                    final currentQuantity = item.quantity;
                    final formattedPrice =
                        formatter.format(item.unitPrice * item.quantity);
                    // Format previous price only if it's not null
                    String? formattedPreviousPrice;
                    if (item.previousPrice != null) {
                      formattedPreviousPrice =
                          formatter.format(item.previousPrice! * item.quantity);
                    }
                    TextEditingController textController =
                        textControllers[index];
                    textController.text = item.quantity.toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Dismissible(
                        key: Key(item.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Removal"),
                                content: Text(
                                    "Are you sure you want to remove ${item.productName} from the cart?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false); // User canceled the action
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true); // User confirmed the action
                                    },
                                    child: const Text("Remove"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) async {
                          // Call the delete function for the single cart item
                          await deleteSingleCartItem(item.id);

                          // Optionally, you can remove the item from the list here as well
                          setState(() {
                            cartItems.removeAt(index); // Assuming you have access to the index
                            selectedCartItems.remove(item); // Remove from selected items if necessary
                          });
                        },
                      background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            navigateToItemScreen(item.productId);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    blurStyle: BlurStyle.normal,
                                    color: Color.fromARGB(75, 117, 117, 117),
                                    spreadRadius: 0.1,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 8.0,
                                left: 6.0,
                                right: 2.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (editCart) // Conditionally render checkbox if editCart is true
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value != null && value) {
                                            // Add the item to selectedCartItems when checkbox is checked
                                            selectedCartItems.add(item);
                                          } else {
                                            // Remove the item from selectedCartItems when checkbox is unchecked
                                            selectedCartItems.remove(item);
                                          }
                                        });
                                      },
                                    ),
                                  SizedBox(
                                    width: 90,
                                    child: (itemPhotos.isNotEmpty)
                                        ? Image.network(
                                            'https://haluansama.com/crm-sales/${itemPhotos[0]}',
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: SizedBox(
                                                width: 180,
                                                child: Text(
                                                  item.productName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Overflow handling
                                                  maxLines:
                                                      3, // Allow up to 3 lines of text
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () async {
                                                final updatedPrice =
                                                    await Navigator.push<
                                                        double?>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EditItemPage(
                                                      itemId: item.id,
                                                      itemName:
                                                          item.productName,
                                                      itemUom: item.uom,
                                                      itemPhoto:
                                                          itemPhotos.isNotEmpty
                                                              ? itemPhotos[0]
                                                              : '',
                                                      itemPrice: item.unitPrice,
                                                    ),
                                                  ),
                                                );

                                                if (updatedPrice != null) {
                                                  setState(() {
                                                    item.unitPrice =
                                                        updatedPrice;
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 200,
                                          child: item.uom.isNotEmpty
                                              ? Text(
                                                  item.uom,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  softWrap: true,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Display the item price
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 200,
                                                      child: Row(
                                                        children: [
                                                          Flexible(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  formattedPrice,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .green,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                if (item.previousPrice !=
                                                                    null) // Check if previousPrice is not null
                                                                  Text(
                                                                    item.unitPrice - item.previousPrice! >
                                                                            0
                                                                        ? ' ▲'
                                                                        : (item.unitPrice - item.previousPrice! <
                                                                                0
                                                                            ? ' ▼'
                                                                            : ''),
                                                                    style:
                                                                        TextStyle(
                                                                      color: (item.unitPrice - item.previousPrice! >
                                                                              0)
                                                                          ? Colors
                                                                              .red
                                                                          : ((item.unitPrice - item.previousPrice! < 0)
                                                                              ? Colors.green
                                                                              : null),
                                                                    ),
                                                                  ),
                                                                if (item.previousPrice !=
                                                                        null &&
                                                                    (item.unitPrice -
                                                                            item.previousPrice!) !=
                                                                        0) // Check if previousPrice is not null and price difference is not 0
                                                                  Text(
                                                                    '${((item.unitPrice - item.previousPrice!) / item.previousPrice! * 100).toStringAsFixed(0)}%',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
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
                                                SizedBox(
                                                  child: (item.previousPrice !=
                                                              null &&
                                                          item.previousPrice !=
                                                              item.unitPrice) // Check if previousPrice is not null and is different from unitPrice
                                                      ? Text(
                                                          formattedPreviousPrice!,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.grey,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        // Group for quantity controls (IconButton and TextField)
                                        Visibility(
                                          visible:
                                              !editCart, // Set visibility based on the value of editCart
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                iconSize: 28,
                                                onPressed: () {
                                                  // Decrement quantity when minus button is pressed
                                                  if (currentQuantity > 1) {
                                                    setState(() {
                                                      item.quantity =
                                                          currentQuantity - 1;
                                                      textController.text = item
                                                          .quantity
                                                          .toString();
                                                      updateItemQuantity(
                                                          item.id,
                                                          item.quantity);
                                                      calculateTotalAndSubTotal();
                                                    });
                                                  } else {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Delete Item?'),
                                                        content: const Text(
                                                            'Are you sure you want to delete this item from the cart?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context); // Close the dialog
                                                            },
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              // Remove the item from the list and delete from the database
                                                              setState(() {
                                                                cartItems
                                                                    .removeAt(
                                                                        index);
                                                                selectedCartItems
                                                                    .remove(
                                                                        item);
                                                                totalCartItems =
                                                                    cartItems
                                                                        .length;
                                                              });
                                                              DatabaseHelper.deleteData(
                                                                  item.id,
                                                                  DatabaseHelper
                                                                      .cartItemTableName); // Assuming this is an asynchronous operation
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      '${item.productName} removed from cart'),
                                                                  duration:
                                                                      const Duration(
                                                                          seconds:
                                                                              1),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                              Navigator.pop(
                                                                  context); // Close the dialog
                                                            },
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.remove),
                                              ),
                                              SizedBox(
                                                width:
                                                    60, // Adjust the width of the TextField container
                                                child: TextField(
                                                  textAlign: TextAlign.center,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .allow(RegExp(
                                                            r'[0-9]')), // Only allow numeric input
                                                    LengthLimitingTextInputFormatter(
                                                        5), // Limit the length of input to 5 characters
                                                  ],
                                                  controller: textController,
                                                  onChanged: (value) {
                                                    final newValue =
                                                        int.tryParse(value);
                                                    if (newValue != null) {
                                                      setState(() {
                                                        item.quantity =
                                                            newValue;
                                                        updateItemQuantity(
                                                            item.id,
                                                            item.quantity);
                                                        calculateTotalAndSubTotal();
                                                      });
                                                    }
                                                    // Check if the entered value is 0 and show confirmation dialog
                                                    if (newValue == 0 ||
                                                        newValue == null) {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                          title: const Text(
                                                              'Delete Item?'),
                                                          content: const Text(
                                                              'Are you sure you want to delete this item from the cart?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                // Reset quantity to 1 and close the dialog
                                                                setState(() {
                                                                  item.quantity =
                                                                      1;
                                                                  textController
                                                                          .text =
                                                                      '1'; // Reset text field value
                                                                  totalCartItems =
                                                                      cartItems
                                                                          .length;
                                                                });
                                                                Navigator.pop(
                                                                    context); // Close the dialog
                                                              },
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Remove the item from the list and delete from the database
                                                                setState(() {
                                                                  cartItems
                                                                      .removeAt(
                                                                          index);
                                                                  selectedCartItems
                                                                      .remove(
                                                                          item);
                                                                });
                                                                DatabaseHelper
                                                                    .deleteData(
                                                                        item.id,
                                                                        DatabaseHelper
                                                                            .cartItemTableName); // Assuming this is an asynchronous operation
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        '${item.productName} removed from cart'),
                                                                    duration: const Duration(
                                                                        seconds:
                                                                            1),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                  ),
                                                                );
                                                                Navigator.pop(
                                                                    context); // Close the dialog
                                                              },
                                                              child: const Text(
                                                                  'Delete'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                iconSize: 28,
                                                onPressed: () {
                                                  // Increment quantity when plus button is pressed
                                                  setState(() {
                                                    item.quantity =
                                                        currentQuantity + 1;
                                                    updateItemQuantity(
                                                        item.id, item.quantity);
                                                    calculateTotalAndSubTotal();
                                                  });
                                                },
                                                icon: const Icon(Icons.add),
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
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavigationBar(),
      persistentFooterButtons: [
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Container(
            padding: const EdgeInsets.only(
              left: 8.0,
              top: 4.0,
            ),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: editCart
                          ? Text(
                              '${selectedCartItems.length} item(s) selected',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total: $formattedTotal',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xff0175FF),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  'Subtotal: $formattedSubtotal',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (editCart)
                      Builder(
                        builder: (BuildContext context) {
                          return ElevatedButton(
                            onPressed: () {
                              if (selectedCartItems.isNotEmpty) {
                                // Show confirmation dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                              'Are you sure you want to delete the following items?'),
                                          const SizedBox(height: 10),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight:
                                                  200.0, // Limit height to 200px for scrollable content
                                            ),
                                            child: Scrollbar(
                                              thumbVisibility: true,
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: selectedCartItems
                                                        .asMap()
                                                        .entries
                                                        .map((entry) {
                                                      int index = entry.key;
                                                      var item = entry.value;
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item.productName,
                                                            textAlign:
                                                                TextAlign.start,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          if (index <
                                                              selectedCartItems
                                                                      .length -
                                                                  1)
                                                            const Divider(
                                                              thickness: 1.0,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context); // Close the dialog
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Perform the delete action
                                            deleteSelectedCartItems();
                                            Navigator.pop(
                                                context); // Close the dialog
                                            setState(() {
                                              editCart = false;
                                            });
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all<Color>(Colors.red),
                              shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    if (!editCart)
                      ElevatedButton(
                        onPressed: () {
                          if (customer == null) {
                            // Show dialog if customer is not selected
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Customer Not Selected'),
                                  content: const Text(
                                      'Please select a customer before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (cartItems.isEmpty) {
                            // Show dialog if cart items are empty
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Cart is Empty'),
                                  content: const Text(
                                      'Please add items to the cart before proceeding.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                            context); // Close the dialog
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            // Logging event
                            EventLogger.logEvent(
                                salesmanId,
                                'Moved to order confirmation page',
                                'Cart Proceeding',
                                leadId: null);
                            // Proceed to the order confirmation page if both customer is selected and cart is not empty
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderConfirmationPage(
                                  customer: customer!,
                                  gst: gst,
                                  sst: sst,
                                  total: total,
                                  subtotal: subtotal,
                                  cartItems: cartItems,
                                ),
                              ),
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xff0175FF)),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          minimumSize: WidgetStateProperty.all<Size>(
                            const Size(120,
                                40), // Adjust the minimum width and height of the button
                          ),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectCustomerCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the CustomerDetails page and wait for result
        Customer? selectedCustomer = await Navigator.push<Customer?>(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetails(
              onSelectionChanged: (Customer selectedCustomer) {
                setState(() {
                  customer = selectedCustomer;
                  customerSelected = true;
                });
              },
            ),
          ),
        );

        // Handle the selected customer received from CustomerDetails page
        if (selectedCustomer != null) {
          setState(() {
            customer = selectedCustomer;
            customerSelected = true;
            calculateTotalAndSubTotal();
            updateCartItemsWithLatestPrices();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color.fromARGB(255, 196, 196, 196)),
              boxShadow: const [
                BoxShadow(
                  blurStyle: BlurStyle.normal,
                  color: Color.fromARGB(75, 117, 117, 117),
                  spreadRadius: 0.1,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]),
          child: ListTile(
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              'Select Customer',
              style: GoogleFonts.inter(
                color: const Color(0xff0175FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomerInfo extends StatefulWidget {
  Customer initialCustomer;
  final Function(Customer) onCustomerUpdated; // Callback to notify cart page

  CustomerInfo({
    super.key,
    required this.initialCustomer,
    required this.onCustomerUpdated, // Inject callback
  });

  @override
  _CustomerInfoState createState() => _CustomerInfoState();
}

class _CustomerInfoState extends State<CustomerInfo> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.initialCustomer;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate to the CustomerDetails page and wait for result
        Customer? selectedCustomer = await Navigator.push<Customer?>(
          context,
          MaterialPageRoute(builder: (context) => const CustomerDetails()),
        );

        // Handle the selected customer received from CustomerDetails page
        if (selectedCustomer != null) {
          // Update the state of the selected customer
          setState(() {
            _customer = selectedCustomer;
          });

          // Notify cart page of the update
          widget.onCustomerUpdated(_customer);
        }
      },
      child: Card(
        elevation: 6,
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _customer.companyName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_customer.customerRate}: ${_customer.discountRate.toString()}% Discount',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff317E33),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_customer.addressLine1}${_customer.addressLine2.isNotEmpty ? '\n${_customer.addressLine2}' : ''}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Color(0xff191731),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _customer.contactNumber,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Text(
                          _customer.email,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.visible, // Allow text to wrap
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: Card(
                elevation: 0,
                color: Color(0xffffffff),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
