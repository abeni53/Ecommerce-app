import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../products/presentation/providers/wishlist_provider.dart';
import '../../../../core/widgets/failure_view.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => FailureView(error: err),
        data: (user) {
          if (user == null) {
            // NOT LOGGED IN
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'You are not logged in.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign In or Register'),
                  ),
                ],
              ),
            );
          }

          // LOGGED IN
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple.withAlpha(50),
                    child: Text(
                      user.email[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Member since 2026',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 48),

                // Account Stats (Mock)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('Orders', '12'),
                    GestureDetector(
                      onTap: () => context.push('/wishlist'),
                      child: _buildStatCol(
                        'Wishlist',
                        ref.watch(wishlistProvider).length.toString(),
                      ),
                    ),
                    _buildStatCol('Reviews', '3'),
                  ],
                ),

                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('My Wishlist'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/wishlist'),
                ),

                const Spacer(),

                // Logout Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // Call the logout method on our notifier
                    ref.read(authProvider.notifier).logout();

                    // Show a nice snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully logged out.')),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
