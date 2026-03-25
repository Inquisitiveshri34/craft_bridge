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

	List<String> _nextStatusesFor(String currentStatus) {
		switch (currentStatus) {
			case 'pending':
				return <String>['confirmed', 'shipped', 'delivered', 'cancelled'];
			case 'confirmed':
				return <String>['shipped', 'delivered', 'cancelled'];
			case 'shipped':
				return <String>['delivered', 'cancelled'];
			case 'delivered':
				return <String>[];
			case 'cancelled':
				return <String>[];
			default:
				return <String>[];
		}
	}

	String _statusLabel(String status) {
		switch (status) {
			case 'pending':
				return 'Pending';
			case 'confirmed':
				return 'Confirmed';
			case 'shipped':
				return 'Shipped';
			case 'delivered':
				return 'Delivered';
			case 'cancelled':
				return 'Cancelled';
			default:
				return status;
		}
	}

	Future<void> _updateOrderStatus(
		OrderModel order,
		String newStatus,
		String statusLabel,
	) async {
		final OrderProvider orderProvider = context.read<OrderProvider>();
		final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
		final bool success = await orderProvider.updateOrderStatus(order.id, newStatus);
		if (!mounted) return;
		messenger.showSnackBar(
			SnackBar(
				content: Text(
					success
							? 'Order status updated to "$statusLabel".'
							: orderProvider.errorMessage ??
									'Failed to update status.',
				),
			),
		);
	}

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
				final List<String> nextStatuses = _nextStatusesFor(order.status);
				return Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						OrderCard(
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
						),
						Padding(
							padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
							child: Row(
								children: [
									Text(
										'Update Status:',
										style: Theme.of(context).textTheme.bodySmall,
									),
									const SizedBox(width: 10),
									Expanded(
										child: DropdownButtonFormField<String>(
											initialValue: null,
											isDense: true,
											decoration: InputDecoration(
												isDense: true,
												contentPadding: const EdgeInsets.symmetric(
													horizontal: 10,
													vertical: 8,
												),
												border: OutlineInputBorder(
													borderRadius: BorderRadius.circular(8),
												),
											),
											hint: Text(
												nextStatuses.isEmpty
														? 'No further updates'
														: 'Choose status',
											),
											items: nextStatuses
													.map(
														(String status) => DropdownMenuItem<String>(
															value: status,
															child: Text(_statusLabel(status)),
														),
													)
													.toList(),
											onChanged: nextStatuses.isEmpty
													? null
													: (String? selectedStatus) {
														if (selectedStatus == null) return;
														_updateOrderStatus(
															order,
															selectedStatus,
															_statusLabel(selectedStatus),
														);
													},
										),
									),
								],
							),
						),
					],
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
