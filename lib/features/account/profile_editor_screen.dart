import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/artist_service.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _artistService = ArtistService();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?['name'] ?? user?['stageName'] ?? '';
    _bioController.text = user?['bio'] ?? '';
    // Handle social links if nested in user object
    if (user?['socialLinks'] != null) {
      _instagramController.text = user!['socialLinks']['instagram'] ?? '';
      _twitterController.text = user['socialLinks']['twitter'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final artistId = auth.user?['artistId'] ?? auth.user?['_id'];
      
      await _artistService.updateProfile(artistId.toString(), {
        'name': _nameController.text,
        'bio': _bioController.text,
        'socialLinks': {
          'instagram': _instagramController.text,
          'twitter': _twitterController.text,
        }
      });
      
      // Refresh user data
      await auth.getMe();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              const SizedBox(height: 16),
              _buildInput('Stage Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildInput('Bio', _bioController, Icons.info_outline, maxLines: 5),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Social Links'),
              const SizedBox(height: 16),
              _buildInput('Instagram', _instagramController, Icons.camera_alt_outlined),
              const SizedBox(height: 16),
              _buildInput('Twitter', _twitterController, Icons.alternate_email),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: NeumorphicTheme.neumorphicDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.card,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.foreground),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedForeground),
          prefixIcon: Icon(icon, color: AppColors.mutedForeground),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
