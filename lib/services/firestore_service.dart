import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/models/review_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

class FirestoreService {
	// ignore: unused_field
	final FirebaseFirestore _db = FirebaseFirestore.instance;

	// UnimplementedError marker for locked PR07 stub count verification.

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
		throw UnimplementedError('addProduct not yet implemented');
	}

	Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
		throw UnimplementedError('updateProduct not yet implemented');
	}

	Future<void> deleteProduct(String productId) async {
		throw UnimplementedError('deleteProduct not yet implemented');
	}

	// ── Order Methods ── implemented in PR33 ─────────────────────

	Future<void> createOrder(OrderModel order) async {
		throw UnimplementedError('createOrder not yet implemented');
	}

	Future<void> updateOrderStatus(String orderId, String status) async {
		throw UnimplementedError('updateOrderStatus not yet implemented');
	}

	// ── Order Stream Methods ── implemented in PR34 ───────────────

	Stream<List<OrderModel>> getOrdersByArtisan(String artisanId) {
		throw UnimplementedError('getOrdersByArtisan not yet implemented');
	}

	Stream<List<OrderModel>> getOrdersByBuyer(String buyerId) {
		throw UnimplementedError('getOrdersByBuyer not yet implemented');
	}

	Stream<List<OrderModel>> getAllOrders() {
		throw UnimplementedError('getAllOrders not yet implemented');
	}

	// ── Review Methods ── implemented in PR44 ────────────────────

	Future<void> addReview(ReviewModel review) async {
		throw UnimplementedError('addReview not yet implemented');
	}

	Stream<List<ReviewModel>> getReviewsByProduct(String productId) {
		throw UnimplementedError('getReviewsByProduct not yet implemented');
	}

	// ── Admin Methods ── implemented in PR48 ─────────────────────

	Future<List<UserModel>> getPendingArtisans() async {
		throw UnimplementedError('getPendingArtisans not yet implemented');
	}
}
