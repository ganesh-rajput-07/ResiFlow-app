import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/pre_approval.dart';
import '../../providers/auth_provider.dart';
import '../../utils/pdf_generator.dart';
import '../../models/pre_approval.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PreApprovalScreen extends StatefulWidget {
  const PreApprovalScreen({super.key});

  @override
  State<PreApprovalScreen> createState() => _PreApprovalScreenState();
}

class _PreApprovalScreenState extends State<PreApprovalScreen> {
  final ApiService _apiService = ApiService();
  List<PreApproval> _approvals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.preApprovals);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? List.from(decoded) : List.from(decoded['results'] ?? []);
        setState(() {
          _approvals = data.map((json) => PreApproval.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRequest(int id) async {
    try {
      final response = await _apiService.delete('${ApiConstants.preApprovals}$id/');
      if (response.statusCode == 204) {
        _fetchApprovals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request deleted successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting request: $e');
    }
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreatePreApprovalForm(),
      ),
    ).then((_) => _fetchApprovals());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gate Passes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchApprovals),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _approvals.isEmpty
              ? const Center(child: Text('You have no gate pass requests.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _approvals.length,
                  itemBuilder: (context, index) {
                    final approval = _approvals[index];
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
                                Expanded(child: Text(approval.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                _StatusBadge(status: approval.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Phone: ${approval.mobile}', style: const TextStyle(color: Colors.grey)),
                            if (approval.purpose != null) Text('Purpose: ${approval.purpose}'),
                            Text('Valid: ${approval.validFrom} to ${approval.validTo}'),
                            if (approval.status == 'rejected') ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _deleteRequest(approval.id!),
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ] else if (approval.status == 'approved' && approval.passId != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final provider = Provider.of<AuthProvider>(context, listen: false);
                                      await PdfGenerator.generateAndShareGatePass(
                                        visitorName: approval.visitorName,
                                        validFrom: approval.validFrom,
                                        validTo: approval.validTo,
                                        purpose: approval.purpose ?? 'Visitor',
                                        passId: approval.passId!,
                                        societyName: provider.user?['society_name'] ?? 'ResiFlow Society',
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error generating PDF: $e')),
                                      );
                                      debugPrint('PDF Error: $e');
                                    }
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                                  label: const Text('View & Share Pass'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBottomSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 'approved') color = Colors.green;
    else if (status == 'rejected') color = Colors.red;
    else color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CreatePreApprovalForm extends StatefulWidget {
  const _CreatePreApprovalForm();

  @override
  State<_CreatePreApprovalForm> createState() => _CreatePreApprovalFormState();
}

class _CreatePreApprovalFormState extends State<_CreatePreApprovalForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _personsController = TextEditingController(text: '1');
  
  String _purpose = 'personal';
  
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validTo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
          if (_validTo.isBefore(_validFrom)) {
            _validTo = _validFrom.add(const Duration(days: 1));
          }
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final req = PreApproval(
        visitorName: _nameController.text,
        mobile: _phoneController.text,
        purpose: _purpose,
        numberOfPersons: int.tryParse(_personsController.text) ?? 1,
        validFrom: DateFormat('yyyy-MM-dd').format(_validFrom),
        validTo: DateFormat('yyyy-MM-dd').format(_validTo),
      );

      final response = await _apiService.post(ApiConstants.preApprovals, req.toJson());

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pre-approval request submitted successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit. Please try again.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Pre-Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _nameController, label: 'Visitor Name', hint: 'Enter full name', prefixIcon: Icons.person_outline),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController, label: 'Phone Number', hint: '10-digit mobile number',
              keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 24),
            const Text('Visit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                 Expanded(child: _buildDateSelector('Valid From', _validFrom, () => _selectDate(context, true))),
                const SizedBox(width: 16),
                Expanded(child: _buildDateSelector('Valid To', _validTo, () => _selectDate(context, false))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _purpose,
                    decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                    items: const [
                      DropdownMenuItem(value: 'personal', child: Text('Personal')),
                      DropdownMenuItem(value: 'official', child: Text('Official')),
                      DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _purpose = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: CustomTextField(controller: _personsController, label: 'Persons', hint: '1', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(text: 'Submit Request', onPressed: _submitRequest, isLoading: _isLoading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontSize: 13)),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
