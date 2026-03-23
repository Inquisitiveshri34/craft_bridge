import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
	// ignore: unused_field
	final FirebaseStorage _storage = FirebaseStorage.instance;

	// ── Storage Methods ── implemented in PR24 ───────────────────

	Future<String> uploadProductImage(File imageFile, String artisanId) async {
		throw UnimplementedError('uploadProductImage not yet implemented');
	}

	// ── Storage Methods ── implemented in PR27 ───────────────────

	Future<String> updateProductImage(
		File newImageFile,
		String artisanId,
		String oldImageUrl,
	) async {
		throw UnimplementedError('updateProductImage not yet implemented');
	}

	Future<void> deleteProductImage(String imageUrl) async {
		throw UnimplementedError('deleteProductImage not yet implemented');
	}
}
