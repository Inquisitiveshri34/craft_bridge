import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/widgets/order_card.dart';

class BuyerOrdersScreen extends StatefulWidget {
	const BuyerOrdersScreen({super.key});

	@override
	State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
	String? _buyerId;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!mounted) return;
			setState(() {
				_buyerId = context.read<AuthProvider>().currentUser?.uid;
			});
			if (_buyerId != null) {
				context.read<OrderProvider>().listenToBuyerOrders(_buyerId!);
			}
		});
	}

	Widget _buildEmptyState() {
		return const EmptyStateWidget(
			icon: Icons.receipt_long_outlined,
			title: 'No orders yet',
			subtitle: 'Products you order will appear here.',
		);
	}

	Widget _buildOrderList(List<OrderModel> orders) {
		return ListView.separated(
			padding: const EdgeInsets.all(AppConstants.defaultPadding),
			itemCount: orders.length,
			separatorBuilder: (_, __) => const SizedBox(height: 8),
			itemBuilder: (context, index) {
				final OrderModel order = orders[index];
				return OrderCard(
					orderId: order.id,
					productTitle: order.productTitle,
					productImageUrl: order.productImageUrl,
					buyerName: order.buyerName,
					artisanName: order.artisanName,
					quantity: order.quantity,
					totalPrice: order.totalPrice,
					status: order.status,
					createdAt: order.createdAt,
					showBuyerName: false,
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final OrderProvider orderProvider = context.watch<OrderProvider>();
		final Stream<List<OrderModel>>? stream = _buyerId == null
				? null
				: orderProvider.watchOrdersForBuyer(_buyerId!);

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('My Orders'),
				automaticallyImplyLeading: false,
			),
			body: StreamBuilder<List<OrderModel>>(
				stream: stream,
				builder: (context, snapshot) {
					if (_buyerId == null ||
							snapshot.connectionState == ConnectionState.waiting) {
						return const LoadingWidget();
					}

					if (snapshot.hasError) {
						return AppErrorWidget(
							message: 'Failed to load your orders: ${snapshot.error}',
							onRetry: () {
								if (_buyerId != null) {
									context.read<OrderProvider>().clearError();
									context.read<OrderProvider>().listenToBuyerOrders(_buyerId!);
								}
							},
						);
					}

					final List<OrderModel> orders = snapshot.data ?? <OrderModel>[];
					if (orders.isEmpty) {
						return _buildEmptyState();
					}
					return _buildOrderList(orders);
				},
			),
		);
	}
}
