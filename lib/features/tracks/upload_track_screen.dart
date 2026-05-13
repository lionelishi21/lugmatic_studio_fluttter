import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/upload_service.dart';

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  final _uploadService = UploadService();
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedFile;
  File? _selectedCover;
  String _selectedType = 'song';
  String? _selectedGenreId;
  List<dynamic> _genres = [];
  
  bool _isLoadingGenres = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      final genres = await _uploadService.getGenres();
      setState(() {
        _genres = genres;
        if (_genres.isNotEmpty) _selectedGenreId = _genres[0]['_id'];
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() => _isLoadingGenres = false);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedCover = File(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null || _selectedCover == null || _selectedGenreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select files')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await _uploadService.uploadContent(
        file: _selectedFile!,
        coverArt: _selectedCover!,
        title: _titleController.text.trim(),
        type: _selectedType,
        genreId: _selectedGenreId!,
        description: _descriptionController.text.trim(),
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content uploaded successfully! It is now pending review.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Upload Content', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading ? _buildUploadProgress() : _buildForm(),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.cloudArrowUp, color: AppColors.primary, size: 64),
            const SizedBox(height: 32),
            Text(
              'Uploading your ${_selectedType}...',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text('${(_uploadProgress * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            Row(
              children: [
                _buildTypeChip('Song', 'song', FontAwesomeIcons.music),
                const SizedBox(width: 12),
                _buildTypeChip('Podcast', 'podcast', FontAwesomeIcons.microphone),
              ],
            ),
            const SizedBox(height: 32),

            // File Pickers
            _buildFilePicker(
              label: 'Audio File',
              hint: _selectedFile != null ? _selectedFile!.path.split('/').last : 'Select MP3/WAV file',
              icon: FontAwesomeIcons.fileAudio,
              onTap: _pickAudio,
            ),
            const SizedBox(height: 16),
            _buildFilePicker(
              label: 'Cover Art',
              hint: _selectedCover != null ? 'Image selected' : 'Select square image (1:1)',
              icon: FontAwesomeIcons.image,
              onTap: _pickImage,
              preview: _selectedCover,
            ),
            const SizedBox(height: 32),

            // Text Fields
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'Give it a name...',
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            
            // Genre Dropdown
            const Text('Genre', style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
            const SizedBox(height: 8),
            _isLoadingGenres 
              ? const CircularProgressIndicator()
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGenreId,
                      dropdownColor: AppColors.card,
                      isExpanded: true,
                      items: _genres.map((g) => DropdownMenuItem<String>(
                        value: g['_id'],
                        child: Text(g['name'], style: const TextStyle(color: AppColors.foreground)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedGenreId = val),
                    ),
                  ),
                ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'What\'s this about?',
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SUBMIT FOR REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: NeumorphicTheme.neumorphicDecoration(
            borderRadius: BorderRadius.circular(16),
          ).copyWith(
            color: isSelected ? AppColors.primary : AppColors.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 14, color: isSelected ? Colors.black : AppColors.mutedForeground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker({required String label, required String hint, required IconData icon, required VoidCallback onTap, File? preview}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: NeumorphicTheme.neumorphicDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                if (preview != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(preview, width: 40, height: 40, fit: BoxFit.cover),
                  )
                else
                  FaIcon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(color: AppColors.foreground.withOpacity(0.7), fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: AppColors.foreground),
          decoration: NeumorphicTheme.neumorphicInputDecoration(hint: hint),
        ),
      ],
    );
  }
}
