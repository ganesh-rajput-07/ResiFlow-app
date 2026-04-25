import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
              CustomButton(text: 'Publish Notice', onPressed: () {
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice Broadcasted!')));
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
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
                      const Flexible(
                        child: Text('Annual Maintenance Meeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('IMPORTANT', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Please gather around the main clubhouse at 5 PM on Sunday to discuss the painting budget.'),
                  const SizedBox(height: 12),
                  const Text('Published by: Secretary • 12 Oct', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
