// ignore_for_file: unused_import

import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/screens/artisan/add_edit_product_screen.dart';
import 'package:craft_bridge/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageProductsScreen extends StatefulWidget {
	const ManageProductsScreen({super.key});

	@override
	State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
	final Set<String> _dismissedProductIds = <String>{};

	List<Map<String, dynamic>> _readProductsFromProvider(ProductProvider provider) {
		try {
			final dynamic dynamicProvider = provider;
			final dynamic dynamicProducts = dynamicProvider.products;
			if (dynamicProducts is List) {
				return dynamicProducts
						.whereType<Map>()
						.map((item) => Map<String, dynamic>.from(item))
						.toList();
			}
		} catch (_) {
			// ProductProvider is a stub before PR26/PR31; return empty until wired.
		}
		return <Map<String, dynamic>>[];
	}

	void _handleDelete(String productId) {
		setState(() {
			_dismissedProductIds.add(productId);
		});
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

	Widget _buildProductGrid(List<Map<String, dynamic>> products) {
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
				final Map<String, dynamic> product = products[index];
				final String productId = (product['id'] ?? '').toString();
				return Dismissible(
					key: Key(productId),
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
									'Are you sure you want to delete "${product['title'] ?? 'this product'}"?',
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
					onDismissed: (_) => _handleDelete(productId),
					child: _FallbackProductCard(product: product),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final ProductProvider productProvider = context.watch<ProductProvider>();
		final List<Map<String, dynamic>> providerProducts =
				_readProductsFromProvider(productProvider);
		final List<Map<String, dynamic>> visibleProducts = providerProducts
				.where((p) => !_dismissedProductIds.contains((p['id'] ?? '').toString()))
				.toList();

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('My Products'),
				actions: [
					Padding(
						padding: const EdgeInsets.only(right: 8),
						child: Center(
							child: Text(
								'${visibleProducts.length} items',
								style: Theme.of(context).textTheme.bodyMedium,
							),
						),
					),
				],
			),
			body: visibleProducts.isEmpty
					? _buildEmptyState()
					: _buildProductGrid(visibleProducts),
			floatingActionButton: FloatingActionButton(
				onPressed: () => Navigator.push(
					context,
					MaterialPageRoute(
						builder: (_) => const _AddEditProductFallbackScreen(),
					),
				),
				tooltip: 'Add Product',
				child: const Icon(Icons.add),
			),
		);
	}
}

class _FallbackProductCard extends StatelessWidget {
	final Map<String, dynamic> product;

	const _FallbackProductCard({required this.product});

	@override
	Widget build(BuildContext context) {
		final String title = (product['title'] ?? 'Untitled Product').toString();
		final double price = (product['price'] is num)
				? (product['price'] as num).toDouble()
				: 0;
		final int stock = (product['stock'] is num) ? (product['stock'] as num).toInt() : 0;
		final bool isActive = product['isActive'] == true;

		return Card(
			child: Column(
				children: [
					Expanded(
						child: Stack(
							children: [
								Container(
									decoration: BoxDecoration(
										color: Theme.of(context)
												.colorScheme
												.primary
												.withValues(alpha: 0.08),
										borderRadius:
												const BorderRadius.vertical(top: Radius.circular(12)),
									),
									child: Center(
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
											color:
													isActive ? Colors.green.shade100 : Colors.grey.shade200,
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
									title,
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												fontWeight: FontWeight.w600,
											),
									maxLines: 2,
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
								const SizedBox(height: 2),
								Text(
									'Stock: $stock',
									style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.5),
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

class _AddEditProductFallbackScreen extends StatelessWidget {
	const _AddEditProductFallbackScreen();

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Add Product')),
			body: const Center(
				child: Text('AddEditProductScreen — implemented in PR20'),
			),
		);
	}
}
