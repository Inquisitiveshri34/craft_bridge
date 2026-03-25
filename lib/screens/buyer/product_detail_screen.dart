import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/models/cart_item_model.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/models/review_model.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/screens/buyer/cart_screen.dart';
import 'package:craft_bridge/services/firestore_service.dart';
import 'package:craft_bridge/widgets/custom_button.dart';
import 'package:craft_bridge/widgets/custom_text_field.dart';

class ProductDetailScreen extends StatefulWidget {
	final ProductModel product;

	const ProductDetailScreen({super.key, required this.product});

	@override
	State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
	int _quantity = 1;
	bool _isAddingToCart = false;
	Position? _buyerPosition;
	bool _isLoadingLocation = false;
	String? _locationStatusMessage;
	final FirestoreService _firestoreService = FirestoreService();
	List<ReviewModel> _reviews = [];
	bool _isLoadingReviews = false;
	bool _isSubmittingReview = false;
	StreamSubscription<List<ReviewModel>>? _reviewsSubscription;
	late final Future<LatLng> _artisanLocationFuture;

	@override
	void initState() {
		super.initState();
		_artisanLocationFuture = _loadArtisanLocation();
		_listenToReviews();
	}

	@override
	void dispose() {
		_reviewsSubscription?.cancel();
		super.dispose();
	}

	void _listenToReviews() {
		setState(() => _isLoadingReviews = true);
		_reviewsSubscription = _firestoreService
				.getReviewsByProduct(widget.product.id)
				.listen(
			(reviews) {
				if (!mounted) return;
				setState(() {
					_reviews = reviews;
					_isLoadingReviews = false;
				});
			},
			onError: (_) {
				if (!mounted) return;
				setState(() => _isLoadingReviews = false);
			},
		);
	}

	void _showReviewBottomSheet() {
		int selectedRating = 0;
		bool showRatingError = false;
		final TextEditingController commentController = TextEditingController();
		final GlobalKey<FormState> formKey = GlobalKey<FormState>();

		showModalBottomSheet<void>(
			context: context,
			isScrollControlled: true,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
			),
			builder: (ctx) {
				return StatefulBuilder(
					builder: (ctx, setSheetState) {
						return Padding(
							padding: EdgeInsets.only(
								left: 16,
								right: 16,
								top: 16,
								bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
							),
							child: Form(
								key: formKey,
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Write a Review',
											style: Theme.of(context)
													.textTheme
													.titleMedium
													?.copyWith(fontWeight: FontWeight.bold),
										),
										const SizedBox(height: 4),
										Text(
											widget.product.title,
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: Theme.of(context)
																	.colorScheme
																	.onSurface
																	.withValues(alpha: 0.6),
														),
										),
										const SizedBox(height: 16),
										Text(
											'Your Rating',
											style: Theme.of(context)
													.textTheme
													.titleSmall
													?.copyWith(fontWeight: FontWeight.w600),
										),
										const SizedBox(height: 8),
										Row(
											children: List.generate(5, (index) {
												final int star = index + 1;
												return IconButton(
													onPressed: () {
														setSheetState(() {
															selectedRating = star;
															showRatingError = false;
														});
													},
													padding: const EdgeInsets.symmetric(horizontal: 2),
													constraints: const BoxConstraints(),
													icon: Icon(
														star <= selectedRating
																? Icons.star_rounded
																: Icons.star_outline_rounded,
														color: star <= selectedRating
																? Colors.amber.shade600
																: Theme.of(context)
																		.colorScheme
																		.onSurface
																		.withValues(alpha: 0.3),
														size: 34,
													),
												);
											}),
										),
										if (showRatingError)
											Padding(
												padding: const EdgeInsets.only(top: 4),
												child: Text(
													'Please select a rating.',
													style: TextStyle(
														color: Theme.of(context).colorScheme.error,
														fontSize: 12,
													),
												),
											),
										const SizedBox(height: 16),
										CustomTextField(
											label: 'Your Review',
											hint: 'Share your experience with this product...',
											controller: commentController,
											maxLines: 3,
											textCapitalization: TextCapitalization.sentences,
											validator: (value) {
												if (value == null || value.trim().isEmpty) {
													return 'Please write a review.';
												}
												if (value.trim().length < 10) {
													return 'Review must be at least 10 characters.';
												}
												return null;
											},
										),
										const SizedBox(height: 20),
										SizedBox(
											width: double.infinity,
											child: ElevatedButton(
												onPressed: _isSubmittingReview
													? null
													: () async {
														if (selectedRating == 0) {
															setSheetState(() => showRatingError = true);
															return;
														}
														if (!formKey.currentState!.validate()) {
															return;
														}

														final AuthProvider authProvider =
																context.read<AuthProvider>();
														final ScaffoldMessengerState messenger =
																ScaffoldMessenger.of(context);
														final NavigatorState navigator = Navigator.of(context);
														final String? buyerId = authProvider.currentUser?.uid;
														if (buyerId == null || buyerId.isEmpty) {
															if (!mounted) return;
															messenger.showSnackBar(
																const SnackBar(
																	content: Text('Please sign in to submit a review.'),
																),
															);
															return;
														}

														setState(() => _isSubmittingReview = true);
														setSheetState(() {});
														try {
															final String reviewId = FirebaseFirestore.instance
																	.collection(AppConstants.reviewsCollection)
																	.doc()
																	.id;
															final ReviewModel review = ReviewModel(
																id: reviewId,
																productId: widget.product.id,
																buyerId: buyerId,
																buyerName: authProvider.currentUser?.displayName ?? '',
																rating: selectedRating.toDouble(),
																comment: commentController.text.trim(),
																createdAt: Timestamp.now(),
															);
															await _firestoreService.addReview(review);
															if (!mounted) return;
															setState(() => _isSubmittingReview = false);
															navigator.pop();
															messenger.showSnackBar(
																const SnackBar(
																	content: Text('Review submitted. Thank you!'),
																),
															);
														} catch (e) {
															if (!mounted) return;
															setState(() => _isSubmittingReview = false);
															setSheetState(() {});
															messenger.showSnackBar(
																SnackBar(content: Text('Failed to submit review: $e')),
															);
														}
													},
												child: _isSubmittingReview
														? const SizedBox(
															height: 20,
															width: 20,
															child: CircularProgressIndicator(
																strokeWidth: 2,
																color: Colors.white,
															),
														)
														: const Text('Submit Review'),
											),
										),
										const SizedBox(height: 8),
									],
								),
							),
						);
					},
				);
			},
		).whenComplete(commentController.dispose);
	}

	Widget _buildReviewsSection() {
		final bool isBuyer =
				context.read<AuthProvider>().currentUser?.role == AppConstants.roleBuyer;
		final double averageRating = _reviews.isEmpty
				? 0
				: _reviews.fold(0.0, (total, review) => total + review.rating) /
						_reviews.length;

		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const Divider(height: 32),
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									'Reviews',
									style: Theme.of(context)
											.textTheme
											.titleMedium
											?.copyWith(fontWeight: FontWeight.bold),
								),
								if (_reviews.isNotEmpty)
									Row(
										children: [
											Icon(
												Icons.star_rounded,
												color: Colors.amber.shade600,
												size: 16,
											),
											const SizedBox(width: 2),
											Text(
												'${averageRating.toStringAsFixed(1)} (${_reviews.length})',
												style: Theme.of(context)
														.textTheme
														.bodySmall
														?.copyWith(
															color: Theme.of(context)
																	.colorScheme
																	.onSurface
																	.withValues(alpha: 0.7),
														),
											),
										],
									),
							],
						),
						if (isBuyer)
							TextButton.icon(
								onPressed: _showReviewBottomSheet,
								icon: const Icon(Icons.rate_review_outlined, size: 18),
								label: const Text('Write a Review'),
							),
					],
				),
				const SizedBox(height: 12),
				if (_isLoadingReviews)
					const Center(
						child: CircularProgressIndicator(strokeWidth: 2),
					)
				else if (_reviews.isEmpty)
					Center(
						child: Padding(
							padding: const EdgeInsets.symmetric(vertical: 16),
							child: Text(
								'No reviews yet. Be the first to review!',
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(
										color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.5),
								),
							),
						),
					)
				else
					ListView.separated(
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						itemCount: _reviews.length,
						separatorBuilder: (_, __) => const Divider(height: 16),
						itemBuilder: (context, index) {
							return _ReviewCard(review: _reviews[index]);
						},
					),
			],
		);
	}

	Widget _buildImageSection() {
		final String imageUrl = widget.product.imageUrl;
		final bool isRemote =
				imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
		final String? localPath =
				isRemote ? null : (imageUrl.startsWith('file://')
						? Uri.tryParse(imageUrl)?.toFilePath()
						: imageUrl);
		return Hero(
			tag: 'product-${widget.product.id}',
			child: imageUrl.isNotEmpty
					? isRemote
							? Image.network(
									imageUrl,
									height: 280,
									width: double.infinity,
									fit: BoxFit.cover,
									loadingBuilder: (context, child, loadingProgress) {
										if (loadingProgress == null) return child;
										return SizedBox(
											height: 280,
											child: Center(
												child: CircularProgressIndicator(
													strokeWidth: 2,
													value: loadingProgress.expectedTotalBytes != null
															? loadingProgress.cumulativeBytesLoaded /
																	loadingProgress.expectedTotalBytes!
															: null,
												),
											),
										);
									},
									errorBuilder: (_, __, ___) => _buildImageFallback(),
								)
							: Image.file(
									File(localPath ?? imageUrl),
									height: 280,
									width: double.infinity,
									fit: BoxFit.cover,
									errorBuilder: (_, __, ___) => _buildImageFallback(),
								)
					: _buildImageFallback(),
		);
	}

	Widget _buildImageFallback() {
		return Container(
			height: 280,
			width: double.infinity,
			color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
			child: Center(
				child: Icon(
					Icons.image_outlined,
					size: 72,
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
				),
			),
		);
	}

	Future<LatLng> _loadArtisanLocation() async {
		try {
			final UserModel? artisan =
					await _firestoreService.getUser(widget.product.artisanId);
			if (artisan != null) {
				return _getArtisanLocation(artisan.displayName);
			}
		} catch (_) {
			// Keep fallback behavior when user lookup fails.
		}
		return _getArtisanLocation(widget.product.artisanName);
	}

	LatLng _getArtisanLocation(String artisanName) {
		switch (artisanName) {
			case 'Meera Devi':
				return const LatLng(26.9124, 75.7873);
			case 'Ravi Kumar':
				return const LatLng(12.9716, 77.5946);
			case 'Pradeep Nair':
				return const LatLng(8.5241, 76.9366);
			case 'Sunita Sharma':
				return const LatLng(28.6139, 77.2090);
			default:
				return const LatLng(20.5937, 78.9629);
		}
	}

	Widget _buildQuantitySelector() {
		return Row(
			children: [
				Text(
					'Quantity',
					style: Theme.of(context)
							.textTheme
							.titleSmall
							?.copyWith(fontWeight: FontWeight.w600),
				),
				const Spacer(),
				Container(
					decoration: BoxDecoration(
						border: Border.all(color: Theme.of(context).colorScheme.outline),
						borderRadius: BorderRadius.circular(8),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: [
							InkWell(
								onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
								borderRadius:
										const BorderRadius.horizontal(left: Radius.circular(7)),
								child: Padding(
									padding:
											const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
									child: Icon(
										Icons.remove,
										size: 16,
										color: _quantity > 1
												? Theme.of(context).colorScheme.onSurface
												: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.3),
									),
								),
							),
							SizedBox(
								width: 40,
								child: Center(
									child: Text(
										'$_quantity',
										style: Theme.of(context)
												.textTheme
												.titleMedium
												?.copyWith(fontWeight: FontWeight.bold),
									),
								),
							),
							InkWell(
								onTap: _quantity < widget.product.stock
										? () => setState(() => _quantity++)
										: null,
								borderRadius:
										const BorderRadius.horizontal(right: Radius.circular(7)),
								child: Padding(
									padding:
											const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
									child: Icon(
										Icons.add,
										size: 16,
										color: _quantity < widget.product.stock
												? Theme.of(context).colorScheme.onSurface
												: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.3),
									),
								),
							),
						],
					),
				),
			],
		);
	}

	Widget _buildMapSection() {
		return FutureBuilder<LatLng>(
			future: _artisanLocationFuture,
			builder: (context, snapshot) {
				final LatLng artisanLocation =
						snapshot.data ?? _getArtisanLocation(widget.product.artisanName);
				final Set<Marker> markers = <Marker>{
					Marker(
						markerId: const MarkerId('artisan-location'),
						position: artisanLocation,
						infoWindow: InfoWindow(
							title: widget.product.artisanName,
							snippet: widget.product.category,
						),
					),
				};
				if (_buyerPosition != null) {
					markers.add(
						Marker(
							markerId: const MarkerId('buyer-location'),
							position: LatLng(
								_buyerPosition!.latitude,
								_buyerPosition!.longitude,
							),
							icon: BitmapDescriptor.defaultMarkerWithHue(
								BitmapDescriptor.hueBlue,
							),
							infoWindow: const InfoWindow(title: 'Your location'),
						),
					);
				}
				final String distanceText = _calculateDistance(artisanLocation);
				return Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Divider(height: 32),
						Text(
							'Artisan Location',
							style: Theme.of(context)
									.textTheme
									.titleMedium
									?.copyWith(fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 4),
						Row(
							children: [
								Expanded(
									child: Text(
										'Made by ${widget.product.artisanName}',
										style: Theme.of(context).textTheme.bodySmall?.copyWith(
												color: Theme.of(context)
														.colorScheme
														.onSurface
														.withValues(alpha: 0.6),
										),
									),
								),
								if (_isLoadingLocation)
									const SizedBox(
										width: 14,
										height: 14,
										child: CircularProgressIndicator(strokeWidth: 2),
									)
								else if (distanceText.isNotEmpty)
									Container(
										padding: const EdgeInsets.symmetric(
											horizontal: 8,
											vertical: 3,
										),
										decoration: BoxDecoration(
											color: Theme.of(context)
													.colorScheme
													.primary
													.withValues(alpha: 0.1),
											borderRadius: BorderRadius.circular(12),
										),
										child: Row(
											mainAxisSize: MainAxisSize.min,
											children: [
												Icon(
													Icons.near_me_outlined,
													size: 12,
													color: Theme.of(context).colorScheme.primary,
												),
												const SizedBox(width: 4),
												Text(
													distanceText,
													style: Theme.of(context)
															.textTheme
															.bodySmall
															?.copyWith(
																color: Theme.of(context)
																		.colorScheme
																		.primary,
																fontWeight: FontWeight.w600,
															),
												),
											],
										),
									),
							],
						),
						const SizedBox(height: 8),
						if (_locationStatusMessage != null)
							Text(
								_locationStatusMessage!,
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.6),
								),
							),
						if (_buyerPosition == null && !_isLoadingLocation)
							Align(
								alignment: Alignment.centerLeft,
								child: TextButton.icon(
									onPressed: _fetchBuyerLocation,
									icon: const Icon(Icons.my_location_outlined, size: 16),
									label: const Text('Use my location (optional)'),
								),
							),
						const SizedBox(height: 12),
						ClipRRect(
							borderRadius: BorderRadius.circular(12),
							child: SizedBox(
								height: 200,
								child: GoogleMap(
									initialCameraPosition: CameraPosition(
										target: artisanLocation,
										zoom: 11,
									),
									markers: markers,
									zoomControlsEnabled: false,
									myLocationButtonEnabled: false,
									myLocationEnabled: false,
									scrollGesturesEnabled: false,
									zoomGesturesEnabled: false,
									rotateGesturesEnabled: false,
									tiltGesturesEnabled: false,
									liteModeEnabled: true,
								),
							),
						),
					],
				);
			},
		);
	}

	Future<void> _fetchBuyerLocation() async {
		if (!mounted) return;
		setState(() {
			_isLoadingLocation = true;
			_locationStatusMessage = null;
		});
		try {
			final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
			if (!serviceEnabled) {
				if (!mounted) return;
				setState(() {
					_isLoadingLocation = false;
					_locationStatusMessage =
							'Location is turned off. You can continue without it.';
				});
				return;
			}

			LocationPermission permission = await Geolocator.checkPermission();
			if (permission == LocationPermission.denied) {
				permission = await Geolocator.requestPermission();
			}
			if (permission == LocationPermission.denied ||
					permission == LocationPermission.deniedForever) {
				if (!mounted) return;
				setState(() {
					_isLoadingLocation = false;
					_locationStatusMessage =
							'Location not shared. Distance is hidden, but shopping continues normally.';
				});
				return;
			}

			final Position position = await Geolocator.getCurrentPosition(
				locationSettings: const LocationSettings(
					accuracy: LocationAccuracy.medium,
				),
			);

			if (!mounted) return;
			setState(() {
				_buyerPosition = position;
				_isLoadingLocation = false;
				_locationStatusMessage = null;
			});
		} catch (_) {
			if (!mounted) return;
			setState(() {
				_isLoadingLocation = false;
				_locationStatusMessage =
						'Could not get location. You can continue without it.';
			});
		}
	}

	String _calculateDistance(LatLng artisanLocation) {
		if (_buyerPosition == null) return '';
		final double distanceInMetres = Geolocator.distanceBetween(
			_buyerPosition!.latitude,
			_buyerPosition!.longitude,
			artisanLocation.latitude,
			artisanLocation.longitude,
		);
		final double distanceInKm = distanceInMetres / 1000;
		if (distanceInKm < 1) {
			return '${distanceInMetres.toStringAsFixed(0)} m away';
		}
		return '${distanceInKm.toStringAsFixed(1)} km away';
	}

	Future<void> _handleAddToCart() async {
		final CartItemModel cartItem = CartItemModel(
			productId: widget.product.id,
			title: widget.product.title,
			imageUrl: widget.product.imageUrl,
			price: widget.product.price,
			quantity: _quantity,
			artisanId: widget.product.artisanId,
			artisanName: widget.product.artisanName,
		);
		setState(() => _isAddingToCart = true);
		await Future.delayed(const Duration(milliseconds: 200));
		setState(() => _isAddingToCart = false);
		if (!mounted) return;
		context.read<CartProvider>().addItem(cartItem);
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text('${widget.product.title} added to cart.'),
				action: SnackBarAction(
					label: 'View Cart',
					onPressed: () => Navigator.push(
						context,
						MaterialPageRoute(builder: (_) => const CartScreen()),
					),
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: Text(
					widget.product.title,
					overflow: TextOverflow.ellipsis,
				),
				backgroundColor: Colors.transparent,
				elevation: 0,
				foregroundColor: Theme.of(context).colorScheme.onSurface,
			),
			body: SingleChildScrollView(
				child: Column(
					children: [
						_buildImageSection(),
						Padding(
							padding: const EdgeInsets.all(AppConstants.defaultPadding),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											Expanded(
												child: Text(
													widget.product.title,
													style:
															Theme.of(context).textTheme.headlineSmall?.copyWith(
																		fontWeight: FontWeight.bold,
																	),
												),
											),
											const SizedBox(width: 16),
											Text(
												'₹${widget.product.price.toStringAsFixed(0)}',
												style: Theme.of(context).textTheme.headlineMedium?.copyWith(
															color: Theme.of(context).colorScheme.primary,
															fontWeight: FontWeight.bold,
														),
											),
										],
									),
									const SizedBox(height: 8),
									Row(
										children: [
											Icon(
												Icons.store_outlined,
												size: 16,
												color: Theme.of(context).colorScheme.primary,
											),
											const SizedBox(width: 4),
											Text(
												widget.product.artisanName,
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: Theme.of(context).colorScheme.primary,
															fontWeight: FontWeight.w500,
														),
											),
										],
									),
									const SizedBox(height: 4),
									Container(
										padding:
												const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
										decoration: BoxDecoration(
											color: Theme.of(context)
													.colorScheme
													.primary
													.withValues(alpha: 0.08),
											borderRadius: BorderRadius.circular(12),
										),
										child: Text(
											widget.product.category,
											style: Theme.of(context).textTheme.bodySmall?.copyWith(
														color: Theme.of(context).colorScheme.primary,
													),
										),
									),
									const Divider(height: 32),
									Text(
										'About this product',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.bold,
												),
									),
									const SizedBox(height: 8),
									Text(
										widget.product.description,
										style: Theme.of(context).textTheme.bodyLarge?.copyWith(
													color: Theme.of(context)
															.colorScheme
															.onSurface
															.withValues(alpha: 0.8),
												),
									),
									const SizedBox(height: 16),
									Row(
										children: [
											Icon(
												Icons.inventory_2_outlined,
												size: 16,
												color: widget.product.stock > 0
														? Colors.green.shade700
														: Theme.of(context).colorScheme.error,
											),
											const SizedBox(width: 4),
											Text(
												widget.product.stock > 0
														? '${widget.product.stock} in stock'
														: 'Out of stock',
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: widget.product.stock > 0
																	? Colors.green.shade700
																	: Theme.of(context).colorScheme.error,
															fontWeight: FontWeight.w500,
														),
											),
										],
									),
									const Divider(height: 32),
									_buildQuantitySelector(),
									_buildMapSection(),
									_buildReviewsSection(),
									const SizedBox(height: 16),
									CustomButton(
										label: 'Add to Cart',
										onPressed: widget.product.stock > 0 && !_isAddingToCart
												? _handleAddToCart
												: null,
										isLoading: _isAddingToCart,
									),
									const SizedBox(height: 32),
								],
							),
						),
					],
				),
			),
		);
	}
}

class _ReviewCard extends StatelessWidget {
	final ReviewModel review;

	const _ReviewCard({required this.review});

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Expanded(
							child: Text(
								review.buyerName,
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(
										fontWeight: FontWeight.w600,
								),
							),
						),
						const SizedBox(width: 8),
						Row(
							children: List.generate(5, (index) {
								return Icon(
									index < review.rating.round()
											? Icons.star_rounded
											: Icons.star_outline_rounded,
									color: Colors.amber.shade600,
									size: 16,
								);
							}),
						),
					],
				),
				const SizedBox(height: 4),
				Text(
					review.comment,
					style: Theme.of(context).textTheme.bodyMedium?.copyWith(
							color: Theme.of(context)
									.colorScheme
									.onSurface
									.withValues(alpha: 0.8),
					),
				),
			],
		);
	}
}
