import 'package:flutter/material.dart';

class AddEditProductScreen extends StatelessWidget {
	const AddEditProductScreen({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Add Product')),
			body: const Center(
				child: Text('AddEditProductScreen — implemented in PR20'),
			),
		);
	}
}
