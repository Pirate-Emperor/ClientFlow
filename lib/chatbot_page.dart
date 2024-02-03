import 'dart:ui';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final String userId = 'default_user';
  String selectedCategory = '';
  List<String> faqQuestions = [];
  bool isTyping = false;
  int currentQuestionIndex = 0;
  bool showSuggestionBox = true;
  int? selectedAreaId;
  bool feedbackEnabled = false;
  int thumbsUpResponseIndex = 0;
  int thumbsDownResponseIndex = 0;

  final List<String> thumbsUpResponses = [
    "Thank you for your feedback!",
    "Thanks! We're happy to help.",
    "Your feedback is appreciated!",
    "Thanks for the thumbs up!",
  ];

  final List<String> thumbsDownResponses = [
    "Sorry to hear that. We'll strive to do better.",
    "Sorry for the inconvenience. We'll work on improving.",
    "We appreciate your feedback and will work to improve.",
    "Your feedback helps us get better. Thank you.",
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedAreaId();
  }

  Future<void> _loadSelectedAreaId() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      selectedAreaId = pref.getInt('areaId');
    });
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({
          "message": message,
          "isUser": true,
          "timestamp": _getCurrentTime()
        });
        _controller.clear();
        isTyping = true;
        feedbackEnabled = false;
      });

      const String url = 'http://10.0.2.2:5000/chat';

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            'message': message,
            'category': selectedCategory,
            'area_id': selectedAreaId,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String botResponse = data['response'];

          setState(() {
            if (selectedCategory == 'sales_order' &&
                data.containsKey('sales_orders')) {
              List<dynamic> salesOrders = data['sales_orders'];
              if (salesOrders.isNotEmpty) {
                _messages.add({
                  "message": "Here is the result of your Sales Order Inquiry:",
                  "isUser": false,
                  "timestamp": _getCurrentTime(),
                  "sales_orders": salesOrders
                });
              } else {
                _messages.add({
                  "message": "No sales orders found.",
                  "isUser": false,
                  "timestamp": _getCurrentTime()
                });
              }
            } else if (selectedCategory == 'search_product' &&
                data.containsKey('products')) {
              List<dynamic> products = data['products'];
              if (products.isNotEmpty) {
                _messages.add({
                  "message": "Here are the products I found:",
                  "isUser": false,
                  "timestamp": _getCurrentTime(),
                  "products": products
                });
              } else {
                _messages.add({
                  "message": "No products found.",
                  "isUser": false,
                  "timestamp": _getCurrentTime()
                });
              }
            } else {
              _messages.add({
                "message": botResponse,
                "isUser": false,
                "timestamp": _getCurrentTime()
              });
            }

            showSuggestionBox = false;
            feedbackEnabled = true;
            isTyping = false;
          });
        } else {
          setState(() {
            _messages.add({
              "message": "Error: Unable to retrieve response.",
              "isUser": false,
              "timestamp": _getCurrentTime()
            });
            isTyping = false;
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({
            "message": "Network error: Unable to reach server.",
            "isUser": false,
            "timestamp": _getCurrentTime()
          });
          isTyping = false;
        });
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleFeedback(bool isThumbsUp) async {
    final message =
        isThumbsUp ? "User gave thumbs up" : "User gave thumbs down";
    String feedbackResponse;

    if (isThumbsUp) {
      feedbackResponse = thumbsUpResponses[thumbsUpResponseIndex];
      thumbsUpResponseIndex =
          (thumbsUpResponseIndex + 1) % thumbsUpResponses.length;
    } else {
      feedbackResponse = thumbsDownResponses[thumbsDownResponseIndex];
      thumbsDownResponseIndex =
          (thumbsDownResponseIndex + 1) % thumbsDownResponses.length;
    }

    final url = Uri.parse('http://10.0.2.2:5000/feedback');
    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'message': message,
        }),
      );

      setState(() {
        feedbackEnabled = false;
        _messages.add({
          "message": feedbackResponse,
          "isUser": false,
          "timestamp": _getCurrentTime()
        });
      });
    } catch (e) {
      // Handle error if needed
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _handleCategorySelection(String category) {
    setState(() {
      selectedCategory = category;
      faqQuestions = _getFAQQuestions(category);
      currentQuestionIndex = 0;
      showSuggestionBox = true;
    });
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'general':
        return 'General FAQs';
      case 'search_product':
        return 'Search Product';
      case 'sales_order':
        return 'Inquire about Sales Order';
      default:
        return category;
    }
  }

  List<String> _getFAQQuestions(String category) {
    if (category == 'general') {
      return [
        'What products does FYH Online Store offer?',
        'How long has FYH Online Store been in business?',
        'Where is FYH Online Store\'s market located?',
        'From which countries does FYH Online Store import products?',
        'How can I contact FYH Online Store for more information?',
        'What is the annual import volume of FYH Online Store?',
        'What product categories are available?',
        'Can customers create an account on the website?',
        'What should I do if I forgot my password?',
        'How do I change my password?',
        'Who can access the admin features?',
        'How do I place an order?',
        'What are the payment methods available?',
        'How can I track my order status?',
        'What is your return and exchange policy?',
        'How can I contact customer service?',
        'Are there any shipping charges?',
        'Do you ship internationally?',
        'Can I cancel or modify my order after placing it?',
        'What warranties do you offer on your products?',
        'How do I register an account on your website?',
        'How do I log in to the admin or salesman portal?',
        'Are there any promotions or discounts available?',
        'How can I check the availability of a specific product?',
        'Do you offer bulk purchase discounts?',
        'Can I get a product demo or sample before purchasing?',
        'How do I become a distributor for FYH products?',
      ];
    }
    return [];
  }

  void _handleFAQSelection(String question) {
    _handleSendMessage(question);
    setState(() {
      faqQuestions.remove(question);
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      selectedCategory = '';
      faqQuestions = [];
    });
  }

  void _cycleQuestions() {
    setState(() {
      currentQuestionIndex = (currentQuestionIndex + 3) % faqQuestions.length;
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return ProductCard(product: product, areaId: selectedAreaId);
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff004c87),
        iconTheme: const IconThemeData(color: Color(0xffF8F9FA)),
        title: const Text(
          'F.Y.H Chat Bot',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (selectedCategory.isEmpty) {
              Navigator.pop(context);
            } else {
              _clearChat();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: -40,
            child: Image.asset(
              'asset/top_start.png',
              width: 300,
              height: 300,
            ),
          ),
          Positioned(
            bottom: -40,
            left: 0,
            child: Image.asset(
              'asset/bttm_start.png',
              width: 250,
              height: 250,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              if (selectedCategory.isEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FAQSelection(
                        onCategorySelected: _handleCategorySelection),
                  ),
                ),
              if (selectedCategory.isNotEmpty)
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(mediaQuery.size.width * 0.02),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(Icons.chat, color: Colors.blue),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: mediaQuery.size.width * 0.03),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getCategoryDisplayName(selectedCategory),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Text('F.Y.H Smart Agent',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.thumb_up_alt_outlined,
                                color: feedbackEnabled
                                    ? Colors.blue
                                    : Colors.grey),
                            onPressed: feedbackEnabled
                                ? () => _handleFeedback(true)
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.thumb_down_alt_outlined,
                                color: feedbackEnabled
                                    ? Colors.blue
                                    : Colors.grey),
                            onPressed: feedbackEnabled
                                ? () => _handleFeedback(false)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    if (faqQuestions.isNotEmpty && showSuggestionBox)
                      Container(
                        margin: const EdgeInsets.all(10),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'You may want to ask:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Column(
                                  children: List.generate(3, (index) {
                                    int questionIndex =
                                        (currentQuestionIndex + index) %
                                            faqQuestions.length;
                                    return Column(
                                      children: [
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title:
                                              Text(faqQuestions[questionIndex]),
                                          trailing:
                                              const Icon(Icons.arrow_forward),
                                          onTap: () {
                                            _handleFAQSelection(
                                                faqQuestions[questionIndex]);
                                          },
                                        ),
                                        if (index < 2)
                                          const Divider(color: Colors.grey),
                                      ],
                                    );
                                  }),
                                ),
                                Center(
                                  child: TextButton(
                                    onPressed: _cycleQuestions,
                                    child: const Text(
                                      'Change Questions',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xff004c87)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              if (selectedCategory.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message["isUser"] as bool;
                      final timestamp = message["timestamp"] as String;
                      final products = message["products"] as List<dynamic>?;
                      final salesOrders =
                          message["sales_orders"] as List<dynamic>?;
                      return Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                                left: mediaQuery.size.width * 0.03,
                                right: mediaQuery.size.width * 0.02,
                                top: mediaQuery.size.width * 0.01,
                                bottom: mediaQuery.size.width * 0.01),
                            padding:
                                EdgeInsets.all(mediaQuery.size.width * 0.03),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color.fromARGB(255, 0, 100, 177)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 3,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message["message"],
                                  style: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  timestamp,
                                  style: TextStyle(
                                      color: isUser
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          if (salesOrders != null && salesOrders.isNotEmpty)
                            ...salesOrders
                                .map((order) => SalesOrderCard(order: order)),
                          if (products != null && products.isNotEmpty)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  return _buildProductCard(products[index]);
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (isTyping)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('F.Y.H Smart Agent is typing...'),
                    ],
                  ),
                ),
              if (selectedCategory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      if (faqQuestions.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: faqQuestions.map((question) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    _handleFAQSelection(question);
                                  },
                                  child: Text(question,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'Write a message',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () =>
                                _handleSendMessage(_controller.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class FAQSelection extends StatelessWidget {
  final Function(String) onCategorySelected;

  const FAQSelection({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/chart_illu.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
        Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset('asset/logo/logo_fyh.png',
                  width: 240, height: 170),
            ),
            const SizedBox(height: 20),
            const Text(
              'WELCOME\nHow May I Assist You?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildCategoryCard(
                          icon: Icons.help_outline,
                          label: 'General FAQs',
                          onTap: () => onCategorySelected('general'),
                        ),
                        _buildCategoryCard(
                          icon: Icons.search,
                          label: 'Search Product',
                          onTap: () => onCategorySelected('search_product'),
                        ),
                        _buildCategoryCard(
                          icon: Icons.description,
                          label: 'Sales Inquiry',
                          onTap: () => onCategorySelected('sales_order'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: 107,
      height: 117,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: const Color.fromRGBO(111, 188, 249, 0.7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 35, color: Colors.black),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
