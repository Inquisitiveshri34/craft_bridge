import 'dart:io';

import 'package:flutter/material.dart';

class CartItemTile extends StatelessWidget {
	final String productId;
	final String title;
	final String imageUrl;
	final double price;
	final int quantity;
	final String artisanName;
	final VoidCallback onIncrement;
	final VoidCallback onDecrement;
	final VoidCallback onRemove;

	const CartItemTile({
		super.key,
		required this.productId,
		required this.title,
		required this.imageUrl,
		required this.price,
		required this.quantity,
		required this.artisanName,
		required this.onIncrement,
		required this.onDecrement,
		required this.onRemove,
	});

	Widget _buildImageFallback(BuildContext context) {
		return Container(
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Icon(
				Icons.image_outlined,
				color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
			),
		);
	}

	bool _isRemoteUrl(String value) {
		return value.startsWith('http://') || value.startsWith('https://');
	}

	String? _localPathFromImageRef(String value) {
		if (value.isEmpty || _isRemoteUrl(value)) return null;
		if (value.startsWith('file://')) {
			return Uri.tryParse(value)?.toFilePath();
		}
		return value;
	}

	Widget _buildProductImage(BuildContext context) {
		if (imageUrl.isEmpty) return _buildImageFallback(context);
		if (!_isRemoteUrl(imageUrl)) {
			final String? localPath = _localPathFromImageRef(imageUrl);
			if (localPath == null) return _buildImageFallback(context);
			final File file = File(localPath);
			if (file.existsSync()) {
				return Image.file(
					file,
					fit: BoxFit.cover,
					errorBuilder: (_, __, ___) => _buildImageFallback(context),
				);
			}
			return _buildImageFallback(context);
		}

		return Image.network(
			imageUrl,
			fit: BoxFit.cover,
			errorBuilder: (_, __, ___) => _buildImageFallback(context),
		);
	}

	Widget _buildQuantityStepper(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				border: Border.all(
					color: Theme.of(context).colorScheme.outline,
				),
				borderRadius: BorderRadius.circular(8),
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					InkWell(
						onTap: quantity > 1 ? onDecrement : null,
						borderRadius: const BorderRadius.horizontal(
							left: Radius.circular(7),
						),
						child: Padding(
							padding: const EdgeInsets.symmetric(
								horizontal: 8,
								vertical: 4,
							),
							child: Icon(
								Icons.remove,
								size: 16,
								color: quantity > 1
										? Theme.of(context).colorScheme.onSurface
										: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.3),
							),
						),
					),
					Container(
						width: 32,
						alignment: Alignment.center,
						child: Text(
							'$quantity',
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(
										fontWeight: FontWeight.w600,
									),
						),
					),
					InkWell(
						onTap: onIncrement,
						borderRadius: const BorderRadius.horizontal(
							right: Radius.circular(7),
						),
						child: Padding(
							padding: const EdgeInsets.symmetric(
								horizontal: 8,
								vertical: 4,
							),
							child: Icon(
								Icons.add,
								size: 16,
								color: Theme.of(context).colorScheme.onSurface,
							),
						),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(12),
				child: Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						ClipRRect(
							borderRadius: BorderRadius.circular(8),
							child: SizedBox(
								width: 72,
								height: 72,
									child: _buildProductImage(context),
							),
						),
						const SizedBox(width: 12),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Expanded(
												child: Text(
													title,
													style:
															Theme.of(context).textTheme.bodyMedium?.copyWith(
																		fontWeight: FontWeight.w600,
																	),
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
												),
											),
											IconButton(
												icon: const Icon(Icons.close, size: 18),
												onPressed: onRemove,
												padding: EdgeInsets.zero,
												constraints: const BoxConstraints(),
												tooltip: 'Remove item',
											),
										],
									),
									const SizedBox(height: 2),
									Text(
										artisanName,
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: Theme.of(context)
															.colorScheme
															.onSurface
															.withValues(alpha: 0.55),
												),
									),
									const SizedBox(height: 8),
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Text(
												'₹${(price * quantity).toStringAsFixed(0)}',
												style: Theme.of(context).textTheme.titleSmall?.copyWith(
															color: Theme.of(context).colorScheme.primary,
															fontWeight: FontWeight.bold,
														),
											),
											_buildQuantityStepper(context),
										],
									),
								],
							),
						),
					],
				),
			),
		);
	}
}
