import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/widgets/custom_button.dart';
import 'package:craft_bridge/widgets/custom_text_field.dart';

class AddEditProductScreen extends StatefulWidget {
	final ProductModel? product;

	const AddEditProductScreen({super.key, this.product});

	@override
	State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	final TextEditingController _titleController = TextEditingController();
	final TextEditingController _descriptionController = TextEditingController();
	final TextEditingController _priceController = TextEditingController();
	final TextEditingController _stockController = TextEditingController();

	String? _selectedCategory;
	bool _isActive = true;
	bool _isLoading = false;

	bool get _isEditMode => widget.product != null;

	@override
	void initState() {
		super.initState();
		if (_isEditMode) {
			final ProductModel product = widget.product!;
			_titleController.text = product.title;
			_descriptionController.text = product.description;
			_priceController.text = product.price.toStringAsFixed(0);
			_stockController.text = product.stock.toString();
			_selectedCategory = product.category;
			_isActive = product.isActive;
		}
	}

	@override
	void dispose() {
		_titleController.dispose();
		_descriptionController.dispose();
		_priceController.dispose();
		_stockController.dispose();
		super.dispose();
	}

	Future<void> _handleSubmit() async {
		if (!_formKey.currentState!.validate()) return;

		final ProductProvider productProvider = context.read<ProductProvider>();
		final String trimmedTitle = _titleController.text.trim();
		final String trimmedDescription = _descriptionController.text.trim();
		final double price = double.parse(_priceController.text.trim());
		final int stock = int.parse(_stockController.text.trim());

		final ProductModel model = _isEditMode
				? widget.product!.copyWith(
						title: trimmedTitle,
						description: trimmedDescription,
						price: price,
						category: _selectedCategory,
						stock: stock,
						isActive: _isActive,
					)
				: ProductModel(
						id: '',
						artisanId: '',
						artisanName: '',
						title: trimmedTitle,
						description: trimmedDescription,
						price: price,
						imageUrl: '',
						category: _selectedCategory!,
						stock: stock,
						isActive: _isActive,
						createdAt: Timestamp.now(),
					);

		setState(() => _isLoading = true);
		await productProvider.addOrUpdateProduct(model: model, isEdit: _isEditMode);
		if (!mounted) return;
		setState(() => _isLoading = false);

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text(
					_isEditMode
							? 'Product updated successfully.'
							: 'Product added successfully.',
				),
			),
		);

		Navigator.of(context).pop();
	}

	Widget _buildImagePlaceholder() {
		return GestureDetector(
			onTap: () {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(
						content: Text('Image picker — implemented in PR21'),
					),
				);
			},
			child: Container(
				height: 180,
				width: double.infinity,
				decoration: BoxDecoration(
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
					borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
					border: Border.all(
						color: Theme.of(context).colorScheme.outline,
						style: BorderStyle.solid,
					),
				),
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(
							Icons.add_photo_alternate_outlined,
							size: 48,
							color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
						),
						const SizedBox(height: 8),
						Text(
							'Tap to add product image',
							style: Theme.of(context).textTheme.bodyMedium?.copyWith(
										color:
												Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
									),
						),
						const SizedBox(height: 4),
						Text(
							'(Image picker wired in PR21)',
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.35),
									),
						),
					],
				),
			),
		);
	}

	Widget _buildCategoryDropdown() {
		return DropdownButtonFormField<String>(
			initialValue: _selectedCategory,
			decoration: const InputDecoration(
				labelText: 'Category',
				hintText: 'Select a category',
			),
			items: AppConstants.productCategories
					.map(
						(String category) => DropdownMenuItem<String>(
							value: category,
							child: Text(category),
						),
					)
					.toList(),
			onChanged: (String? value) {
				setState(() => _selectedCategory = value);
			},
			validator: (String? value) {
				if (value == null || value.isEmpty) {
					return 'Please select a category.';
				}
				return null;
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
			),
			body: SafeArea(
				child: SingleChildScrollView(
					child: Padding(
						padding: const EdgeInsets.all(AppConstants.defaultPadding),
						child: Form(
							key: _formKey,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Text(
										'Product Image',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.bold,
												),
									),
									const SizedBox(height: 8),
									_buildImagePlaceholder(),
									const SizedBox(height: 24),
									Text(
										'Product Details',
										style: Theme.of(context).textTheme.titleMedium?.copyWith(
													fontWeight: FontWeight.bold,
												),
									),
									const SizedBox(height: 12),
									CustomTextField(
										label: 'Title',
										hint: 'e.g. Hand-painted Ceramic Vase',
										controller: _titleController,
										textCapitalization: TextCapitalization.sentences,
										validator: (String? value) {
											if (value == null || value.trim().isEmpty) {
												return 'Title is required.';
											}
											if (value.trim().length < 3) {
												return 'Title must be at least 3 characters.';
											}
											return null;
										},
									),
									const SizedBox(height: 16),
									CustomTextField(
										label: 'Description',
										hint: 'Describe your product — materials, dimensions, story',
										controller: _descriptionController,
										maxLines: 4,
										textCapitalization: TextCapitalization.sentences,
										validator: (String? value) {
											if (value == null || value.trim().isEmpty) {
												return 'Description is required.';
											}
											if (value.trim().length < 10) {
												return 'Description must be at least 10 characters.';
											}
											return null;
										},
									),
									const SizedBox(height: 16),
									Row(
										children: [
											Expanded(
												child: CustomTextField(
													label: 'Price (₹)',
													hint: '0',
													controller: _priceController,
													keyboardType: TextInputType.number,
													validator: (String? value) {
														if (value == null || value.trim().isEmpty) {
															return 'Price is required.';
														}
														final double? price =
																double.tryParse(value.trim());
														if (price == null) {
															return 'Enter a valid number.';
														}
														if (price <= 0) {
															return 'Price must be greater than 0.';
														}
														return null;
													},
												),
											),
											const SizedBox(width: 12),
											Expanded(
												child: CustomTextField(
													label: 'Stock',
													hint: '0',
													controller: _stockController,
													keyboardType: TextInputType.number,
													validator: (String? value) {
														if (value == null || value.trim().isEmpty) {
															return 'Stock is required.';
														}
														final int? stock = int.tryParse(value.trim());
														if (stock == null) {
															return 'Enter a whole number.';
														}
														if (stock < 0) {
															return 'Stock cannot be negative.';
														}
														return null;
													},
												),
											),
										],
									),
									const SizedBox(height: 16),
									_buildCategoryDropdown(),
									const SizedBox(height: 16),
									SwitchListTile(
										value: _isActive,
										title: const Text('Product is active'),
										contentPadding: EdgeInsets.zero,
										onChanged: (bool value) {
											setState(() => _isActive = value);
										},
									),
									const SizedBox(height: 24),
									CustomButton(
										label: _isEditMode ? 'Update Product' : 'Add Product',
										onPressed: _isLoading ? null : _handleSubmit,
										isLoading: _isLoading,
									),
									const SizedBox(height: 24),
								],
							),
						),
					),
				),
			),
		);
	}
}
