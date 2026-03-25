import 'package:flutter/material.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/models/user_model.dart';
import 'package:craft_bridge/services/firestore_service.dart';
import 'package:craft_bridge/widgets/order_card.dart';

class ManageUsersScreen extends StatefulWidget {
	const ManageUsersScreen({super.key});

	@override
	State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
	final FirestoreService _firestoreService = FirestoreService();
	List<UserModel> _users = <UserModel>[];
	bool _isLoading = false;
	String? _errorMessage;

	@override
	void initState() {
		super.initState();
		_loadUsers();
	}

	Future<void> _loadUsers() async {
		setState(() {
			_isLoading = true;
			_errorMessage = null;
		});
		try {
			final List<UserModel> users = await _firestoreService.getAllUsers();
			users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
			if (!mounted) return;
			setState(() {
				_users = users;
				_isLoading = false;
			});
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_errorMessage = 'Failed to load users: $e';
				_isLoading = false;
			});
		}
	}

	Future<void> _handleApprove(String uid) async {
		try {
			await _firestoreService.updateUserApproval(uid, true);
			if (!mounted) return;
			setState(() {
				_users = _users
						.map((u) => u.uid == uid ? u.copyWith(isApproved: true) : u)
						.toList();
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Artisan approved.')),
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to approve artisan: $e')),
			);
		}
	}

	Future<void> _handleReject(String uid) async {
		final bool? confirm = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Reject Artisan'),
				content: const Text('Are you sure you want to reject this registration?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx, false),
						child: const Text('Cancel'),
					),
					TextButton(
						onPressed: () => Navigator.pop(ctx, true),
						style: TextButton.styleFrom(
							foregroundColor: Theme.of(context).colorScheme.error,
						),
						child: const Text('Reject'),
					),
				],
			),
		);
		if (confirm != true || !mounted) return;

		try {
			await _firestoreService.updateUserApproval(uid, false);
			if (!mounted) return;
			setState(() {
				_users = _users
						.map((u) => u.uid == uid ? u.copyWith(isApproved: false) : u)
						.toList();
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Registration rejected.')),
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to reject: $e')),
			);
		}
	}

	Widget _buildBody() {
		if (_isLoading) {
			return const LoadingWidget();
		}
		if (_errorMessage != null) {
			return AppErrorWidget(
				message: _errorMessage!,
				onRetry: _loadUsers,
			);
		}
		if (_users.isEmpty) {
			return const EmptyStateWidget(
				icon: Icons.people_outline,
				title: 'No users found',
				subtitle: 'User accounts will appear here once registered.',
			);
		}

		return ListView.separated(
			padding: const EdgeInsets.all(AppConstants.defaultPadding),
			itemCount: _users.length,
			separatorBuilder: (_, __) => const SizedBox(height: 8),
			itemBuilder: (context, index) {
				final UserModel user = _users[index];
				return _ArtisanApprovalCard(
					user: user,
					onApprove: () => _handleApprove(user.uid),
					onReject: () => _handleReject(user.uid),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Theme.of(context).colorScheme.surface,
			appBar: AppBar(
				title: const Text('Manage Users'),
				actions: [
					IconButton(
						icon: const Icon(Icons.refresh),
						tooltip: 'Refresh',
						onPressed: _loadUsers,
					),
				],
			),
			body: _buildBody(),
		);
	}
}

class _ArtisanApprovalCard extends StatelessWidget {
	final UserModel user;
	final VoidCallback onApprove;
	final VoidCallback onReject;

	const _ArtisanApprovalCard({
		required this.user,
		required this.onApprove,
		required this.onReject,
	});

	@override
	Widget build(BuildContext context) {
		final bool isArtisan = user.role == AppConstants.roleArtisan;
		final bool isPending = isArtisan && !user.isApproved;

		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Row(
							children: [
								CircleAvatar(
									backgroundColor: Theme.of(context)
											.colorScheme
											.primary
											.withValues(alpha: 0.15),
									child: Text(
										user.displayName.isNotEmpty
												? user.displayName[0].toUpperCase()
												: '?',
										style: TextStyle(
											color: Theme.of(context).colorScheme.primary,
											fontWeight: FontWeight.bold,
										),
									),
								),
								const SizedBox(width: 12),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												user.displayName,
												style: Theme.of(context)
														.textTheme
														.titleSmall
														?.copyWith(fontWeight: FontWeight.bold),
											),
											Text(
												user.email,
												style: Theme.of(context).textTheme.bodySmall?.copyWith(
															color: Theme.of(context)
																	.colorScheme
																	.onSurface
																	.withValues(alpha: 0.6),
														),
											),
										],
									),
								),
								Container(
									padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
									decoration: BoxDecoration(
										color: isPending
												? Colors.orange.shade100
												: user.isApproved
														? Colors.green.shade100
														: Colors.grey.shade200,
										borderRadius: BorderRadius.circular(12),
									),
									child: Text(
										isPending
												? 'Pending'
												: user.isApproved
														? 'Approved'
														: 'Rejected',
										style: TextStyle(
											fontSize: 11,
											fontWeight: FontWeight.w600,
											color: isPending
													? Colors.orange.shade800
													: user.isApproved
															? Colors.green.shade800
															: Colors.grey.shade700,
										),
									),
								),
							],
						),
						const SizedBox(height: 8),
						Text(
							'Role: ${user.role}',
							style: Theme.of(context).textTheme.bodySmall?.copyWith(
										color: Theme.of(context)
												.colorScheme
												.onSurface
												.withValues(alpha: 0.75),
									),
						),
						if (user.bio.isNotEmpty) ...[
							const SizedBox(height: 8),
							Text(
								user.bio,
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
											color: Theme.of(context)
													.colorScheme
													.onSurface
													.withValues(alpha: 0.7),
										),
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
							),
						],
						if (isArtisan) ...[
							const SizedBox(height: 12),
							Row(
								children: [
									Expanded(
										child: OutlinedButton(
											onPressed: onReject,
											style: OutlinedButton.styleFrom(
												foregroundColor: Theme.of(context).colorScheme.error,
												side: BorderSide(color: Theme.of(context).colorScheme.error),
											),
											child: const Text('Reject'),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: ElevatedButton(
											onPressed: onApprove,
											child: const Text('Approve'),
										),
									),
								],
							),
						],
					],
				),
			),
		);
	}
}
