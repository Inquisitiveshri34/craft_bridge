import 'package:flutter/foundation.dart';
import 'package:craft_bridge/models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
	final Map<String, CartItemModel> _items = <String, CartItemModel>{};

	List<CartItemModel> get items =>
			List<CartItemModel>.unmodifiable(_items.values.toList());

	int get itemCount =>
			_items.values.fold(0, (int sum, CartItemModel item) => sum + item.quantity);

	double get totalPrice => _items.values
			.fold(0.0, (double sum, CartItemModel item) => sum + item.totalPrice);

	bool get isEmpty => _items.isEmpty;

	int get uniqueItemCount => _items.length;

	void addItem(CartItemModel item) {
		if (_items.containsKey(item.productId)) {
			final CartItemModel existing = _items[item.productId]!;
			_items[item.productId] = existing.copyWith(
				quantity: existing.quantity + item.quantity,
			);
		} else {
			_items[item.productId] = item;
		}
		notifyListeners();
	}

	void removeItem(String productId) {
		_items.remove(productId);
		notifyListeners();
	}

	void updateQuantity(String productId, int quantity) {
		if (!_items.containsKey(productId)) return;
		if (quantity <= 0) {
			_items.remove(productId);
		} else {
			_items[productId] = _items[productId]!.copyWith(quantity: quantity);
		}
		notifyListeners();
	}

	void clearCart() {
		_items.clear();
		notifyListeners();
	}

	bool containsProduct(String productId) {
		return _items.containsKey(productId);
	}

	int getItemQuantity(String productId) {
		return _items[productId]?.quantity ?? 0;
	}
}
