import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/core/theme/app_theme.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/screens/buyer/buyer_orders_screen.dart';
import 'package:craft_bridge/screens/buyer/cart_screen.dart';
import 'package:craft_bridge/screens/buyer/product_detail_screen.dart';
import 'package:craft_bridge/widgets/order_card.dart';
import 'package:craft_bridge/widgets/product_card.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 0;
  double _contentOpacity = 0.0;

  PageRouteBuilder<void> _buildProductDetailRoute(
    ProductModel product,
  ) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => ProductDetailScreen(
        product: product,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const Offset begin = Offset(1.0, 0.0);
        const Offset end = Offset.zero;
        final Animatable<Offset> tween = Tween<Offset>(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().listenToProducts();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _contentOpacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
        8,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductProvider>().searchProducts('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          context.read<ProductProvider>().searchProducts(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    final List<String> categories = ['All', ...AppConstants.productCategories];
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        final String selectedCategory = productProvider.filterCategory;
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final String category = categories[index];
              final bool isSelected = selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  context.read<ProductProvider>().filterByCategory(category);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSortDropdown() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            8,
            AppConstants.defaultPadding,
            8,
          ),
          child: Row(
            children: [
              Text(
                'Sort by',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: productProvider.sortField,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.inputBorderRadius,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'createdAt_desc',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'createdAt_asc',
                      child: Text('Oldest'),
                    ),
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Price: High to Low'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<ProductProvider>().sortProducts(value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const LoadingWidget();
        }
        if (productProvider.errorMessage != null) {
          return AppErrorWidget(
            message: productProvider.errorMessage!,
            onRetry: () {
              productProvider.clearError();
              productProvider.listenToProducts();
            },
          );
        }

        final List<ProductModel> products = productProvider.filteredProducts;
        if (products.isEmpty) {
          return _buildEmptyState();
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth < 600 ? 2 : 3;

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final ProductModel product = products[index];
            return ProductCard(
              productId: product.id,
              title: product.title,
              price: product.price,
              imageUrl: product.imageUrl,
              artisanName: product.artisanName,
              category: product.category,
              isActive: product.isActive,
              onTap: () => Navigator.push(
                context,
                _buildProductDetailRoute(product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No products found',
      subtitle: 'Try a different search or category.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = _currentNavIndex == 0
        ? 'Discover'
        : _currentNavIndex == 1
            ? 'My Cart'
            : 'My Orders';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (_currentNavIndex == 0)
            Consumer<ThemeProvider>(
              builder: (_, themeProvider, __) => IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
            ),
          if (_currentNavIndex == 0)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () => context.read<AuthProvider>().signOut(),
            ),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return AnimatedScale(
                  scale: cartProvider.itemCount > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: FloatingActionButton.extended(
                    onPressed: () => setState(() => _currentNavIndex = 1),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      '${cartProvider.itemCount} item${cartProvider.itemCount == 1 ? '' : 's'}',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          AnimatedOpacity(
            opacity: _contentOpacity,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeIn,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildCategoryChips(),
                _buildSortDropdown(),
                Expanded(
                  child: _buildProductGrid(),
                ),
              ],
            ),
          ),
          const CartScreen(),
          const BuyerOrdersScreen(),
        ],
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          return BottomNavigationBar(
            currentIndex: _currentNavIndex,
            onTap: (index) => setState(() => _currentNavIndex = index),
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cartProvider.itemCount > 0,
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      '${cartProvider.itemCount}',
                      key: ValueKey<int>(cartProvider.itemCount),
                    ),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: cartProvider.itemCount > 0,
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      '${cartProvider.itemCount}',
                      key: ValueKey<int>(cartProvider.itemCount),
                    ),
                  ),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
            ],
          );
        },
      ),
    );
  }
}
