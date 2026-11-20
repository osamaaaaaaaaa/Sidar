import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skincare/Utils/AppColors.dart';
import 'package:skincare/Utils/AppTheme.dart';
import 'package:skincare/Views/Auth/SignUp.dart';
import 'package:skincare/Views/Onboarding/ivory_motion_background.dart';
import 'package:skincare/Views/Onboarding/animated_sidar_logo.dart';
import 'package:skincare/Views/Onboarding/typewriter_question_header.dart';
import 'package:skincare/Views/Onboarding/location_step.dart';

class OnboardingQuestionnaireView extends StatefulWidget {
  const OnboardingQuestionnaireView({super.key});

  @override
  State<OnboardingQuestionnaireView> createState() =>
      _OnboardingQuestionnaireViewState();
}

class _OnboardingQuestionnaireViewState
    extends State<OnboardingQuestionnaireView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Selected values
  int? _selectedAge;
  String? _selectedGender;
  String? _selectedLocation;
  String? _selectedCity;
  String? _selectedSkinType;

  // Option visibility flags for typewriter typing completion
  bool _step1OptionsVisible = false;
  bool _step2OptionsVisible = false;
  bool _step4OptionsVisible = false;

  bool get _isArabic =>
      (Get.locale?.languageCode ?? 'ar').toLowerCase().startsWith('ar');

  void _toggleLanguage() {
    final next = _isArabic
        ? const Locale('en', 'US')
        : const Locale('ar', 'SA');
    Get.updateLocale(next);
  }

  void _goToNext() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishToRegistration();
    }
  }

  void _goToPrevious() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Get.back();
    }
  }

  void _finishToRegistration() {
    Get.to(
      () => SignUpView(
        initialAge: _selectedAge,
        initialGender: _selectedGender,
        initialLocation: _selectedLocation,
        initialCity: _selectedCity,
        initialSkinType: _selectedSkinType,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IvoryMotionBackground(
        child: Column(
          children: [
            // Header bar: Back button + Progress dots + Language toggle
            _buildHeader(),

            // Page contents
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentStep = idx);
                },
                children: [
                  _buildIntroStep(),
                  _buildAgeStep(),
                  _buildGenderStep(),
                  _buildLocationStep(),
                  _buildSkinTypeStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            onPressed: _goToPrevious,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
          ),

          // Step Progress indicator
          Row(
            children: List.generate(5, (index) {
              final active = index == _currentStep;
              final completed = index < _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? AppColors.oliveGreen
                      : (completed
                            ? AppColors.secondary
                            : AppColors.primary.withValues(alpha: 0.18)),
                ),
              );
            }),
          ),

          // Language toggle button matching video "اللغه English"
          InkWell(
            onTap: _toggleLanguage,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.oliveGreen.withValues(alpha: 0.35),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.oliveGreen.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: AppColors.oliveGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isArabic ? 'اللغه English' : 'العربية',
                    style: AppTheme.bodyStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.oliveGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 0: Welcome Greeting with Animated Logo
  // ==========================================
  Widget _buildIntroStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Luxury animated SIDAR logo medallion with rotating orbital rings
          const AnimatedSidarLogo(size: 145),

          const SizedBox(height: 32),

          // Speech bubble card
          _speechCard(
            titleArabic: 'أهلاً بك في سدر',
            bodyArabic:
                'نساعدك على فهم أعمق لبشرتك وشعرك،\nلنرشدك إلى العناية التي تناسبك.',
            titleEnglish: 'Welcome to SIDAR',
            bodyEnglish:
                "We're here to help you understand your skin and hair better,\nand discover the care that's right for you.",
          ),

          const Spacer(flex: 3),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _goToNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oliveGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 3,
                shadowColor: AppColors.oliveGreen.withValues(alpha: 0.35),
              ),
              child: Text(
                _isArabic ? 'التالي' : 'Next',
                style: AppTheme.bodyStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: Age Question (with Typewriter Animation)
  // ==========================================
  Widget _buildAgeStep() {
    final ageOptions = [
      {'val': 22, 'labelAr': 'أقل من 25 سنة', 'labelEn': 'Under 25'},
      {'val': 29, 'labelAr': '25 - 34 سنة', 'labelEn': '25 - 34'},
      {'val': 39, 'labelAr': '35 - 44 سنة', 'labelEn': '35 - 44'},
      {'val': 52, 'labelAr': '45 - 60 سنة', 'labelEn': '45 - 60'},
      {'val': 65, 'labelAr': 'أكثر من 60 سنة', 'labelEn': 'Over 60'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Header with typewriter animation & slanted pencil
          TypewriterQuestionHeader(
            key: ValueKey('step_1_$_isArabic'),
            title: _isArabic ? 'كم عمرك؟' : 'How old are you?',
            subtitle: _isArabic
                ? 'تختلف احتياجات بشرتك وشعرك مع اختلاف مراحل العمر. نريد أن نفهم احتياجاتك لنقدم لك تجربة أكثر تخصيصاً.'
                : 'At different ages, your skin needs different skincare treatments.',
            onTypingComplete: () {
              if (mounted) {
                setState(() => _step1OptionsVisible = true);
              }
            },
          ),

          const SizedBox(height: 24),

          // Options list with slide-up & fade-in animation
          Expanded(
            child: AnimatedOpacity(
              opacity: _step1OptionsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _step1OptionsVisible
                    ? Offset.zero
                    : const Offset(0, 0.12),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                child: ListView.separated(
                  itemCount: ageOptions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = ageOptions[idx];
                    final val = item['val'] as int;
                    final isSelected = _selectedAge == val;
                    final label = _isArabic
                        ? item['labelAr'] as String
                        : item['labelEn'] as String;

                    return _optionPill(
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAge = val;
                        });
                        // Auto-advance with smooth delay
                        Future.delayed(
                          const Duration(milliseconds: 280),
                          _goToNext,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: Gender Question (with Typewriter Animation)
  // ==========================================
  Widget _buildGenderStep() {
    final genderOptions = [
      {
        'key': 'female',
        'icon': Icons.female_rounded,
        'labelAr': 'أنثى',
        'labelEn': 'Female',
      },
      {
        'key': 'male',
        'icon': Icons.male_rounded,
        'labelAr': 'ذكر',
        'labelEn': 'Male',
      },
      {
        'key': 'other',
        'icon': Icons.shield_outlined,
        // As requested in the video: user crossed Non-binary and wrote "افضل عدم الإفصاح"
        'labelAr': 'أفضل عدم الإفصاح',
        'labelEn': 'Prefer not to say',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Header with typewriter animation & slanted pencil
          TypewriterQuestionHeader(
            key: ValueKey('step_2_$_isArabic'),
            title: _isArabic ? 'ما جنسك؟' : 'What gender do you identify with?',
            subtitle: _isArabic
                ? 'تختلف طبيعة البشرة والشعر واحتياجات العناية بهما من شخص لآخر، ويساعدنا ذلك على تخصيص تجربتك.'
                : 'Hormones have a big impact on how our skin looks and feels at every age.',
            onTypingComplete: () {
              if (mounted) {
                setState(() => _step2OptionsVisible = true);
              }
            },
          ),

          const SizedBox(height: 24),

          // Options list with slide-up & fade-in animation
          Expanded(
            child: AnimatedOpacity(
              opacity: _step2OptionsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _step2OptionsVisible
                    ? Offset.zero
                    : const Offset(0, 0.12),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                child: ListView.separated(
                  itemCount: genderOptions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final item = genderOptions[idx];
                    final key = item['key'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selectedGender == key;
                    final label = _isArabic
                        ? item['labelAr'] as String
                        : item['labelEn'] as String;

                    return _optionPill(
                      label: label,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedGender = key);
                        Future.delayed(
                          const Duration(milliseconds: 280),
                          _goToNext,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: Location / Climate Question (with Typewriter Animation)
  // ==========================================
  Widget _buildLocationStep() => LocationStep(
    isArabic: _isArabic,
    country: _selectedLocation,
    city: _selectedCity,
    onLocationChanged: (country, city) => setState(() {
      _selectedLocation = country;
      _selectedCity = city;
    }),
    onContinue: _goToNext,
  );

  // ==========================================
  // STEP 4: Skin Type Question (with Typewriter Animation)
  // ==========================================
  Widget _buildSkinTypeStep() {
    final skinTypeOptions = [
      {
        'key': 'normal',
        'icon': Icons.spa_outlined,
        'labelAr': 'بشرة عادية (متوازنة وغير دهنية ولا جافة)',
        'labelEn': 'Normal skin (balanced & comfortable)',
      },
      {
        'key': 'dry',
        'icon': Icons.water_drop_outlined,
        'labelAr': 'بشرة جافة (مشدودة وتميل للجفاف والقشور)',
        'labelEn': 'Dry skin (tight & prone to flaking)',
      },
      {
        'key': 'oily',
        'icon': Icons.opacity_rounded,
        'labelAr': 'بشرة دهنية (لامعة ومسام واضحة)',
        'labelEn': 'Oily skin (shiny & visible pores)',
      },
      {
        'key': 'combination',
        'icon': Icons.pie_chart_outline_rounded,
        'labelAr': 'بشرة مختلطة (دهنية بالأنف والجبين وجافة بالخدين)',
        'labelEn': 'Combination skin (oily T-zone, dry cheeks)',
      },
      {
        'key': 'sensitive',
        'icon': Icons.favorite_border_rounded,
        'labelAr': 'بشرة حساسة (سريعة الاحمرار والتهيج)',
        'labelEn': 'Sensitive skin (easily irritated or flushed)',
      },
      {
        'key': 'unknown',
        'icon': Icons.help_outline_rounded,
        'labelAr': 'لا أعرف نوع بشرتي',
        'labelEn': "I don't know my skin type",
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Header with typewriter animation & slanted pencil
          TypewriterQuestionHeader(
            key: ValueKey('step_4_$_isArabic'),
            title: _isArabic ? 'ما هو نوع بشرتك؟' : 'What is your skin type?',
            subtitle: _isArabic
                ? 'معرفة نوع بشرتك هي الأساس لتحديد الروتين والمنتجات العلاجية الأنسب لك بدقة.'
                : 'Knowing your skin type is the foundation for personalized clinical care.',
            onTypingComplete: () {
              if (mounted) {
                setState(() => _step4OptionsVisible = true);
              }
            },
          ),

          const SizedBox(height: 20),

          // Options list with slide-up & fade-in animation
          Expanded(
            child: AnimatedOpacity(
              opacity: _step4OptionsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _step4OptionsVisible
                    ? Offset.zero
                    : const Offset(0, 0.12),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                child: ListView.separated(
                  itemCount: skinTypeOptions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = skinTypeOptions[idx];
                    final key = item['key'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selectedSkinType == key;
                    final label = _isArabic
                        ? item['labelAr'] as String
                        : item['labelEn'] as String;

                    return _optionPill(
                      label: label,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedSkinType = key);
                        Future.delayed(
                          const Duration(milliseconds: 320),
                          _finishToRegistration,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED UI COMPONENTS
  // ==========================================

  Widget _speechCard({
    required String titleArabic,
    required String bodyArabic,
    required String titleEnglish,
    required String bodyEnglish,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5F4D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isArabic ? titleArabic : titleEnglish,
            textAlign: TextAlign.center,
            style: AppTheme.headingStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isArabic ? bodyArabic : bodyEnglish,
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionPill({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.oliveGreen.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.oliveGreen : AppColors.borderSoft,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.oliveGreen.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? AppColors.oliveGreen
                    : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppColors.oliveGreen
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.oliveGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
