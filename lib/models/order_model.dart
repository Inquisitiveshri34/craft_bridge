import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
	final String id;
	final String buyerId;
	final String buyerName;
	final String artisanId;
	final String artisanName;
	final String productId;
	final String productTitle;
	final String productImageUrl;
	final int quantity;
	final double totalPrice;
	final String status;
	final Timestamp createdAt;

	const OrderModel({
		required this.id,
		required this.buyerId,
		required this.buyerName,
		required this.artisanId,
		required this.artisanName,
		required this.productId,
		required this.productTitle,
		required this.productImageUrl,
		required this.quantity,
		required this.totalPrice,
		required this.status,
		required this.createdAt,
	});

	factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
				id: map['id'] as String,
				buyerId: map['buyerId'] as String,
				buyerName: map['buyerName'] as String,
				artisanId: map['artisanId'] as String,
				artisanName: map['artisanName'] as String,
				productId: map['productId'] as String,
				productTitle: map['productTitle'] as String,
				productImageUrl: map['productImageUrl'] as String? ?? '',
				quantity: map['quantity'] as int,
				totalPrice: (map['totalPrice'] as num).toDouble(),
				status: map['status'] as String,
				createdAt: map['createdAt'] as Timestamp,
			);

	Map<String, dynamic> toMap() => {
				'id': id,
				'buyerId': buyerId,
				'buyerName': buyerName,
				'artisanId': artisanId,
				'artisanName': artisanName,
				'productId': productId,
				'productTitle': productTitle,
				'productImageUrl': productImageUrl,
				'quantity': quantity,
				'totalPrice': totalPrice,
				'status': status,
				'createdAt': createdAt,
			};

	OrderModel copyWith({
		String? id,
		String? buyerId,
		String? buyerName,
		String? artisanId,
		String? artisanName,
		String? productId,
		String? productTitle,
		String? productImageUrl,
		int? quantity,
		double? totalPrice,
		String? status,
		Timestamp? createdAt,
	}) =>
			OrderModel(
				id: id ?? this.id,
				buyerId: buyerId ?? this.buyerId,
				buyerName: buyerName ?? this.buyerName,
				artisanId: artisanId ?? this.artisanId,
				artisanName: artisanName ?? this.artisanName,
				productId: productId ?? this.productId,
				productTitle: productTitle ?? this.productTitle,
				productImageUrl: productImageUrl ?? this.productImageUrl,
				quantity: quantity ?? this.quantity,
				totalPrice: totalPrice ?? this.totalPrice,
				status: status ?? this.status,
				createdAt: createdAt ?? this.createdAt,
			);
}
