import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  final ApiService _apiService = ApiService();
  final _postController = TextEditingController();
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.communityPosts);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _posts = data is List ? data : (data['results'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _postController, label: 'What\'s on your mind?', hint: 'Write your post...', maxLines: 4, prefixIcon: Icons.edit),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Post to Community',
                onPressed: () async {
                  if (_postController.text.isEmpty) return;
                  final response = await _apiService.post(ApiConstants.communityPosts, {
                    'content': _postController.text,
                  });

                  if (response.statusCode == 201 && mounted) {
                    _postController.clear();
                    Navigator.pop(ctx);
                    _fetchPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post published!'), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showComments(dynamic post) {
    final commentController = TextEditingController();
    final comments = (post['comments'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comments (${comments.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (comments.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No comments yet.', style: TextStyle(color: Colors.grey)))
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: AppTheme.primaryLight, child: Text('${c['author_name']?[0] ?? 'U'}')),
                        title: Text(c['author_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(c['content'] ?? ''),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: () async {
                      if (commentController.text.isEmpty) return;
                      await _apiService.post(ApiConstants.communityComments, {
                        'post': post['id'],
                        'content': commentController.text,
                      });
                      Navigator.pop(ctx);
                      _fetchPosts();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Discussions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('No discussions yet. Start a conversation!', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final comments = (post['comments'] as List?) ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text('${post['author_name']?[0] ?? 'U'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(post['author_name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(post['created_at']?.substring(0, 10) ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (post['is_pinned'] == true)
                                  const Icon(Icons.push_pin, size: 16, color: Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(post['content'] ?? '', style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 16),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showComments(post),
                                  icon: const Icon(Icons.comment_outlined, size: 18),
                                  label: Text('Comments (${comments.length})'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPostSheet,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
