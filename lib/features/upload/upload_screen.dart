import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../data/services/upload_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _uploadService = UploadService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _selectedFile;
  File? _selectedCover;
  String? _selectedGenreId;
  String _contentType = 'song';
  
  bool _isUploading = false;
  double _uploadProgress = 0;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedCover = File(image.path);
      });
    }
  }

  void _handleUpload() async {
    if (_selectedFile == null || _selectedCover == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select files')),
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
        title: _titleController.text,
        type: _contentType,
        genreId: _selectedGenreId ?? 'default', // Fetch from API later
        description: _descriptionController.text,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful!'), backgroundColor: AppColors.primary),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedFile = null;
      _selectedCover = null;
      _uploadProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Content')),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Art Picker
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: NeumorphicTheme.neumorphicDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _selectedCover != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_selectedCover!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Upload Cover Art', style: TextStyle(color: AppColors.mutedForeground)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: NeumorphicTheme.neumorphicInputDecoration(
                  label: 'Content Title',
                  hint: 'Enter the name of your track or podcast',
                  prefixIcon: Icons.title,
                ),
              ),
              const SizedBox(height: 20),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: NeumorphicTheme.neumorphicInputDecoration(
                  label: 'Description (Optional)',
                  hint: 'Tell your fans about this creation...',
                  prefixIcon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 32),

              // File Selection Button
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: NeumorphicTheme.neumorphicDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file_outlined, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedFile != null ? _selectedFile!.path.split('/').last : 'Select Audio File',
                          style: TextStyle(
                            color: _selectedFile != null ? AppColors.foreground : AppColors.mutedForeground,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.attach_file, color: AppColors.mutedForeground, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Upload Button / Progress
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppColors.card,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.primary)),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleUpload,
                    child: const Text('Publish Now'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
