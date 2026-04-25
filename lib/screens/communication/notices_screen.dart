import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.notices);
      if (response.statusCode == 200) {
        setState(() {
          _notices = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching notices: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddNoticeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Notice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _titleController, label: 'Notice Title', hint: 'e.g. Water Cut Tomorrow'),
              const SizedBox(height: 12),
              CustomTextField(controller: _contentController, label: 'Details', hint: 'Provide notice contents...', maxLines: 4),
              const SizedBox(height: 24),
              CustomButton(text: 'Publish Notice', onPressed: () async {
                final success = await _apiService.post(ApiConstants.notices, {
                  'title': _titleController.text,
                  'content': _contentController.text,
                });
                if (success.statusCode == 201 && mounted) {
                  _titleController.clear();
                  _contentController.clear();
                  Navigator.pop(context);
                  _fetchNotices(); // refresh list
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice Broadcasted!'), backgroundColor: Colors.green));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to publish notice.'), backgroundColor: Colors.red));
                }
              }),
              const SizedBox(height: 32),
            ]
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?['role'] == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _notices.isEmpty 
          ? const Center(child: Text("No notices broadcasted yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(notice['title'] ?? 'Notice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(notice['content'] ?? ''),
                        const SizedBox(height: 12),
                        Text('Published by: ${notice['created_by_name'] ?? 'Admin'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: _showAddNoticeSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('New Notice', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }
}
