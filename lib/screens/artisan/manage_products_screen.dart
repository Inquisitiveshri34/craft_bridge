import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/screens/artisan/add_edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
	const ManageProductsScreen({super.key});

	@override
	State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
	bool _cardsVisible = false;

	@override
	void initState() {
		super.initState();
		Future.delayed(const Duration(milliseconds: 80), () {
			if (mounted) {
				setState(() => _cardsVisible = true);
			}
		});
	}

	Future<void> _handleDelete(String productId) async {
		await context.read<ProductProvider>().removeProduct(productId);
		if (!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
				content: Text('Product removed.'),
				duration: Duration(seconds: 2),
			),
		);
	}

	Widget _buildEmptyState() {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(
						Icons.inventory_2_outlined,
						size: 80,
						color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
					),
					const SizedBox(height: 16),
					Text(
						'No products yet',
						style: Theme.of(context).textTheme.headlineSmall?.copyWith(
									fontWeight: FontWeight.bold,
									color:
											Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
								),
					),
					const SizedBox(height: 8),
					Text(
						'Tap the + button to add your first product.',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									color:
											Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
								),
						textAlign: TextAlign.center,
					),
				],
			),
		);
	}

	Widget _buildProductGrid(
		List<Map<String, dynamic>> products,
		ProductProvider productProvider,
	) {
		final double screenWidth = MediaQuery.of(context).size.width;
		final int crossAxisCount = screenWidth < 600 ? 2 : 3;

		return GridView.builder(
			padding: const EdgeInsets.all(AppConstants.defaultPadding),
			gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
				crossAxisCount: crossAxisCount,
				crossAxisSpacing: 12,
				mainAxisSpacing: 12,
				childAspectRatio: 0.72,
			),
			itemCount: products.length,
			itemBuilder: (context, index) {
				final product = products[index];

				return AnimatedOpacity(
					opacity: _cardsVisible ? 1.0 : 0.0,
					duration: const Duration(milliseconds: 400),
					curve: Curves.easeIn,
					child: Dismissible(
						key: Key(product["id"] as String),
						direction: DismissDirection.endToStart,
						background: Container(
							alignment: Alignment.centerRight,
							padding: const EdgeInsets.only(right: 16),
							decoration: BoxDecoration(
								color: Theme.of(context).colorScheme.error,
								borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
							),
							child: const Icon(Icons.delete_outline, color: Colors.white),
						),
						confirmDismiss: (_) async {
							return await showDialog<bool>(
								context: context,
								builder: (ctx) => AlertDialog(
									title: const Text('Delete Product'),
									content: Text(
										'Are you sure you want to delete "${product['title']}"?',
									),
									actions: [
										TextButton(
											onPressed: () => Navigator.pop(ctx, false),
											child: const Text('Cancel'),
										),
										TextButton(
											onPressed: () => Navigator.pop(ctx, true),
											style: TextButton.styleFrom(
												foregroundColor: Theme.of(context).colorScheme.error,
											),
											child: const Text('Delete'),
										),
									],
								),
							);
						},
						onDismissed: (_) => _handleDelete(product["id"] as String),
						child: GestureDetector(
							onTap: () => Navigator.push(
								context,
								MaterialPageRoute(
									builder: (_) => AddEditProductScreen(
										product: productProvider.toProductModel(product),
									),
								),
							),
							child: _StubProductCard(product: product),
						),
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final ProductProvider productProvider = context.watch<ProductProvider>();
		final List<Map<String, dynamic>> products = productProvider.products;

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('My Products'),
				actions: [
					Padding(
						padding: const EdgeInsets.only(right: 8),
						child: Center(
							child: Text(
								'${products.length} items',
								style: Theme.of(context).textTheme.bodyMedium,
							),
						),
					),
				],
			),
			body: products.isEmpty
				? _buildEmptyState()
				: _buildProductGrid(products, productProvider),
			floatingActionButton: FloatingActionButton(
				onPressed: () => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => const AddEditProductScreen(),
					),
				),
				tooltip: 'Add Product',
				child: const Icon(Icons.add),
			),
		);
	}
}

class _StubProductCard extends StatelessWidget {
	final Map<String, dynamic> product;

	const _StubProductCard({
		required this.product,
	});

	@override
	Widget build(BuildContext context) {
		final bool isActive = product['isActive'] == true;
		final String imageUrl = (product['imageUrl'] ?? '').toString();
		final bool hasLocalImage =
				imageUrl.isNotEmpty && File(imageUrl).existsSync();

		return Card(
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
			),
			child: Column(
				children: [
					Expanded(
						child: Stack(
							children: [
								Container(
									width: double.infinity,
									decoration: BoxDecoration(
										color:
												Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
										borderRadius:
												const BorderRadius.vertical(top: Radius.circular(12)),
									),
									child: hasLocalImage
											? ClipRRect(
													borderRadius: const BorderRadius.vertical(
														top: Radius.circular(12),
													),
													child: Image.file(
														File(imageUrl),
														fit: BoxFit.cover,
														width: double.infinity,
														height: double.infinity,
													),
											)
											: Center(
													child: Icon(
														Icons.image_outlined,
														size: 40,
														color: Theme.of(context)
																.colorScheme
																.primary
																.withValues(alpha: 0.4),
													),
												),
								),
								Positioned(
									top: 8,
									right: 8,
									child: Container(
										padding:
												const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
										decoration: BoxDecoration(
											color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
											borderRadius: BorderRadius.circular(4),
										),
										child: Text(
											isActive ? 'Active' : 'Inactive',
											style: TextStyle(
												fontSize: 10,
												fontWeight: FontWeight.w600,
												color:
														isActive ? Colors.green.shade800 : Colors.grey.shade600,
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
									product['title'] as String,
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												fontWeight: FontWeight.w600,
											),
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
								const SizedBox(height: 4),
								Text(
									'₹${(product['price'] as double).toStringAsFixed(0)}',
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: Theme.of(context).colorScheme.primary,
												fontWeight: FontWeight.bold,
											),
								),
								const SizedBox(height: 2),
								Text(
									'Stock: ${product['stock']}',
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color:
														Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
											),
								),
							],
						),
					),
				],
			),
		);
	}
}
