import 'package:flutter/material.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
import 'package:craft_bridge/widgets/order_card.dart';

class ManageAllOrdersScreen extends StatefulWidget {
	const ManageAllOrdersScreen({super.key});

	@override
	State<ManageAllOrdersScreen> createState() => _ManageAllOrdersScreenState();
}

class _ManageAllOrdersScreenState extends State<ManageAllOrdersScreen> {
	final FirestoreService _firestoreService = FirestoreService();
	String _selectedStatus = 'all';

	List<String> get _statusFilters => <String>[
				'all',
				AppConstants.statusPending,
				AppConstants.statusConfirmed,
				AppConstants.statusShipped,
				AppConstants.statusDelivered,
				AppConstants.statusCancelled,
			];

	String _filterLabel(String status) {
		if (status == 'all') return 'All';
		return status[0].toUpperCase() + status.substring(1);
	}

	List<OrderModel> _applyStatusFilter(List<OrderModel> orders) {
		if (_selectedStatus == 'all') return orders;
		return orders.where((order) => order.status == _selectedStatus).toList();
	}

	Widget _buildFilterBar() {
		return SizedBox(
			height: 48,
			child: ListView.separated(
				scrollDirection: Axis.horizontal,
				padding: const EdgeInsets.symmetric(
					horizontal: AppConstants.defaultPadding,
					vertical: 4,
				),
				itemBuilder: (context, index) {
					final String status = _statusFilters[index];
					final bool isSelected = _selectedStatus == status;
					return FilterChip(
						label: Text(_filterLabel(status)),
						selected: isSelected,
						onSelected: (_) {
							setState(() => _selectedStatus = status);
						},
						showCheckmark: false,
						selectedColor: Theme.of(context).colorScheme.primary,
						labelStyle: TextStyle(
							color: isSelected
									? Colors.white
									: Theme.of(context).colorScheme.onSurface,
							fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
						),
						side: BorderSide(
							color: isSelected
									? Theme.of(context).colorScheme.primary
									: Theme.of(context).colorScheme.outline,
						),
					);
				},
				separatorBuilder: (_, __) => const SizedBox(width: 8),
				itemCount: _statusFilters.length,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('All Orders'),
			),
			body: StreamBuilder<List<OrderModel>>(
				stream: _firestoreService.getAllOrders(),
				builder: (context, snapshot) {
					if (snapshot.connectionState == ConnectionState.waiting) {
						return const LoadingWidget();
					}
					if (snapshot.hasError) {
						return AppErrorWidget(
							message: 'Failed to load platform orders: ${snapshot.error}',
							onRetry: () => setState(() {}),
						);
					}

					final List<OrderModel> allOrders = snapshot.data ?? <OrderModel>[];
					final List<OrderModel> filteredOrders = _applyStatusFilter(allOrders);
					if (filteredOrders.isEmpty) {
						return Column(
							children: [
								_buildFilterBar(),
								Expanded(
									child: EmptyStateWidget(
										icon: Icons.list_alt_outlined,
										title: allOrders.isEmpty ? 'No orders yet' : 'No matching orders',
										subtitle: allOrders.isEmpty
												? 'All platform orders will appear here.'
												: 'Try selecting a different order status filter.',
									),
								),
							],
						);
					}

					return Column(
						children: [
							_buildFilterBar(),
							Padding(
								padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
								child: Align(
									alignment: Alignment.centerRight,
									child: Text(
										'${filteredOrders.length} order${filteredOrders.length == 1 ? '' : 's'}',
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
													color: Theme.of(context)
															.colorScheme
															.onSurface
															.withValues(alpha: 0.7),
												),
									),
								),
							),
							Expanded(
								child: ListView.separated(
									padding: const EdgeInsets.all(AppConstants.defaultPadding),
									itemCount: filteredOrders.length,
									separatorBuilder: (_, __) => const SizedBox(height: 8),
									itemBuilder: (context, index) {
										final OrderModel order = filteredOrders[index];
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
								),
							),
						],
					);
				},
			),
		);
	}
}
