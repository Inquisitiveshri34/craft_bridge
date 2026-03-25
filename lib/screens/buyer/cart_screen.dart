import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/cart_item_tile.dart';
import 'package:craft_bridge/widgets/custom_button.dart';

class CartScreen extends StatefulWidget {
	final ProductModel product;
	final int quantity;

	const CartScreen({
		super.key,
		required this.product,
		required this.quantity,
	});

	@override
	State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
	late int _quantity;
	bool _isPlacingOrder = false;

	@override
	void initState() {
		super.initState();
		_quantity = widget.quantity;
	}

	Future<void> _handlePlaceOrder() async {
		final AuthProvider authProvider = context.read<AuthProvider>();
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
		final String orderId = FirebaseFirestore.instance
				.collection(AppConstants.ordersCollection)
				.doc()
				.id;
		final OrderModel order = OrderModel(
			id: orderId,
			buyerId: buyerId,
			buyerName: buyerName,
			artisanId: widget.product.artisanId,
			artisanName: widget.product.artisanName,
			productId: widget.product.id,
			productTitle: widget.product.title,
			productImageUrl: widget.product.imageUrl,
			quantity: _quantity,
			totalPrice: widget.product.price * _quantity,
			status: AppConstants.statusPending,
			createdAt: Timestamp.now(),
		);
		final bool success = await orderProvider.createOrder(order);
		setState(() => _isPlacingOrder = false);

		if (!mounted) return;
		if (success) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Order placed successfully!')),
			);
			Navigator.of(context).popUntil((route) => route.isFirst);
		} else {
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(orderProvider.errorMessage ?? 'Failed to place order.'),
				),
			);
		}
	}

	Widget _buildOrderSummary() {
		final double subtotal = widget.product.price * _quantity;
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
								'Subtotal ($_quantity item${_quantity == 1 ? '' : 's'})',
								style: Theme.of(context).textTheme.bodyMedium,
							),
							Text(
								'₹${subtotal.toStringAsFixed(0)}',
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
								'₹${subtotal.toStringAsFixed(0)}',
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
		// Placeholder consumption until CartProvider is fully implemented in PR42.
		context.watch<CartProvider>();

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(title: const Text('Review Order')),
			body: Column(
				children: [
					Expanded(
						child: ListView(
							padding: const EdgeInsets.all(AppConstants.defaultPadding),
							children: [
								Text(
									'Order Items',
									style: Theme.of(context)
											.textTheme
											.titleMedium
											?.copyWith(fontWeight: FontWeight.bold),
								),
								const SizedBox(height: 12),
								CartItemTile(
									productId: widget.product.id,
									title: widget.product.title,
									imageUrl: widget.product.imageUrl,
									price: widget.product.price,
									quantity: _quantity,
									artisanName: widget.product.artisanName,
									onIncrement: widget.product.stock > _quantity
											? () => setState(() => _quantity++)
											: () {},
									onDecrement: _quantity > 1
											? () => setState(() => _quantity--)
											: () {},
									onRemove: () => Navigator.pop(context),
								),
								const SizedBox(height: 16),
								Container(
									padding: const EdgeInsets.all(12),
									decoration: BoxDecoration(
										color: Theme.of(context)
												.colorScheme
												.primary
												.withValues(alpha: 0.06),
										borderRadius: BorderRadius.circular(8),
										border: Border.all(
											color: Theme.of(context)
													.colorScheme
													.primary
													.withValues(alpha: 0.2),
										),
									),
									child: Row(
										children: [
											Icon(
												Icons.info_outline,
												size: 16,
												color: Theme.of(context).colorScheme.primary,
											),
											const SizedBox(width: 8),
											Expanded(
												child: Text(
													'Multi-item cart with CartProvider — implemented in PR42.',
													style: Theme.of(context)
															.textTheme
															.bodySmall
															?.copyWith(
																color: Theme.of(context).colorScheme.primary,
															),
												),
											),
										],
									),
								),
							],
						),
					),
					_buildOrderSummary(),
				],
			),
		);
	}
}
