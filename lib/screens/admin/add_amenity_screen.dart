import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddAmenityScreen extends StatefulWidget {
  const AddAmenityScreen({super.key});

  @override
  State<AddAmenityScreen> createState() => _AddAmenityScreenState();
}

class _AddAmenityScreenState extends State<AddAmenityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timingsController = TextEditingController();
  final _caretakerNameController = TextEditingController();
  final _caretakerPhoneController = TextEditingController();
  
  String _selectedCategory = 'other';
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  final List<Map<String, String>> _categories = [
    {'value': 'gym', 'label': 'Gym'},
    {'value': 'pool', 'label': 'Swimming Pool'},
    {'value': 'garden', 'label': 'Garden'},
    {'value': 'clubhouse', 'label': 'Clubhouse'},
    {'value': 'playground', 'label': 'Playground'},
    {'value': 'parking', 'label': 'Parking'},
    {'value': 'hall', 'label': 'Community Hall'},
    {'value': 'library', 'label': 'Library'},
    {'value': 'sports', 'label': 'Sports Facility'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _submitAmenity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConstants.amenities,
        {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'timings': _timingsController.text.trim(),
          'caretaker_name': _caretakerNameController.text.trim(),
          'caretaker_phone': _caretakerPhoneController.text.trim(),
        },
      );

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amenity added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return true to trigger refresh
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add amenity: ${response.body}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Amenity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(controller: _nameController, label: 'Amenity Name *', hint: 'e.g. Grand Swimming Pool'),
              const SizedBox(height: 16),
              const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['value'],
                        child: Text(cat['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: _descriptionController, label: 'Description', hint: 'Optional rules or details', maxLines: 3),
              const SizedBox(height: 16),
              CustomTextField(controller: _locationController, label: 'Location', hint: 'e.g. Ground Floor, Wing A'),
              const SizedBox(height: 16),
              CustomTextField(controller: _timingsController, label: 'Timings', hint: 'e.g. 6:00 AM - 10:00 PM'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: _caretakerNameController, label: 'Caretaker Name', hint: 'Optional')),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(controller: _caretakerPhoneController, label: 'Caretaker Phone', hint: 'Optional')),
                ],
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Save Amenity',
                onPressed: _submitAmenity,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
