import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
import 'package:craft_bridge/services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
	final FirestoreService _firestoreService = FirestoreService();
	final StorageService _storageService = StorageService();
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

	Future<bool> addProduct(ProductModel product) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();
		try {
			final String productId = product.id.isEmpty
					? FirebaseFirestore.instance
							.collection(AppConstants.productsCollection)
							.doc()
							.id
					: product.id;
			final ProductModel payload = product.copyWith(
				id: productId,
				createdAt: product.createdAt,
			);
			await _firestoreService.addProduct(payload);

			_artisanProducts = [payload, ..._artisanProducts];
			if (payload.isActive) {
				_products = [payload, ..._products];
			}

			_isLoading = false;
			notifyListeners();
			return true;
		} catch (e) {
			_errorMessage = 'Failed to add product: $e';
			_isLoading = false;
			notifyListeners();
			return false;
		}
	}

	Future<bool> updateProduct(ProductModel product) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();
		try {
			await _firestoreService.updateProduct(product.id, product.toMap());

			final int artisanIndex =
					_artisanProducts.indexWhere((p) => p.id == product.id);
			if (artisanIndex != -1) {
				_artisanProducts[artisanIndex] = product;
			}

			final int allIndex = _products.indexWhere((p) => p.id == product.id);
			if (product.isActive) {
				if (allIndex != -1) {
					_products[allIndex] = product;
				} else {
					_products = [product, ..._products];
				}
			} else if (allIndex != -1) {
				_products.removeAt(allIndex);
			}

			_isLoading = false;
			notifyListeners();
			return true;
		} catch (e) {
			_errorMessage = 'Failed to update product: $e';
			_isLoading = false;
			notifyListeners();
			return false;
		}
	}

	Future<bool> deleteProduct(String productId) async {
		_isLoading = true;
		_errorMessage = null;
		notifyListeners();
		try {
			final ProductModel? existing =
					_artisanProducts.cast<ProductModel?>().firstWhere(
							(product) => product?.id == productId,
							orElse: () => null,
						);
			final String imageUrl = existing?.imageUrl ?? '';

			await _firestoreService.deleteProduct(productId);
			if (imageUrl.isNotEmpty) {
				await _storageService.deleteProductImage(imageUrl);
			}

			_artisanProducts.removeWhere((p) => p.id == productId);
			_products.removeWhere((p) => p.id == productId);

			_isLoading = false;
			notifyListeners();
			return true;
		} catch (e) {
			_errorMessage = 'Failed to delete product: $e';
			_isLoading = false;
			notifyListeners();
			return false;
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
