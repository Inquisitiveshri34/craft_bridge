class AppConstants {
  // App identity
  static const String appName = 'CraftBridge';
  static const String appTagline = 'Digital storefront for local artisans';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleArtisan = 'artisan';
  static const String roleBuyer = 'buyer';

  // Order statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Product categories
  static const List<String> productCategories = [
    'Pottery',
    'Textiles',
    'Jewellery',
    'Woodwork',
    'Paintings',
    'Leather',
    'Other',
  ];

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 8.0;
}
