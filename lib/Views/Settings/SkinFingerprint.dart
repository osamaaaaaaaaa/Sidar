import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkinFingerprintView extends StatefulWidget {
  const SkinFingerprintView({super.key});

  @override
  State<SkinFingerprintView> createState() => _SkinFingerprintViewState();
}

class _SkinFingerprintViewState extends State<SkinFingerprintView> {
  final _supabase = Supabase.instance.client;
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  bool _sunSensitive = false;
  String? _skinType;
  Map<String, dynamic> _loadedHealth = {};

  final _types = ProfileValues.skinTypes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
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
      _loadedHealth = row ?? {};
      _skinType = ProfileValues.skinType(row?['skin_type']);
      _sunSensitive = row?['sun_sensitive'] == true;
      _allergiesController.text = (row?['allergies'] ?? '').toString();
      _medicationsController.text = (row?['medications'] ?? '').toString();
    } catch (_) {
      if (mounted) _loadFailed = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || _loadFailed) return;
    if (_skinType == null) {
      authNotice(profileValidationMessage('skin'), error: true);
      return;
    }
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      setState(() => _isSaving = true);
      // Leave untouched health values (including legacy structured values) as-is.
      await AuthService().saveProfile({
        'skin_type': _skinType,
        if (_allergiesController.text !=
            (_loadedHealth['allergies'] ?? '').toString())
          'allergies': _allergiesController.text.trim(),
        if (_medicationsController.text !=
            (_loadedHealth['medications'] ?? '').toString())
          'medications': _medicationsController.text.trim(),
        if (_sunSensitive != (_loadedHealth['sun_sensitive'] == true))
          'sun_sensitive': _sunSensitive,
      });

      if (mounted) {
        Get.back(result: true);
        authNotice(
          authText('Skin fingerprint updated.', 'تم تحديث البصمة الجلدية.'),
        );
      }
    } catch (_) {
      if (mounted)
        authNotice(
          authText(
            'Unable to save profile. Please retry.',
            'تعذر حفظ الملف الشخصي. حاول مجددًا.',
          ),
          error: true,
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTheme.backgroundGradient(
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
                    ),
                    TextButton(
                      onPressed: _loadProfile,
                      child: Text(authText('Retry', 'إعادة المحاولة')),
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(authText('Back', 'رجوع')),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 26),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authText('Skin type', 'نوع البشرة'),
                              style: AppTheme.bodyStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _types.map((t) {
                                final selected = _skinType == t;
                                return ChoiceChip(
                                  label: Text(
                                    profileLabel(t),
                                    style: AppTheme.bodyStyle(
                                      color: selected
                                          ? Colors.black
                                          : AppColors.textPrimary,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: selected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Colors.black.withOpacity(
                                    0.25,
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.15),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _skinType = t),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              authText(
                                'Sensitivity & Triggers',
                                'الحساسية والمحفزات',
                              ),
                              style: AppTheme.bodyStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AppTheme.glassPanel(
                              borderRadius: 16,
                              padding: EdgeInsets.zero,
                              child: SwitchListTile(
                                value: _sunSensitive,
                                onChanged: (v) =>
                                    setState(() => _sunSensitive = v),
                                activeColor: AppColors.primary,
                                activeTrackColor: AppColors.primary.withOpacity(
                                  0.3,
                                ),
                                inactiveThumbColor: AppColors.textSecondary,
                                inactiveTrackColor: Colors.black.withOpacity(
                                  0.3,
                                ),
                                title: Text(
                                  authText('Sun sensitive', 'حساسية الشمس'),
                                  style: AppTheme.bodyStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  authText(
                                    'Does your skin burn easily in the sun?',
                                    'هل تحترق بشرتك بسهولة تحت الشمس؟',
                                  ),
                                  style: AppTheme.bodyStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              authText('Known Allergies', 'الحساسية المعروفة'),
                              style: AppTheme.bodyStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _field(
                              _allergiesController,
                              authText(
                                'List any allergies (e.g., fragrance, specific chemical)',
                                'اذكر أي حساسية مثل العطور أو مواد كيميائية معينة',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              authText(
                                'Current Medications',
                                'الأدوية الحالية',
                              ),
                              style: AppTheme.bodyStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _field(
                              _medicationsController,
                              authText(
                                'List any active topical or oral medications',
                                'اذكر الأدوية الموضعية أو الفموية المستخدمة',
                              ),
                            ),
                            const SizedBox(height: 38),
                            AppTheme.goldButton(
                              text: authText('Save changes', 'حفظ التعديلات'),
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
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return TextFormField(
      controller: c,
      style: AppTheme.bodyStyle(),
      decoration: AppTheme.inputDecoration(hintText: hint),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        AppTheme.circleBackButton(onTap: () => Get.back()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authText('Skin Fingerprint', 'البصمة الجلدية'),
                style: AppTheme.headingStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
