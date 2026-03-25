import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/widgets/order_card.dart';

class ArtisanOrdersScreen extends StatefulWidget {
	const ArtisanOrdersScreen({super.key});

	@override
	State<ArtisanOrdersScreen> createState() => _ArtisanOrdersScreenState();
}

class _ArtisanOrdersScreenState extends State<ArtisanOrdersScreen> {
	String? _artisanId;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!mounted) return;
			setState(() {
				_artisanId = context.read<AuthProvider>().currentUser?.uid;
			});
		});
	}

	Widget _buildEmptyState() {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Icon(
						Icons.receipt_long_outlined,
						size: 80,
						color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
					),
					const SizedBox(height: 16),
					Text(
						'No orders yet',
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
						'Orders from buyers will appear here.',
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
					showBuyerName: true,
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final OrderProvider orderProvider = context.read<OrderProvider>();
		final Stream<List<OrderModel>>? stream = _artisanId == null
				? null
				: orderProvider.watchOrdersForArtisan(_artisanId!);

		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('My Orders'),
			),
			body: StreamBuilder<List<OrderModel>>(
				stream: stream,
				builder: (context, snapshot) {
					if (_artisanId == null ||
							snapshot.connectionState == ConnectionState.waiting) {
						return const Center(child: CircularProgressIndicator());
					}

					if (snapshot.hasError) {
						return Center(
							child: Padding(
								padding: const EdgeInsets.all(AppConstants.defaultPadding),
								child: Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Icon(
											Icons.error_outline,
											size: 48,
											color: Theme.of(context).colorScheme.error,
										),
										const SizedBox(height: 12),
										Text(
											'Failed to load orders: ${snapshot.error}',
											textAlign: TextAlign.center,
										),
									],
								),
							),
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
