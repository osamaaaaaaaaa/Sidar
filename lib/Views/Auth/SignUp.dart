import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare/Services/app_feedback.dart';
import 'package:skincare/Services/app_config_service.dart';
import 'package:skincare/Services/auth_service.dart';
import 'package:skincare/Services/auth_profile_ui.dart';
import 'package:skincare/Services/profile_values.dart';
import 'package:skincare/Views/Auth/Login.dart';
import 'package:skincare/Views/Home/Home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpView extends StatefulWidget {
  final int? initialAge;
  final String? initialGender;
  final String? initialLocation;
  final String? initialCity;
  final String? initialSkinType;

  const SignUpView({
    super.key,
    this.initialAge,
    this.initialGender,
    this.initialLocation,
    this.initialCity,
    this.initialSkinType,
  });

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();

  String? selectedSkinType;
  String? selectedGender;
  String? selectedCountry;
  bool sunSensitive = false;
  bool _privacyAccepted = false;

  bool _isLoading = false;
  bool _isOpeningPrivacy = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _awaitingConfirmation = false;

  final genders = ProfileValues.genders;

  @override
  void initState() {
    super.initState();
    if (widget.initialAge != null) {
      _ageController.text = widget.initialAge.toString();
    }
    if (widget.initialGender != null) {
      selectedGender = widget.initialGender;
    }
    if (widget.initialLocation != null) {
      selectedCountry = widget.initialLocation;
    }
    if (widget.initialSkinType != null) {
      selectedSkinType =
          ProfileValues.skinType(widget.initialSkinType) ??
          widget.initialSkinType;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return '${'please_enter'.tr} $fieldName';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Please enter your email'.tr;
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address'.tr;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password'.tr;
    }
    if (password.length < 8) {
      return authText('Use at least 8 characters.', 'استخدم 8 أحرف على الأقل.');
    }
    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    final error = ProfileValues.validatePassword(
      _passwordController.text,
      value ?? '',
    );
    if (error == 'length') {
      return authText('Use at least 8 characters.', 'استخدم 8 أحرف على الأقل.');
    }
    if (error == 'match') {
      return authText('Passwords do not match.', 'كلمتا المرور غير متطابقتين.');
    }
    return null;
  }

  String? _validateInt(String? value, String label) =>
      ProfileValues.validAge(value ?? '')
      ? null
      : profileValidationMessage('age');

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    if (!_privacyAccepted) {
      _showError(
        authText(
          'Please accept the Privacy Policy to create an account.',
          'يرجى الموافقة على سياسة الخصوصية لإنشاء الحساب.',
        ),
      );
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final passwordError = ProfileValues.validatePassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (passwordError != null) {
      _showError(
        passwordError == 'match'
            ? authText('Passwords do not match.', 'كلمتا المرور غير متطابقتين.')
            : authText(
                'Use at least 8 characters.',
                'استخدم 8 أحرف على الأقل.',
              ),
      );
      return;
    }

    // Skin type is gathered in onboarding when available. Direct sign-up keeps
    // a truthful unknown value instead of forcing a choice on this screen.
    final skinTypeForProfile = selectedSkinType ?? 'unknown';
    final validation = ProfileValues.validateProfile(
      name: _fullNameController.text,
      age: _ageController.text,
      genderValue: selectedGender,
      skin: skinTypeForProfile,
      location: selectedCountry,
    );
    if (validation != null) {
      _showError(profileValidationMessage(validation));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profile: {
          'full_name': _fullNameController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'gender': selectedGender,
          'skin_type': skinTypeForProfile,
          'location_text': selectedCountry,
          'allergies': _allergiesController.text.trim(),
          'medications': _medicationsController.text.trim(),
          'sun_sensitive': sunSensitive,
          'privacy_accepted': true,
          'privacy_accepted_at': DateTime.now().toUtc().toIso8601String(),
          'preferred_language': Get.locale?.languageCode ?? 'ar',
        },
      );
      if (!mounted) return;
      if (authResponse.user == null) {
        throw Exception('Unable to create account right now.');
      }
      if (selectedCountry == widget.initialLocation &&
          (widget.initialCity?.trim().isNotEmpty ?? false)) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'city_${authResponse.user!.id}',
            widget.initialCity!.trim(),
          );
          await prefs.setString(
            'city_country_${authResponse.user!.id}',
            selectedCountry!,
          );
        } catch (e) {
          log('Could not save selected city: $e', name: 'SignUp');
        }
      }
      if (authResponse.session == null) {
        _passwordController.clear();
        setState(() => _awaitingConfirmation = true);
        return;
      }
      await _auth.prepareSession();
      if (!mounted || AuthFlow.instance.recoveryPending || !_auth.isLoggedIn)
        return;
      Get.offAll(() => const HomeView());
    } on AuthException catch (e) {
      log(e.toString(), name: 'SignUpError');

      _showError(_mapAuthError(e.message));
    } catch (e) {
      log(e.toString(), name: 'SignUpError');
      _showError(
        'Something went wrong while creating your account. Please try again.'
            .tr,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'This email is already registered.'.tr;
    }
    if (lower.contains('password')) {
      return 'Please use a stronger password.'.tr;
    }
    if (lower.contains('email')) {
      return 'Please check your email address and try again.'.tr;
    }
    if (lower.contains('network')) {
      return 'Please check your internet connection and try again.'.tr;
    }

    return message;
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.error(message, title: 'Sign up failed'.tr);
  }

  Future<void> _openPrivacyPolicy() async {
    if (_isOpeningPrivacy) return;
    setState(() => _isOpeningPrivacy = true);
    try {
      final config = await AppConfigService.instance.fetchRemoteConfig(
        forceRefresh: true,
      );
      final uri = Uri.tryParse(config.privacyPolicyUrl.trim());
      final canOpen =
          uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
      if (!canOpen ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showError(
          authText(
            'The Privacy Policy link is unavailable right now.',
            'رابط سياسة الخصوصية غير متاح حاليًا.',
          ),
        );
      }
    } catch (_) {
      _showError(
        authText(
          'The Privacy Policy link is unavailable right now.',
          'رابط سياسة الخصوصية غير متاح حاليًا.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningPrivacy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingConfirmation) {
      return Scaffold(
        body: AppTheme.backgroundGradient(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppTheme.glassPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authText(
                          'Check your email',
                          'تحقق من بريدك الإلكتروني',
                        ),
                        style: AppTheme.headingStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authText(
                          'Account created. Confirm your email, then sign in.',
                          'تم إنشاء الحساب. أكّد بريدك الإلكتروني ثم سجّل الدخول.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AppTheme.goldButton(
                        text: 'login_now'.tr,
                        onPressed: () => Get.offAll(() => const LoginView()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: AppTheme.backgroundGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildTopBar(),
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 28),

                      _buildSectionCard(
                        title: 'basic_information'.tr,
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            _buildGlassField(
                              controller: _fullNameController,
                              icon: Icons.person_outline,
                              hint: 'full_name'.tr,
                              validator: (v) =>
                                  _validateRequired(v, 'full_name'.tr),
                            ),
                            const SizedBox(height: 12),
                            _buildGlassField(
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              hint: 'email'.tr,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 12),
                            _buildGlassField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hint: 'password'.tr,
                              isPassword: true,
                              validator: _validatePassword,
                              obscureText: _hidePassword,
                              textDirection: TextDirection.ltr,
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () {
                                  setState(() {
                                    _hidePassword = !_hidePassword;
                                  });
                                },
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildGlassField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_reset_rounded,
                              hint: authText(
                                'Confirm password',
                                'تأكيد كلمة المرور',
                              ),
                              isPassword: true,
                              validator: _validatePasswordConfirmation,
                              obscureText: _hideConfirmation,
                              textDirection: TextDirection.ltr,
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () => setState(
                                  () => _hideConfirmation = !_hideConfirmation,
                                ),
                                icon: Icon(
                                  _hideConfirmation
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      _buildSectionCard(
                        title: 'health_data_management'.tr,
                        icon: Icons.favorite_border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGlassField(
                              controller: _allergiesController,
                              icon: Icons.warning_amber_rounded,
                              hint: 'allergies_question'.tr,
                              validator: null,
                            ),
                            const SizedBox(height: 12),
                            _buildGlassField(
                              controller: _medicationsController,
                              icon: Icons.medication_outlined,
                              hint: 'current_medications'.tr,
                              validator: null,
                            ),
                            const SizedBox(height: 18),
                            _buildSunSensitivityToggle(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),
                      _buildPrivacyConsent(),
                      const SizedBox(height: 12),
                      _buildSubmitButton(),
                      const SizedBox(height: 18),
                      _buildLoginFooter(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [AppTheme.circleBackButton(onTap: () => Get.back())]);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SIDAR AI',
          style: AppTheme.headingStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'create_account_title'.tr,
          style: AppTheme.headingStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'signup_subtitle'.tr,
          style: AppTheme.bodyStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return AppTheme.glassPanel(
      borderRadius: 24,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTheme.bodyStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool obscureText = false,
    bool isNumber = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    TextDirection? textDirection,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType:
          keyboardType ??
          (isNumber ? TextInputType.number : TextInputType.text),
      textDirection: textDirection,
      textAlign: textDirection == TextDirection.ltr
          ? TextAlign.left
          : TextAlign.right,
      validator: validator,
      style: AppTheme.bodyStyle(
        fontSize: 14.5,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.primary,
      decoration: AppTheme.inputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildSelectorField({
    required IconData icon,
    required String hint,
    required String? value,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AppColors.error
                : AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                textAlign: TextAlign.right,
                style: AppTheme.bodyStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunSensitivityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'sun_sensitivity'.tr,
              style: AppTheme.bodyStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: sunSensitive,
            onChanged: (val) => setState(() => sunSensitive = val),
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(.35),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AppTheme.goldButton(
      text: 'save_health_profile_and_start'.tr,
      onPressed: _handleSignUp,
      isLoading: _isLoading,
    );
  }

  Widget _buildPrivacyConsent() {
    final isArabic = Get.locale?.languageCode == 'ar';
    final baseStyle = AppTheme.bodyStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
      height: 1.45,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _privacyAccepted,
          onChanged: (value) =>
              setState(() => _privacyAccepted = value ?? false),
          activeColor: AppColors.primary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Wrap(
              children: [
                Text(
                  isArabic ? 'أوافق على ' : 'I agree to the ',
                  style: baseStyle,
                ),
                TextButton(
                  onPressed: _isOpeningPrivacy ? null : _openPrivacyPolicy,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                    style: baseStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  isArabic
                      ? ' ومعالجة بياناتي الصحية لتقديم هذه الخدمة.'
                      : ' and the processing of my health information for this service.',
                  style: baseStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFooter() {
    return Center(
      child: TextButton(
        onPressed: () => Get.offAll(() => const LoginView()),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'already_have_account'.tr,
                style: AppTheme.bodyStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(text: '  '),
              TextSpan(
                text: 'login_now'.tr,
                style: AppTheme.bodyStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGenderBottomSheet() {
    Get.bottomSheet(
      AppTheme.glassPanel(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'select_gender'.tr,
                style: AppTheme.headingStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(authText('Not specified', 'غير محدد')),
                onTap: () {
                  setState(() => selectedGender = null);
                  Get.back();
                },
              ),
              ...genders.map(
                (gender) => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  leading: Icon(
                    selectedGender == gender
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: selectedGender == gender
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    profileLabel(gender),
                    style: AppTheme.bodyStyle(
                      color: selectedGender == gender
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() => selectedGender = gender);
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
