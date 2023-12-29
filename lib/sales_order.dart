class SalesOrder {
  int id;
  String session;
  int customerId;
  String productId;
  String productName;
  int quantity;
  String uom;
  double originalUnitPrice;
  String salesmanName;
  DateTime createdDate;
  String status;

  // Constructor
  SalesOrder({
    required this.id,
    required this.session,
    required this.customerId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.uom,
    required this.originalUnitPrice,
    required this.salesmanName,
    required this.createdDate,
    required this.status,
  });

  // Factory method to create a SalesOrder object from JSON
  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] as int,
      session: json['session'] as String,
      customerId: json['customer_id'] as int,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['qty'] as int,
      uom: json['uom'] as String,
      originalUnitPrice: double.parse(json['ori_unit_price'].toString()),
      salesmanName: json['salesman_name'] as String,
      createdDate: DateTime.parse(json['created_date']),
      status: json['status'] as String,
    );
  }

  // Method to convert a SalesOrder object to JSON (optional, for POST requests or local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session': session,
      'customer_id': customerId,
      'product_id': productId,
      'product_name': productName,
      'qty': quantity,
      'uom': uom,
      'ori_unit_price': originalUnitPrice,
      'salesman_name': salesmanName,
      'created_date': createdDate.toIso8601String(),
      'status': status,
    };
  }
}
