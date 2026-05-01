import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && mounted) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submitDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.multipartRequest(
        ApiConstants.documents,
        'POST',
        {
          'title': _titleController.text.trim(),
        },
        fileField: 'file',
        filePath: _selectedFile!.path, // This works on mobile/desktop. For web, we need bytes.
        fileBytes: _selectedFile!.bytes,
        fileName: _selectedFile!.name,
      );

      if (response.statusCode == 201 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Return true to trigger refresh
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload document: ${response.statusCode}'), backgroundColor: Colors.red));
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
      appBar: AppBar(title: const Text('Upload Document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(controller: _titleController, label: 'Document Title *', hint: 'e.g. Society Rules 2024'),
              const SizedBox(height: 24),
              const Text('File *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    border: Border.all(color: AppTheme.primaryColor, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle : Icons.upload_file,
                        size: 48,
                        color: _selectedFile != null ? Colors.green : AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'Tap to select a file',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('PDF, DOC, JPG, PNG allowed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Upload Document',
                onPressed: _submitDocument,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
