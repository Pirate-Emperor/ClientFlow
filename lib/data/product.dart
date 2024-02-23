class Product {
  final int id;
  final int subCategory;
  final int brand;
  final String productName;
  final String productCode;
  final String priceGuide;
  final String photo1;
  final String photo2;
  final String photo3;
  final String photo4;
  final String featured;
  final String stock;
  final String status;
  final String description;
  final String uom;
  final Map<String, dynamic> priceByUom;
  final Map<String, String> stockByUom;
  final Map<String, String> discount;

  Product({
    this.id = 0,
    this.subCategory = 0,
    this.brand = 0,
    this.productName = '',
    this.productCode = '',
    this.priceGuide = '',
    this.photo1 = '',
    this.photo2 = '',
    this.photo3 = '',
    this.photo4 = '',
    this.featured = '',
    this.stock = '',
    this.status = '',
    this.description = '',
    this.uom = '',
    this.priceByUom = const {},
    this.stockByUom = const {},
    this.discount = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sub_category': subCategory,
      'brand': brand,
      'product_name': productName,
      'product_code': productCode,
      'price_guide': priceGuide,
      'photo1': photo1,
      'photo2': photo2,
      'photo3': photo3,
      'photo4': photo4,
      'featured': featured,
      'stock': stock,
      'status': status,
      'description': description,
      'uom': uom,
      'price_by_uom': priceByUom,
      'stock_by_uom': stockByUom,
      'discount': discount,
    };
  }
}
