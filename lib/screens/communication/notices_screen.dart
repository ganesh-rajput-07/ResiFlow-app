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
        final data = jsonDecode(response.body);
        setState(() {
          _notices = data is List ? data : (data['results'] ?? []);
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
              const Text('Broadcast New Notice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _titleController, label: 'Notice Title', hint: 'e.g. Water Cut Tomorrow'),
              const SizedBox(height: 12),
              CustomTextField(controller: _contentController, label: 'Details', hint: 'Provide notice contents...', maxLines: 4),
              const SizedBox(height: 16),
              Row(
                children: [
                   _MediaPickerButton(icon: Icons.image, label: 'Banner', color: Colors.indigo, onTap: () {}),
                   const SizedBox(width: 12),
                   _MediaPickerButton(icon: Icons.attach_file, label: 'PDF/Doc', color: Colors.orange, onTap: () {}),
                ],
              ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Official Notices'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _notices.isEmpty 
          ? const Center(child: Text("No notices broadcasted yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    border: const Border(left: BorderSide(color: Colors.redAccent, width: 5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Image if exists
                      if (notice['image'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(notice['image'], height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.campaign, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(notice['title'] ?? 'Notice', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(notice['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(notice['created_at']?.substring(0, 10) ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text('By: ${notice['created_by_name'] ?? 'Admin'}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: _showAddNoticeSheet,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Notice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
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
