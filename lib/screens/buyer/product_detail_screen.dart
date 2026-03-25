import 'package:flutter/material.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
	final ProductModel product;

	const ProductDetailScreen({super.key, required this.product});

	@override
	State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
	int _quantity = 1;
	bool _isAddingToCart = false;

	Widget _buildImageSection() {
		return Hero(
			tag: 'product-${widget.product.id}',
			child: widget.product.imageUrl.isNotEmpty
					? Image.network(
							widget.product.imageUrl,
							height: 280,
							width: double.infinity,
							fit: BoxFit.cover,
							loadingBuilder: (context, child, loadingProgress) {
								if (loadingProgress == null) return child;
								return SizedBox(
									height: 280,
									child: Center(
										child: CircularProgressIndicator(
											strokeWidth: 2,
											value: loadingProgress.expectedTotalBytes != null
													? loadingProgress.cumulativeBytesLoaded /
															loadingProgress.expectedTotalBytes!
													: null,
										),
									),
								);
							},
							errorBuilder: (_, __, ___) => _buildImageFallback(),
						)
					: _buildImageFallback(),
		);
	}

	Widget _buildImageFallback() {
		return Container(
			height: 280,
			width: double.infinity,
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Center(
				child: Icon(
					Icons.image_outlined,
					size: 72,
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
				),
			),
		);
	}

	Widget _buildQuantitySelector() {
		return Row(
			children: [
				Text(
					'Quantity',
					style: Theme.of(context)
							.textTheme
							.titleSmall
							?.copyWith(fontWeight: FontWeight.w600),
				),
				const Spacer(),
				Container(
					decoration: BoxDecoration(
						border: Border.all(color: Theme.of(context).colorScheme.outline),
						borderRadius: BorderRadius.circular(8),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							InkWell(
								onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
								borderRadius:
										const BorderRadius.horizontal(left: Radius.circular(7)),
								child: Padding(
									padding:
											const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
									child: Icon(
										Icons.remove,
										size: 16,
										color: _quantity > 1
												? Theme.of(context).colorScheme.onSurface
												: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.3),
									),
								),
							),
							SizedBox(
								width: 40,
								child: Center(
									child: Text(
										'$_quantity',
										style: Theme.of(context)
												.textTheme
												.titleMedium
												?.copyWith(fontWeight: FontWeight.bold),
									),
								),
							),
							InkWell(
								onTap: _quantity < widget.product.stock
										? () => setState(() => _quantity++)
										: null,
								borderRadius:
										const BorderRadius.horizontal(right: Radius.circular(7)),
								child: Padding(
									padding:
											const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
									child: Icon(
										Icons.add,
										size: 16,
										color: _quantity < widget.product.stock
												? Theme.of(context).colorScheme.onSurface
												: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.3),
									),
								),
							),
						],
					),
				),
			],
		);
	}

	Future<void> _handleAddToCart() async {
		setState(() => _isAddingToCart = true);
		await Future.delayed(const Duration(milliseconds: 300));
		setState(() => _isAddingToCart = false);
		if (!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text('${widget.product.title} added to cart — wired in PR42.'),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: Text(
					widget.product.title,
					overflow: TextOverflow.ellipsis,
				),
				backgroundColor: Colors.transparent,
				elevation: 0,
				foregroundColor: Theme.of(context).colorScheme.onSurface,
			),
			body: SingleChildScrollView(
				child: Column(
					children: [
						_buildImageSection(),
						Padding(
							padding: const EdgeInsets.all(AppConstants.defaultPadding),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Expanded(
												child: Text(
													widget.product.title,
													style:
															Theme.of(context).textTheme.headlineSmall?.copyWith(
																		fontWeight: FontWeight.bold,
																	),
												),
											),
											const SizedBox(width: 16),
											Text(
												'₹${widget.product.price.toStringAsFixed(0)}',
												style: Theme.of(context).textTheme.headlineMedium?.copyWith(
															color: Theme.of(context).colorScheme.primary,
															fontWeight: FontWeight.bold,
														),
											),
										],
									),
									const SizedBox(height: 8),
									Row(
										children: [
											Icon(
												Icons.store_outlined,
												size: 16,
												color: Theme.of(context).colorScheme.primary,
											),
											const SizedBox(width: 4),
											Text(
												widget.product.artisanName,
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: Theme.of(context).colorScheme.primary,
															fontWeight: FontWeight.w500,
														),
											),
										],
									),
									const SizedBox(height: 4),
									Container(
										padding:
												const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
										decoration: BoxDecoration(
											color: Theme.of(context)
													.colorScheme
													.primary
													.withValues(alpha: 0.08),
											borderRadius: BorderRadius.circular(12),
										),
										child: Text(
											widget.product.category,
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context).colorScheme.primary,
													),
										),
									),
									const Divider(height: 32),
									Text(
										'About this product',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.bold,
												),
									),
									const SizedBox(height: 8),
									Text(
										widget.product.description,
										style: Theme.of(context).textTheme.bodyLarge?.copyWith(
													color: Theme.of(context)
															.colorScheme
															.onSurface
															.withValues(alpha: 0.8),
												),
									),
									const SizedBox(height: 16),
									Row(
										children: [
											Icon(
												Icons.inventory_2_outlined,
												size: 16,
												color: widget.product.stock > 0
														? Colors.green.shade700
														: Theme.of(context).colorScheme.error,
											),
											const SizedBox(width: 4),
											Text(
												widget.product.stock > 0
														? '${widget.product.stock} in stock'
														: 'Out of stock',
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: widget.product.stock > 0
																	? Colors.green.shade700
																	: Theme.of(context).colorScheme.error,
															fontWeight: FontWeight.w500,
														),
											),
										],
									),
									const Divider(height: 32),
									_buildQuantitySelector(),
									const SizedBox(height: 16),
									CustomButton(
										label: 'Add to Cart',
										onPressed: widget.product.stock > 0 && !_isAddingToCart
												? _handleAddToCart
												: null,
										isLoading: _isAddingToCart,
									),
									const SizedBox(height: 32),
								],
							),
						),
					],
				),
			),
		);
	}
}
