import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rent_badge.dart';

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

  Future<void> _toggleLike(dynamic post) async {
    final isLiked = post['is_liked'] ?? false;
    final postId = post['id'];
    try {
      final response = await _apiService.post(
        '${ApiConstants.communityPosts}$postId/${isLiked ? 'unlike' : 'like'}/',
        {},
      );
      if (response.statusCode == 200) {
        _fetchPosts(); // Refresh to get updated like status and count
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _postController, 
                label: 'What\'s on your mind?', 
                hint: 'Share something with your society...', 
                maxLines: 4, 
                prefixIcon: Icons.edit_note,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MediaPickerButton(icon: Icons.image, label: 'Photo', color: Colors.green, onTap: () {}),
                  const SizedBox(width: 12),
                  _MediaPickerButton(icon: Icons.videocam, label: 'Video', color: Colors.red, onTap: () {}),
                  const SizedBox(width: 12),
                  _MediaPickerButton(icon: Icons.attach_file, label: 'File', color: Colors.blue, onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Publish Post',
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
                      const SnackBar(content: Text('Post published to society!'), backgroundColor: Colors.green),
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
              Text('Comments (${comments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (comments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('No comments yet. Be the first to reply!', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final c = comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryLight, 
                              child: Text('${c['author_name']?[0] ?? 'U'}', style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(c['author_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(width: 4),
                                            RentBadge(isRenter: c['is_renter'] ?? false, fontSize: 8),
                                          ],
                                        ),
                                        if (c['author_wing'] != null)
                                          Text('${c['author_wing']}-${c['author_unit']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c['content'] ?? '', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      decoration: const InputDecoration(hintText: 'Write a comment...', border: InputBorder.none),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Community Feed'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? const Center(child: Text('No discussions yet. Start a conversation!', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final isLiked = post['is_liked'] ?? false;
                      final likesCount = post['likes_count'] ?? 0;
                      final comments = (post['comments'] as List?) ?? [];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryLight,
                                    child: Text('${post['author_name']?[0] ?? 'U'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(post['author_name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(width: 4),
                                            RentBadge(isRenter: post['is_renter'] ?? false),
                                            if (post['author_wing'] != null) ...[
                                              const SizedBox(width: 4),
                                              const Text('•', style: TextStyle(color: Colors.grey)),
                                              const SizedBox(width: 4),
                                              Text('${post['author_wing']}-${post['author_unit']}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                          ],
                                        ),
                                        Text(post['created_at']?.substring(0, 10) ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  if (post['is_pinned'] == true)
                                    const Icon(Icons.push_pin, size: 18, color: Colors.orange),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Text(post['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4)),
                            ),
                            
                            // Mock Media (Rich Aesthetics)
                            if (post['image'] != null || post['content'].toString().length % 5 == 0) ...[
                               const SizedBox(height: 12),
                               Container(
                                 height: 200,
                                 width: double.infinity,
                                 margin: const EdgeInsets.symmetric(horizontal: 12),
                                 decoration: BoxDecoration(
                                   color: Colors.grey[200],
                                   borderRadius: BorderRadius.circular(12),
                                   image: const DecorationImage(
                                     image: NetworkImage('https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80&w=1000'),
                                     fit: BoxFit.cover,
                                   ),
                                 ),
                               ),
                            ],

                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  if (likesCount > 0) ...[
                                    const Icon(Icons.thumb_up, size: 14, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text('$likesCount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                  const Spacer(),
                                  if (comments.isNotEmpty)
                                    Text('${comments.length} comments', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Divider(height: 24),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _toggleLike(post),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 20, color: isLiked ? Colors.blue : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Like', style: TextStyle(color: isLiked ? Colors.blue : Colors.grey, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showComments(post),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('Comment', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewPostSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaPickerButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
