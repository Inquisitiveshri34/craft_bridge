import 'dart:io';
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
	// ignore: unused_field
	final FirebaseStorage _storage = FirebaseStorage.instance;
	final StreamController<double> _uploadProgressController =
			StreamController<double>.broadcast();

	Stream<double> get uploadProgressStream => _uploadProgressController.stream;

	// ── Storage Methods ── implemented in PR24 ───────────────────

	Future<String> uploadProductImage(File imageFile, String artisanId) async {
		final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
		final Reference ref = _storage
				.ref()
				.child('products')
				.child(artisanId)
				.child(fileName);
		final UploadTask uploadTask = ref.putFile(
			imageFile,
			SettableMetadata(contentType: 'image/jpeg'),
		);
		_uploadProgressController.add(0.0);
		uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
			if (snapshot.totalBytes <= 0) return;
			final double progress =
					snapshot.bytesTransferred / snapshot.totalBytes;
			_uploadProgressController.add(progress.clamp(0.0, 1.0));
		});
		await uploadTask;
		_uploadProgressController.add(1.0);
		final String downloadUrl = await ref.getDownloadURL();
		return downloadUrl;
	}

	// ── Storage Methods ── implemented in PR27 ───────────────────

	Future<String> updateProductImage(
		File newImageFile,
		String artisanId,
		String oldImageUrl,
	) async {
		await deleteProductImage(oldImageUrl);
		final String newDownloadUrl =
				await uploadProductImage(newImageFile, artisanId);
		return newDownloadUrl;
	}

	Future<void> deleteProductImage(String imageUrl) async {
		if (imageUrl.isEmpty) return;
		try {
			final Reference ref = _storage.refFromURL(imageUrl);
			await ref.delete();
		} on FirebaseException catch (e) {
			if (e.code == 'object-not-found') {
				return;
			}
			rethrow;
		}
	}
}
