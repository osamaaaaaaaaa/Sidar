import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileView extends StatefulWidget {
  final bool isCompleteProfile;

  const EditProfileView({
    super.key,
    this.isCompleteProfile = false,
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  bool _sunSensitive = false;
  String? _gender;
  String? _skinType;
  String? _country;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in again.');
      final row = await AuthService().ensureProfile().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted || _supabase.auth.currentUser?.id != user.id) return;
      _fullNameController.text = (row?['full_name'] ?? '').toString();
      _emailController.text = user.email ?? '';
      _ageController.text = (row?['age'] ?? '').toString();
      _gender = ProfileValues.gender(row?['gender']);
      _skinType = ProfileValues.skinType(row?['skin_type']);
      _country = ProfileValues.country(row?['location_text']);
      _allergiesController.text = (row?['allergies'] ?? '').toString();
      _medicationsController.text = (row?['medications'] ?? '').toString();
      _sunSensitive = row?['sun_sensitive'] == true;
    } catch (_) {
      if (mounted) _loadFailed = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final validation = ProfileValues.validateProfile(
      name: _fullNameController.text,
      age: _ageController.text,
      genderValue: _gender,
      skin: _skinType,
      location: _country,
    );
    if (validation != null) {
      authNotice(profileValidationMessage(validation), error: true);
      return;
    }
    try {
      setState(() => _isSaving = true);
      await AuthService().saveProfile({
        'full_name': _fullNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _gender == '' ? null : _gender,
        'skin_type': _skinType,
        'location_text': _country,
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'sun_sensitive': _sunSensitive,
      });

      if (mounted) {
        Get.back(result: true);
        authNotice(
          authText(
            'Profile updated successfully.',
            'تم تحديث الملف الشخصي بنجاح.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        authNotice(
          authText(
            'Unable to save profile. Please retry.',
            'تعذر حفظ الملف الشخصي. حاول مجددًا.',
          ),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTheme.backgroundGradient(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _loadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authText(
                          'Unable to load profile.',
                          'تعذر تحميل الملف الشخصي.',
                        ),
                        style: TextStyle(
                          fontFamily: AppTheme.appFontFamily,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(authText('Retry', 'إعادة المحاولة')),
                      ),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(authText('Back', 'رجوع')),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildTopBar(),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.isCompleteProfile ||
                                    _skinType == null ||
                                    _country == null)
                                  _buildCompletionNotice(),

                                // Section 1: Basic Information
                                _buildSectionHeader(
                                  icon: Icons.person_outline_rounded,
                                  title: authText(
                                    'Basic Information',
                                    'المعلومات الأساسية',
                                  ),
                                  subtitle: authText(
                                    'Identity and primary demographics',
                                    'الهوية والمعلومات الديموغرافية الأساسية',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppTheme.glassPanel(
                                  borderRadius: 20,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        authText('Full name', 'الاسم الكامل'),
                                        required: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _field(
                                        _fullNameController,
                                        authText('Full name', 'الاسم الكامل'),
                                        requiredValue: true,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFieldLabel(
                                        authText(
                                          'Email (read-only)',
                                          'البريد الإلكتروني (للقراءة فقط)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _field(
                                        _emailController,
                                        authText('Email', 'البريد الإلكتروني'),
                                        readOnly: true,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldLabel(
                                                  authText(
                                                    'Age (optional)',
                                                    'العمر (اختياري)',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                _field(
                                                  _ageController,
                                                  authText('Age', 'العمر'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildFieldLabel(
                                                  authText(
                                                    'Gender (optional)',
                                                    'الجنس (اختياري)',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                _dropdownField(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFieldLabel(
                                        authText('Country', 'الدولة'),
                                        required: true,
                                      ),
                                      const SizedBox(height: 8),
                                      profileDropdown(
                                        label: authText('Country', 'الدولة'),
                                        values: ProfileValues.countries,
                                        value: _country,
                                        requiredValue: true,
                                        country: true,
                                        onChanged: (v) =>
                                            setState(() => _country = v),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // Section 2: Health & Skin Profile
                                _buildSectionHeader(
                                  icon: Icons.spa_outlined,
                                  title: authText(
                                    'Health & Skin Profile',
                                    'بيانات الصحة والبشرة',
                                  ),
                                  subtitle: authText(
                                    'Used as clinical defaults for intelligent diagnosis',
                                    'تُعتمد افتراضيًا في التحليل والتشخيص السريري الذكي',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppTheme.glassPanel(
                                  borderRadius: 20,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        authText('Skin type', 'نوع البشرة'),
                                        required: true,
                                      ),
                                      const SizedBox(height: 8),
                                      profileDropdown(
                                        label: authText('Skin type', 'نوع البشرة'),
                                        values: ProfileValues.skinTypes,
                                        value: _skinType,
                                        requiredValue: true,
                                        onChanged: (v) =>
                                            setState(() => _skinType = v),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFieldLabel(
                                        authText(
                                          'Allergies (optional)',
                                          'الحساسية ومسبباتها (اختياري)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _field(
                                        _allergiesController,
                                        authText(
                                          'e.g. Fragrance, nuts, aspirin...',
                                          'مثال: حساسية عطور، أدوية، مكسرات...',
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildFieldLabel(
                                        authText(
                                          'Current medications (optional)',
                                          'الأدوية والعلاجات الحالية (اختياري)',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _field(
                                        _medicationsController,
                                        authText(
                                          'e.g. Retinoids, antibiotics, hormonal...',
                                          'مثال: ريتينويد، مضادات حيوية، علاجات هرمونية...',
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _buildSunSensitivityRow(),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),
                                AppTheme.goldButton(
                                  text: widget.isCompleteProfile
                                      ? authText(
                                          'Save & Continue',
                                          'حفظ ومتابعة',
                                        )
                                      : authText(
                                          'Save changes',
                                          'حفظ التعديلات',
                                        ),
                                  isLoading: _isSaving,
                                  onPressed: _save,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCompletionNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authText(
                'Please complete your personal and clinical details to ensure accurate AI skin and hair analysis.',
                'يرجى استكمال معلوماتك الشخصية والسريرية لتخصيص نتائج التحليل الذكي بدقة.',
              ),
              style: TextStyle(
                fontFamily: AppTheme.appFontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSunSensitivityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldSoft,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authText('Sun Sensitivity', 'حساسية البشرة للشمس'),
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authText(
                    'Does your skin react quickly to sunlight?',
                    'هل تتحسس أو تحترق بشرتك سريعاً عند التعرض للشمس؟',
                  ),
                  style: TextStyle(
                    fontFamily: AppTheme.appFontFamily,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _sunSensitive,
            onChanged: (v) => setState(() => _sunSensitive = v),
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.goldSoft,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.appFontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool requiredValue = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: AppTheme.bodyStyle(),
      validator: (v) {
        if (requiredValue && (v ?? '').trim().isEmpty) {
          return profileValidationMessage('name');
        }
        if (controller == _ageController && !ProfileValues.validAge(v ?? '')) {
          return profileValidationMessage('age');
        }
        return null;
      },
      decoration: AppTheme.inputDecoration(hintText: hint),
    );
  }

  Widget _dropdownField() => profileDropdown(
    label: authText('Gender (optional)', 'الجنس (اختياري)'),
    values: ProfileValues.genders,
    value: _gender,
    onChanged: (v) => setState(() => _gender = v),
  );

  Widget _buildTopBar() {
    final title = widget.isCompleteProfile
        ? authText('Complete Profile', 'إكمال المعلومات الشخصية')
        : authText('Edit Profile', 'تعديل الملف الشخصي');

    return Row(
      children: [
        AppTheme.circleBackButton(onTap: () => Get.back()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headingStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              Text(
                authText(
                  'Personal & clinical profile matching',
                  'مطابقة البيانات الشخصية والسريرية',
                ),
                style: TextStyle(
                  fontFamily: AppTheme.appFontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
