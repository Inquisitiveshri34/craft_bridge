import 'package:flutter/material.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class ProductCard extends StatelessWidget {
	final String productId;
	final String title;
	final double price;
	final String imageUrl;
	final String artisanName;
	final String category;
	final bool isActive;
	final VoidCallback? onTap;

	const ProductCard({
		super.key,
		required this.productId,
		required this.title,
		required this.price,
		required this.imageUrl,
		required this.artisanName,
		required this.category,
		required this.isActive,
		this.onTap,
	});

	Widget _buildImageFallback(BuildContext context) {
		return Container(
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Center(
				child: Icon(
					Icons.image_outlined,
					size: 36,
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: onTap,
			child: Card(
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
				),
				child: Column(
					children: [
						Expanded(
							child: Stack(
								children: [
									Hero(
										tag: 'product-$productId',
										child: ClipRRect(
											borderRadius:
													const BorderRadius.vertical(top: Radius.circular(12)),
											child: imageUrl.isNotEmpty
													? Image.network(
															imageUrl,
															width: double.infinity,
															fit: BoxFit.cover,
															loadingBuilder:
																	(context, child, loadingProgress) {
																if (loadingProgress == null) return child;
																return Center(
																	child: CircularProgressIndicator(
																		strokeWidth: 2,
																		value: loadingProgress.expectedTotalBytes !=
																						null
																				? loadingProgress.cumulativeBytesLoaded /
																						loadingProgress.expectedTotalBytes!
																				: null,
																	),
																);
															},
															errorBuilder: (context, error, stackTrace) =>
																	_buildImageFallback(context),
														)
													: _buildImageFallback(context),
										),
									),
									if (!isActive)
										Positioned.fill(
											child: Container(
												color: Colors.black.withValues(alpha: 0.45),
												child: Center(
													child: Container(
														padding: const EdgeInsets.symmetric(
															horizontal: 8,
															vertical: 4,
														),
														decoration: BoxDecoration(
															color: Colors.black54,
															borderRadius: BorderRadius.circular(4),
														),
														child: const Text(
															'Inactive',
															style: TextStyle(
																color: Colors.white,
																fontSize: 11,
																fontWeight: FontWeight.w600,
															),
														),
													),
												),
											),
										),
								],
							),
						),
						Padding(
							padding: const EdgeInsets.all(8),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													fontWeight: FontWeight.w600,
												),
										maxLines: 2,
										overflow: TextOverflow.ellipsis,
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
										maxLines: 1,
										overflow: TextOverflow.ellipsis,
									),
									const SizedBox(height: 4),
									Text(
										'₹${price.toStringAsFixed(0)}',
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: Theme.of(context).colorScheme.primary,
													fontWeight: FontWeight.bold,
												),
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
