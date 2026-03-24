import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
	final FirestoreService _firestoreService = FirestoreService();
	List<ProductModel> _products = [];
	List<ProductModel> _artisanProducts = [];
	bool _isLoading = false;
	String? _errorMessage;
	StreamSubscription<List<ProductModel>>? _productsSubscription;
	StreamSubscription<List<ProductModel>>? _artisanSubscription;

	List<Map<String, dynamic>> get products =>
			List.unmodifiable(_products.map((product) => product.toMap()).toList());
	List<Map<String, dynamic>> get artisanProducts => List.unmodifiable(
			_artisanProducts.map((product) => product.toMap()).toList(),
		);
	bool get isLoading => _isLoading;
	String? get errorMessage => _errorMessage;

	void listenToProducts() {
		_productsSubscription?.cancel();
		_isLoading = true;
		notifyListeners();
		_productsSubscription = _firestoreService.getProducts().listen(
			(productList) {
				_products = productList;
				_isLoading = false;
				_errorMessage = null;
				notifyListeners();
			},
			onError: (Object error) {
				_errorMessage = 'Failed to load products: $error';
				_isLoading = false;
				notifyListeners();
			},
		);
	}

	void listenToArtisanProducts(String artisanId) {
		_artisanSubscription?.cancel();
		_isLoading = true;
		notifyListeners();
		_artisanSubscription = _firestoreService.getProductsByArtisan(artisanId).listen(
			(productList) {
				_artisanProducts = productList;
				_isLoading = false;
				_errorMessage = null;
				notifyListeners();
			},
			onError: (Object error) {
				_errorMessage = 'Failed to load your products: $error';
				_isLoading = false;
				notifyListeners();
			},
		);
	}

	Future<ProductModel?> getProductById(String productId) async {
		try {
			return await _firestoreService.getProductById(productId);
		} catch (e) {
			_errorMessage = 'Failed to load product: $e';
			notifyListeners();
			return null;
		}
	}

	void clearError() {
		_errorMessage = null;
		notifyListeners();
	}

	Future<void> addOrUpdateProduct({
		required ProductModel model,
		required bool isEdit,
	}) async {
		if (isEdit) {
			final int index = _artisanProducts.indexWhere((p) => p.id == model.id);
			if (index != -1) {
				_artisanProducts[index] = model;
			}
			final int allIndex = _products.indexWhere((p) => p.id == model.id);
			if (allIndex != -1) {
				_products[allIndex] = model;
			}
		} else {
			final ProductModel newModel = model.copyWith(
				id: DateTime.now().millisecondsSinceEpoch.toString(),
			);
			_artisanProducts.insert(0, newModel);
			if (newModel.isActive) {
				_products.insert(0, newModel);
			}
		}
		notifyListeners();
	}

	Future<void> removeProduct(String productId) async {
		_products.removeWhere((p) => p.id == productId);
		_artisanProducts.removeWhere((p) => p.id == productId);
		notifyListeners();
	}

	ProductModel toProductModel(Map<String, dynamic> map) {
		return ProductModel.fromMap(map);
	}

	@override
	void dispose() {
		_productsSubscription?.cancel();
		_artisanSubscription?.cancel();
		super.dispose();
	}
}
