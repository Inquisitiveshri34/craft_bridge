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
		final StreamSubscription<TaskSnapshot> progressSubscription =
				uploadTask.snapshotEvents.listen(
			(snapshot) {
				if (snapshot.totalBytes <= 0) return;
				final double progress =
						snapshot.bytesTransferred / snapshot.totalBytes;
				_uploadProgressController.add(progress.clamp(0.0, 1.0));
			},
			onError: (_) {
				// uploadTask await below handles the actual failure path.
			},
		);

		try {
			final TaskSnapshot snapshot = await uploadTask;
			_uploadProgressController.add(1.0);
			return await snapshot.ref.getDownloadURL();
		} on FirebaseException catch (e) {
			if (e.code == 'canceled' || e.code == 'object-not-found') {
				throw FirebaseException(
					plugin: 'firebase_storage',
					code: e.code,
					message: 'Image upload failed. Please choose the image again.',
				);
			}
			rethrow;
		} finally {
			await progressSubscription.cancel();
		}
	}

	// ── Storage Methods ── implemented in PR27 ───────────────────

	Future<String> updateProductImage(
		File newImageFile,
		String artisanId,
		String oldImageUrl,
	) async {
		try {
			await deleteProductImage(oldImageUrl);
		} on FirebaseException catch (e) {
			if (e.code != 'object-not-found') {
				rethrow;
			}
		}
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
