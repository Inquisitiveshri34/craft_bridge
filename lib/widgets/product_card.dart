import 'dart:io';

import 'package:flutter/material.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class ProductCard extends StatelessWidget {
	final String productId;
	final String title;
	final double price;
	final String imageUrl;
	final String artisanName;
	final String category;
	final bool isActive;
	final VoidCallback? onTap;

	const ProductCard({
		super.key,
		required this.productId,
		required this.title,
		required this.price,
		required this.imageUrl,
		required this.artisanName,
		required this.category,
		required this.isActive,
		this.onTap,
	});

	Widget _buildImageFallback(BuildContext context) {
		return Container(
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Center(
				child: Icon(
					Icons.image_outlined,
					size: 36,
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
				),
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
		if (imageUrl.isEmpty) {
			return _buildImageFallback(context);
		}

		if (!_isRemoteUrl(imageUrl)) {
			final String? localPath = _localPathFromImageRef(imageUrl);
			if (localPath == null) return _buildImageFallback(context);
			final File file = File(localPath);
			if (file.existsSync()) {
				return Image.file(
					file,
					width: double.infinity,
					fit: BoxFit.cover,
					errorBuilder: (_, __, ___) => _buildImageFallback(context),
				);
			}
			return _buildImageFallback(context);
		}

		return Image.network(
			imageUrl,
			width: double.infinity,
			fit: BoxFit.cover,
			loadingBuilder: (context, child, loadingProgress) {
				if (loadingProgress == null) return child;
				return Center(
					child: CircularProgressIndicator(
						strokeWidth: 2,
						value: loadingProgress.expectedTotalBytes != null
								? loadingProgress.cumulativeBytesLoaded /
										loadingProgress.expectedTotalBytes!
								: null,
					),
				);
			},
			errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
		);
	}

	@override
	Widget build(BuildContext context) {
		return LayoutBuilder(
			builder: (context, constraints) {
				final double cardWidth = constraints.maxWidth;
				final double base = cardWidth.isFinite && cardWidth > 0 ? cardWidth : 140;
				final double padding = base * 0.055;
				final double tinyGap = base * 0.014;
				final double smallGap = base * 0.028;
				final double inactiveFontSize = base * 0.08;

				return GestureDetector(
					onTap: onTap,
					child: Card(
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
						),
						child: Column(
							children: [
								Expanded(
									child: Stack(
										children: [
											Hero(
												tag: 'product-$productId',
												child: ClipRRect(
													borderRadius: const BorderRadius.vertical(
														top: Radius.circular(12),
													),
													child: imageUrl.isNotEmpty
														? _buildProductImage(context)
														: _buildImageFallback(context),
												),
											),
											if (!isActive)
												Positioned.fill(
													child: Container(
														color: Colors.black.withValues(alpha: 0.45),
														child: Center(
															child: Container(
																padding: EdgeInsets.symmetric(
																	horizontal: padding,
																	vertical: tinyGap,
																),
																decoration: BoxDecoration(
																	color: Colors.black54,
																	borderRadius: BorderRadius.circular(tinyGap * 3),
																),
																child: Text(
																	'Inactive',
																	style: TextStyle(
																		color: Colors.white,
																		fontSize: inactiveFontSize,
																		fontWeight: FontWeight.w600,
																	),
																),
															),
														),
													),
												),
										],
									),
								),
								Padding(
									padding: EdgeInsets.all(padding),
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
											SizedBox(height: tinyGap),
											Text(
												artisanName,
												style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context)
																.colorScheme
																.onSurface
																.withValues(alpha: 0.55),
													),
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
											),
											SizedBox(height: smallGap),
											Text(
												category,
												style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context)
																.colorScheme
																.onSurface
																.withValues(alpha: 0.45),
													),
												maxLines: 1,
												overflow: TextOverflow.ellipsis,
											),
											SizedBox(height: smallGap),
											Text(
												'₹${price.toStringAsFixed(0)}',
												style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context).colorScheme.primary,
														fontWeight: FontWeight.bold,
													),
											),
										],
									),
								),
							],
						),
					),
				);
			},
		);
	}
}
