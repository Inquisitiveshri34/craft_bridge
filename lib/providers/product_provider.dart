import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
	final List<Map<String, dynamic>> _products = [
		{
			'id': '1',
			'title': 'Hand-painted Ceramic Vase',
			'description': 'A hand-painted ceramic vase made by local artisans.',
			'price': 1200.0,
			'category': 'Pottery',
			'stock': 5,
			'isActive': true,
			'imageUrl': '',
			'artisanId': '',
			'artisanName': '',
			'createdAt': Timestamp.now(),
		},
		{
			'id': '2',
			'title': 'Block Print Cotton Scarf',
			'description': 'Soft cotton scarf with traditional block prints.',
			'price': 650.0,
			'category': 'Textiles',
			'stock': 12,
			'isActive': true,
			'imageUrl': '',
			'artisanId': '',
			'artisanName': '',
			'createdAt': Timestamp.now(),
		},
		{
			'id': '3',
			'title': 'Silver Filigree Earrings',
			'description': 'Elegant handcrafted silver filigree earrings.',
			'price': 850.0,
			'category': 'Jewellery',
			'stock': 8,
			'isActive': false,
			'imageUrl': '',
			'artisanId': '',
			'artisanName': '',
			'createdAt': Timestamp.now(),
		},
		{
			'id': '4',
			'title': 'Teak Wood Serving Board',
			'description': 'Premium teak wood serving board with natural finish.',
			'price': 1800.0,
			'category': 'Woodwork',
			'stock': 3,
			'isActive': true,
			'imageUrl': '',
			'artisanId': '',
			'artisanName': '',
			'createdAt': Timestamp.now(),
		},
		{
			'id': '5',
			'title': 'Madhubani Wall Painting',
			'description': 'Traditional Madhubani painting for home decor.',
			'price': 3500.0,
			'category': 'Paintings',
			'stock': 1,
			'isActive': true,
			'imageUrl': '',
			'artisanId': '',
			'artisanName': '',
			'createdAt': Timestamp.now(),
		},
	];

	List<Map<String, dynamic>> get products =>
			List<Map<String, dynamic>>.unmodifiable(_products);

	Future<void> addOrUpdateProduct({
		required ProductModel model,
		required bool isEdit,
	}) async {
		await Future.delayed(const Duration(milliseconds: 500));

		if (isEdit) {
			final int index = _products.indexWhere((p) => p['id'] == model.id);
			if (index != -1) {
				_products[index] = model.toMap();
			}
		} else {
			final String id = DateTime.now().millisecondsSinceEpoch.toString();
			_products.insert(
				0,
				model.copyWith(id: id).toMap(),
			);
		}

		notifyListeners();
	}

	Future<void> removeProduct(String productId) async {
		_products.removeWhere((p) => p['id'] == productId);
		notifyListeners();
	}

	ProductModel toProductModel(Map<String, dynamic> map) {
		return ProductModel(
			id: (map['id'] ?? '').toString(),
			artisanId: (map['artisanId'] ?? '').toString(),
			artisanName: (map['artisanName'] ?? '').toString(),
			title: (map['title'] ?? '').toString(),
			description: (map['description'] ?? '').toString(),
			price: ((map['price'] ?? 0) as num).toDouble(),
			imageUrl: (map['imageUrl'] ?? '').toString(),
			category: (map['category'] ?? '').toString(),
			stock: ((map['stock'] ?? 0) as num).toInt(),
			isActive: map['isActive'] == true,
			createdAt: (map['createdAt'] is Timestamp)
					? map['createdAt'] as Timestamp
					: Timestamp.now(),
		);
	}
}
