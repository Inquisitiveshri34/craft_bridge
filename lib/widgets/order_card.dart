import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class OrderCard extends StatelessWidget {
	final String orderId;
	final String productTitle;
	final String productImageUrl;
	final String buyerName;
	final String artisanName;
	final int quantity;
	final double totalPrice;
	final String status;
	final Timestamp createdAt;
	final VoidCallback? onTap;
	final bool showBuyerName;

	const OrderCard({
		super.key,
		required this.orderId,
		required this.productTitle,
		required this.productImageUrl,
		required this.buyerName,
		required this.artisanName,
		required this.quantity,
		required this.totalPrice,
		required this.status,
		required this.createdAt,
		this.onTap,
		this.showBuyerName = true,
	});

	static Color _statusColor(String status) {
		switch (status) {
			case AppConstants.statusPending:
				return Colors.orange.shade700;
			case AppConstants.statusConfirmed:
				return Colors.blue.shade700;
			case AppConstants.statusShipped:
				return Colors.purple.shade700;
			case AppConstants.statusDelivered:
				return Colors.green.shade700;
			case AppConstants.statusCancelled:
				return Colors.red.shade700;
			default:
				return Colors.grey.shade700;
		}
	}

	Widget _buildStatusChip(BuildContext context) {
		final Color color = _statusColor(status);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: color.withValues(alpha: 0.4)),
			),
			child: Text(
				status[0].toUpperCase() + status.substring(1),
				style: TextStyle(
					color: color,
					fontSize: 11,
					fontWeight: FontWeight.w600,
				),
			),
		);
	}

	String _formatDate(Timestamp timestamp) {
		final DateTime dt = timestamp.toDate();
		final List<String> months = [
			'Jan',
			'Feb',
			'Mar',
			'Apr',
			'May',
			'Jun',
			'Jul',
			'Aug',
			'Sep',
			'Oct',
			'Nov',
			'Dec',
		];
		return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
	}

	Widget _buildImageFallback(BuildContext context) {
		return Container(
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Icon(
				Icons.shopping_bag_outlined,
				color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
			),
		);
	}

	bool _isRemoteUrl(String value) {
		return value.startsWith('http://') || value.startsWith('https://');
	}

	String? _localPathFromImageRef(String value) {
		if (value.isEmpty || _isRemoteUrl(value)) return null;
		if (value.startsWith('file://')) {
			return Uri.tryParse(value)?.toFilePath();
		}
		return value;
	}

	Widget _buildProductImage(BuildContext context) {
		if (productImageUrl.isEmpty) return _buildImageFallback(context);

		if (!_isRemoteUrl(productImageUrl)) {
			final String? localPath = _localPathFromImageRef(productImageUrl);
			if (localPath == null) return _buildImageFallback(context);
			final File file = File(localPath);
			if (file.existsSync()) {
				return Image.file(
					file,
					fit: BoxFit.cover,
					errorBuilder: (_, __, ___) => _buildImageFallback(context),
				);
			}
			return _buildImageFallback(context);
		}

		return Image.network(
			productImageUrl,
			fit: BoxFit.cover,
			errorBuilder: (_, __, ___) => _buildImageFallback(context),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Card(
			child: InkWell(
				borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(12),
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							ClipRRect(
								borderRadius: BorderRadius.circular(8),
								child: SizedBox(
									width: 64,
									height: 64,
									child: _buildProductImage(context),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: [
												Expanded(
													child: Text(
														productTitle,
														style:
																Theme.of(context).textTheme.bodyMedium?.copyWith(
																			fontWeight: FontWeight.w600,
																		),
														maxLines: 2,
														overflow: TextOverflow.ellipsis,
													),
												),
												const SizedBox(width: 8),
												_buildStatusChip(context),
											],
										),
										const SizedBox(height: 4),
										Text(
											showBuyerName
													? 'Buyer: $buyerName'
													: 'Artisan: $artisanName',
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context)
																.colorScheme
																.onSurface
																.withValues(alpha: 0.6),
													),
										),
										const SizedBox(height: 4),
										Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: [
												Text(
													'Qty: $quantity',
													style: Theme.of(context).textTheme.bodySmall?.copyWith(
																color: Theme.of(context)
																		.colorScheme
																		.onSurface
																		.withValues(alpha: 0.6),
															),
												),
												Text(
													'₹${totalPrice.toStringAsFixed(0)}',
													style:
															Theme.of(context).textTheme.bodySmall?.copyWith(
																		color: Theme.of(context).colorScheme.primary,
																		fontWeight: FontWeight.bold,
																	),
												),
											],
										),
										const SizedBox(height: 4),
										Text(
											_formatDate(createdAt),
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context)
																.colorScheme
																.onSurface
																.withValues(alpha: 0.45),
													),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}

class LoadingWidget extends StatelessWidget {
	final String? message;

	const LoadingWidget({super.key, this.message});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					CircularProgressIndicator(
						color: Theme.of(context).colorScheme.primary,
					),
					if (message != null) ...[
						const SizedBox(height: 16),
						Text(
							message!,
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									color: Theme.of(context)
											.colorScheme
											.onSurface
											.withValues(alpha: 0.6),
								),
							textAlign: TextAlign.center,
						),
					],
				],
			),
		);
	}
}

class EmptyStateWidget extends StatelessWidget {
	final IconData icon;
	final String title;
	final String subtitle;
	final String? actionLabel;
	final VoidCallback? onAction;

	const EmptyStateWidget({
		super.key,
		required this.icon,
		required this.title,
		required this.subtitle,
		this.actionLabel,
		this.onAction,
	});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(32),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(
							icon,
							size: 80,
							color: Theme.of(context)
									.colorScheme
									.primary
									.withValues(alpha: 0.3),
						),
						const SizedBox(height: 16),
						Text(
							title,
							style: Theme.of(context).textTheme.headlineSmall?.copyWith(
									fontWeight: FontWeight.bold,
									color: Theme.of(context)
											.colorScheme
											.onSurface
											.withValues(alpha: 0.6),
								),
							textAlign: TextAlign.center,
						),
						const SizedBox(height: 8),
						Text(
							subtitle,
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									color: Theme.of(context)
											.colorScheme
											.onSurface
											.withValues(alpha: 0.45),
								),
							textAlign: TextAlign.center,
						),
						if (actionLabel != null && onAction != null) ...[
							const SizedBox(height: 24),
							OutlinedButton(
								onPressed: onAction,
								child: Text(actionLabel!),
							),
						],
					],
				),
			),
		);
	}
}

class AppErrorWidget extends StatelessWidget {
	final String message;
	final VoidCallback? onRetry;

	const AppErrorWidget({
		super.key,
		required this.message,
		this.onRetry,
	});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: Padding(
				padding: const EdgeInsets.all(32),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(
							Icons.error_outline,
							size: 64,
							color: Theme.of(context).colorScheme.error,
						),
						const SizedBox(height: 16),
						Text(
							'Something went wrong',
							style: Theme.of(context)
									.textTheme
									.titleMedium
									?.copyWith(fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 8),
						Text(
							message,
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(
									color: Theme.of(context)
											.colorScheme
											.onSurface
											.withValues(alpha: 0.7),
								),
							textAlign: TextAlign.center,
						),
						if (onRetry != null) ...[
							const SizedBox(height: 24),
							OutlinedButton.icon(
								onPressed: onRetry,
								icon: const Icon(Icons.refresh, size: 18),
								label: const Text('Retry'),
							),
						],
					],
				),
			),
		);
	}
}
