import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:clientflow/model/cart_model.dart';

class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({super.key});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  static int _selectedIndex = 0;
  bool _isVisible = true;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      setState(() {
        _isVisible = false;
      });
    }
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: _isVisible ? 80 : 0,
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Consumer<CartModel>( // Use Consumer to listen for cart count changes
            builder: (context, cartModel, child) {
              return NavigationBar(
                elevation: 0,
                backgroundColor: Colors.white,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  switch (index) {
                    case 0:
                      if (ModalRoute.of(context)!.settings.name != '/home') {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                      break;
                    case 1:
                      if (ModalRoute.of(context)!.settings.name != '/sales') {
                        Navigator.pushReplacementNamed(context, '/sales');
                      }
                      break;
                    case 2:
                      if (ModalRoute.of(context)!.settings.name != '/product') {
                        Navigator.pushReplacementNamed(context, '/product');
                      }
                      break;
                    case 3:
                      if (ModalRoute.of(context)!.settings.name != '/cart') {
                        Navigator.pushReplacementNamed(context, '/cart');
                      }
                      break;
                    case 4:
                      if (ModalRoute.of(context)!.settings.name != '/profile') {
                        Navigator.pushReplacementNamed(context, '/profile');
                      }
                      break;
                    default:
                      if (ModalRoute.of(context)!.settings.name != '/home') {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                      break;
                  }
                },
                indicatorColor: const Color(0xff0175FF),
                selectedIndex: _selectedIndex,
                destinations: <Widget>[
                  const NavigationDestination(
                    selectedIcon: Icon(
                      Icons.home,
                      color: Colors.white,
                    ),
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  const NavigationDestination(
                    selectedIcon: Icon(Icons.sell, color: Colors.white),
                    icon: Icon(Icons.sell_outlined),
                    label: 'Sales',
                  ),
                  const NavigationDestination(
                    selectedIcon: Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                    ),
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: 'Product',
                  ),
                  NavigationDestination(
                    selectedIcon: Badge(
                      label: Text(cartModel.cartItemCount.toString(), style: const TextStyle(fontSize: 16),), // Use cart count from model
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                      ),
                    ),
                    icon: Badge(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      label: Text(cartModel.cartItemCount.toString(), style: const TextStyle(fontSize: 12)), // Use cart count from model
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                      ),
                    ),
                    label: 'Cart',
                  ),
                  const NavigationDestination(
                    selectedIcon: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                    icon: Icon(Icons.person_outline),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
