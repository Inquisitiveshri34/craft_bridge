import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/models/review_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class FirestoreService {
	// ignore: unused_field
	final FirebaseFirestore _db = FirebaseFirestore.instance;

	// Legacy PR07 stub marker comment.

	// ── User Methods ── implemented in PR10 ──────────────────────

	Future<void> createUser(UserModel user) async {
		await _db
			.collection(AppConstants.usersCollection)
			.doc(user.uid)
			.set(user.toMap());
	}

	Future<UserModel?> getUser(String uid) async {
		final DocumentSnapshot doc = await _db
			.collection(AppConstants.usersCollection)
			.doc(uid)
			.get();
		if (!doc.exists) return null;
		return UserModel.fromMap(doc.data() as Map<String, dynamic>);
	}

	Future<void> updateUser(String uid, Map<String, dynamic> data) async {
		await _db
			.collection(AppConstants.usersCollection)
			.doc(uid)
			.update(data);
	}

	Future<List<UserModel>> getAllUsers() async {
		final QuerySnapshot snapshot =
				await _db.collection(AppConstants.usersCollection).get();
		return snapshot.docs
			.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
			.toList();
	}

	Future<void> updateUserApproval(String uid, bool isApproved) async {
		await _db
			.collection(AppConstants.usersCollection)
			.doc(uid)
			.update({'isApproved': isApproved});
	}

	// ── Product Read Methods ── implemented in PR26 ───────────────

	Stream<List<ProductModel>> getProducts() {
		return _db
				.collection(AppConstants.productsCollection)
				.where('isActive', isEqualTo: true)
				.snapshots()
				.map(
					(snapshot) => snapshot.docs
							.map((doc) => ProductModel.fromMap(doc.data()))
							.toList(),
				);
	}

	Stream<List<ProductModel>> getProductsByArtisan(String artisanId) {
		return _db
				.collection(AppConstants.productsCollection)
				.where('artisanId', isEqualTo: artisanId)
				.snapshots()
				.map(
					(snapshot) => snapshot.docs
							.map((doc) => ProductModel.fromMap(doc.data()))
							.toList(),
				);
	}

	Future<ProductModel?> getProductById(String productId) async {
		final DocumentSnapshot doc = await _db
				.collection(AppConstants.productsCollection)
				.doc(productId)
				.get();
		if (!doc.exists) return null;
		return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
	}

	// ── Product Write Methods ── implemented in PR31 ──────────────

	Future<void> addProduct(ProductModel product) async {
		await _db
				.collection(AppConstants.productsCollection)
				.doc(product.id)
				.set(product.toMap());
	}

	Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
		await _db
				.collection(AppConstants.productsCollection)
				.doc(productId)
				.update(data);
	}

	Future<void> deleteProduct(String productId) async {
		await _db
				.collection(AppConstants.productsCollection)
				.doc(productId)
				.delete();
	}

	// ── Order Methods ── implemented in PR33 ─────────────────────

	Future<void> createOrder(OrderModel order) async {
		await _db
				.collection(AppConstants.ordersCollection)
				.doc(order.id)
				.set(order.toMap());
	}

	Future<void> updateOrderStatus(String orderId, String status) async {
		await _db
				.collection(AppConstants.ordersCollection)
				.doc(orderId)
				.update({'status': status});
	}

	// ── Order Stream Methods ── implemented in PR34 ───────────────

	Stream<List<OrderModel>> getOrdersByArtisan(String artisanId) {
		return _db
				.collection(AppConstants.ordersCollection)
				.where('artisanId', isEqualTo: artisanId)
				.snapshots()
				.map(
					(snapshot) {
						final List<OrderModel> orders = snapshot.docs
								.map((doc) => OrderModel.fromMap(doc.data()))
								.toList();
						orders.sort(
							(a, b) => b.createdAt.compareTo(a.createdAt),
						);
						return orders;
					},
				);
	}

	Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
		return _db
				.collection(AppConstants.ordersCollection)
				.where('buyerId', isEqualTo: buyerId)
				.snapshots()
				.map(
					(snapshot) {
						final List<OrderModel> orders = snapshot.docs
								.map((doc) => OrderModel.fromMap(doc.data()))
								.toList();
						orders.sort(
							(a, b) => b.createdAt.compareTo(a.createdAt),
						);
						return orders;
					},
				);
	}

	Stream<List<OrderModel>> getAllOrders() {
		return _db
				.collection(AppConstants.ordersCollection)
				.orderBy('createdAt', descending: true)
				.snapshots()
				.map(
					(snapshot) => snapshot.docs
							.map((doc) => OrderModel.fromMap(doc.data()))
							.toList(),
				);
	}

	// ── Review Methods ── implemented in PR44 ────────────────────

	Future<void> addReview(ReviewModel review) async {
		await _db
				.collection(AppConstants.reviewsCollection)
				.doc(review.id)
				.set(review.toMap());
	}

	Stream<List<ReviewModel>> getReviewsByProduct(String productId) {
		return _db
				.collection(AppConstants.reviewsCollection)
				.where('productId', isEqualTo: productId)
				.orderBy('createdAt', descending: true)
				.snapshots()
				.map(
					(snapshot) => snapshot.docs
							.map((doc) => ReviewModel.fromMap(doc.data()))
							.toList(),
				);
	}

	// ── Admin Methods ── implemented in PR48 ─────────────────────

	Future<List<UserModel>> getPendingArtisans() async {
		final QuerySnapshot snapshot = await _db
				.collection(AppConstants.usersCollection)
				.where('role', isEqualTo: AppConstants.roleArtisan)
				.where('isApproved', isEqualTo: false)
				.get();
		return snapshot.docs
				.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
				.toList();
	}
}
