class CartItemModel {
	final String productId;
	final String title;
	final String imageUrl;
	final double price;
	final int quantity;
	final String artisanId;
	final String artisanName;

	const CartItemModel({
		required this.productId,
		required this.title,
		required this.imageUrl,
		required this.price,
		required this.quantity,
		required this.artisanId,
		required this.artisanName,
	});

	CartItemModel copyWith({
		String? productId,
		String? title,
		String? imageUrl,
		double? price,
		int? quantity,
		String? artisanId,
		String? artisanName,
	}) =>
			CartItemModel(
				productId: productId ?? this.productId,
				title: title ?? this.title,
				imageUrl: imageUrl ?? this.imageUrl,
				price: price ?? this.price,
				quantity: quantity ?? this.quantity,
				artisanId: artisanId ?? this.artisanId,
				artisanName: artisanName ?? this.artisanName,
			);

	double get totalPrice => price * quantity;
}
