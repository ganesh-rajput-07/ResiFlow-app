import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime? _birthdate;
  List<dynamic> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        if (data['birthdate'] != null) {
          _birthdate = DateTime.tryParse(data['birthdate']);
        }
        _familyMembers = data['family_members'] ?? [];
        
        // Update user in provider
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).updateUser(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final response = await _apiService.patch(
        ApiConstants.profile,
        {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'username': _usernameController.text,
          'phone': _phoneController.text,
          'birthdate': _birthdate != null ? DateFormat('yyyy-MM-dd').format(_birthdate!) : null,
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green));
        _fetchProfile();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryDark,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
      });
    }
  }

  void _showAddFamilyMemberDialog([dynamic member]) {
    final isEdit = member != null;
    final nameController = TextEditingController(text: isEdit ? member['name'] : '');
    DateTime? dob = isEdit && member['birthdate'] != null ? DateTime.tryParse(member['birthdate']) : null;
    
    final predefinedRelations = ['Spouse', 'Child', 'Parent', 'Sibling', 'Other'];
    String? selectedRelation = isEdit ? (predefinedRelations.contains(member['relation']) ? member['relation'] : 'Other') : 'Spouse';
    final customRelationController = TextEditingController(
      text: isEdit && !predefinedRelations.contains(member['relation']) ? member['relation'] : ''
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Family Member' : 'Add Family Member', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  CustomTextField(controller: nameController, label: 'Name', hint: 'Full Name'),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: dob ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => dob = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Birthdate', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                      child: Text(dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : 'Select Birthdate'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRelation,
                    decoration: const InputDecoration(labelText: 'Relation', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                    items: predefinedRelations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setModalState(() => selectedRelation = val),
                  ),
                  if (selectedRelation == 'Other') ...[
                    const SizedBox(height: 16),
                    CustomTextField(controller: customRelationController, label: 'Custom Relation', hint: 'e.g. Grandparent'),
                  ],
                  const SizedBox(height: 24),
                  CustomButton(
                    text: isEdit ? 'Save Changes' : 'Add Member',
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      final finalRelation = selectedRelation == 'Other' ? customRelationController.text.trim() : selectedRelation;
                      if (finalRelation == null || finalRelation.isEmpty) return;

                      final payload = {
                        'name': nameController.text.trim(),
                        'birthdate': dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : null,
                        'relation': finalRelation,
                      };

                      try {
                        if (isEdit) {
                          await _apiService.put('${ApiConstants.baseUrl}/accounts/family-members/${member['id']}/', payload);
                        } else {
                          await _apiService.post('${ApiConstants.baseUrl}/accounts/family-members/', payload);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchProfile();
                        }
                      } catch (e) {
                        debugPrint('Error saving family member: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _deleteFamilyMember(int id) async {
    try {
      await _apiService.delete('${ApiConstants.baseUrl}/accounts/family-members/$id/');
      _fetchProfile();
    } catch (e) {
      debugPrint('Error deleting family member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final age = _calculateAge(_birthdate);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resident Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryDark,
                      child: Text(
                        (_firstNameController.text.isNotEmpty ? _firstNameController.text[0].toUpperCase() : 'U'),
                        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user?['society_name'] != null)
                      Text(user!['society_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryDark)),
                    if (user?['unit_number'] != null)
                      Text('Unit: ${user!['unit_number']}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _firstNameController, label: 'First Name', hint: 'First Name')),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _lastNameController, label: 'Last Name', hint: 'Last Name')),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _usernameController, label: 'Username', hint: 'Username', prefixIcon: Icons.alternate_email, enabled: false),
              const SizedBox(height: 16),
              CustomTextField(controller: _phoneController, label: 'Phone Number', hint: 'Phone Number', prefixIcon: Icons.phone),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_birthdate != null ? DateFormat('yyyy-MM-dd').format(_birthdate!) : 'Select your birthdate'),
                      if (age != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text('$age yrs', style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Save Profile', onPressed: _saveProfile, isLoading: _isSaving),
              
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Family Members', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton.icon(
                    onPressed: () => _showAddFamilyMemberDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  )
                ],
              ),
              if (_familyMembers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No family members added yet.', style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = _familyMembers[index];
                    final memberDob = member['birthdate'] != null ? DateTime.tryParse(member['birthdate']) : null;
                    final memberAge = _calculateAge(memberDob);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Row(
                          children: [
                            Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (memberAge != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text('($memberAge yrs)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                          ],
                        ),
                        subtitle: Text(member['relation']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _showAddFamilyMemberDialog(member)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteFamilyMember(member['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
