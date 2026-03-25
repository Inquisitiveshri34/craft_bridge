import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/order_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';

class OrderProvider extends ChangeNotifier {
	final FirestoreService _firestoreService = FirestoreService();

	List<OrderModel> _artisanOrders = <OrderModel>[];
	bool _isLoading = false;
	String? _errorMessage;

	List<OrderModel> get artisanOrders => List<OrderModel>.unmodifiable(_artisanOrders);
	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

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

	void clearError() {
		_errorMessage = null;
		notifyListeners();
	}
}
