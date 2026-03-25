import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/product_model.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/services/storage_service.dart';
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
	File? _selectedImageFile;
	bool _isUploadingImage = false;
	bool _isDirty = false;
	String? _uploadedImageUrl;
	bool _imageRemoved = false;

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
			_uploadedImageUrl = product.imageUrl.isNotEmpty ? product.imageUrl : null;
		}
		_addDirtyListeners();
	}

	void _addDirtyListeners() {
		_titleController.addListener(_markDirty);
		_descriptionController.addListener(_markDirty);
		_priceController.addListener(_markDirty);
		_stockController.addListener(_markDirty);
	}

	void _markDirty() {
		if (!_isDirty) {
			setState(() => _isDirty = true);
		}
	}

	@override
	void dispose() {
		_titleController.removeListener(_markDirty);
		_descriptionController.removeListener(_markDirty);
		_priceController.removeListener(_markDirty);
		_stockController.removeListener(_markDirty);
		_titleController.dispose();
		_descriptionController.dispose();
		_priceController.dispose();
		_stockController.dispose();
		super.dispose();
	}

	Future<void> _handleSubmit() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() => _isLoading = true);

		try {
			String? imageUrl = _uploadedImageUrl;
			final String? artisanId = context.read<AuthProvider>().currentUser?.uid;
			if (artisanId == null) {
				setState(() {
					_isLoading = false;
					_isUploadingImage = false;
				});
				if (!mounted) return;
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Error: user not authenticated.')),
				);
				return;
			}

			if (_selectedImageFile != null) {
				setState(() => _isUploadingImage = true);
				if (_isEditMode &&
						_uploadedImageUrl != null &&
						_uploadedImageUrl!.isNotEmpty) {
					imageUrl = await StorageService().updateProductImage(
						_selectedImageFile!,
						artisanId,
						_uploadedImageUrl!,
					);
				} else {
					imageUrl = await StorageService().uploadProductImage(
						_selectedImageFile!,
						artisanId,
					);
				}
				if (!mounted) return;
				setState(() {
					_uploadedImageUrl = imageUrl;
					_imageRemoved = false;
					_isUploadingImage = false;
				});
			} else if (_imageRemoved &&
					_isEditMode &&
					_uploadedImageUrl != null &&
					_uploadedImageUrl!.isNotEmpty) {
				await StorageService().deleteProductImage(_uploadedImageUrl!);
				imageUrl = '';
				_uploadedImageUrl = null;
			}
			if (!mounted) return;

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
							imageUrl: imageUrl ?? widget.product!.imageUrl,
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
							imageUrl: imageUrl ?? '',
							category: _selectedCategory!,
							stock: stock,
							isActive: _isActive,
							createdAt: Timestamp.now(),
						);

			await productProvider.addOrUpdateProduct(model: model, isEdit: _isEditMode);
			if (!mounted) return;
			setState(() {
				_isLoading = false;
				_isDirty = false;
			});

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
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_isLoading = false;
				_isUploadingImage = false;
			});
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Upload failed: $e')),
			);
		}
	}

	Future<void> _pickImage() async {
		try {
			final XFile? pickedFile = await ImagePicker().pickImage(
				source: ImageSource.gallery,
				maxWidth: 1024,
				maxHeight: 1024,
				imageQuality: 85,
			);
			if (pickedFile == null) return;

			setState(() {
				_selectedImageFile = File(pickedFile.path);
				_isDirty = true;
			});
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Could not open image picker: $e')),
			);
		}
	}

	void _removeImage() {
		setState(() {
			_selectedImageFile = null;
			_imageRemoved = true;
			_isDirty = true;
		});
	}

	Widget _buildImageSection() {
		if (_selectedImageFile != null) {
			return Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					ClipRRect(
						borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
						child: Image.file(
							_selectedImageFile!,
							height: 200,
							width: double.infinity,
							fit: BoxFit.cover,
						),
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Expanded(
								child: OutlinedButton.icon(
									onPressed: _isUploadingImage ? null : _pickImage,
									icon: const Icon(Icons.edit_outlined, size: 16),
									label: const Text('Change Image'),
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: OutlinedButton.icon(
									onPressed: _isUploadingImage ? null : _removeImage,
									icon: Icon(
										Icons.delete_outline,
										size: 16,
										color: Theme.of(context).colorScheme.error,
									),
									label: Text(
										'Remove',
										style: TextStyle(
											color: Theme.of(context).colorScheme.error,
										),
									),
								),
							),
						],
					),
					if (_isUploadingImage) ...[
						const SizedBox(height: 8),
						const LinearProgressIndicator(),
						const SizedBox(height: 4),
						Text(
							'Uploading image...',
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.5),
								),
							textAlign: TextAlign.center,
						),
					],
				],
			);
		}

		if (_uploadedImageUrl != null && !_imageRemoved) {
			return Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					ClipRRect(
						borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
						child: Image.network(
							_uploadedImageUrl!,
							height: 200,
							width: double.infinity,
							fit: BoxFit.cover,
							loadingBuilder: (context, child, loadingProgress) {
								if (loadingProgress == null) return child;
								return SizedBox(
									height: 200,
									child: Center(
										child: CircularProgressIndicator(
											strokeWidth: 2,
											value: loadingProgress.expectedTotalBytes != null
													? loadingProgress.cumulativeBytesLoaded /
															loadingProgress.expectedTotalBytes!
													: null,
										),
									),
								);
							},
							errorBuilder: (_, __, ___) => Container(
								height: 200,
								color: Theme.of(context).colorScheme.primary.withValues(
									alpha: 0.08,
								),
								child: Center(
									child: Icon(
										Icons.broken_image_outlined,
										size: 48,
										color: Theme.of(context)
												.colorScheme
												.primary
												.withValues(alpha: 0.4),
									),
								),
							),
						),
					),
					const SizedBox(height: 8),
					Row(
						children: [
							Expanded(
								child: OutlinedButton.icon(
									onPressed: _pickImage,
									icon: const Icon(Icons.edit_outlined, size: 16),
									label: const Text('Change Image'),
								),
							),
							const SizedBox(width: 8),
							Expanded(
								child: OutlinedButton.icon(
									onPressed: _removeImage,
									icon: Icon(
										Icons.delete_outline,
										size: 16,
										color: Theme.of(context).colorScheme.error,
									),
									label: Text(
										'Remove',
										style: TextStyle(
											color: Theme.of(context).colorScheme.error,
										),
									),
								),
							),
						],
					),
				],
			);
		}

		return GestureDetector(
			onTap: _pickImage,
			child: Container(
				height: 180,
				width: double.infinity,
				decoration: BoxDecoration(
					color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
					borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
					border: Border.all(
						color: Theme.of(context).colorScheme.outline,
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
									color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.5),
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
				_markDirty();
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
		return PopScope(
			canPop: !_isDirty,
			onPopInvokedWithResult: (bool didPop, Object? result) async {
				if (didPop) return;
				final NavigatorState navigator = Navigator.of(context);
				final bool? shouldPop = await showDialog<bool>(
					context: context,
					builder: (ctx) => AlertDialog(
						title: const Text('Discard Changes?'),
						content: const Text(
							'You have unsaved changes. Are you sure you want to leave?',
						),
						actions: [
							TextButton(
								onPressed: () => Navigator.pop(ctx, false),
								child: const Text('Keep Editing'),
							),
							TextButton(
								onPressed: () => Navigator.pop(ctx, true),
								style: TextButton.styleFrom(
									foregroundColor: Theme.of(ctx).colorScheme.error,
								),
								child: const Text('Discard'),
							),
						],
					),
				);

				if (shouldPop == true && mounted) {
					navigator.pop();
				}
			},
			child: Scaffold(
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
									_buildImageSection(),
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
											_markDirty();
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
			),
		);
	}
}
