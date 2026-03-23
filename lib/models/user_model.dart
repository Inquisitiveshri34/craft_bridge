import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
	final String uid;
	final String email;
	final String displayName;
	final String role;
	final String photoUrl;
	final String bio;
	final bool isApproved;
	final Timestamp createdAt;

	const UserModel({
		required this.uid,
		required this.email,
		required this.displayName,
		required this.role,
		required this.photoUrl,
		required this.bio,
		required this.isApproved,
		required this.createdAt,
	});

	factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
				uid: map['uid'] as String,
				email: map['email'] as String,
				displayName: map['displayName'] as String,
				role: map['role'] as String,
				photoUrl: map['photoUrl'] as String? ?? '',
				bio: map['bio'] as String? ?? '',
				isApproved: map['isApproved'] as bool? ?? false,
				createdAt: map['createdAt'] as Timestamp,
			);

	Map<String, dynamic> toMap() => {
				'uid': uid,
				'email': email,
				'displayName': displayName,
				'role': role,
				'photoUrl': photoUrl,
				'bio': bio,
				'isApproved': isApproved,
				'createdAt': createdAt,
			};

	UserModel copyWith({
		String? uid,
		String? email,
		String? displayName,
		String? role,
		String? photoUrl,
		String? bio,
		bool? isApproved,
		Timestamp? createdAt,
	}) =>
			UserModel(
				uid: uid ?? this.uid,
				email: email ?? this.email,
				displayName: displayName ?? this.displayName,
				role: role ?? this.role,
				photoUrl: photoUrl ?? this.photoUrl,
				bio: bio ?? this.bio,
				isApproved: isApproved ?? this.isApproved,
				createdAt: createdAt ?? this.createdAt,
			);
}
