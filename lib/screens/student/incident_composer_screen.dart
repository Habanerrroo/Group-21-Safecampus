import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/location_picker.dart';
import '../../services/incident_service.dart';

class IncidentComposerScreen extends StatefulWidget {
  final VoidCallback? onSubmit;

  const IncidentComposerScreen({
    super.key,
    this.onSubmit,
  });

  @override
  State<IncidentComposerScreen> createState() => _IncidentComposerScreenState();
}

class _IncidentComposerScreenState extends State<IncidentComposerScreen> {
  int _currentStep = 0;
  String _selectedCategory = '';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isAnonymous = false;
  List<String> _photosPaths = [];
  bool _isSubmitting = false;
  
  final _incidentService = IncidentService();

  final List<IncidentCategory> _categories = [
    IncidentCategory('theft', 'Theft', '🎒'),
    IncidentCategory('assault', 'Assault', '⚠️'),
    IncidentCategory('harassment', 'Harassment', '🚫'),
    IncidentCategory('fire', 'Fire', '🔥'),
    IncidentCategory('medical', 'Medical', '🏥'),
    IncidentCategory('other', 'Other', '📝'),
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to rebuild when text changes
    _descriptionController.addListener(() => setState(() {}));
    _locationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      // Create incident in database
      final incidentId = await _incidentService.createIncident(
        title: '${_selectedCategory.toUpperCase()} - ${_locationController.text}',
        type: _selectedCategory,
        severity: _determineSeverity(),
        location: _locationController.text,
        description: _descriptionController.text,
        isAnonymous: _isAnonymous,
      );
      
      if (incidentId != null) {
        // Upload photos if any
        for (final photoPath in _photosPaths) {
          await _incidentService.uploadIncidentMedia(
            incidentId: incidentId,
            mediaType: 'photo',
            filePath: photoPath,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incident reported successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        // Reset form
    setState(() {
      _currentStep = 0;
      _selectedCategory = '';
      _descriptionController.clear();
      _locationController.clear();
      _isAnonymous = false;
      _photosPaths = [];
    });
        
        widget.onSubmit?.call();
      } else {
        throw Exception('Failed to create incident');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit incident: $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  String _determineSeverity() {
    // Determine severity based on category
    switch (_selectedCategory.toLowerCase()) {
      case 'assault':
      case 'fire':
      case 'medical':
        return 'high';
      case 'harassment':
      case 'theft':
        return 'medium';
      default:
        return 'low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Indicator
        _buildProgressIndicator(),
        const SizedBox(height: 24),

        // Step Content
        if (_currentStep == 0) _buildCategoryStep(),
        if (_currentStep == 1) _buildDetailsStep(),
        if (_currentStep == 2) _buildReviewStep(),

        const SizedBox(height: 24),

        // Navigation Buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accent : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What happened?',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the type of incident',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category.id;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = category.id);
                Future.delayed(const Duration(milliseconds: 300), _nextStep);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us more',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details about the incident',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 24),

        // Description
        Text(
          'Description',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 5,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Describe what happened...',
            hintStyle: GoogleFonts.inter(color: AppColors.foregroundLight),
          ),
        ),
        const SizedBox(height: 20),

        // Location Picker
        LocationPicker(
          selectedLocation: _locationController.text.isEmpty ? null : _locationController.text,
          onLocationSelected: (location) {
            _locationController.text = location;
            setState(() {}); // Trigger rebuild for button validation
          },
        ),
        const SizedBox(height: 20),

        // Photo Picker
        PhotoPicker(
          onPhotosChanged: (photos) {
            setState(() => _photosPaths = photos);
          },
          maxPhotos: 5,
        ),
        const SizedBox(height: 20),

        // Anonymous checkbox
        GestureDetector(
          onTap: () => setState(() => _isAnonymous = !_isAnonymous),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _isAnonymous ? AppColors.secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isAnonymous ? AppColors.secondary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: _isAnonymous
                    ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Report anonymously',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review report',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm details before submitting',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.foregroundLight,
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildReviewRow('Type', _selectedCategory.toUpperCase()),
              const Divider(height: 24, color: AppColors.border),
              _buildReviewRow('Location', _locationController.text.isEmpty 
                  ? 'Not specified' 
                  : _locationController.text),
              const Divider(height: 24, color: AppColors.border),
              _buildReviewRow('Anonymous', _isAnonymous ? 'Yes' : 'No'),
              const Divider(height: 24, color: AppColors.border),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isEmpty
                        ? 'No description provided'
                        : _descriptionController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  if (_photosPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 24, color: AppColors.border),
                    Text(
                      'Photos: ${_photosPaths.length} attached',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.foregroundLight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    // Determine if the current step is valid
    bool canProceed = false;
    
    if (_currentStep == 0) {
      // Step 0: Category must be selected
      canProceed = _selectedCategory.isNotEmpty;
    } else if (_currentStep == 1) {
      // Step 1: Description and location must be filled
      canProceed = _descriptionController.text.trim().isNotEmpty &&
                   _locationController.text.trim().isNotEmpty;
    } else if (_currentStep == 2) {
      // Step 2: Always can submit (review step)
      canProceed = true;
    }
    
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Previous'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canProceed
                ? (_currentStep == 2 ? _handleSubmit : _nextStep)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == 2 
                  ? AppColors.success 
                  : AppColors.secondary,
            ),
            child: Text(_currentStep == 2 ? 'Submit' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class IncidentCategory {
  final String id;
  final String label;
  final String icon;

  IncidentCategory(this.id, this.label, this.icon);
}

