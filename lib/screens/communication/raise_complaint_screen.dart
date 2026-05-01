import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<dynamic> _myComplaints = [];
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchMyComplaints();
  }

  Future<void> _fetchMyComplaints() async {
    setState(() => _isFetching = true);
    try {
      final response = await _apiService.get(ApiConstants.complaints);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _myComplaints = data is List ? data : (data['results'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _showRaiseComplaintDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raise New Complaint', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextField(controller: _titleController, label: 'Subject', hint: 'e.g. Water Leakage'),
              const SizedBox(height: 12),
              CustomTextField(controller: _descController, label: 'Description', hint: 'Describe the issue...', maxLines: 4),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Submit Ticket',
                isLoading: _isLoading,
                onPressed: () async {
                  if (_titleController.text.isEmpty || _descController.text.isEmpty) return;
                  setModalState(() => _isLoading = true);
                  try {
                    final response = await _apiService.post(ApiConstants.complaints, {
                      'title': _titleController.text,
                      'description': _descController.text,
                    });
                    if (response.statusCode == 201) {
                      _titleController.clear();
                      _descController.clear();
                      Navigator.pop(context);
                      _fetchMyComplaints();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint registered successfully')));
                    }
                  } catch (e) {
                    debugPrint('Error: $e');
                  } finally {
                    setModalState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : _myComplaints.isEmpty
              ? const Center(child: Text('No complaints raised yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myComplaints.length,
                  itemBuilder: (context, index) {
                    final c = _myComplaints[index];
                    final statusColor = c['status'] == 'resolved' ? Colors.green : (c['status'] == 'in_progress' ? Colors.orange : Colors.blue);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(c['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c['description']),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(c['status'].toString().toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRaiseComplaintDialog,
        icon: const Icon(Icons.add_comment),
        label: const Text('Raise Ticket'),
      ),
    );
  }
}
