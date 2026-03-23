import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
	final String id;
	final String artisanId;
	final String artisanName;
	final String title;
	final String description;
	final double price;
	final String imageUrl;
	final String category;
	final int stock;
	final bool isActive;
	final Timestamp createdAt;

	const ProductModel({
		required this.id,
		required this.artisanId,
		required this.artisanName,
		required this.title,
		required this.description,
		required this.price,
		required this.imageUrl,
		required this.category,
		required this.stock,
		required this.isActive,
		required this.createdAt,
	});

	factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
				id: map['id'] as String,
				artisanId: map['artisanId'] as String,
				artisanName: map['artisanName'] as String,
				title: map['title'] as String,
				description: map['description'] as String,
				price: (map['price'] as num).toDouble(),
				imageUrl: map['imageUrl'] as String? ?? '',
				category: map['category'] as String,
				stock: map['stock'] as int,
				isActive: map['isActive'] as bool? ?? true,
				createdAt: map['createdAt'] as Timestamp,
			);

	Map<String, dynamic> toMap() => {
				'id': id,
				'artisanId': artisanId,
				'artisanName': artisanName,
				'title': title,
				'description': description,
				'price': price,
				'imageUrl': imageUrl,
				'category': category,
				'stock': stock,
				'isActive': isActive,
				'createdAt': createdAt,
			};

	ProductModel copyWith({
		String? id,
		String? artisanId,
		String? artisanName,
		String? title,
		String? description,
		double? price,
		String? imageUrl,
		String? category,
		int? stock,
		bool? isActive,
		Timestamp? createdAt,
	}) =>
			ProductModel(
				id: id ?? this.id,
				artisanId: artisanId ?? this.artisanId,
				artisanName: artisanName ?? this.artisanName,
				title: title ?? this.title,
				description: description ?? this.description,
				price: price ?? this.price,
				imageUrl: imageUrl ?? this.imageUrl,
				category: category ?? this.category,
				stock: stock ?? this.stock,
				isActive: isActive ?? this.isActive,
				createdAt: createdAt ?? this.createdAt,
			);
}
