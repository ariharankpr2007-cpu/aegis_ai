import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _disasterType = 'Flood';
  File? _selectedImage;
  bool _isScanning = false;

  static const _types = <String>[
    'Flood',
    'Fire',
    'Earthquake',
    'Cyclone',
    'Landslide',
    'Road Accident',
    'Building Collapse',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image == null || !mounted) return;
    setState(() => _selectedImage = File(image.path));
  }

  Future<void> _scanWithAi() async {
    if (_selectedImage == null) {
      _showMessage('Choose a photo before starting AI Scan.');
      return;
    }
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isScanning = false);
    _showMessage('AI Scan is ready for backend integration.');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final preferences = await SharedPreferences.getInstance();
    final reports = preferences.getStringList('aegis_reports') ?? <String>[];
    reports.insert(
      0,
      jsonEncode({
        'type': _disasterType,
        'description': _descriptionController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    await preferences.setStringList('aegis_reports', reports);
    if (!mounted) return;
    _showMessage('Disaster report submitted successfully.');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Disaster'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Share what happened',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('Your report helps responders assess the situation.'),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _disasterType,
                decoration: const InputDecoration(
                  labelText: 'Disaster type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _disasterType = value ?? _disasterType),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a short description.' : null,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the location, danger, and people affected.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 78),
                    child: Icon(Icons.notes_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _PhotoPreview(image: _selectedImage),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isScanning ? null : _scanWithAi,
                icon: _isScanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.psychology_outlined),
                label: Text(_isScanning ? 'Scanning…' : 'AI Scan'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.image});
  final File? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: image == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 45, color: Colors.black45),
                  SizedBox(height: 8),
                  Text('Add a photo if it is safe to do so'),
                ],
              )
            : Image.file(image!, fit: BoxFit.cover),
      ),
    );
  }
}
