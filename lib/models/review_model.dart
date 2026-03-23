import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
	final String id;
	final String productId;
	final String buyerId;
	final String buyerName;
	final double rating;
	final String comment;
	final Timestamp createdAt;

	const ReviewModel({
		required this.id,
		required this.productId,
		required this.buyerId,
		required this.buyerName,
		required this.rating,
		required this.comment,
		required this.createdAt,
	});

	factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
				id: map['id'] as String,
				productId: map['productId'] as String,
				buyerId: map['buyerId'] as String,
				buyerName: map['buyerName'] as String,
				rating: (map['rating'] as num).toDouble(),
				comment: map['comment'] as String,
				createdAt: map['createdAt'] as Timestamp,
			);

	Map<String, dynamic> toMap() => {
				'id': id,
				'productId': productId,
				'buyerId': buyerId,
				'buyerName': buyerName,
				'rating': rating,
				'comment': comment,
				'createdAt': createdAt,
			};

	ReviewModel copyWith({
		String? id,
		String? productId,
		String? buyerId,
		String? buyerName,
		double? rating,
		String? comment,
		Timestamp? createdAt,
	}) =>
			ReviewModel(
				id: id ?? this.id,
				productId: productId ?? this.productId,
				buyerId: buyerId ?? this.buyerId,
				buyerName: buyerName ?? this.buyerName,
				rating: rating ?? this.rating,
				comment: comment ?? this.comment,
				createdAt: createdAt ?? this.createdAt,
			);
}
