import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/neumorphic_theme.dart';
import '../navigation/main_nav_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for local wizard state
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingData {
  // Step 0
  String name = '';
  String artistType = 'solo';
  String bio = '';
  List<String> genres = [];
  String country = '';

  // Step 1
  String legalName = '';
  DateTime? dateOfBirth;
  String nationality = '';
  String idType = 'passport';
  String idNumber = '';
  String idDocumentUrl = '';

  // Step 2
  bool platformAgreementSigned = false;
  String platformAgreementSignature = '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class ArtistOnboardingScreen extends StatefulWidget {
  const ArtistOnboardingScreen({super.key});

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final ApiClient _api = ApiClient();

  // Screen-level state
  bool _loading = true;
  String _screenState = 'loading'; // loading | pending | rejected | form
  String _rejectionReason = '';
  int _currentStep = 0;

  final PageController _pageController = PageController();
  final _onboardingData = _OnboardingData();

  // Step 0 keys & controllers
  final _step0Key = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _countryCtrl;

  // Step 1 keys & controllers
  final _step1Key = GlobalKey<FormState>();
  late TextEditingController _legalNameCtrl;
  late TextEditingController _nationalityCtrl;
  late TextEditingController _idNumberCtrl;

  // Step 2 key & controllers
  final _step2Key = GlobalKey<FormState>();
  late TextEditingController _signatureCtrl;

  // ID document upload state
  bool _uploadingId = false;
  String _uploadedIdFilename = '';

  // Submit state
  bool _submitting = false;
  bool _submitted = false;

  static const List<String> _genreOptions = [
    'Reggae', 'Dancehall', 'Soca', 'Calypso', 'Afrobeats',
    'R&B', 'Hip Hop', 'Pop', 'Gospel', 'Jazz', 'Other',
  ];

  static const List<String> _artistTypes = [
    'solo', 'band', 'producer', 'podcaster', 'composer',
  ];

  static const List<String> _idTypes = [
    'passport', 'drivers_license', 'national_id', 'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _countryCtrl = TextEditingController();
    _legalNameCtrl = TextEditingController();
    _nationalityCtrl = TextEditingController();
    _idNumberCtrl = TextEditingController();
    _signatureCtrl = TextEditingController();
    _fetchStatus();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _legalNameCtrl.dispose();
    _nationalityCtrl.dispose();
    _idNumberCtrl.dispose();
    _signatureCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── API helpers ────────────────────────────────────────────────────────────

  Future<void> _fetchStatus() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/onboarding/status');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;

      final status = data['verificationStatus'] ?? 'not_submitted';

      if (status == 'approved') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavScreen()),
          );
        }
        return;
      }

      if (status == 'pending') {
        setState(() {
          _screenState = 'pending';
          _loading = false;
        });
        return;
      }

      if (status == 'rejected') {
        setState(() {
          _screenState = 'rejected';
          _rejectionReason = data['rejectionReason'] ?? '';
          _loading = false;
        });
        return;
      }

      // not_submitted — pre-fill saved data
      _prefillFromStatus(data);
      final savedStep = (data['onboardingStep'] as int?) ?? 0;
      setState(() {
        _screenState = 'form';
        _currentStep = savedStep.clamp(0, 3);
        _loading = false;
      });

      if (_currentStep > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(_currentStep);
        });
      }
    } catch (_) {
      // On error fall through to show the form from scratch
      setState(() {
        _screenState = 'form';
        _loading = false;
      });
    }
  }

  void _prefillFromStatus(Map<String, dynamic> data) {
    if (data['name'] != null) {
      _onboardingData.name = data['name'];
      _nameCtrl.text = data['name'];
    }
    if (data['bio'] != null) {
      _onboardingData.bio = data['bio'];
      _bioCtrl.text = data['bio'];
    }
    if (data['nationality'] != null) {
      _onboardingData.nationality = data['nationality'];
      _nationalityCtrl.text = data['nationality'];
    }
    if (data['genres'] != null && data['genres'] is List) {
      _onboardingData.genres = List<String>.from(data['genres']);
    }
    if (data['legalName'] != null) {
      _onboardingData.legalName = data['legalName'];
      _legalNameCtrl.text = data['legalName'];
    }
    if (data['idType'] != null) {
      _onboardingData.idType = data['idType'];
    }
    if (data['idNumber'] != null) {
      _onboardingData.idNumber = data['idNumber'];
      _idNumberCtrl.text = data['idNumber'];
    }
    if (data['idDocumentUrl'] != null) {
      _onboardingData.idDocumentUrl = data['idDocumentUrl'];
      if (data['idDocumentUrl'].toString().isNotEmpty) {
        _uploadedIdFilename = 'Previously uploaded';
      }
    }
    if (data['platformAgreementSigned'] == true) {
      _onboardingData.platformAgreementSigned = true;
    }
    if (data['platformAgreementSignature'] != null) {
      _onboardingData.platformAgreementSignature = data['platformAgreementSignature'];
      _signatureCtrl.text = data['platformAgreementSignature'];
    }
    if (data['dateOfBirth'] != null) {
      try {
        _onboardingData.dateOfBirth = DateTime.parse(data['dateOfBirth']);
      } catch (_) {}
    }
  }

  Future<void> _saveStep(int step) async {
    try {
      final body = _buildStepBody(step);
      body['step'] = step + 1;
      await _api.dio.post('/onboarding/save-step', data: body);
    } catch (_) {
      // Auto-save failure — don't block UX
    }
  }

  Map<String, dynamic> _buildStepBody(int step) {
    switch (step) {
      case 0:
        return {
          'name': _onboardingData.name,
          'artistType': _onboardingData.artistType,
          'bio': _onboardingData.bio,
          'genres': _onboardingData.genres,
          'country': _onboardingData.country,
        };
      case 1:
        return {
          'legalName': _onboardingData.legalName,
          'dateOfBirth': _onboardingData.dateOfBirth?.toIso8601String(),
          'nationality': _onboardingData.nationality,
          'idType': _onboardingData.idType,
          'idNumber': _onboardingData.idNumber,
          'idDocumentUrl': _onboardingData.idDocumentUrl,
        };
      case 2:
        return {
          'platformAgreementSigned': _onboardingData.platformAgreementSigned,
          'platformAgreementSignature': _onboardingData.platformAgreementSignature,
        };
      default:
        return {};
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _submitting = true);
    try {
      await _api.dio.post('/onboarding/submit');
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _uploadIdDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final filename = file.name;
    final bytes = file.bytes;
    if (bytes == null) return;

    String contentType = 'application/octet-stream';
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') contentType = 'application/pdf';
    if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';

    setState(() => _uploadingId = true);

    try {
      // 1. Get presigned URL
      final presignRes = await _api.dio.post('/upload/presign/id-document', data: {
        'filename': filename,
        'contentType': contentType,
      });
      final presignData = presignRes.data['data'];
      final uploadUrl = presignData['uploadUrl'] as String;
      final publicUrl = presignData['publicUrl'] as String;

      // 2. PUT file bytes directly to S3
      final rawDio = Dio();
      await rawDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      setState(() {
        _onboardingData.idDocumentUrl = publicUrl;
        _uploadedIdFilename = filename;
        _uploadingId = false;
      });
    } catch (e) {
      setState(() => _uploadingId = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  // ── Step navigation ────────────────────────────────────────────────────────

  Future<void> _goToStep(int step) async {
    // Save current step data async (fire & forget)
    _saveStep(_currentStep);

    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onContinue() {
    bool valid = false;
    switch (_currentStep) {
      case 0:
        valid = _step0Key.currentState?.validate() ?? false;
        if (valid && _onboardingData.genres.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one genre.'),
              backgroundColor: AppColors.destructive,
            ),
          );
          valid = false;
        }
        break;
      case 1:
        valid = _step1Key.currentState?.validate() ?? false;
        if (valid && _onboardingData.idDocumentUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload your government ID document.'),
              backgroundColor: AppColors.destructive,
            ),
          );
          valid = false;
        }
        break;
      case 2:
        valid = _step2Key.currentState?.validate() ?? false;
        if (valid && !_onboardingData.platformAgreementSigned) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please agree to the Platform Agreement.'),
              backgroundColor: AppColors.destructive,
            ),
          );
          valid = false;
        }
        break;
      case 3:
        _submitApplication();
        return;
    }

    if (valid && _currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final minAge = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _onboardingData.dateOfBirth ?? minAge,
      firstDate: DateTime(1920),
      lastDate: minAge,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.black,
            surface: AppColors.card,
            onSurface: AppColors.foreground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _onboardingData.dateOfBirth = picked);
    }
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoader();

    switch (_screenState) {
      case 'pending':
        return _buildPendingScreen();
      case 'rejected':
        return _buildRejectedScreen();
      default:
        if (_submitted) return _buildSuccessScreen();
        return _buildWizard();
    }
  }

  // ── Full-screen loader ─────────────────────────────────────────────────────

  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  // ── Pending screen ─────────────────────────────────────────────────────────

  Widget _buildPendingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Under Review',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your application is being reviewed by our team. This usually takes 2–3 business days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "You'll be notified by email once a decision is made.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Rejected screen ────────────────────────────────────────────────────────

  Widget _buildRejectedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.destructive.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.cancel_outlined, color: AppColors.destructive, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Application Rejected',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_rejectionReason.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
                    ),
                    child: Text(
                      _rejectionReason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                _primaryButton(
                  label: 'Update & Resubmit',
                  onPressed: () {
                    setState(() {
                      _screenState = 'form';
                      _currentStep = 0;
                      _submitted = false;
                    });
                    _pageController.jumpToPage(0);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success screen ─────────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Application Submitted',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our team will review your application within 2–3 business days. You will be notified by email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _primaryButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wizard scaffold ────────────────────────────────────────────────────────

  Widget _buildWizard() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.screenGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildStep0(),
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Wizard header ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    const titles = [
      'Artist Profile',
      'Legal & Identity',
      'Platform Agreement',
      'Review & Submit',
    ];
    const subtitles = [
      'Tell fans who you are',
      'Verify your identity',
      'Review and sign the agreement',
      'Check your details and apply',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: () => _goToStep(_currentStep - 1),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.foreground, size: 16),
              ),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[_currentStep],
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitles[_currentStep],
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of 4',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ───────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final filled = i <= _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? AppColors.primary : AppColors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0: Artist Profile
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _step0Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Name
            _fieldLabel('Stage / Artist Name'),
            TextFormField(
              controller: _nameCtrl,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Artist Name',
                hint: 'Your stage name or band name',
                prefixIcon: Icons.music_note_outlined,
              ),
              onChanged: (v) => _onboardingData.name = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Artist Type
            _fieldLabel('Artist Type'),
            DropdownButtonFormField<String>(
              value: _onboardingData.artistType,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.foreground, fontSize: 15),
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Type',
                hint: 'Select artist type',
              ),
              items: _artistTypes.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(_capitalize(t)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _onboardingData.artistType = v);
              },
            ),
            const SizedBox(height: 20),

            // Bio
            _fieldLabel('Bio'),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 5,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Bio',
                hint: 'Tell fans about yourself (min 50 characters)',
              ),
              onChanged: (v) => _onboardingData.bio = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 50) return 'Bio must be at least 50 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Genres
            _fieldLabel('Genres (select at least 1)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genreOptions.map((genre) {
                final selected = _onboardingData.genres.contains(genre);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _onboardingData.genres.remove(genre);
                      } else {
                        _onboardingData.genres.add(genre);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withOpacity(0.18) : AppColors.glassBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      genre,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.mutedForeground,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Country
            _fieldLabel('Country'),
            TextFormField(
              controller: _countryCtrl,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Country',
                hint: 'e.g. Jamaica',
                prefixIcon: Icons.public_outlined,
              ),
              onChanged: (v) => _onboardingData.country = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            _continueButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1: Legal & Identity
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final dob = _onboardingData.dateOfBirth;
    final dobText = dob != null ? DateFormat('d MMM yyyy').format(dob) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legal Full Name
            _fieldLabel('Legal Full Name'),
            TextFormField(
              controller: _legalNameCtrl,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Legal Full Name',
                hint: 'As it appears on your ID',
                prefixIcon: Icons.person_outline,
              ),
              onChanged: (v) => _onboardingData.legalName = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Date of Birth
            _fieldLabel('Date of Birth'),
            GestureDetector(
              onTap: _pickDateOfBirth,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, color: AppColors.mutedForeground, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      dobText ?? 'Select date of birth',
                      style: TextStyle(
                        color: dobText != null ? AppColors.foreground : AppColors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined, color: AppColors.mutedForeground, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Nationality
            _fieldLabel('Nationality'),
            TextFormField(
              controller: _nationalityCtrl,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Nationality',
                hint: 'e.g. Jamaican',
                prefixIcon: Icons.flag_outlined,
              ),
              onChanged: (v) => _onboardingData.nationality = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ID Type
            _fieldLabel('ID Type'),
            DropdownButtonFormField<String>(
              value: _onboardingData.idType,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.foreground, fontSize: 15),
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'ID Type',
                hint: 'Select ID type',
              ),
              items: _idTypes.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(_idTypeLabel(t)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _onboardingData.idType = v);
              },
            ),
            const SizedBox(height: 20),

            // ID Number
            _fieldLabel('ID Number'),
            TextFormField(
              controller: _idNumberCtrl,
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'ID Number',
                hint: 'As printed on your document',
                prefixIcon: Icons.badge_outlined,
              ),
              onChanged: (v) => _onboardingData.idNumber = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Government ID Upload
            _fieldLabel('Government ID Document'),
            GestureDetector(
              onTap: _uploadingId ? null : _uploadIdDocument,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _uploadedIdFilename.isNotEmpty
                      ? AppColors.primary.withOpacity(0.06)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _uploadedIdFilename.isNotEmpty
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.border,
                    width: 1.5,
                    // Dashed border simulated using a solid border on a
                    // nested container below for compatibility.
                  ),
                ),
                child: _uploadingId
                    ? const Column(children: [
                        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                        SizedBox(height: 12),
                        Text('Uploading...', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                      ])
                    : _uploadedIdFilename.isNotEmpty
                        ? Column(children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _uploadedIdFilename,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to replace',
                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                            ),
                          ])
                        : Column(children: [
                            Icon(Icons.upload_file_outlined, color: AppColors.mutedForeground, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to upload ID document',
                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'JPG, PNG, or PDF — max 10 MB',
                              style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                            ),
                          ]),
              ),
            ),
            const SizedBox(height: 32),

            _continueButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Platform Agreement
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agreement card
            Container(
              decoration: NeumorphicTheme.neumorphicDecoration(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lugmatic Artist Platform Agreement',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  _agreementBullet('80% of all streaming and gift revenue goes to you'),
                  _agreementBullet('20% platform fee covers hosting, payment processing, and support'),
                  _agreementBullet('You confirm you own or control all rights to uploaded content'),
                  _agreementBullet('Split sheets must be completed for collaborative tracks'),
                  _agreementBullet('Content must comply with Lugmatic Community Guidelines'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Digital signature
            _fieldLabel('Digital Signature'),
            TextFormField(
              controller: _signatureCtrl,
              style: const TextStyle(
                color: AppColors.foreground,
                fontStyle: FontStyle.italic,
                fontSize: 16,
              ),
              decoration: NeumorphicTheme.cardInputDecoration(
                label: 'Full Legal Name',
                hint: 'Type your full legal name to sign',
                prefixIcon: Icons.draw_outlined,
              ),
              onChanged: (v) => _onboardingData.platformAgreementSignature = v,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Signature required' : null,
            ),
            const SizedBox(height: 20),

            // Agreement checkbox
            GestureDetector(
              onTap: () => setState(() {
                _onboardingData.platformAgreementSigned = !_onboardingData.platformAgreementSigned;
              }),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _onboardingData.platformAgreementSigned
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _onboardingData.platformAgreementSigned
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: _onboardingData.platformAgreementSigned
                        ? const Icon(Icons.check, color: Colors.black, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I have read and agree to the Platform Agreement',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _continueButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _agreementBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3: Review & Submit
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStep3() {
    final d = _onboardingData;
    final dob = d.dateOfBirth != null ? DateFormat('d MMM yyyy').format(d.dateOfBirth!) : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reviewSection('Artist Profile', [
            _reviewRow('Name', d.name),
            _reviewRow('Artist Type', _capitalize(d.artistType)),
            _reviewRow('Country', d.country),
            _reviewRow('Genres', d.genres.join(', ')),
            _reviewRow('Bio', d.bio.length > 80 ? '${d.bio.substring(0, 80)}...' : d.bio),
          ]),
          const SizedBox(height: 16),
          _reviewSection('Legal & Identity', [
            _reviewRow('Legal Name', d.legalName),
            _reviewRow('Date of Birth', dob),
            _reviewRow('Nationality', d.nationality),
            _reviewRow('ID Type', _idTypeLabel(d.idType)),
            _reviewRow('ID Number', d.idNumber),
            _reviewRow('ID Document', d.idDocumentUrl.isNotEmpty ? 'Uploaded' : 'Not uploaded'),
          ]),
          const SizedBox(height: 16),
          _reviewSection('Platform Agreement', [
            _reviewRow('Signature', d.platformAgreementSignature),
            _reviewRow('Agreed', d.platformAgreementSigned ? 'Yes' : 'No'),
          ]),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Application',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      decoration: NeumorphicTheme.neumorphicDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared UI helpers ──────────────────────────────────────────────────────

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _continueButton() {
    return _primaryButton(label: _currentStep < 3 ? 'Continue' : 'Submit', onPressed: _onContinue);
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
    );
  }

  // ── String helpers ─────────────────────────────────────────────────────────

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _idTypeLabel(String type) {
    switch (type) {
      case 'passport':
        return 'Passport';
      case 'drivers_license':
        return "Driver's License";
      case 'national_id':
        return 'National ID';
      default:
        return 'Other';
    }
  }
}
