import 'package:flutter/material.dart';
import 'package:clientflow/db_sqlite.dart';
import 'package:clientflow/utility_function.dart';

class CartModel extends ChangeNotifier {
  int _cartItemCount = 0;

  int get cartItemCount => _cartItemCount;

  Future<void> initializeCartCount() async {
    _cartItemCount = await _fetchCartItemCount();
    notifyListeners(); // Notify listeners after setting the count
  }

  void updateCartCount(int count) {
    _cartItemCount = count;
    notifyListeners(); // Notify all listeners
  }

  Future<int> _fetchCartItemCount() async {
    final userId = await UtilityFunction.getUserId();

    try {
      const tableName = 'cart_item';
      final condition = "buyer_id = $userId AND status = 'in progress'";

      final db = await DatabaseHelper.database;

      final itemCount = await DatabaseHelper.countData(
        db,
        tableName,
        condition,
      );
      return itemCount;
    } catch (e) {
      // Handle errors here
      return 0;
    }
  }
}

