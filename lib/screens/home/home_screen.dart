import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/post_card.dart';
import '../../services/post_service.dart';
import '../../utils/errors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/responsive_page.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostService>().fetchPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.campaign_rounded,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      body: ResponsivePage(
        child: Consumer<PostService>(
          builder: (context, service, _) {
            if (service.isLoading && service.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (service.error != null && service.posts.isEmpty) {
              return ErrorRetry(
                message: translateSupabaseError(service.error!),
                onRetry: service.fetchPosts,
              );
            }
            if (service.posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: service.fetchPosts,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'لا توجد منشورات بعد',
                  subtitle: 'كن أول من يشارك تجربته مع فرقة الكشافة التاسعة',
                  action: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('أول منشور'),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: service.fetchPosts,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: service.posts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return PostCard(post: service.posts[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}