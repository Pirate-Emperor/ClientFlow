class Customer {
  int id;
  String companyName = '';
  String addressLine1 = '';
  String addressLine2 = '';
  String contactNumber = '';
  String email = '';
  String customerRate = '';
  int discountRate = 0;

  Customer({
    this.id = 0,
    this.companyName = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.contactNumber = '',
    this.email = '',
    this.customerRate = '',
    this.discountRate = 0,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      companyName: map['company_name'] ?? '',
      addressLine1: map['address_line_1'] ?? '',
      addressLine2: map['address_line_2'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      email: map['email'] ?? '',
      customerRate: map['customer_rate'] ?? '',
      discountRate: map['discount_rate'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'contact_number': contactNumber,
      'email': email,
      'customer_rate': customerRate,
      'discount_rate': discountRate,
    };
  }
}
