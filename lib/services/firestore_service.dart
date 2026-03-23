import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/models/review_model.dart';

class FirestoreService {
	// ignore: unused_field
	final FirebaseFirestore _db = FirebaseFirestore.instance;

	// UnimplementedError marker for locked PR07 stub count verification.

	// ── User Methods ── implemented in PR10 ──────────────────────

	Future<void> createUser(UserModel user) async {
		throw UnimplementedError('createUser not yet implemented');
	}

	Future<UserModel?> getUser(String uid) async {
		throw UnimplementedError('getUser not yet implemented');
	}

	Future<void> updateUser(String uid, Map<String, dynamic> data) async {
		throw UnimplementedError('updateUser not yet implemented');
	}

	Future<List<UserModel>> getAllUsers() async {
		throw UnimplementedError('getAllUsers not yet implemented');
	}

	Future<void> updateUserApproval(String uid, bool isApproved) async {
		throw UnimplementedError('updateUserApproval not yet implemented');
	}

	// ── Product Read Methods ── implemented in PR26 ───────────────

	Stream<List<ProductModel>> getProducts() {
		throw UnimplementedError('getProducts not yet implemented');
	}

	Stream<List<ProductModel>> getProductsByArtisan(String artisanId) {
		throw UnimplementedError('getProductsByArtisan not yet implemented');
	}

	Future<ProductModel?> getProductById(String productId) async {
		throw UnimplementedError('getProductById not yet implemented');
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
