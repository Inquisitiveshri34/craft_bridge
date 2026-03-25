import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/cart_item_model.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/cart_item_tile.dart';
import 'package:craft_bridge/widgets/custom_button.dart';

class CartScreen extends StatefulWidget {
	const CartScreen({super.key});

	@override
	State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
	bool _isPlacingOrder = false;

	Future<void> _handlePlaceOrder() async {
		final AuthProvider authProvider = context.read<AuthProvider>();
		final CartProvider cartProvider = context.read<CartProvider>();
		final OrderProvider orderProvider = context.read<OrderProvider>();
		final String? buyerId = authProvider.currentUser?.uid;
		final String? buyerName = authProvider.currentUser?.displayName;

		if (buyerId == null || buyerName == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Error: user not authenticated.')),
			);
			return;
		}

		setState(() => _isPlacingOrder = true);
		final List<CartItemModel> items = cartProvider.items;
		bool allSuccess = true;
		for (final CartItemModel item in items) {
			final bool success = await orderProvider.createOrder(
				buyerId: buyerId,
				buyerName: buyerName,
				productId: item.productId,
				productTitle: item.title,
				productImageUrl: item.imageUrl,
				artisanId: item.artisanId,
				artisanName: item.artisanName,
				price: item.price,
				quantity: item.quantity,
			);
			if (!success) {
				allSuccess = false;
			}
		}
		setState(() => _isPlacingOrder = false);

		if (!mounted) return;
		if (allSuccess) {
			cartProvider.clearCart();
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Order placed successfully! Check your order history.'),
				),
			);
			Navigator.of(context).pop();
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(
						orderProvider.errorMessage ?? 'Some orders failed to place.',
					),
				),
			);
		}
	}

	Widget _buildEmptyCart() {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(
						Icons.shopping_cart_outlined,
						size: 80,
						color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
					),
					const SizedBox(height: 16),
					Text(
						'Your cart is empty',
						style: Theme.of(context).textTheme.headlineSmall?.copyWith(
								fontWeight: FontWeight.bold,
								color: Theme.of(context)
										.colorScheme
										.onSurface
										.withValues(alpha: 0.6),
							),
					),
					const SizedBox(height: 8),
					Text(
						'Add products from the Browse screen.',
						style: Theme.of(context).textTheme.bodyMedium?.copyWith(
								color: Theme.of(context)
										.colorScheme
										.onSurface
										.withValues(alpha: 0.45),
							),
					),
				],
			),
		);
	}

	Widget _buildOrderSummary(CartProvider cartProvider) {
		return Container(
			padding: const EdgeInsets.all(AppConstants.defaultPadding),
			decoration: BoxDecoration(
				color: Theme.of(context).colorScheme.surface,
				border: Border(
					top: BorderSide(
						color: Theme.of(context).colorScheme.outline,
						width: 0.5,
					),
				),
			),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								'${cartProvider.itemCount} item${cartProvider.itemCount == 1 ? '' : 's'}',
								style: Theme.of(context).textTheme.bodyMedium,
							),
							Text(
								'₹${cartProvider.totalPrice.toStringAsFixed(0)}',
								style: Theme.of(context)
										.textTheme
										.bodyMedium
										?.copyWith(fontWeight: FontWeight.w600),
							),
						],
					),
					const SizedBox(height: 4),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								'Delivery',
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(
											color: Theme.of(context)
													.colorScheme
													.onSurface
													.withValues(alpha: 0.6),
										),
							),
							Text(
								'Free',
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(
											color: Colors.green.shade700,
											fontWeight: FontWeight.w500,
										),
							),
						],
					),
					const Divider(height: 24),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								'Total',
								style: Theme.of(context)
										.textTheme
										.titleMedium
										?.copyWith(fontWeight: FontWeight.bold),
							),
							Text(
								'₹${cartProvider.totalPrice.toStringAsFixed(0)}',
								style: Theme.of(context).textTheme.titleLarge?.copyWith(
											color: Theme.of(context).colorScheme.primary,
											fontWeight: FontWeight.bold,
										),
							),
						],
					),
					const SizedBox(height: 16),
					CustomButton(
						label: 'Place Order',
						onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
						isLoading: _isPlacingOrder,
					),
					const SizedBox(height: 8),
					Text(
						'No payment required for this demo order.',
						style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: Theme.of(context)
											.colorScheme
											.onSurface
											.withValues(alpha: 0.45),
								),
						textAlign: TextAlign.center,
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('My Cart'),
				actions: [
					Consumer<CartProvider>(
						builder: (_, CartProvider cartProvider, __) {
							if (cartProvider.isEmpty) {
								return const SizedBox.shrink();
							}
							return TextButton(
								onPressed: () {
									showDialog<void>(
										context: context,
										builder: (ctx) => AlertDialog(
											title: const Text('Clear Cart'),
											content: const Text(
												'Remove all items from your cart?',
											),
											actions: [
												TextButton(
													onPressed: () => Navigator.pop(ctx),
													child: const Text('Cancel'),
												),
												TextButton(
													onPressed: () {
														Navigator.pop(ctx);
														context.read<CartProvider>().clearCart();
													},
													style: TextButton.styleFrom(
														foregroundColor: Theme.of(context).colorScheme.error,
													),
													child: const Text('Clear'),
												),
											],
										),
									);
								},
								child: const Text('Clear'),
							);
						},
					),
				],
			),
			body: Consumer<CartProvider>(
				builder: (context, CartProvider cartProvider, _) {
					if (cartProvider.isEmpty) {
						return _buildEmptyCart();
					}
					return Column(
						children: [
							Expanded(
								child: ListView.separated(
									padding: const EdgeInsets.all(AppConstants.defaultPadding),
									itemCount: cartProvider.items.length,
									separatorBuilder: (_, __) => const SizedBox(height: 8),
									itemBuilder: (context, index) {
										final CartItemModel item = cartProvider.items[index];
										return CartItemTile(
											productId: item.productId,
											title: item.title,
											imageUrl: item.imageUrl,
											price: item.price,
											quantity: item.quantity,
											artisanName: item.artisanName,
											onIncrement: () => cartProvider.updateQuantity(
													item.productId,
													item.quantity + 1,
												),
											onDecrement: () => cartProvider.updateQuantity(
													item.productId,
													item.quantity - 1,
												),
											onRemove: () => cartProvider.removeItem(item.productId),
										);
									},
								),
							),
							_buildOrderSummary(cartProvider),
						],
					);
				},
			),
		);
	}
}
