import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
	final FirestoreService _firestoreService = FirestoreService();

	List<OrderModel> _artisanOrders = <OrderModel>[];
	List<OrderModel> _buyerOrders = <OrderModel>[];
	bool _isLoading = false;
	String? _errorMessage;
	StreamSubscription<List<OrderModel>>? _buyerOrdersSubscription;

	List<OrderModel> get artisanOrders => List<OrderModel>.unmodifiable(_artisanOrders);
	List<OrderModel> get buyerOrders => List<OrderModel>.unmodifiable(_buyerOrders);
	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

	Stream<List<OrderModel>> watchOrdersForArtisan(String artisanId) {
		return _firestoreService.getOrdersByArtisan(artisanId);
	}

	Stream<List<OrderModel>> watchOrdersForBuyer(String buyerId) {
		return _firestoreService.getOrdersByBuyer(buyerId);
	}

	Future<void> fetchOrdersForArtisan(String artisanId) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			_artisanOrders = await _firestoreService.getOrdersByArtisan(artisanId).first;
		} on UnimplementedError {
			_artisanOrders = <OrderModel>[];
			_errorMessage = 'Orders stream will be wired in PR34.';
		} catch (e) {
			_errorMessage = 'Failed to load orders: $e';
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	Future<void> fetchOrdersForBuyer(String buyerId) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			_buyerOrders = await _firestoreService.getOrdersByBuyer(buyerId).first;
		} catch (e) {
			_errorMessage = 'Failed to load your orders: $e';
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	void listenToBuyerOrders(String buyerId) {
		_buyerOrdersSubscription?.cancel();
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		_buyerOrdersSubscription = _firestoreService.getOrdersByBuyer(buyerId).listen(
			(orderList) {
				_buyerOrders = orderList;
				_isLoading = false;
				_errorMessage = null;
				notifyListeners();
			},
			onError: (Object error) {
				_errorMessage = 'Failed to load your orders: $error';
				_isLoading = false;
				notifyListeners();
			},
		);
	}

	Future<bool> createOrder({
		required String buyerId,
		required String buyerName,
		required String productId,
		required String productTitle,
		required String productImageUrl,
		required String artisanId,
		required String artisanName,
		required double price,
		required int quantity,
	}) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();

		try {
			final String orderId = FirebaseFirestore.instance
					.collection(AppConstants.ordersCollection)
					.doc()
					.id;
			final OrderModel order = OrderModel(
				id: orderId,
				buyerId: buyerId,
				buyerName: buyerName,
				artisanId: artisanId,
				artisanName: artisanName,
				productId: productId,
				productTitle: productTitle,
				productImageUrl: productImageUrl,
				quantity: quantity,
				totalPrice: price * quantity,
				status: AppConstants.statusPending,
				createdAt: Timestamp.now(),
			);
			await _firestoreService.createOrder(order);
			_artisanOrders = <OrderModel>[order, ..._artisanOrders];
			_isLoading = false;
			notifyListeners();
			return true;
		} catch (e) {
			_errorMessage = 'Failed to place order: $e';
			_isLoading = false;
			notifyListeners();
			return false;
		}
	}

	Future<bool> updateOrderStatus(String orderId, String newStatus) async {
		const Set<String> validStatuses = <String>{
			'pending',
			'confirmed',
			'shipped',
			'delivered',
			'cancelled',
		};

		if (!validStatuses.contains(newStatus)) {
			_errorMessage = 'Invalid order status: $newStatus';
			notifyListeners();
			return false;
		}

		try {
			await _firestoreService.updateOrderStatus(orderId, newStatus);
			_errorMessage = null;
			return true;
		} catch (e) {
			_errorMessage = 'Failed to update order status: $e';
			notifyListeners();
			return false;
		}
	}

	void clearError() {
		_errorMessage = null;
		notifyListeners();
	}

	@override
	void dispose() {
		_buyerOrdersSubscription?.cancel();
		super.dispose();
	}
}
