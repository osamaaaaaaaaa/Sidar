(function () {
  const state = {
    lang: localStorage.getItem('sidar_lang') || window.SIDAR_CONFIG?.DEFAULT_LANG || 'en',
    currentUser: null,
    selectedFiles: [],
    currentResult: null,
    history: [],
    profile: {},
    liveDoctors: [],
    liveProducts: [],
    isAdmin: false,
  };

  const routes = [...document.querySelectorAll('[data-route]')];
  const routeIds = routes.map((route) => route.id);
  const authTabs = [...document.querySelectorAll('[data-auth-tab]')];
  const authForms = {
    login: document.getElementById('loginForm'),
    signup: document.getElementById('signupForm'),
  };

  const COUNTRY_CODES = [
    'AF','AL','DZ','AD','AO','AG','AR','AM','AU','AT','AZ','BS','BH','BD','BB','BY','BE','BZ','BJ','BT','BO','BA','BW','BR','BN','BG','BF','BI','CV','KH','CM','CA','CF','TD','CL','CN','CO','KM','CG','CD','CR','CI','HR','CU','CY','CZ','DK','DJ','DM','DO','EC','EG','SV','GQ','ER','EE','SZ','ET','FJ','FI','FR','GA','GM','GE','DE','GH','GR','GD','GT','GN','GW','GY','HT','HN','HU','IS','IN','ID','IR','IQ','IE','IL','IT','JM','JP','JO','KZ','KE','KI','KW','KG','LA','LV','LB','LS','LR','LY','LI','LT','LU','MG','MW','MY','MV','ML','MT','MH','MR','MU','MX','FM','MD','MC','MN','ME','MA','MZ','MM','NA','NR','NP','NL','NZ','NI','NE','NG','KP','MK','NO','OM','PK','PW','PA','PG','PY','PE','PH','PL','PT','QA','RO','RU','RW','KN','LC','VC','WS','SM','ST','SA','SN','RS','SC','SL','SG','SK','SI','SB','SO','ZA','KR','SS','ES','LK','SD','SR','SE','CH','SY','TJ','TZ','TH','TL','TG','TO','TT','TN','TR','TM','TV','UG','UA','AE','GB','US','UY','UZ','VU','VA','VE','VN','YE','ZM','ZW'
  ];

  const elements = {
    langToggleBtn: document.getElementById('langToggleBtn'),
    mobileLangToggleBtn: document.getElementById('mobileLangToggleBtn'),
    mobileTopLangToggleBtn: document.getElementById('mobileTopLangToggleBtn'),
    logoutBtn: document.getElementById('logoutBtn'),
    navLoginBtn: document.getElementById('navLoginBtn'),
    mobileLoginBtn: document.getElementById('mobileLoginBtn'),
    mobileLogoutBtn: document.getElementById('mobileLogoutBtn'),
    heroLoginBtn: document.getElementById('heroLoginBtn'),
    footerLoginBtn: document.getElementById('footerLoginBtn'),
    footerMyAccountBtn: document.getElementById('footerMyAccountBtn'),
    menuBtn: document.getElementById('menuBtn'),
    mobileMenu: document.getElementById('mobileMenu'),
    imageInput: document.getElementById('imageInput'),
    imagePreviewGrid: document.getElementById('imagePreviewGrid'),
    clearScanBtn: document.getElementById('clearScanBtn'),
    scanForm: document.getElementById('scanForm'),
    downloadReportBtn: document.getElementById('downloadReportBtn'),
    saveScanBtn: document.getElementById('saveScanBtn'),
    newScanBtn: document.getElementById('newScanBtn'),
    resultsBackBtn: document.getElementById('resultsBackBtn'),
    loginForm: document.getElementById('loginForm'),
    signupForm: document.getElementById('signupForm'),
    magicLinkBtn: document.getElementById('magicLinkBtn'),
    profileName: document.getElementById('profileName'),
    profileEmail: document.getElementById('profileEmail'),
    profileInitials: document.getElementById('profileInitials'),
    profileAge: document.getElementById('profileAge'),
    profileGender: document.getElementById('profileGender'),
    profileSkinType: document.getElementById('profileSkinType'),
    profileLocation: document.getElementById('profileLocation'),
    profileHeight: document.getElementById('profileHeight'),
    profileWeight: document.getElementById('profileWeight'),
    totalScansKpi: document.getElementById('totalScansKpi'),
    latestPriorityKpi: document.getElementById('latestPriorityKpi'),
    savedPlanKpi: document.getElementById('savedPlanKpi'),
    historyList: document.getElementById('historyList'),
    planForm: document.getElementById('planForm'),
    settingsForm: document.getElementById('settingsForm'),
    resultTitle: document.getElementById('resultTitle'),
    resultConfidence: document.getElementById('resultConfidence'),
    resultPriority: document.getElementById('resultPriority'),
    resultImageQuality: document.getElementById('resultImageQuality'),
    resultPatterns: document.getElementById('resultPatterns'),
    resultGuidance: document.getElementById('resultGuidance'),
    resultReasons: document.getElementById('resultReasons'),
    resultPriorityBadge: document.getElementById('resultPriorityBadge'),
    resultPriorityIcon: document.getElementById('resultPriorityIcon'),
    resultPrioritySupport: document.getElementById('resultPrioritySupport'),
    resultPriorityBadgeClone: document.getElementById('resultPriorityBadgeClone'),
    resultPriorityIconClone: document.getElementById('resultPriorityIconClone'),
    resultGuidanceClone: document.getElementById('resultGuidanceClone'),
    hydrationValueClone: document.getElementById('hydrationValueClone'),
    hydrationBarClone: document.getElementById('hydrationBarClone'),
    poreValueClone: document.getElementById('poreValueClone'),
    poreBarClone: document.getElementById('poreBarClone'),
    fineLinesValueClone: document.getElementById('fineLinesValueClone'),
    fineLinesBarClone: document.getElementById('fineLinesBarClone'),
    toneValueClone: document.getElementById('toneValueClone'),
    toneBarClone: document.getElementById('toneBarClone'),
    resultTitleClone: document.getElementById('resultTitleClone'),
    resultConfidenceClone: document.getElementById('resultConfidenceClone'),
    resultPriorityClone: document.getElementById('resultPriorityClone'),
    resultImageQualityClone: document.getElementById('resultImageQualityClone'),
    resultOverallScoreClone: document.getElementById('resultOverallScoreClone'),
    resultScoreLabelClone: document.getElementById('resultScoreLabelClone'),
    resultScoreSummaryClone: document.getElementById('resultScoreSummaryClone'),
    scoreRingClone: document.getElementById('scoreRingClone'),
    resultPatternsClone: document.getElementById('resultPatternsClone'),
    resultOverallScore: document.getElementById('resultOverallScore'),
    resultScoreLabel: document.getElementById('resultScoreLabel'),
    resultScoreSummary: document.getElementById('resultScoreSummary'),
    scoreRing: document.getElementById('scoreRing'),
    hydrationValue: document.getElementById('hydrationValue'),
    hydrationBar: document.getElementById('hydrationBar'),
    poreValue: document.getElementById('poreValue'),
    poreBar: document.getElementById('poreBar'),
    fineLinesValue: document.getElementById('fineLinesValue'),
    fineLinesBar: document.getElementById('fineLinesBar'),
    toneValue: document.getElementById('toneValue'),
    toneBar: document.getElementById('toneBar'),
    morningRoutineList: document.getElementById('morningRoutineList'),
    eveningRoutineList: document.getElementById('eveningRoutineList'),
    naturalProductsList: document.getElementById('naturalProductsList'),
    commercialProductsList: document.getElementById('commercialProductsList'),
    nearbyDoctorsList: document.getElementById('nearbyDoctorsList'),
    shareWhatsappBtn: document.getElementById('shareWhatsappBtn'),
    shareInstagramBtn: document.getElementById('shareInstagramBtn'),
    shareTiktokBtn: document.getElementById('shareTiktokBtn'),
    shareFullReportBtn: document.getElementById('shareFullReportBtn'),
    year: document.getElementById('year'),
    reportYear: document.getElementById('reportYear'),
  };

  const staticTranslations = {
    en: {
      nav_home: 'Home',
      nav_how: 'How It Works',
      nav_partners: 'Partners',
      nav_pricing: 'Pricing',
      nav_faq: 'FAQ',
      nav_investors: 'Investors',
      nav_about: 'About',
      nav_contact: 'Contact',
      nav_dashboard: 'Dashboard',
      nav_my_account: 'My Account',
      nav_login: 'Login',
      nav_logout: 'Logout',
      sign_up: 'Sign Up',

      hero_desc_long:
        'Discover the future of beauty analysis with SIDAR AI. Upload images, describe the concern, and receive a structured AI report with scores, routines, product guidance, and doctor recommendations.',
      hero_start: '✦ Start AI Analysis',
      hero_signup: 'Sign Up',

      discover_heading: 'What You Can <em>Discover</em>',
      discover_desc_long:
        'The old SIDAR production logic is preserved here: multi-image upload, structured Gemini analysis, history, routines, report sharing, and save-to-account.',

      upload_title: 'Drop images here or click to upload',
      upload_subtitle: 'JPG, PNG, WEBP — maximum 5 images',
      analyze_now: 'Analyze Now',
      clear: 'Clear',
      live_result_preview: 'Live Result Preview',
      guidance: 'Guidance',
      visible_findings: 'Visible findings',
      download_report: 'Download report',
      open_full_result: 'Open full result',

      full_ai_report: 'Full <em>AI Report</em>',
      back_to_analysis: 'Back to analysis',
      summary: 'Summary',
      key_findings: 'Key findings',
      reasons: 'Reasons',
      morning_routine: 'Morning routine',
      evening_routine: 'Evening routine',
      save_scan: 'Save Scan',
      new_scan: 'New Scan',

      scan_type: 'Scan type',
      area: 'Area',
      duration: 'Duration',
      severity: 'Severity',
      skin_type_label: 'Skin type',
      notes: 'Notes',
      notes_placeholder: 'Any extra context that may help the AI review.',

      pricing_title: 'Simple plans for <em>every stage</em>',
      faq_title: 'Common <em>questions</em>',

      contact_heading: 'Get in <em>Touch</em>',
      contact_eyebrow: '// Contact Us',
      contact_send: 'Send a Message',
      contact_first: 'First Name',
      contact_last: 'Last Name',
      contact_email: 'Email Address',
      contact_inquiry: 'Inquiry Type',
      contact_message: 'Message',
      contact_submit: 'Send Message →',
      contact_success: 'Message Sent!',
      contact_success_copy: 'Thank you for reaching out. We will respond within 24 hours.',
      first_name_placeholder: 'Sarah',
      last_name_placeholder: 'Al-Ahmad',
      contact_email_placeholder: 'sarah@company.com',
      contact_message_placeholder: 'Tell us about your interest in SIDAR AI...',

      guest_mode_title: 'You can still use SIDAR as a guest',
      guest_mode_desc:
        'Run analysis and keep a limited local history on this device. Create an account to save reports to the cloud and sync your dashboard.',
      guest_mode_start: 'Start as Guest',
      guest_mode_login: 'Login / Sign up',

      auth_access: '// Account Access',
      auth_title: 'Sign in to save reports, plans, and settings',
  auth_desc: 'Create your account or sign in to save reports, manage your routines, and access your personalized SIDAR account.',
      email: 'Email',
      password: 'Password',
      full_name: 'Full name',
      magic_link: 'Send magic link',
      or_use: 'Or use',

      start_new_analysis: 'Start New Analysis',
      total_scans: 'Total scans',
      latest_priority: 'Latest priority',
      beauty_profile_kpi: 'Beauty profile',
      scan_history: 'Scan history',
      saved_sessions_label: 'Saved sessions',
      my_account_title: 'My account',
      my_account_badge: 'Profile',
      wellness_plan: 'Wellness plan',
      am_pm_label: 'AM / PM',

      dashboard_age: 'Age',
      dashboard_gender: 'Gender',
      dashboard_skin_type: 'Skin type',
      dashboard_location: 'Location',
      dashboard_display_name: 'Display name',
      dashboard_location_label: 'Location',
      dashboard_height: 'Height (cm)',
      dashboard_weight: 'Weight (kg)',
      dashboard_allergies: 'Allergies',
      dashboard_medications: 'Medications',
      dashboard_sun_sensitive: 'Sun sensitive',
      dashboard_language: 'Language',
      dashboard_notifications: 'Notifications',
      dashboard_enabled: 'Enabled',
      dashboard_disabled: 'Disabled',
      dashboard_save_settings: 'Save Settings',
      dashboard_morning_routine: 'Morning routine',
      dashboard_night_routine: 'Night routine',
      dashboard_save_plan: 'Save Plan',
      gender_female: 'Female',
      gender_male: 'Male',
      gender_other: 'Other',
      yes: 'Yes',
      no: 'No',
      select: 'Select',
      select_country: 'Select country',
      skin_goals_label: 'Skin goals',

      pricing_free: 'Free',
      pricing_guest: 'Guest',
      pricing_guest_desc: 'Run limited local analyses on one device.',
      pricing_guest_price: '0',
      pricing_guest_feature_1: 'Local history',
      pricing_guest_feature_2: 'Basic report view',
      pricing_guest_feature_3: 'No cloud sync',

      pricing_popular: 'Most Popular',
      pricing_plus: 'SIDAR Plus',
      pricing_plus_desc: 'Save reports, sync dashboard, and manage routines.',
      pricing_plus_price: '$9',
      pricing_plus_feature_1: 'Cloud history',
      pricing_plus_feature_2: 'Saved plans',
      pricing_plus_feature_3: 'Priority support',

      pricing_business: 'Business',
      pricing_clinic: 'Clinic / Brand',
      pricing_clinic_desc: 'For partner workflows and referral integrations.',
      pricing_clinic_price: 'Custom',
      pricing_clinic_feature_1: 'Partner dashboard',
      pricing_clinic_feature_2: 'Referrals',
      pricing_clinic_feature_3: 'Custom integrations',

      faq_q1: 'Is this a medical diagnosis?',
      faq_a1: 'No. SIDAR provides AI-assisted beauty and wellness guidance, not a medical diagnosis.',
      faq_q2: 'How many images can I upload?',
      faq_a2: 'Up to 5 images per analysis.',
      faq_q3: 'Can I use it as a guest?',
      faq_a3: 'Yes. Guest mode works locally, while signed-in users can sync their reports.',
      faq_q4: 'Does SIDAR support Arabic?',
      faq_a4: 'Yes. You can switch instantly between English and Arabic.',

      footer_about_us: 'About Us',
      footer_investors: 'Investors',
      footer_title:
        'AI-powered beauty intelligence platform. This production package merges the old working logic with the new premium website design.',

      profile_default_name: 'SIDAR User',
      dashboard_guest_email: 'guest@sidar.app',

      no_images: 'Upload at least one image.',
      images_limit: 'Maximum 5 images',
      delete: 'Delete',
      report_title: 'Your result',
      results_empty_guidance: 'No report yet.',
      share_report_support: 'Share the summary or the full report with suggested solutions.',
      no_patterns_yet: 'No visible findings yet.',
      report_generated: 'Report generated successfully.',
      generate_result_error: 'Unable to generate result.',
      something_went_wrong: 'Something went wrong.',
      scan_saved_device: 'Scan saved on this device.',
      no_saved_scans_short: 'No saved scans yet.',
      history_fallback_title: 'Saved analysis',
      account_created_short: 'Account created successfully.',
      enter_email_first: 'Enter your email first.',
      plan_saved_short: 'Plan saved successfully.',
      account_settings_saved: 'Account settings saved.',
      instagram_copied: 'Report copied for Instagram.',
      tiktok_copied: 'Report copied for TikTok.',
      full_report_copied: 'Full report copied.',
      copy_success: 'Copied successfully.',
      copy_error: 'Unable to copy.',

      share_text_report_title: 'SIDAR AI Report',
      share_text_default_analysis: 'Beauty Analysis',
      share_text_score: 'Score',
      share_text_priority: 'Priority',
      share_text_summary: 'Summary',

      score_label_skin: 'SKIN SCORE',
      score_label_hair: 'HAIR SCORE',
      score_metric_hydration: 'Hydration',
      score_metric_pore_clarity: 'Pore Clarity',
      score_metric_fine_lines: 'Fine Lines',
      score_metric_overall_tone: 'Overall Tone',
      score_metric_density: 'Hair Density',
      score_metric_texture: 'Hair Texture',
      score_metric_strength: 'Hair Strength',
      score_metric_scalp_health: 'Scalp Health',
      score_summary_skin_good: 'Above average skin health profile',
      score_summary_skin_followup: 'Skin profile needs supportive care',
      score_summary_hair_good: 'Hair and scalp profile looks promising',
    },

    ar: {
      nav_home: 'الرئيسية',
      nav_how: 'كيف يعمل',
      nav_partners: 'الشركاء',
      nav_pricing: 'الأسعار',
      nav_faq: 'الأسئلة',
      nav_investors: 'المستثمرون',
      nav_about: 'من نحن',
      nav_contact: 'تواصل',
      nav_dashboard: 'لوحة التحكم',
      nav_my_account: 'حسابي',
      nav_login: 'تسجيل الدخول',
      nav_logout: 'تسجيل الخروج',
      sign_up: 'إنشاء حساب',

      hero_desc_long:
        'اكتشف مستقبل تحليل الجمال مع SIDAR AI. ارفع الصور، وحدد المشكلة، واحصل على تقرير ذكي منظم يتضمن الدرجات، والروتين، وترشيحات المنتجات، واقتراحات الأطباء.',
      hero_start: '✦ ابدأ التحليل',
      hero_signup: 'إنشاء حساب',

      discover_heading: 'ما الذي يمكنك <em>اكتشافه</em>',
      discover_desc_long:
        'تم الحفاظ على منطق SIDAR الإنتاجي القديم هنا: رفع متعدد للصور، تحليل Gemini منظم، سجل محفوظ، روتين يومي، مشاركة التقرير، والحفظ داخل الحساب.',

      upload_title: 'اسحب الصور هنا أو اضغط للرفع',
      upload_subtitle: 'JPG و PNG و WEBP — بحد أقصى 5 صور',
      analyze_now: 'ابدأ التحليل',
      clear: 'مسح',
      live_result_preview: 'معاينة النتيجة المباشرة',
      guidance: 'الإرشادات',
      visible_findings: 'النتائج الظاهرة',
      download_report: 'تحميل التقرير',
      open_full_result: 'فتح النتيجة الكاملة',

      full_ai_report: 'التقرير <em>الذكي الكامل</em>',
      back_to_analysis: 'العودة للتحليل',
      summary: 'الملخص',
      key_findings: 'أهم الملاحظات',
      reasons: 'الأسباب',
      morning_routine: 'روتين الصباح',
      evening_routine: 'روتين المساء',
      save_scan: 'حفظ التحليل',
      new_scan: 'تحليل جديد',

      scan_type: 'نوع التحليل',
      area: 'المنطقة',
      duration: 'المدة',
      severity: 'الحدة',
      skin_type_label: 'نوع البشرة',
      notes: 'ملاحظات',
      notes_placeholder: 'أي تفاصيل إضافية قد تساعد الذكاء الاصطناعي في المراجعة.',

      pricing_title: 'خطط بسيطة <em>لكل مرحلة</em>',
      faq_title: 'الأسئلة <em>الشائعة</em>',

      contact_heading: 'تواصل <em>معنا</em>',
      contact_eyebrow: '// تواصل معنا',
      contact_send: 'أرسل رسالة',
      contact_first: 'الاسم الأول',
      contact_last: 'اسم العائلة',
      contact_email: 'البريد الإلكتروني',
      contact_inquiry: 'نوع الاستفسار',
      contact_message: 'الرسالة',
      contact_submit: 'إرسال الرسالة →',
      contact_success: 'تم إرسال الرسالة!',
      contact_success_copy: 'شكرًا لتواصلك معنا. سنرد خلال 24 ساعة.',
      first_name_placeholder: 'سارة',
      last_name_placeholder: 'الأحمد',
      contact_email_placeholder: 'sarah@company.com',
      contact_message_placeholder: 'أخبرنا بطبيعة اهتمامك بمنصة SIDAR AI...',

      guest_mode_title: 'يمكنك استخدام SIDAR كضيف',
      guest_mode_desc:
        'شغّل التحليل واحتفظ بسجل محلي محدود على هذا الجهاز. أنشئ حسابًا لحفظ التقارير على السحابة ومزامنة لوحة التحكم.',
      guest_mode_start: 'ابدأ كضيف',
      guest_mode_login: 'دخول / إنشاء حساب',

      auth_title: 'سجّل الدخول لحفظ التقارير والخطط والإعدادات',
auth_desc: 'أنشئ حسابك أو سجّل الدخول لحفظ التقارير، وإدارة روتينك، والوصول إلى حسابك SIDAR المخصصة لك.',      email: 'البريد الإلكتروني',
      password: 'كلمة المرور',
      full_name: 'الاسم الكامل',
      magic_link: 'إرسال رابط الدخول',
      or_use: 'أو استخدم',

      start_new_analysis: 'ابدأ تحليلًا جديدًا',
      total_scans: 'إجمالي التحليلات',
      latest_priority: 'آخر أولوية',
      beauty_profile_kpi: 'الملف الجمالي',
      scan_history: 'سجل التحليلات',
      saved_sessions_label: 'الجلسات المحفوظة',
      my_account_title: 'حسابي',
      my_account_badge: 'الملف الشخصي',
      wellness_plan: 'الخطة الجمالية',
      am_pm_label: 'صباح / مساء',

      dashboard_age: 'العمر',
      dashboard_skin_type: 'نوع البشرة',
      dashboard_location: 'الموقع',
      dashboard_display_name: 'الاسم الظاهر',
      dashboard_location_label: 'الموقع',
      dashboard_language: 'اللغة',
      dashboard_notifications: 'الإشعارات',
      dashboard_enabled: 'مفعلة',
      dashboard_disabled: 'معطلة',
      dashboard_save_settings: 'حفظ الإعدادات',
      dashboard_morning_routine: 'روتين الصباح',
      dashboard_night_routine: 'روتين الليل',
      dashboard_save_plan: 'حفظ الخطة',

      pricing_free: 'مجاني',
      pricing_guest: 'ضيف',
      pricing_guest_desc: 'شغّل تحليلات محلية محدودة على جهاز واحد.',
      pricing_guest_price: '0',
      pricing_guest_feature_1: 'سجل محلي',
      pricing_guest_feature_2: 'عرض أساسي للتقرير',
      pricing_guest_feature_3: 'بدون مزامنة سحابية',

      pricing_popular: 'الأكثر شيوعًا',
      pricing_plus: 'SIDAR Plus',
      pricing_plus_desc: 'احفظ التقارير، وازامن لوحة التحكم، وأدر الروتينات.',
      pricing_plus_price: '$9',
      pricing_plus_feature_1: 'سجل سحابي',
      pricing_plus_feature_2: 'خطط محفوظة',
      pricing_plus_feature_3: 'دعم أولوية',

      pricing_business: 'أعمال',
      pricing_clinic: 'عيادة / علامة تجارية',
      pricing_clinic_desc: 'لسير العمل الخاص بالشركاء وتكاملات الإحالة.',
      pricing_clinic_price: 'مخصص',
      pricing_clinic_feature_1: 'لوحة شركاء',
      pricing_clinic_feature_2: 'إحالات',
      pricing_clinic_feature_3: 'تكاملات مخصصة',

      faq_q1: 'هل هذا تشخيص طبي؟',
      faq_a1: 'لا. SIDAR يقدم إرشادات جمالية وعافية مدعومة بالذكاء الاصطناعي، وليس تشخيصًا طبيًا.',
      faq_q2: 'كم صورة يمكنني رفعها؟',
      faq_a2: 'حتى 5 صور لكل تحليل.',
      faq_q3: 'هل يمكنني استخدامه كضيف؟',
      faq_a3: 'نعم. وضع الضيف يعمل محليًا، بينما يمكن للمستخدمين المسجلين مزامنة تقاريرهم.',
      faq_q4: 'هل يدعم SIDAR اللغة العربية؟',
      faq_a4: 'نعم. يمكنك التبديل فورًا بين العربية والإنجليزية.',

      footer_about_us: 'من نحن',
      footer_investors: 'المستثمرون',
      footer_title:
        'منصة ذكاء جمالي مدعومة بالذكاء الاصطناعي. هذه الحزمة الإنتاجية تدمج المنطق القديم العامل مع تصميم الموقع الجديد المميز.',

      profile_default_name: 'مستخدم SIDAR',
      dashboard_guest_email: 'guest@sidar.app',

      no_images: 'ارفع صورة واحدة على الأقل.',
      images_limit: 'الحد الأقصى 5 صور',
      delete: 'حذف',
      report_title: 'نتيجتك',
      results_empty_guidance: 'لا يوجد تقرير بعد.',
      share_report_support: 'شارك الملخص أو التقرير الكامل مع الحلول المقترحة.',
      no_patterns_yet: 'لا توجد نتائج ظاهرة بعد.',
      report_generated: 'تم إنشاء التقرير بنجاح.',
      generate_result_error: 'تعذر إنشاء النتيجة.',
      something_went_wrong: 'حدث خطأ ما.',
      scan_saved_device: 'تم حفظ التحليل على هذا الجهاز.',
      no_saved_scans_short: 'لا توجد تحليلات محفوظة بعد.',
      history_fallback_title: 'تحليل محفوظ',
      account_created_short: 'تم إنشاء الحساب بنجاح.',
      enter_email_first: 'أدخل بريدك الإلكتروني أولًا.',
      plan_saved_short: 'تم حفظ الخطة بنجاح.',
      account_settings_saved: 'تم حفظ إعدادات الحساب.',
      instagram_copied: 'تم نسخ التقرير لإنستجرام.',
      tiktok_copied: 'تم نسخ التقرير لتيك توك.',
      full_report_copied: 'تم نسخ التقرير الكامل.',
      copy_success: 'تم النسخ بنجاح.',
      copy_error: 'تعذر النسخ.',

      share_text_report_title: 'تقرير SIDAR AI',
      share_text_default_analysis: 'تحليل جمالي',
      share_text_score: 'الدرجة',
      share_text_priority: 'الأولوية',
      share_text_summary: 'الملخص',

      score_label_skin: 'درجة البشرة',
      score_label_hair: 'درجة الشعر',
      score_metric_hydration: 'الترطيب',
      score_metric_pore_clarity: 'نقاء المسام',
      score_metric_fine_lines: 'الخطوط الدقيقة',
      score_metric_overall_tone: 'اللون العام',
      score_metric_density: 'كثافة الشعر',
      score_metric_texture: 'ملمس الشعر',
      score_metric_strength: 'قوة الشعر',
      score_metric_scalp_health: 'صحة الفروة',
      score_summary_skin_good: 'ملف صحة البشرة أعلى من المتوسط',
      score_summary_skin_followup: 'ملف البشرة يحتاج إلى عناية داعمة',
      score_summary_hair_good: 'ملف الشعر والفروة يبدو واعدًا',
    },
  };

  const extraTranslations = {
    en: {
      auth_access: '// Account Access',
      dashboard_gender: 'Gender',
      dashboard_height: 'Height (cm)',
      dashboard_weight: 'Weight (kg)',
      dashboard_allergies: 'Allergies',
      dashboard_medications: 'Medications',
      dashboard_sun_sensitive: 'Sun sensitive',
      gender_female: 'Female',
      gender_male: 'Male',
      gender_other: 'Other',
      yes: 'Yes',
      no: 'No',
      select_country: 'Select country',
      skin_goals_label: 'Skin goals',
    },
    ar: {
      auth_access: '// الوصول للحساب',
      dashboard_gender: 'الجنس',
      dashboard_height: 'الطول (سم)',
      dashboard_weight: 'الوزن (كجم)',
      dashboard_allergies: 'الحساسية',
      dashboard_medications: 'الأدوية',
      dashboard_sun_sensitive: 'حساسية الشمس',
      gender_female: 'أنثى',
      gender_male: 'ذكر',
      gender_other: 'أخرى',
      yes: 'نعم',
      no: 'لا',
      select_country: 'اختر الدولة',
      skin_goals_label: 'أهداف البشرة',
    },
  };

  function t(key) {
    return (
      extraTranslations[state.lang]?.[key] ||
      window.SIDAR_I18N?.[state.lang]?.[key] ||
      staticTranslations[state.lang]?.[key] ||
      extraTranslations.en?.[key] ||
      staticTranslations.en?.[key] ||
      key
    );
  }

  function showToast(message, type = 'success') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    const box = document.createElement('div');
    box.className = `toast ${type}`;
    box.textContent = message;
    container.appendChild(box);
    setTimeout(() => box.remove(), 3200);
  }

  function setNodeText(node, value) {
    if (!node) return;
    if (typeof value === 'string' && value.includes('<')) node.innerHTML = value;
    else node.textContent = value;
  }

  function applyStaticTranslations() {
    const langMap = staticTranslations[state.lang] || staticTranslations.en;

    document.querySelectorAll('a[data-p="landing"]').forEach((el) => setNodeText(el, langMap.nav_home));
    document.querySelectorAll('a[data-p="how"]').forEach((el) => setNodeText(el, langMap.nav_how));
    document.querySelectorAll('a[data-p="partners"]').forEach((el) => setNodeText(el, langMap.nav_partners));
    document.querySelectorAll('a[data-p="faq"]').forEach((el) => setNodeText(el, langMap.nav_faq));
    document.querySelectorAll('a[data-p="investors"]').forEach((el) => setNodeText(el, langMap.nav_investors));
    document.querySelectorAll('a[data-p="pricing"]').forEach((el) => setNodeText(el, langMap.nav_pricing));
    document.querySelectorAll('a[data-p="about"]').forEach((el) => setNodeText(el, langMap.nav_about));
    document.querySelectorAll('a[data-p="contact"]').forEach((el) => setNodeText(el, langMap.nav_contact));
    document.querySelectorAll('a[data-p="auth"]').forEach((el) => setNodeText(el, langMap.nav_my_account));

    [elements.navLoginBtn, elements.mobileLoginBtn, elements.heroLoginBtn, elements.footerLoginBtn].forEach((el) => {
      if (el && !el.dataset.authState) el.textContent = langMap.nav_login;
    });

    if (elements.logoutBtn) elements.logoutBtn.textContent = langMap.nav_logout;
    if (elements.footerMyAccountBtn) elements.footerMyAccountBtn.textContent = langMap.nav_my_account;

    const mobileMenuLinks = document.querySelectorAll('#mobileMenu a');
    const mobileKeys = [
      langMap.nav_home,
      langMap.nav_how,
      langMap.nav_partners,
      langMap.nav_faq,
      langMap.nav_investors,
      langMap.nav_pricing,
      langMap.nav_about,
      langMap.nav_contact,
      langMap.nav_my_account,
    ];
    mobileMenuLinks.forEach((a, i) => {
      if (mobileKeys[i]) a.textContent = mobileKeys[i];
    });

    const heroSecondaryCta = document.querySelector('[data-i18n="landing_cta_secondary"]');
    if (heroSecondaryCta) heroSecondaryCta.textContent = langMap.hero_signup;

    const pricingTitle = document.querySelector('#pricing .display');
    if (pricingTitle) pricingTitle.innerHTML = langMap.pricing_title;

    const faqTitle = document.querySelector('#faq .display');
    if (faqTitle) faqTitle.innerHTML = langMap.faq_title;

    const guestTitle = document.querySelector('#guest .h2');
    if (guestTitle) guestTitle.textContent = langMap.guest_mode_title;

    const guestLead = document.querySelector('#guest .lead');
    if (guestLead) guestLead.textContent = langMap.guest_mode_desc;

    const guestBtns = document.querySelectorAll('#guest .footer-actions-row a');
    if (guestBtns[0]) guestBtns[0].textContent = langMap.guest_mode_start;
    if (guestBtns[1]) guestBtns[1].textContent = langMap.guest_mode_login;

    const authTitle = document.querySelector('#auth .h2');
    if (authTitle) authTitle.textContent = langMap.auth_title;

    const authDesc = document.querySelector('#auth .body-text');
    if (authDesc) authDesc.textContent = langMap.auth_desc;

    const authDivider = document.querySelector('#auth .auth-divider span');
    if (authDivider) authDivider.textContent = langMap.or_use;

    const profileMetaLabels = document.querySelectorAll('.profile-meta-list span');
    if (profileMetaLabels[0]) profileMetaLabels[0].textContent = langMap.dashboard_age;
    if (profileMetaLabels[1]) profileMetaLabels[1].textContent = langMap.dashboard_gender || t('dashboard_gender');
    if (profileMetaLabels[2]) profileMetaLabels[2].textContent = langMap.dashboard_skin_type;
    if (profileMetaLabels[3]) profileMetaLabels[3].textContent = langMap.dashboard_location;
    if (profileMetaLabels[4]) profileMetaLabels[4].textContent = langMap.dashboard_height || t('dashboard_height');
    if (profileMetaLabels[5]) profileMetaLabels[5].textContent = langMap.dashboard_weight || t('dashboard_weight');

    const dashboardPanelTitles = document.querySelectorAll('.dashboard-panel .title-row h3');
    if (dashboardPanelTitles[0]) dashboardPanelTitles[0].textContent = t('scan_history');
    if (dashboardPanelTitles[1]) dashboardPanelTitles[1].textContent = langMap.my_account_title;
    if (dashboardPanelTitles[2]) dashboardPanelTitles[2].textContent = langMap.wellness_plan;

    const dashboardPanelBadges = document.querySelectorAll('.dashboard-panel .title-row span');
    if (dashboardPanelBadges[0]) dashboardPanelBadges[0].textContent = t('saved_sessions_label');
    if (dashboardPanelBadges[1]) dashboardPanelBadges[1].textContent = langMap.my_account_badge;
    if (dashboardPanelBadges[2]) dashboardPanelBadges[2].textContent = langMap.am_pm_label;

    if (elements.settingsForm) {
      const settingsLabels = elements.settingsForm.querySelectorAll('label > span');
      const settingsValues = [
        t('dashboard_display_name'),
        t('dashboard_age'),
        t('dashboard_gender'),
        t('dashboard_skin_type'),
        t('dashboard_location_label'),
        t('dashboard_height'),
        t('dashboard_weight'),
        t('dashboard_language'),
        t('dashboard_allergies'),
        t('dashboard_medications'),
        t('dashboard_sun_sensitive'),
        t('dashboard_notifications'),
      ];
      settingsLabels.forEach((label, index) => {
        if (settingsValues[index]) label.textContent = settingsValues[index];
      });

      if (elements.settingsForm.full_name) elements.settingsForm.full_name.placeholder = state.lang === 'ar' ? 'اسم العرض' : 'Your display name';
      if (elements.settingsForm.age) elements.settingsForm.age.placeholder = '28';
      if (elements.settingsForm.location_text) elements.settingsForm.location_text.placeholder = state.lang === 'ar' ? 'دبي' : 'Dubai';

      const skinTypeSelect = elements.settingsForm.querySelector('select[name="skin_type"]');
      if (skinTypeSelect) {
        const options = skinTypeSelect.querySelectorAll('option');
        const vals = state.lang === 'ar'
          ? ['اختر', 'عادية', 'جافة', 'دهنية', 'مختلطة', 'حساسة']
          : ['Select', 'Normal', 'Dry', 'Oily', 'Combination', 'Sensitive'];
        options.forEach((opt, i) => {
          if (vals[i]) opt.textContent = vals[i];
        });
      }

      const preferredLangSelect = elements.settingsForm.querySelector('select[name="preferred_language"]');
      if (preferredLangSelect) {
        const options = preferredLangSelect.querySelectorAll('option');
        if (options[0]) options[0].textContent = 'English';
        if (options[1]) options[1].textContent = 'العربية';
      }

      const notifSelect = elements.settingsForm.querySelector('select[name="notifications_enabled"]');
      if (notifSelect) {
        const options = notifSelect.querySelectorAll('option');
        if (options[0]) options[0].textContent = langMap.dashboard_enabled;
        if (options[1]) options[1].textContent = langMap.dashboard_disabled;
      }

      const saveBtn = elements.settingsForm.querySelector('button[type="submit"]');
      if (saveBtn) saveBtn.textContent = langMap.dashboard_save_settings;
    }

    if (elements.planForm) {
      const planLabels = elements.planForm.querySelectorAll('label > span');
      if (planLabels[0]) planLabels[0].textContent = langMap.dashboard_morning_routine;
      if (planLabels[1]) planLabels[1].textContent = langMap.dashboard_night_routine;

      if (elements.planForm.morning_routine) {
        elements.planForm.morning_routine.placeholder =
          state.lang === 'ar' ? 'تنظيف لطيف، مرطب، واقي شمس...' : 'Gentle cleanse, moisturizer, sunscreen...';
      }
      if (elements.planForm.night_routine) {
        elements.planForm.night_routine.placeholder =
          state.lang === 'ar' ? 'غسول، سيروم مهدئ، مرطب...' : 'Cleanser, calming serum, moisturizer...';
      }

      const savePlanBtn = elements.planForm.querySelector('button[type="submit"]');
      if (savePlanBtn) savePlanBtn.textContent = langMap.dashboard_save_plan;
    }

    const pricingCards = document.querySelectorAll('#pricing .partner-card');
    if (pricingCards[0]) {
      const badge = pricingCards[0].querySelector('.tag-badge');
      const title = pricingCards[0].querySelector('.h3');
      const desc = pricingCards[0].querySelector('.body-text');
      const price = pricingCards[0].querySelector('.compact-price');
      const items = pricingCards[0].querySelectorAll('.compact-list li');
      if (badge) badge.textContent = langMap.pricing_free;
      if (title) title.textContent = langMap.pricing_guest;
      if (desc) desc.textContent = langMap.pricing_guest_desc;
      if (price) price.textContent = langMap.pricing_guest_price;
      if (items[0]) items[0].textContent = langMap.pricing_guest_feature_1;
      if (items[1]) items[1].textContent = langMap.pricing_guest_feature_2;
      if (items[2]) items[2].textContent = langMap.pricing_guest_feature_3;
    }

    if (pricingCards[1]) {
      const badge = pricingCards[1].querySelector('.tag-badge');
      const title = pricingCards[1].querySelector('.h3');
      const desc = pricingCards[1].querySelector('.body-text');
      const price = pricingCards[1].querySelector('.compact-price');
      const items = pricingCards[1].querySelectorAll('.compact-list li');
      if (badge) badge.textContent = langMap.pricing_popular;
      if (title) title.textContent = langMap.pricing_plus;
      if (desc) desc.textContent = langMap.pricing_plus_desc;
      if (price) price.textContent = langMap.pricing_plus_price;
      if (items[0]) items[0].textContent = langMap.pricing_plus_feature_1;
      if (items[1]) items[1].textContent = langMap.pricing_plus_feature_2;
      if (items[2]) items[2].textContent = langMap.pricing_plus_feature_3;
    }

    if (pricingCards[2]) {
      const badge = pricingCards[2].querySelector('.tag-badge');
      const title = pricingCards[2].querySelector('.h3');
      const desc = pricingCards[2].querySelector('.body-text');
      const price = pricingCards[2].querySelector('.compact-price');
      const items = pricingCards[2].querySelectorAll('.compact-list li');
      if (badge) badge.textContent = langMap.pricing_business;
      if (title) title.textContent = langMap.pricing_clinic;
      if (desc) desc.textContent = langMap.pricing_clinic_desc;
      if (price) price.textContent = langMap.pricing_clinic_price;
      if (items[0]) items[0].textContent = langMap.pricing_clinic_feature_1;
      if (items[1]) items[1].textContent = langMap.pricing_clinic_feature_2;
      if (items[2]) items[2].textContent = langMap.pricing_clinic_feature_3;
    }

    const faqCards = document.querySelectorAll('#faq .history-list article');
    if (faqCards[0]) {
      const q = faqCards[0].querySelector('.h4');
      const a = faqCards[0].querySelector('.body-text');
      if (q) q.textContent = langMap.faq_q1;
      if (a) a.textContent = langMap.faq_a1;
    }
    if (faqCards[1]) {
      const q = faqCards[1].querySelector('.h4');
      const a = faqCards[1].querySelector('.body-text');
      if (q) q.textContent = langMap.faq_q2;
      if (a) a.textContent = langMap.faq_a2;
    }
    if (faqCards[2]) {
      const q = faqCards[2].querySelector('.h4');
      const a = faqCards[2].querySelector('.body-text');
      if (q) q.textContent = langMap.faq_q3;
      if (a) a.textContent = langMap.faq_a3;
    }
    if (faqCards[3]) {
      const q = faqCards[3].querySelector('.h4');
      const a = faqCards[3].querySelector('.body-text');
      if (q) q.textContent = langMap.faq_q4;
      if (a) a.textContent = langMap.faq_a4;
    }

    const contactEyebrow = document.querySelector('#contact .eyebrow');
    if (contactEyebrow) contactEyebrow.textContent = langMap.contact_eyebrow;

    const contactTitle = document.querySelector('#contact .display');
    if (contactTitle) contactTitle.innerHTML = langMap.contact_heading;

    const contactSend = document.querySelector('#contact .cform .h3');
    if (contactSend) contactSend.textContent = langMap.contact_send;

    const contactLabels = document.querySelectorAll('#contact label > span');
    const contactValues = [
      langMap.contact_first,
      langMap.contact_last,
      langMap.contact_email,
      langMap.contact_inquiry,
      langMap.contact_message,
    ];
    contactLabels.forEach((el, i) => {
      if (contactValues[i]) el.textContent = contactValues[i];
    });

    const contactInputs = document.querySelectorAll('#contact .fi');
    if (contactInputs[0]) contactInputs[0].placeholder = langMap.first_name_placeholder;
    if (contactInputs[1]) contactInputs[1].placeholder = langMap.last_name_placeholder;
    if (contactInputs[2]) contactInputs[2].placeholder = langMap.contact_email_placeholder;
    if (contactInputs[4]) contactInputs[4].placeholder = langMap.contact_message_placeholder;

    const inquirySelect = document.querySelector('#contact select.fi');
    if (inquirySelect) {
      const options = inquirySelect.querySelectorAll('option');
      const vals = state.lang === 'ar'
        ? ['فرصة شراكة', 'استفسار استثماري', 'تعاون عيادة / علامة تجارية', 'صحافة / إعلام', 'استفسار عام']
        : ['Partnership Opportunity', 'Investment Inquiry', 'Clinic / Brand Collaboration', 'Press / Media', 'General Inquiry'];
      options.forEach((opt, i) => {
        if (vals[i]) opt.textContent = vals[i];
      });
    }

    const contactBtn = document.querySelector('#contact #cFormWrap .btn');
    if (contactBtn) contactBtn.textContent = langMap.contact_submit;

    const contactOkTitle = document.querySelector('#contact #formOk .h3');
    if (contactOkTitle) contactOkTitle.textContent = langMap.contact_success;

    const contactOkCopy = document.querySelector('#contact #formOk .body-text');
    if (contactOkCopy) contactOkCopy.textContent = langMap.contact_success_copy;
  }

  function applyTranslations() {
    document.querySelectorAll('[data-i18n]').forEach((node) => {
      const value = t(node.dataset.i18n);
      if (typeof value === 'string' && /<[^>]+>/.test(value)) node.innerHTML = value;
      else node.textContent = value;
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach((node) => {
      node.placeholder = t(node.dataset.i18nPlaceholder);
    });

    document.querySelectorAll('[data-i18n-aria-label]').forEach((node) => {
      node.setAttribute('aria-label', t(node.dataset.i18nAriaLabel));
    });

    document.title = t('page_title');
    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) metaDescription.setAttribute('content', t('page_description'));

    applyStaticTranslations();
    renderHistory();

    if (state.currentResult) renderResult(state.currentResult, false);
  }

  function setLanguage(lang) {
    state.lang = lang;
    localStorage.setItem('sidar_lang', lang);
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.body.classList.toggle('lang-ar', lang === 'ar');

    if (elements.langToggleBtn) elements.langToggleBtn.textContent = lang === 'ar' ? 'EN' : 'AR';
    if (elements.mobileLangToggleBtn) elements.mobileLangToggleBtn.textContent = lang === 'ar' ? 'EN' : 'AR';
    if (elements.mobileTopLangToggleBtn) elements.mobileTopLangToggleBtn.textContent = lang === 'ar' ? 'EN' : 'AR';

    applyTranslations();
    populateCountrySelects();
    if (elements.settingsForm?.preferred_language) {
      elements.settingsForm.preferred_language.value = getPreferredProfileLanguage();
    }
    updateAuthUi();
  }

  function embedScanIntoHow() {
    const howRoute = document.getElementById('how');
    const scanSection = document.getElementById('scan');
    if (!howRoute || !scanSection || howRoute.contains(scanSection)) return;

    scanSection.classList.remove('route', 'active-route');
    scanSection.removeAttribute('data-route');
    scanSection.classList.add('embedded-scan-section');
    howRoute.appendChild(scanSection);
  }

  function closeMobileMenu() {
    elements.mobileMenu?.classList.remove('open');
  }

  function activateRoute(routeId) {
    routes.forEach((route) => route.classList.toggle('active-route', route.id === routeId));
  }

  function navigate(hash) {
    const rawId = hash.replace('#', '') || 'landing';
    let routeId = rawId === 'scan' ? 'how' : (routeIds.includes(rawId) ? rawId : 'landing');
    const anchorTarget = rawId === 'scan' ? 'scan' : (routeIds.includes(rawId) ? null : rawId);

    if (routeId === 'dashboard' && !state.currentUser) routeId = 'guest';

    activateRoute(routeId);
    closeMobileMenu();

    requestAnimationFrame(() => {
      if (anchorTarget) {
        const target = document.getElementById(anchorTarget);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
          return;
        }
      }
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  function bindRouter() {
    window.addEventListener('hashchange', () => navigate(window.location.hash));
    document.querySelectorAll('a[href^="#"]').forEach((link) => {
      link.addEventListener('click', () => setTimeout(closeMobileMenu, 120));
    });
    navigate(window.location.hash || '#landing');
  }

  function bindAuthTabs() {
    authTabs.forEach((btn) => {
      btn.addEventListener('click', () => {
        authTabs.forEach((b) => b.classList.remove('active'));
        Object.values(authForms).forEach((form) => form.classList.remove('active-auth-form'));
        btn.classList.add('active');
        authForms[btn.dataset.authTab].classList.add('active-auth-form');
      });
    });
  }

  function bindRevealAnimations() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) entry.target.classList.add('in-view');
      });
    }, { threshold: 0.1 });

    document.querySelectorAll('.reveal-up, .rv').forEach((node) => observer.observe(node));
  }

  function renderImagePreview() {
    if (!elements.imagePreviewGrid) return;
    elements.imagePreviewGrid.innerHTML = '';

    state.selectedFiles.forEach((file, index) => {
      const card = document.createElement('article');
      card.className = 'preview-card';

      const img = document.createElement('img');
      img.className = 'preview-image';
      img.src = URL.createObjectURL(file);
      img.alt = file.name;

      const footer = document.createElement('div');
      footer.className = 'preview-footer';
      footer.innerHTML = `<div class="preview-file-meta"><strong>${file.name}</strong><span>${Math.round(file.size / 1024)} KB</span></div>`;

      const removeBtn = document.createElement('button');
      removeBtn.type = 'button';
      removeBtn.className = 'preview-delete-btn';
      removeBtn.setAttribute('aria-label', t('delete'));
      removeBtn.innerHTML = '&times;';
      removeBtn.addEventListener('click', () => {
        state.selectedFiles.splice(index, 1);
        renderImagePreview();
      });

      card.append(img, removeBtn, footer);
      elements.imagePreviewGrid.appendChild(card);
    });
  }

  function bindUploader() {
    if (!elements.imageInput) return;

    elements.imageInput.addEventListener('change', (e) => {
      const files = Array.from(e.target.files || []);
      const next = [...state.selectedFiles, ...files].slice(0, 5);

      if (state.selectedFiles.length + files.length > 5) showToast(t('images_limit'), 'error');

      state.selectedFiles = next;
      renderImagePreview();
      elements.imageInput.value = '';
    });

    elements.clearScanBtn?.addEventListener('click', () => {
      state.selectedFiles = [];
      elements.scanForm?.reset();
      renderImagePreview();
    });
  }

  function localizePriority(priority) {
    const normalized = String(priority || '').toLowerCase();
    if (normalized.includes('high') || normalized.includes('urgent')) return state.lang === 'ar' ? 'عالية' : 'High';
    if (normalized.includes('low')) return state.lang === 'ar' ? 'منخفضة' : 'Low';
    return state.lang === 'ar' ? 'متوسطة' : 'Moderate';
  }

  function localizeImageQuality(value) {
    const normalized = String(value || '').toLowerCase();
    if (normalized.includes('low')) return state.lang === 'ar' ? 'منخفضة' : 'Low';
    if (normalized.includes('good')) return state.lang === 'ar' ? 'جيدة' : 'Good';
    return state.lang === 'ar' ? 'متوسطة' : 'Medium';
  }

  function buildPriorityClass(priority) {
    const normalized = String(priority || '').toLowerCase();
    if (normalized.includes('high') || normalized.includes('urgent')) return 'high';
    if (normalized.includes('low')) return 'low';
    return 'medium';
  }

  function buildScoreSet(result) {
    const confidenceValue = Number(String(result.ai_confidence || '').replace('%', ''));
    const overall = Number.isFinite(Number(result.overall_score))
      ? Number(result.overall_score)
      : (Number.isFinite(confidenceValue) ? confidenceValue : null);

    const target =
      result.analysis_target ||
      (String(result.input?.scan_type || '').includes('hair') || result.input?.body_location === 'scalp' ? 'hair' : 'skin');

    if (target === 'hair') {
      return {
        label: t('score_label_hair'),
        summary: overall == null ? t('results_empty_guidance') : t('score_summary_hair_good'),
        overall,
        hydration: Number.isFinite(Number(result.hair_density_score)) ? Number(result.hair_density_score) : null,
        pore: Number.isFinite(Number(result.hair_texture_score)) ? Number(result.hair_texture_score) : null,
        fine: Number.isFinite(Number(result.hair_strength_score)) ? Number(result.hair_strength_score) : null,
        tone: Number.isFinite(Number(result.scalp_health_score)) ? Number(result.scalp_health_score) : null,
        labels: [t('score_metric_density'), t('score_metric_texture'), t('score_metric_strength'), t('score_metric_scalp_health')],
      };
    }

    return {
      label: t('score_label_skin'),
      summary: overall == null ? t('results_empty_guidance') : (overall >= 85 ? t('score_summary_skin_good') : t('score_summary_skin_followup')),
      overall,
      hydration: Number.isFinite(Number(result.hydration_score)) ? Number(result.hydration_score) : null,
      pore: Number.isFinite(Number(result.pore_clarity_score)) ? Number(result.pore_clarity_score) : null,
      fine: Number.isFinite(Number(result.fine_lines_score)) ? Number(result.fine_lines_score) : (overall == null ? null : Math.max(0, overall - 4)),
      tone: Number.isFinite(Number(result.overall_tone_score)) ? Number(result.overall_tone_score) : (overall == null ? null : Math.min(100, overall + 2)),
      labels: [t('score_metric_hydration'), t('score_metric_pore_clarity'), t('score_metric_fine_lines'), t('score_metric_overall_tone')],
    };
  }

  function defaultNaturalProducts() {
    return state.lang === 'ar'
      ? [
          { name: 'جل الصبار النقي', desc: 'للتهدئة والترطيب الخفيف' },
          { name: 'زيت الجوجوبا', desc: 'لدعم الحاجز الطبيعي للبشرة' },
          { name: 'شاي أخضر مهدئ', desc: 'كمادات لطيفة للبشرة المتهيجة' },
        ]
      : [
          { name: 'Pure Aloe Vera Gel', desc: 'For soothing and light hydration' },
          { name: 'Jojoba Oil', desc: 'To support the skin barrier' },
          { name: 'Green Tea Compress', desc: 'A gentle option for irritated skin' },
        ];
  }

  function defaultCommercialProducts(result) {
    const target =
      result?.analysis_target ||
      (String(result?.input?.scan_type || '').includes('hair') || result?.input?.body_location === 'scalp' ? 'hair' : 'skin');

    if (state.lang === 'ar') {
      return target === 'hair'
        ? [
            { name: 'Ducray Anaphase+ Shampoo', desc: 'شامبو داعم لكثافة الشعر وفروة الرأس', price: '$21.50', image: './assets/laroche_cicaplast_b5.png' },
            { name: 'Vichy Dercos Energising Shampoo', desc: 'شامبو مقوٍ للشعر الضعيف', price: '$19.90', image: './assets/cerave_hydrating_cleanser.webp' },
            { name: 'The Ordinary Multi-Peptide Serum for Hair Density', desc: 'سيروم داعم لكثافة الشعر', price: '$23.00', image: './assets/theordinary_niacinamide.webp' },
          ]
        : [
            { name: 'CeraVe Hydrating Cleanser 236ml', desc: 'غسول لطيف للبشرة العادية إلى الجافة', price: '$9.99', image: './assets/cerave_hydrating_cleanser.webp' },
            { name: 'La Roche-Posay Cicaplast Baume B5+ 40ml', desc: 'بلسم مهدئ لدعم حاجز البشرة', price: '$18.99', image: './assets/laroche_cicaplast_b5.png' },
            { name: 'The Ordinary Niacinamide 10% + Zinc 1% 30ml', desc: 'سيروم يدعم مظهر المسام وتوازن الدهون', price: '$13.80', image: './assets/theordinary_niacinamide.webp' },
          ];
    }

    return target === 'hair'
      ? [
          { name: 'Ducray Anaphase+ Shampoo', desc: 'Supportive shampoo for hair density and scalp care', price: '$21.50', image: './assets/laroche_cicaplast_b5.png' },
          { name: 'Vichy Dercos Energising Shampoo', desc: 'Fortifying shampoo for weakened hair', price: '$19.90', image: './assets/cerave_hydrating_cleanser.webp' },
          { name: 'The Ordinary Multi-Peptide Serum for Hair Density', desc: 'Density-support serum for the scalp', price: '$23.00', image: './assets/theordinary_niacinamide.webp' },
        ]
      : [
          { name: 'CeraVe Hydrating Cleanser 236ml', desc: 'Gentle cleanser for normal to dry skin', price: '$9.99', image: './assets/cerave_hydrating_cleanser.webp' },
          { name: 'La Roche-Posay Cicaplast Baume B5+ 40ml', desc: 'Barrier-support soothing balm', price: '$18.99', image: './assets/laroche_cicaplast_b5.png' },
          { name: 'The Ordinary Niacinamide 10% + Zinc 1% 30ml', desc: 'Supports oil balance and visible pores', price: '$13.80', image: './assets/theordinary_niacinamide.webp' },
        ];
  }

  function defaultDoctors(result) {
    const target =
      result?.analysis_target ||
      (String(result?.input?.scan_type || '').includes('hair') || result?.input?.body_location === 'scalp' ? 'hair' : 'skin');

    if (state.lang === 'ar') {
      return target === 'hair'
        ? [
            { name: 'د. ليان فؤاد', specialty: 'استشارية جلدية وشعر', address: 'عيادات النخبة الطبية، شارع التسعين، القاهرة الجديدة', link: '#contact' },
            { name: 'د. كريم نادر', specialty: 'عيادة الشعر وفروة الرأس', address: 'مركز كير بلس، مدينة نصر، القاهرة', link: '#contact' },
            { name: 'د. سارة مأمون', specialty: 'جلدية وتجميل علاجي', address: 'عيادات دار الجلدية، الشيخ زايد، الجيزة', link: '#contact' },
          ]
        : [
            { name: 'د. مريم عادل', specialty: 'استشارية جلدية', address: 'عيادات ميديكال هب، المعادي، القاهرة', link: '#contact' },
            { name: 'د. يوسف سامح', specialty: 'جلدية وحساسية', address: 'مركز ديرما كير، سموحة، الإسكندرية', link: '#contact' },
            { name: 'د. ندى شريف', specialty: 'جلدية تجميلية', address: 'عيادات فيتاليا، التجمع الخامس، القاهرة', link: '#contact' },
          ];
    }

    return target === 'hair'
      ? [
          { name: 'Dr. Layan Fouad', specialty: 'Dermatology & Hair Specialist', address: 'Elite Medical Clinics, 90th Street, New Cairo', link: '#contact' },
          { name: 'Dr. Karim Nader', specialty: 'Hair & Scalp Clinic', address: 'Care Plus Center, Nasr City, Cairo', link: '#contact' },
          { name: 'Dr. Sarah Mamoun', specialty: 'Dermatology & Therapeutic Aesthetics', address: 'Dar Dermatology Clinics, Sheikh Zayed, Giza', link: '#contact' },
        ]
      : [
          { name: 'Dr. Mariam Adel', specialty: 'Consultant Dermatologist', address: 'Medical Hub Clinics, Maadi, Cairo', link: '#contact' },
          { name: 'Dr. Youssef Sameh', specialty: 'Dermatology & Allergy', address: 'Derma Care Center, Smouha, Alexandria', link: '#contact' },
          { name: 'Dr. Nada Sherif', specialty: 'Aesthetic Dermatology', address: 'Vitalia Clinics, Fifth Settlement, Cairo', link: '#contact' },
        ];
  }

  function normalizeProductArray(value, fallbackFactory) {
    if (Array.isArray(value) && value.length) {
      return value.map((item) => (typeof item === 'string' ? { name: item, desc: '' } : item));
    }

    if (typeof value === 'string' && value.trim()) {
      try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) return parsed.map((item) => (typeof item === 'string' ? { name: item, desc: '' } : item));
      } catch {}
    }

    return typeof fallbackFactory === 'function' ? fallbackFactory() : [];
  }

  function normalizeDoctorArray(value, fallbackFactory) {
    if (Array.isArray(value) && value.length) {
      return value.map((item) => (typeof item === 'string' ? { name: item, meta: '', link: '#' } : item));
    }

    if (typeof value === 'string' && value.trim()) {
      try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) return parsed;
      } catch {}
    }

    return typeof fallbackFactory === 'function' ? fallbackFactory() : [];
  }

  function defaultDoctors(result) {
    if (state.liveDoctors && state.liveDoctors.length) {
      const targetCountry = getResultCountryLabel(result);
      const filtered = state.liveDoctors.filter(d => 
        (d.country || '').toLowerCase().includes((targetCountry || '').toLowerCase()) ||
        (d.city || '').toLowerCase().includes((targetCountry || '').toLowerCase())
      );
      const pool = filtered.length ? filtered : state.liveDoctors;
      return pool.map(d => ({
        name: d.profiles?.full_name || d.name,
        specialty: d.specialization || (state.lang === 'ar' ? 'أخصائي جلدية' : 'Dermatology Specialist'),
        address: `${d.clinic_hospital || ''}, ${d.city || ''}, ${d.country || ''}`,
        link: '#contact'
      }));
    }
    const target =
      result?.analysis_target ||
      (String(result?.input?.scan_type || '').includes('hair') || result?.input?.body_location === 'scalp' ? 'hair' : 'skin');
    const kit = doctorAddressKit(result);
    const hairCase = target === 'hair';
    const specialty = hairCase ? (state.lang === 'ar' ? 'شعر وفروة رأس' : 'Hair & scalp') : kit[1];

    return [
      {
        name: hairCase ? (state.lang === 'ar' ? kit[0].replace('للجلدية', 'للشعر وفروة الرأس') : kit[0].replace('Dermatology', 'Hair & Scalp')) : kit[0],
        specialty,
        address: kit[2],
        link: '#contact',
      },
      {
        name: kit[3],
        specialty: hairCase ? (state.lang === 'ar' ? 'متابعة فروة الرأس' : 'Scalp follow-up') : (state.lang === 'ar' ? 'متابعة جلدية متخصصة' : 'Specialist follow-up'),
        address: kit[4],
        link: '#contact',
      },
      {
        name: kit[5],
        specialty,
        address: kit[6],
        link: '#contact',
      },
    ];
  }

  function mapPriorityToUrgency(priority) {
    const normalized = String(priority || '').toLowerCase();
    if (normalized.includes('high') || normalized.includes('urgent')) return 'high';
    if (normalized.includes('low')) return 'low';
    return 'medium';
  }

  function mapUrgencyToPriority(urgency) {
    const normalized = String(urgency || '').toLowerCase();
    if (normalized.includes('high')) return 'High';
    if (normalized.includes('low')) return 'Low';
    return 'Moderate';
  }

  function normalizeScanRow(row) {
    if (!row) return null;
    if (row.case_priority || row.visible_patterns || row.guidance || row.next_steps) return row;

    return {
      ...row,
      title: row.report_title || row.title || '',
      ai_confidence: row.ai_confidence || '',
      case_priority: mapUrgencyToPriority(row.urgency),
      image_quality: row.image_quality || '',
      visible_patterns: Array.isArray(row.visible_findings) ? row.visible_findings : [],
      guidance: row.problem_description || row.summary || '',
      next_steps: Array.isArray(row.care_steps) ? row.care_steps : [],
      images: Array.isArray(row.image_urls) ? row.image_urls.map((url) => ({ publicUrl: url, fileName: '' })) : (Array.isArray(row.images) ? row.images : []),
      reasons: Array.isArray(row.reasons) ? row.reasons : [],
      disclaimer: row.disclaimer || '',
      analysis_target: row.analysis_target,
      issue_type: row.issue_type,
      overall_score: row.overall_score,
      hydration_score: row.hydration_score,
      pore_clarity_score: row.pore_clarity_score,
      fine_lines_score: row.fine_lines_score,
      overall_tone_score: row.overall_tone_score,
      hair_density_score: row.hair_density_score,
      hair_texture_score: row.hair_texture_score,
      hair_strength_score: row.hair_strength_score,
      scalp_health_score: row.scalp_health_score,
      morning_routine: Array.isArray(row.morning_routine) ? row.morning_routine : [],
      evening_routine: Array.isArray(row.evening_routine) ? row.evening_routine : [],
      natural_product_suggestions: row.natural_product_suggestions,
      commercial_product_suggestions: row.commercial_product_suggestions,
      nearby_doctors: row.nearby_doctors,
      input: {
        scan_type: row.scan_type,
        body_location: row.body_location,
        duration: row.duration,
        severity: row.severity,
        symptoms: Array.isArray(row.symptoms) ? row.symptoms : [],
        notes: row.notes || '',
        issue_type: row.issue_type || '',
        skin_type_context: row.concern_category || '',
      },
      created_at: row.created_at,
    };
  }

  function buildUnifiedScanPayload(result) {
    const scoreSet = buildScoreSet(result);

    return {
      title: result.title || '',
      report_title: result.title || '',
      scan_type: result.input.scan_type,
      body_location: result.input.body_location,
      duration: result.input.duration,
      severity: result.input.severity,
      symptoms: result.input.symptoms,
      notes: result.input.notes,
      issue_type: result.input.issue_type || result.issue_type || '',
      concern_category: result.input.skin_type_context || '',
      analysis_target:
        result.analysis_target || (['hair_check', 'scalp_check'].includes(result.input.scan_type) || result.input.body_location === 'scalp' ? 'hair' : 'skin'),
      image_urls: Array.isArray(result.images) ? result.images.map((item) => item.publicUrl).filter(Boolean) : [],
      images_count: Array.isArray(result.images) ? result.images.length : 0,
      language_code: state.lang,
      ai_confidence: result.ai_confidence || '',
      summary: result.guidance || '',
      problem_description: result.guidance || '',
      urgency: mapPriorityToUrgency(result.case_priority),
      image_quality: result.image_quality || '',
      visible_findings: result.visible_patterns || [],
      care_steps: result.next_steps || [],
      reasons: result.reasons || [],
      overall_score: scoreSet.overall,
      hydration_score: scoreSet.hydration,
      pore_clarity_score: scoreSet.pore,
      fine_lines_score: scoreSet.fine,
      overall_tone_score: scoreSet.tone,
      morning_routine: Array.isArray(result.morning_routine) ? result.morning_routine : [],
      evening_routine: Array.isArray(result.evening_routine) ? result.evening_routine : [],
      natural_product_suggestions: Array.isArray(result.natural_product_suggestions) ? result.natural_product_suggestions : [],
      commercial_product_suggestions: Array.isArray(result.commercial_product_suggestions) ? result.commercial_product_suggestions : [],
      nearby_doctors: Array.isArray(result.nearby_doctors) ? result.nearby_doctors : [],
      disclaimer:
        result.disclaimer || (state.lang === 'ar' ? 'إرشادات تعليمية وليست تشخيصًا طبيًا نهائيًا.' : 'Educational guidance only, not a final medical diagnosis.'),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
  }

  function getScanFormData() {
    const formData = new FormData(elements.scanForm);
    const selectedLocation = formData.get('location_text')?.trim() || getProfileLocation();
    return {
      scan_type: formData.get('scan_type'),
      issue_type: formData.get('issue_type'),
      skin_type_context: formData.get('skin_type_context'),
      body_location: formData.get('body_location'),
      duration: formData.get('duration'),
      severity: formData.get('severity'),
      symptoms: formData.getAll('symptoms'),
      notes: formData.get('notes')?.trim() || '',
    };
  }

  function renderSteps(container, items) {
    if (!container) return;
    container.innerHTML = '';

    if (!items?.length) {
      const li = document.createElement('li');
      li.className = 'empty-copy';
      li.textContent = state.lang === 'ar' ? 'لا توجد بيانات متاحة لهذا القسم بعد.' : 'No data available for this section yet.';
      container.appendChild(li);
      return;
    }

    items.forEach((step) => {
      const li = document.createElement('li');
      li.textContent = step;
      container.appendChild(li);
    });
  }
function renderProducts(container, items, showPrice = true) {
  if (!container) return;
  container.innerHTML = '';

  if (!items?.length) {
    const card = document.createElement('article');
    card.className = 'suggestion-card empty-copy';
    card.textContent =
      state.lang === 'ar'
        ? 'لا توجد اقتراحات متاحة حاليًا.'
        : 'No recommendations are available right now.';
    container.appendChild(card);
    return;
  }

  items.forEach((item) => {
    const name = item?.name || (state.lang === 'ar' ? 'منتج مقترح' : 'Suggested product');
    const desc = item?.desc || item?.description || '';
    const price = showPrice ? (item?.price || '') : '';
    const image = item?.image || './assets/product-placeholder.png';

    const card = document.createElement('article');
    card.className = 'suggestion-card product-card';

    card.innerHTML = `
      <div class="product-card-image">
        <img 
          src="${image}" 
          alt="${name}" 
          loading="lazy"
          onerror="this.src='./assets/product-placeholder.png'"
        >
      </div>
      <div class="product-card-copy">
        <strong class="product-name">${name}</strong>
        ${price ? `<div class="product-price">${price}</div>` : ''}
        ${desc ? `<span class="product-desc">${desc}</span>` : ''}
        ${item?.link && item.link !== '#' ? `<a class="doctor-cta" href="${item.link}" target="_blank" rel="noopener noreferrer">${state.lang === 'ar' ? 'عرض المنتج' : 'View product'}</a>` : ''}
      </div>
    `;

    container.appendChild(card);
  });
}

  function renderDoctors(container, items) {
    if (!container) return;
    container.innerHTML = '';

    if (!items?.length) {
      const card = document.createElement('article');
      card.className = 'doctor-card empty-copy';
      card.textContent = state.lang === 'ar' ? 'لا توجد اقتراحات أطباء متاحة لهذه المنطقة حاليًا.' : 'No doctor suggestions are available for this location right now.';
      container.appendChild(card);
      return;
    }

    items.forEach((item) => {
      const link = document.createElement('a');
      link.className = 'doctor-card-link';
      link.href = item.link || '#contact';
      if (/^https?:\/\//i.test(link.href)) {
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
      }
      link.innerHTML = `
        <article class="doctor-card">
          <strong>${item.name || ''}</strong>
          <span class="doctor-specialty">${item.specialty || item.meta || ''}</span>
          <span class="doctor-address">${item.address || ''}</span>
          <span class="doctor-cta">${state.lang === 'ar' ? 'تواصل الآن' : 'Contact now'}</span>
        </article>
      `;
      container.appendChild(link);
    });
  }

  function renderResult(result, navigateToPage = true) {
    result = normalizeScanRow(result) || result;
    state.currentResult = result;

    const localizedPriority = localizePriority(result.case_priority || '--');
    const localizedQuality = localizeImageQuality(result.image_quality || '--');
    const priorityClass = buildPriorityClass(result.case_priority || '--');
    const scoreSet = buildScoreSet(result);
    const morningRoutine = Array.isArray(result.morning_routine) ? result.morning_routine : [];
    const eveningRoutine = Array.isArray(result.evening_routine) ? result.evening_routine : [];
    const naturalProducts = normalizeProductArray(result.natural_product_suggestions, () => defaultNaturalProducts(result)).map((item) => ({ ...item, price: '' }));
    const commercialProducts = normalizeProductArray(result.commercial_product_suggestions, () => defaultCommercialProducts(result));
    let nearbyDoctors = normalizeDoctorArray(result.nearby_doctors, () => defaultDoctors(result));
    if (shouldReplaceDoctorList(nearbyDoctors, result)) nearbyDoctors = defaultDoctors(result);
    const reasons = Array.isArray(result.reasons) ? result.reasons : [];

    if (elements.resultTitle) elements.resultTitle.textContent = result.title || t('report_title');
    if (elements.resultTitleClone) elements.resultTitleClone.textContent = result.title || t('report_title');

    if (elements.resultGuidance) {
      elements.resultGuidance.textContent = result.guidance || result.problem_description || t('results_empty_guidance');
      elements.resultGuidance.classList.toggle('empty-copy', !(result.guidance || result.problem_description));
    }

    if (elements.resultPriority) elements.resultPriority.textContent = localizedPriority;
    if (elements.resultPriorityClone) elements.resultPriorityClone.textContent = localizedPriority;
    if (elements.resultConfidence) elements.resultConfidence.textContent = result.ai_confidence || '--';
    if (elements.resultConfidenceClone) elements.resultConfidenceClone.textContent = result.ai_confidence || '--';
    if (elements.resultImageQuality) elements.resultImageQuality.textContent = localizedQuality;
    if (elements.resultImageQualityClone) elements.resultImageQualityClone.textContent = localizedQuality;

    if (elements.resultPriorityBadge) {
      elements.resultPriorityBadge.textContent = localizedPriority;
      elements.resultPriorityBadge.className = `priority-chip ${priorityClass}`;
    }

    if (elements.resultPriorityIcon) elements.resultPriorityIcon.textContent = priorityClass === 'high' ? '!' : priorityClass === 'low' ? '✓' : '•';

    if (elements.resultPriorityBadgeClone) {
      elements.resultPriorityBadgeClone.textContent = localizedPriority;
      elements.resultPriorityBadgeClone.className = `priority-chip ${priorityClass}`;
    }

    if (elements.resultPriorityIconClone) elements.resultPriorityIconClone.textContent = priorityClass === 'high' ? '!' : priorityClass === 'low' ? '✓' : '•';

    if (elements.resultGuidanceClone) {
      elements.resultGuidanceClone.textContent = result.guidance || result.problem_description || t('results_empty_guidance');
      elements.resultGuidanceClone.classList.toggle('empty-copy', !(result.guidance || result.problem_description));
    }

    if (elements.resultPrioritySupport) elements.resultPrioritySupport.textContent = t('share_report_support');

    if (elements.resultPatterns) {
      elements.resultPatterns.innerHTML = '';
      elements.resultPatterns.className = 'result-findings-list';

      if ((result.visible_patterns || []).length) {
        result.visible_patterns.forEach((pattern) => {
          const item = document.createElement('div');
          item.className = 'finding-item';
          item.innerHTML = `<span class="finding-icon">◌</span><strong>${pattern}</strong>`;
          elements.resultPatterns.appendChild(item);
        });
      } else {
        elements.resultPatterns.className = 'result-findings-list empty-copy';
        elements.resultPatterns.textContent = t('no_patterns_yet');
      }
    }

    if (elements.resultPatternsClone) {
      elements.resultPatternsClone.innerHTML = '';
      elements.resultPatternsClone.className = 'result-findings-list';

      if ((result.visible_patterns || []).length) {
        result.visible_patterns.forEach((pattern) => {
          const item = document.createElement('div');
          item.className = 'finding-item';
          item.innerHTML = `<span class="finding-icon">◌</span><strong>${pattern}</strong>`;
          elements.resultPatternsClone.appendChild(item);
        });
      } else {
        elements.resultPatternsClone.className = 'result-findings-list empty-copy';
        elements.resultPatternsClone.textContent = t('no_patterns_yet');
      }
    }

    if (elements.resultOverallScore) elements.resultOverallScore.textContent = scoreSet.overall == null ? '--' : Math.round(scoreSet.overall);
    if (elements.resultOverallScoreClone) elements.resultOverallScoreClone.textContent = scoreSet.overall == null ? '--' : Math.round(scoreSet.overall);
    if (elements.resultScoreLabel) elements.resultScoreLabel.textContent = scoreSet.label;
    if (elements.resultScoreLabelClone) elements.resultScoreLabelClone.textContent = scoreSet.label;
    if (elements.resultScoreSummary) elements.resultScoreSummary.textContent = scoreSet.summary;
    if (elements.resultScoreSummaryClone) elements.resultScoreSummaryClone.textContent = scoreSet.summary;

    if (elements.scoreRing) elements.scoreRing.style.setProperty('--score', scoreSet.overall == null ? 0 : Math.max(0, Math.min(100, scoreSet.overall)));
    if (elements.scoreRingClone) elements.scoreRingClone.style.setProperty('--score', scoreSet.overall == null ? 0 : Math.max(0, Math.min(100, scoreSet.overall)));

    const metricMap = [
      [elements.hydrationValue, elements.hydrationBar, scoreSet.hydration],
      [elements.poreValue, elements.poreBar, scoreSet.pore],
      [elements.fineLinesValue, elements.fineLinesBar, scoreSet.fine],
      [elements.toneValue, elements.toneBar, scoreSet.tone],
      [elements.hydrationValueClone, elements.hydrationBarClone, scoreSet.hydration],
      [elements.poreValueClone, elements.poreBarClone, scoreSet.pore],
      [elements.fineLinesValueClone, elements.fineLinesBarClone, scoreSet.fine],
      [elements.toneValueClone, elements.toneBarClone, scoreSet.tone],
    ];

    metricMap.forEach(([valueEl, barEl, score]) => {
      if (valueEl) valueEl.textContent = score == null ? '--' : `${Math.round(score)}%`;
      if (barEl) barEl.style.width = score == null ? '0%' : `${Math.max(0, Math.min(100, score))}%`;
    });

    const lines = document.querySelectorAll('.score-lines');
    lines.forEach((group) => {
      const spans = group.querySelectorAll('.metric-line.big > span');
      if (spans[0]) spans[0].textContent = scoreSet.labels[0];
      if (spans[1]) spans[1].textContent = scoreSet.labels[1];
      if (spans[2]) spans[2].textContent = scoreSet.labels[2];
      if (spans[3]) spans[3].textContent = scoreSet.labels[3];
    });

    renderSteps(elements.morningRoutineList, morningRoutine);
    renderSteps(elements.eveningRoutineList, eveningRoutine);
    renderProducts(elements.naturalProductsList, naturalProducts, false);
    renderProducts(elements.commercialProductsList, commercialProducts);
    renderDoctors(elements.nearbyDoctorsList, nearbyDoctors);

    if (elements.resultReasons) {
      elements.resultReasons.innerHTML = '';
      if (!reasons.length) {
        const row = document.createElement('div');
        row.className = 'reason-item';
        row.innerHTML = `<span class="reason-dot">i</span><p>${state.lang === 'ar' ? 'لا توجد أسباب تفصيلية إضافية في نتيجة التحليل الحالية.' : 'No additional reasoning details were returned in this analysis.'}</p>`;
        elements.resultReasons.appendChild(row);
      } else {
        reasons.forEach((reason) => {
          const row = document.createElement('div');
          row.className = 'reason-item';
          row.innerHTML = `<span class="reason-dot">i</span><p>${reason}</p>`;
          elements.resultReasons.appendChild(row);
        });
      }
    }

    if (navigateToPage) window.location.hash = '#results';
  }

  async function analyzeScan(event) {
    event.preventDefault();

    if (!state.selectedFiles.length) {
      showToast(t('no_images'), 'error');
      return;
    }

    const formPayload = getScanFormData();
    const supabaseReady = window.SidarSupabase.canUseSupabase();
    let uploadedImages = state.selectedFiles.map((file) => ({ fileName: file.name, publicUrl: '' }));

    const submitBtn = elements.scanForm?.querySelector('button[type="submit"]');
    const originalLabel = submitBtn?.textContent || '';

    try {
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = state.lang === 'ar' ? 'جارٍ التحليل...' : 'Analyzing...';
      }

      if (supabaseReady) {
        const ownerId = state.currentUser?.id || `guest-${crypto.randomUUID()}`;
        uploadedImages = await window.SidarSupabase.uploadImages(state.selectedFiles, ownerId);
      }

      if (!window.SidarAI?.generateAnalysis) {
        throw new Error(
          state.lang === 'ar'
            ? 'خطأ في الاتصال بخدمة الذكاء الاصطناعي (Gemini/Firebase). تأكد من الربط والشبكة.'
            : 'Error connecting to Gemini/Firebase AI service. Check connection and setup.'
        );
      }

      const catalogRes = await window.SidarSupabase.getRecommendationCatalog(formPayload);
      if (catalogRes.error) throw catalogRes.error;
      const catalog = catalogRes.data || { doctors: [], products: [] };
      const result = await window.SidarAI.generateAnalysis(formPayload, state.selectedFiles, state.lang, catalog);
      if (!result) throw new Error(t('generate_result_error'));

      // Gemini selects IDs only; presentation data is always read from verified database records.
      const productsById = new Map((catalog.products || []).map((item) => [String(item.id), item]));
      const doctorsById = new Map((catalog.doctors || []).map((item) => [String(item.id), item]));
      const selectedProducts = (result.suggested_product_ids || []).map((id) => productsById.get(String(id))).filter(Boolean);
      const selectedDoctors = (result.suggested_doctor_ids || []).map((id) => doctorsById.get(String(id))).filter(Boolean);
      result.commercial_product_suggestions = selectedProducts.map((product) => ({
        id: product.id, name: [product.brand, product.name].filter(Boolean).join(' '), desc: product.description || '',
        price: product.price == null ? '' : `${product.price} ${product.currency || ''}`.trim(), image: product.image_url || '', link: product.product_url || '#',
      }));
      result.nearby_doctors = selectedDoctors.map((doctor) => ({
        id: doctor.id, name: doctor.full_name, specialty: doctor.specialization,
        address: [doctor.clinic_hospital, doctor.city, doctor.country].filter(Boolean).join('، '), link: doctor.booking_url || doctor.contact_url || '#',
      }));

      result.images = uploadedImages;
      result.input = formPayload;

      renderResult(result);
      showToast(t('report_generated'));
    } catch (error) {
      console.error(error);
      showToast(error.message || t('something_went_wrong'), 'error');
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = originalLabel || t('analyze_now');
      }
    }
  }

  function buildShareText() {
    if (!state.currentResult) return t('share_text_report_title');

    const scoreSet = buildScoreSet(state.currentResult);

    return [
      t('share_text_report_title'),
      `${state.currentResult.title || t('share_text_default_analysis')}`,
      `${t('share_text_score')}: ${scoreSet.overall == null ? '--' : Math.round(scoreSet.overall)}`,
      `${t('share_text_priority')}: ${localizePriority(state.currentResult.case_priority || '--')}`,
      `${t('share_text_summary')}: ${state.currentResult.guidance || ''}`,
    ].join('\n');
  }

  function copyText(text, successMessage) {
    navigator.clipboard
      .writeText(text)
      .then(() => showToast(successMessage || t('copy_success')))
      .catch(() => showToast(t('copy_error'), 'error'));
  }

  function shareViaWeb(title, text, fallbackUrl) {
    if (navigator.share) {
      navigator.share({ title, text }).catch(() => {});
      return;
    }
    window.open(fallbackUrl, '_blank', 'noopener');
  }

  function downloadReport() {
    if (!state.currentResult) return;

    const lines = [buildShareText(), '', ...(state.currentResult.next_steps || [])].join('\n');
    const blob = new Blob([lines], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `sidar-report-${Date.now()}.txt`;
    a.click();

    URL.revokeObjectURL(url);
  }

  async function saveCurrentScan() {
    if (!state.currentResult) return;

    const payload = buildUnifiedScanPayload(state.currentResult);

    try {
      if (state.currentUser && window.SidarSupabase.canUseSupabase()) {
        const { error } = await window.SidarSupabase.saveScan({ user_id: state.currentUser.id, ...payload });
        if (error) throw error;

        showToast(state.lang === 'ar' ? 'تم حفظ التحليل في الحساب.' : 'Scan saved to account.');
        await loadDashboardData();
      } else {
        state.history.unshift(normalizeScanRow(payload));
        state.history = state.history.slice(0, 12);
        localStorage.setItem('sidar_guest_history', JSON.stringify(state.history));
        showToast(t('scan_saved_device'));
        renderHistory();
      }
    } catch (error) {
      console.error(error);
      showToast(error.message || 'Unable to save.', 'error');
    }
  }

  function formatDate(dateString) {
    try {
      return new Intl.DateTimeFormat(state.lang === 'ar' ? 'ar-EG' : 'en-US', {
        dateStyle: 'medium',
        timeStyle: 'short',
      }).format(new Date(dateString));
    } catch {
      return dateString;
    }
  }

  function renderHistory(items = state.history) {
    if (!elements.historyList) return;

    elements.historyList.innerHTML = '';

    if (!items?.length) {
      const card = document.createElement('div');
      card.className = 'history-card';
      card.textContent = t('no_saved_scans_short');
      elements.historyList.appendChild(card);

      if (elements.totalScansKpi) elements.totalScansKpi.textContent = '0';
      if (elements.latestPriorityKpi) elements.latestPriorityKpi.textContent = '--';
      if (elements.savedPlanKpi) elements.savedPlanKpi.textContent = 'AM/PM';
      return;
    }

    items.forEach((rawScan) => {
      const scan = normalizeScanRow(rawScan) || rawScan;
      const card = document.createElement('article');
      card.className = 'history-card';

      const localizedPriority = localizePriority(scan.case_priority || '--');

      card.innerHTML = `
        <strong>${scan.title || scan.scan_type?.replace(/_/g, ' ') || t('history_fallback_title')}</strong>
        <div class="history-meta">
          <span>${formatDate(scan.created_at || new Date().toISOString())}</span>
          <span class="priority-chip ${buildPriorityClass(scan.case_priority)}">${localizedPriority}</span>
          <span>${scan.ai_confidence || '--'}</span>
        </div>
        <p>${scan.guidance || scan.problem_description || ''}</p>
      `;

      card.addEventListener('click', () => renderResult(scan));
      elements.historyList.appendChild(card);
    });

    if (elements.totalScansKpi) elements.totalScansKpi.textContent = String(items.length).padStart(2, '0');
    if (elements.latestPriorityKpi) elements.latestPriorityKpi.textContent = localizePriority(items[0]?.case_priority || '--');
    if (elements.savedPlanKpi) elements.savedPlanKpi.textContent = 'AM/PM';
  }

  function setProfile(user, profile = state.profile) {
    const fullName = profile?.full_name || user?.user_metadata?.full_name || user?.email?.split('@')[0] || t('profile_default_name');
    const email = user?.email || profile?.email || t('dashboard_guest_email');

    if (elements.profileName) elements.profileName.textContent = fullName;
    if (elements.profileEmail) elements.profileEmail.textContent = email;

    if (elements.profileInitials) {
      elements.profileInitials.textContent =
        fullName
          .split(' ')
          .slice(0, 2)
          .map((part) => part[0]?.toUpperCase() || '')
          .join('') || 'SI';
    }

    if (elements.profileAge) elements.profileAge.textContent = profile?.age || '--';
    if (elements.profileSkinType) elements.profileSkinType.textContent = profile?.skin_type || '--';
    if (elements.profileLocation) elements.profileLocation.textContent = profile?.location_text || profile?.city || '--';

    if (elements.settingsForm?.full_name) elements.settingsForm.full_name.value = fullName;
    if (elements.settingsForm?.age) elements.settingsForm.age.value = profile?.age || '';
    if (elements.settingsForm?.skin_type) elements.settingsForm.skin_type.value = profile?.skin_type || '';
    if (elements.settingsForm?.location_text) elements.settingsForm.location_text.value = profile?.location_text || profile?.city || '';
    if (elements.settingsForm?.preferred_lang) elements.settingsForm.preferred_lang.value = profile?.preferred_lang || state.lang;
  }

  function updateAuthUi() {
    const isLoggedIn = Boolean(state.currentUser);

    elements.logoutBtn?.classList.toggle('hidden', !isLoggedIn);
    elements.mobileLogoutBtn?.classList.toggle('hidden', !isLoggedIn);

    [elements.navLoginBtn, elements.mobileLoginBtn, elements.footerLoginBtn].forEach((el) => {
      if (!el) return;
      el.classList.toggle('hidden', isLoggedIn);

      if (isLoggedIn) {
        el.setAttribute('aria-hidden', 'true');
        el.setAttribute('tabindex', '-1');
      } else {
        el.removeAttribute('aria-hidden');
        el.removeAttribute('tabindex');
      }

      el.dataset.authState = isLoggedIn ? 'hidden' : '';
    });

    if (elements.heroLoginBtn) {
      if (isLoggedIn) {
        elements.heroLoginBtn.textContent = state.lang === 'ar' ? 'لوحة التحكم' : 'Dashboard';
        elements.heroLoginBtn.setAttribute('href', '#dashboard');
        elements.heroLoginBtn.dataset.authState = 'dashboard';
      } else {
        elements.heroLoginBtn.textContent = state.lang === 'ar' ? 'إنشاء حساب' : 'Sign Up';
        elements.heroLoginBtn.setAttribute('href', '#auth');
        elements.heroLoginBtn.dataset.authState = '';
      }
    }
  }

  async function loadDashboardData() {
    if (state.currentUser && window.SidarSupabase.canUseSupabase()) {
      const [scanRes, profileRes, planRes] = await Promise.all([
        window.SidarSupabase.listScans(state.currentUser.id),
        window.SidarSupabase.getProfile ? window.SidarSupabase.getProfile(state.currentUser.id) : Promise.resolve({ data: null }),
        window.SidarSupabase.getPlan ? window.SidarSupabase.getPlan(state.currentUser.id) : Promise.resolve({ data: null }),
      ]);

      if (!scanRes.error && scanRes.data) state.history = (scanRes.data || []).map(normalizeScanRow);

      if (profileRes?.data) {
        state.profile = profileRes.data;
        localStorage.setItem('sidar_profile', JSON.stringify(state.profile));
      }

      if (planRes?.data) {
        const plan = planRes.data;
        if (plan.morning_routine && elements.planForm?.morning_routine) elements.planForm.morning_routine.value = plan.morning_routine;
        if (plan.evening_routine && elements.planForm?.night_routine) elements.planForm.night_routine.value = plan.evening_routine;
      }
    } else {
      state.history = JSON.parse(localStorage.getItem('sidar_guest_history') || '[]').map(normalizeScanRow);
      state.profile = JSON.parse(localStorage.getItem('sidar_profile') || '{}');
    }

    setProfile(state.currentUser, state.profile);
    renderHistory(state.history);
  }

  async function hydrateSession() {
    try {
      const { data } = await window.SidarSupabase.getSession();
      state.currentUser = data?.session?.user || null;
      updateAuthUi();
      await loadDashboardData();

      const client = window.SidarSupabase.getClient();
      if (client) {
        client.auth.onAuthStateChange(async (_event, sessionState) => {
          state.currentUser = sessionState?.user || null;
          updateAuthUi();

          if (state.currentUser) await window.SidarSupabase.ensureProfile(state.currentUser);
          await loadDashboardData();
        });
      }
    } catch (error) {
      console.error(error);
      setProfile(null, state.profile);
      renderHistory();
    }
  }

  async function onLogin(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const { error } = await window.SidarSupabase.signIn(data);
      if (error) throw error;

      showToast(state.lang === 'ar' ? 'تم تسجيل الدخول.' : 'Signed in successfully.');
      window.location.hash = '#dashboard';
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onSignup(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const { error } = await window.SidarSupabase.signUp(data);
      if (error) throw error;

      showToast(t('account_created_short'));
      window.location.hash = '#dashboard';
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onMagicLink() {
    const loginEmail =
      elements.loginForm.querySelector('input[name="email"]').value ||
      elements.signupForm.querySelector('input[name="email"]').value;

    if (!loginEmail) {
      showToast(t('enter_email_first'), 'error');
      return;
    }

    try {
      const { error } = await window.SidarSupabase.sendMagicLink(loginEmail);
      if (error) throw error;

      showToast(state.lang === 'ar' ? 'تم إرسال رابط الدخول.' : 'Magic link sent.');
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onLogout() {
    try {
      await window.SidarSupabase.signOut();
      state.currentUser = null;
      updateAuthUi();
      showToast(state.lang === 'ar' ? 'تم تسجيل الخروج.' : 'Logged out.');
      window.location.hash = '#landing';
      await loadDashboardData();
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onPlanSave(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      if (state.currentUser && window.SidarSupabase.canUseSupabase()) {
        const { error } = await window.SidarSupabase.savePlan({
          user_id: state.currentUser.id,
          morning_routine: data.morning_routine,
          evening_routine: data.night_routine,
        });
        if (error) throw error;
      } else {
        localStorage.setItem('sidar_plan', JSON.stringify(data));
      }

      showToast(t('plan_saved_short'));
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onSettingsSave(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      setLanguage(data.preferred_lang || state.lang);

      state.profile = {
        ...state.profile,
        full_name: data.full_name,
        age: data.age,
        skin_type: data.skin_type,
        location_text: data.location_text,
        preferred_lang: data.preferred_lang,
        notifications_enabled: data.notifications_enabled === 'true',
        email: state.currentUser?.email || state.profile.email,
      };

      if (state.currentUser && window.SidarSupabase.canUseSupabase()) {
        const payload = {
          id: state.currentUser.id,
          email: state.currentUser.email,
          full_name: data.full_name,
          age: data.age ? Number(data.age) : null,
          skin_type: data.skin_type,
          location_text: data.location_text,
          preferred_lang: data.preferred_lang,
          notifications_enabled: data.notifications_enabled === 'true',
        };

        const { error } = await window.SidarSupabase.saveSettings(payload);
        if (error) throw error;
      } else {
        localStorage.setItem('sidar_profile', JSON.stringify(state.profile));
        localStorage.setItem('sidar_settings', JSON.stringify(data));
      }

      setProfile(state.currentUser, state.profile);
      showToast(t('account_settings_saved'));
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  function restoreLocalForms() {
    const settings = JSON.parse(localStorage.getItem('sidar_settings') || '{}');
    const profile = JSON.parse(localStorage.getItem('sidar_profile') || '{}');
    const plan = JSON.parse(localStorage.getItem('sidar_plan') || '{}');

    state.profile = { ...profile, ...settings };

    if (elements.settingsForm?.full_name) elements.settingsForm.full_name.value = state.profile.full_name || '';
    if (elements.settingsForm?.age) elements.settingsForm.age.value = state.profile.age || '';
    if (elements.settingsForm?.skin_type) elements.settingsForm.skin_type.value = state.profile.skin_type || '';
    if (elements.settingsForm?.location_text) elements.settingsForm.location_text.value = state.profile.location_text || '';
    if (elements.settingsForm?.preferred_lang) elements.settingsForm.preferred_lang.value = state.profile.preferred_lang || state.lang;
    if (elements.settingsForm?.notifications_enabled) {
      elements.settingsForm.notifications_enabled.value = String(state.profile.notifications_enabled ?? 'true');
    }

    if (plan.morning_routine && elements.planForm?.morning_routine) elements.planForm.morning_routine.value = plan.morning_routine;
    if (plan.night_routine && elements.planForm?.night_routine) elements.planForm.night_routine.value = plan.night_routine;
  }

  function bindSharing() {
    elements.shareWhatsappBtn?.addEventListener('click', () => {
      const text = buildShareText();
      shareViaWeb('SIDAR AI Report', text, `https://wa.me/?text=${encodeURIComponent(text)}`);
    });

    elements.shareInstagramBtn?.addEventListener('click', () => {
      copyText(buildShareText(), t('instagram_copied'));
    });

    elements.shareTiktokBtn?.addEventListener('click', () => {
      copyText(buildShareText(), t('tiktok_copied'));
    });

    elements.shareFullReportBtn?.addEventListener('click', () => {
      const text = [buildShareText(), '', ...(state.currentResult?.next_steps || [])].join('\n');
      copyText(text, t('full_report_copied'));
    });
  }

  function bindEvents() {
    elements.langToggleBtn?.addEventListener('click', () => setLanguage(state.lang === 'ar' ? 'en' : 'ar'));
    elements.mobileLangToggleBtn?.addEventListener('click', () => setLanguage(state.lang === 'ar' ? 'en' : 'ar'));
    elements.mobileTopLangToggleBtn?.addEventListener('click', () => setLanguage(state.lang === 'ar' ? 'en' : 'ar'));
    elements.menuBtn?.addEventListener('click', () => elements.mobileMenu?.classList.toggle('open'));

    elements.scanForm?.addEventListener('submit', analyzeScan);
    elements.downloadReportBtn?.addEventListener('click', downloadReport);
    elements.saveScanBtn?.addEventListener('click', saveCurrentScan);

    elements.newScanBtn?.addEventListener('click', () => {
      state.selectedFiles = [];
      elements.scanForm?.reset();
      renderImagePreview();
      window.location.hash = '#scan';
    });

    elements.resultsBackBtn?.addEventListener('click', () => {
      window.location.hash = '#scan';
    });

    elements.loginForm?.addEventListener('submit', onLogin);
    elements.signupForm?.addEventListener('submit', onSignup);
    elements.magicLinkBtn?.addEventListener('click', onMagicLink);
    elements.logoutBtn?.addEventListener('click', onLogout);
    elements.mobileLogoutBtn?.addEventListener('click', onLogout);
    elements.planForm?.addEventListener('submit', onPlanSave);
    elements.settingsForm?.addEventListener('submit', onSettingsSave);

    bindSharing();
  }

  function getPreferredProfileLanguage(profile = state.profile) {
    return profile?.preferred_language || profile?.preferred_lang || state.lang;
  }

  function getCountryName(code, lang = state.lang) {
    if (!code) return '';
    try {
      const locale = lang === 'ar' ? 'ar' : 'en';
      return new Intl.DisplayNames([locale], { type: 'region' }).of(code) || code;
    } catch {
      return code;
    }
  }

  function getResultCountryCode(result = state.currentResult) {
    return String(result?.input?.location_text || result?.raw_ai_response?.location_text || getProfileLocation() || '').toUpperCase();
  }

  function getResultCountryLabel(result = state.currentResult) {
    const code = getResultCountryCode(result);
    return result?.input?.location_label || result?.raw_ai_response?.location_label || getCountryName(code) || code || getProfileLocationLabel();
  }

  function doctorAddressKit(result = state.currentResult) {
    const code = getResultCountryCode(result);
    const label = getResultCountryLabel(result) || (state.lang === 'ar' ? 'دولتك' : 'your country');
    const kits = {
      EG: {
        en: ['New Cairo Dermatology Center', 'Dermatology', 'Building 12, Teseen Street, New Cairo, Cairo, Egypt', 'Cairo Skin & Hair Clinic', '5 El Nasr Road, Nasr City, Cairo, Egypt', 'Maadi Derma Clinic', 'Road 9, Maadi, Cairo, Egypt'],
        ar: ['مركز القاهرة الجديدة للجلدية', 'جلدية وتجميل', 'مبنى 12، شارع التسعين، التجمع الخامس، القاهرة، مصر', 'عيادة القاهرة للبشرة والشعر', '5 شارع النصر، مدينة نصر، القاهرة، مصر', 'عيادة المعادي ديرما', 'شارع 9، المعادي، القاهرة، مصر'],
      },
      SA: {
        en: ['Riyadh Dermatology Center', 'Dermatology', 'Olaya Street, Al Olaya, Riyadh, Saudi Arabia', 'Jeddah Skin & Hair Clinic', 'Prince Sultan Road, Al Zahra, Jeddah, Saudi Arabia', 'Dammam Derma Clinic', 'Prince Mohammed Bin Fahd Road, Dammam, Saudi Arabia'],
        ar: ['مركز الرياض للجلدية', 'جلدية وتجميل', 'شارع العليا، حي العليا، الرياض، السعودية', 'عيادة جدة للبشرة والشعر', 'طريق الأمير سلطان، حي الزهراء، جدة، السعودية', 'عيادة الدمام ديرما', 'طريق الأمير محمد بن فهد، الدمام، السعودية'],
      },
      AE: {
        en: ['Dubai Dermatology Clinic', 'Dermatology', 'Jumeirah Beach Road, Umm Suqeim, Dubai, United Arab Emirates', 'Abu Dhabi Skin Center', 'Al Karamah Street, Abu Dhabi, United Arab Emirates', 'Sharjah Derma Clinic', 'Al Majaz Waterfront, Sharjah, United Arab Emirates'],
        ar: ['عيادة دبي للجلدية', 'جلدية وتجميل', 'طريق شاطئ جميرا، أم سقيم، دبي، الإمارات', 'مركز أبوظبي للبشرة', 'شارع الكرامة، أبوظبي، الإمارات', 'عيادة الشارقة ديرما', 'واجهة المجاز المائية، الشارقة، الإمارات'],
      },
      US: {
        en: ['Downtown Dermatology Associates', 'Dermatology', '120 E 57th Street, New York, NY, United States', 'Skin & Scalp Care Center', '233 N Michigan Avenue, Chicago, IL, United States', 'Westside Dermatology Clinic', 'Beverly Boulevard, Los Angeles, CA, United States'],
        ar: ['مركز داون تاون للجلدية', 'جلدية وتجميل', '120 شرق شارع 57، نيويورك، الولايات المتحدة', 'مركز العناية بالبشرة وفروة الرأس', '233 شمال شارع ميشيغان، شيكاغو، الولايات المتحدة', 'عيادة ويست سايد للجلدية', 'شارع بيفرلي، لوس أنجلوس، الولايات المتحدة'],
      },
      GB: {
        en: ['London Dermatology Clinic', 'Dermatology', 'Harley Street, Marylebone, London, United Kingdom', 'Manchester Skin Clinic', 'Deansgate, Manchester, United Kingdom', 'Birmingham Derma Clinic', 'Colmore Row, Birmingham, United Kingdom'],
        ar: ['عيادة لندن للجلدية', 'جلدية وتجميل', 'شارع هارلي، ماريليبون، لندن، المملكة المتحدة', 'عيادة مانشستر للبشرة', 'دينزجيت، مانشستر، المملكة المتحدة', 'عيادة برمنغهام ديرما', 'كولمور رو، برمنغهام، المملكة المتحدة'],
      },
      QA: {
        en: ['Doha Dermatology Center', 'Dermatology', 'Al Waab Street, Doha, Qatar', 'West Bay Skin Clinic', 'Omar Al Mukhtar Street, Doha, Qatar', 'Lusail Derma Clinic', 'Marina District, Lusail, Qatar'],
        ar: ['مركز الدوحة للجلدية', 'جلدية وتجميل', 'شارع الوعب، الدوحة، قطر', 'عيادة الخليج الغربي للبشرة', 'شارع عمر المختار، الدوحة، قطر', 'عيادة لوسيل ديرما', 'منطقة المارينا، لوسيل، قطر'],
      },
      KW: {
        en: ['Kuwait City Dermatology Clinic', 'Dermatology', 'Gulf Road, Kuwait City, Kuwait', 'Salmiya Skin & Hair Center', 'Salem Al Mubarak Street, Salmiya, Kuwait', 'Hawally Derma Clinic', 'Beirut Street, Hawally, Kuwait'],
        ar: ['عيادة مدينة الكويت للجلدية', 'جلدية وتجميل', 'شارع الخليج، مدينة الكويت، الكويت', 'مركز السالمية للبشرة والشعر', 'شارع سالم المبارك، السالمية، الكويت', 'عيادة حولي ديرما', 'شارع بيروت، حولي، الكويت'],
      },
      BH: {
        en: ['Manama Dermatology Clinic', 'Dermatology', 'Government Avenue, Manama, Bahrain', 'Seef Skin Center', 'Road 2825, Seef, Bahrain', 'Riffa Derma Clinic', 'Riffa Views, Riffa, Bahrain'],
        ar: ['عيادة المنامة للجلدية', 'جلدية وتجميل', 'شارع الحكومة، المنامة، البحرين', 'مركز السيف للبشرة', 'طريق 2825، السيف، البحرين', 'عيادة الرفاع ديرما', 'الرفاع فيوز، الرفاع، البحرين'],
      },
      OM: {
        en: ['Muscat Dermatology Center', 'Dermatology', 'Sultan Qaboos Street, Muscat, Oman', 'Qurum Skin Clinic', 'Qurum Commercial Area, Muscat, Oman', 'Seeb Derma Clinic', 'Al Mouj Street, Seeb, Oman'],
        ar: ['مركز مسقط للجلدية', 'جلدية وتجميل', 'شارع السلطان قابوس، مسقط، عمان', 'عيادة القرم للبشرة', 'القرم التجارية، مسقط، عمان', 'عيادة السيب ديرما', 'شارع الموج، السيب، عمان'],
      },
      JO: {
        en: ['Amman Dermatology Clinic', 'Dermatology', 'Queen Rania Street, Amman, Jordan', 'Abdoun Skin Center', 'Cairo Street, Abdoun, Amman, Jordan', 'Irbid Derma Clinic', 'University Street, Irbid, Jordan'],
        ar: ['عيادة عمان للجلدية', 'جلدية وتجميل', 'شارع الملكة رانيا، عمان، الأردن', 'مركز عبدون للبشرة', 'شارع القاهرة، عبدون، عمان، الأردن', 'عيادة إربد ديرما', 'شارع الجامعة، إربد، الأردن'],
      },
      MA: {
        en: ['Casablanca Dermatology Clinic', 'Dermatology', 'Boulevard Anfa, Casablanca, Morocco', 'Rabat Skin Center', 'Avenue Mohammed V, Rabat, Morocco', 'Marrakesh Derma Clinic', 'Gueliz, Marrakesh, Morocco'],
        ar: ['عيادة الدار البيضاء للجلدية', 'جلدية وتجميل', 'شارع أنفا، الدار البيضاء، المغرب', 'مركز الرباط للبشرة', 'شارع محمد الخامس، الرباط، المغرب', 'عيادة مراكش ديرما', 'جليز، مراكش، المغرب'],
      },
    };
    const kit = kits[code]?.[state.lang === 'ar' ? 'ar' : 'en'];
    if (kit) return kit;
    return state.lang === 'ar'
      ? [`عيادة جلدية قريبة في ${label}`, 'جلدية وتجميل', `المنطقة الطبية المركزية، ${label}`, `مركز البشرة والشعر في ${label}`, `شارع العيادات الرئيسي، ${label}`, `عيادة متابعة جلدية في ${label}`, `الحي الطبي، ${label}`]
      : [`Nearby dermatology clinic in ${label}`, 'Dermatology', `Central Medical District, ${label}`, `Skin & hair center in ${label}`, `Main Clinics Avenue, ${label}`, `Specialist dermatology follow-up in ${label}`, `Medical Quarter, ${label}`];
  }

  function shouldReplaceDoctorList(items, result) {
    const code = getResultCountryCode(result);
    if (!code || code === 'EG' || !Array.isArray(items) || !items.length) return false;
    const egyptHints = /egypt|cairo|giza|alexandria|maadi|nasr|new cairo|القاهرة|مصر|الجيزة|الإسكندرية|المعادي|مدينة نصر/i;
    return items.every((item) => egyptHints.test(`${item.address || ''} ${item.name || ''}`));
  }

  function populateCountrySelects() {
    document.querySelectorAll('select.country-select').forEach((select) => {
      const currentValue = select.value || select.dataset.value || '';
      select.innerHTML = '';

      const placeholder = document.createElement('option');
      placeholder.value = '';
      placeholder.textContent = t('select_country');
      select.appendChild(placeholder);

      COUNTRY_CODES.forEach((code) => {
        const option = document.createElement('option');
        option.value = code;
        option.textContent = getCountryName(code);
        select.appendChild(option);
      });

      if (currentValue) select.value = currentValue;
    });
  }

  function getProfileLocation(profile = state.profile) {
    return profile?.location_text?.trim() || '';
  }

  function getProfileLocationLabel(profile = state.profile) {
    const value = getProfileLocation(profile);
    return getCountryName(value) || value;
  }

  function formatProfileValue(value, suffix = '') {
    if (value === null || value === undefined || value === '') return '--';
    return `${value}${suffix}`;
  }

  function localizeGender(value) {
    const gender = String(value || '').toLowerCase();
    if (!gender) return '--';
    if (state.lang === 'ar') {
      if (gender === 'female') return 'أنثى';
      if (gender === 'male') return 'ذكر';
      if (gender === 'other') return 'آخر';
    }
    return gender.charAt(0).toUpperCase() + gender.slice(1);
  }

  function setSelectValue(select, value, label) {
    if (!select) return;
    const normalizedValue = value || '';
    if (normalizedValue && !select.querySelector(`option[value="${CSS.escape(normalizedValue)}"]`)) {
      const option = document.createElement('option');
      option.value = normalizedValue;
      option.textContent = label || normalizedValue;
      select.appendChild(option);
    }
    select.value = normalizedValue;
  }

  function ensureAuthenticatedAction(messageKey) {
    if (state.currentUser && window.SidarSupabase.canUseSupabase()) return true;
    const fallbackMessage =
      state.lang === 'ar'
        ? 'يجب تسجيل الدخول أولًا لاستخدام التحليل وحفظ التقارير.'
        : 'You need to sign in first to run analysis and save reports.';
    showToast(messageKey ? t(messageKey) : fallbackMessage, 'error');
    window.location.hash = '#auth';
    return false;
  }

  function syncScanLocationField() {
    if (!elements.scanForm?.location_text) return;
    if (!elements.scanForm.location_text.value.trim()) {
      setSelectValue(elements.scanForm.location_text, getProfileLocation(), getProfileLocationLabel());
    }
  }

  function buildDetailedFindings(result) {
    const patterns = Array.isArray(result.visible_patterns) ? result.visible_patterns : [];
    const reasons = Array.isArray(result.reasons) ? result.reasons : [];
    const priority = result.case_priority || 'Moderate';
    const scoreSet = buildScoreSet(result);

    const findings = patterns.map((title, index) => ({
      title,
      description: reasons[index] || result.guidance || result.problem_description || '',
      severity: priority.toLowerCase(),
      category: result.analysis_target || 'skin',
      sort_order: index,
    }));

    if ((result.analysis_target || 'skin') !== 'hair') {
      findings.push(
        {
          title: t('score_metric_fine_lines'),
          description:
            state.lang === 'ar'
              ? `تقييم الخطوط الدقيقة مفعل في هذا التقرير بدرجة ${scoreSet.fine == null ? '--' : `${Math.round(scoreSet.fine)}%`}.`
              : `Fine lines assessment is active in this report at ${scoreSet.fine == null ? '--' : `${Math.round(scoreSet.fine)}%`}.`,
          severity: priority.toLowerCase(),
          category: 'skin_score',
          sort_order: findings.length,
        },
        {
          title: t('score_metric_overall_tone'),
          description:
            state.lang === 'ar'
              ? `تجانس اللون مفعل في هذا التقرير بدرجة ${scoreSet.tone == null ? '--' : `${Math.round(scoreSet.tone)}%`}.`
              : `Overall tone balance is active in this report at ${scoreSet.tone == null ? '--' : `${Math.round(scoreSet.tone)}%`}.`,
          severity: priority.toLowerCase(),
          category: 'skin_score',
          sort_order: findings.length + 1,
        }
      );
    }

    return findings;
  }

  function normalizeScanRow(row) {
    if (!row) return null;
    if (row.case_priority || row.visible_patterns || row.guidance || row.next_steps) return row;

    return {
      ...row,
      title: row.report_title || row.title || '',
      ai_confidence: row.ai_confidence || '',
      case_priority: mapUrgencyToPriority(row.urgency),
      image_quality: row.image_quality || '',
      visible_patterns: Array.isArray(row.visible_findings) ? row.visible_findings : [],
      guidance: row.problem_description || row.summary || '',
      next_steps: Array.isArray(row.care_steps) ? row.care_steps : [],
      images: Array.isArray(row.scan_images) && row.scan_images.length
        ? row.scan_images.map((item) => ({ publicUrl: item.image_url, path: item.image_path || '', fileName: item.image_path || '' }))
        : (Array.isArray(row.image_urls) ? row.image_urls.map((url) => ({ publicUrl: url, fileName: '' })) : []),
      reasons: Array.isArray(row.reasons) ? row.reasons : [],
      detailed_findings: Array.isArray(row.scan_findings) ? row.scan_findings : [],
      disclaimer: row.disclaimer || '',
      analysis_target: row.analysis_target,
      issue_type: row.issue_type,
      overall_score: row.overall_score,
      hydration_score: row.hydration_score,
      pore_clarity_score: row.pore_clarity_score,
      fine_lines_score: row.fine_lines_score,
      overall_tone_score: row.overall_tone_score,
      hair_density_score: row.hair_density_score,
      hair_texture_score: row.hair_texture_score,
      hair_strength_score: row.hair_strength_score,
      scalp_health_score: row.scalp_health_score,
      morning_routine: Array.isArray(row.morning_routine) ? row.morning_routine : [],
      evening_routine: Array.isArray(row.evening_routine) ? row.evening_routine : [],
      natural_product_suggestions: row.natural_product_suggestions,
      commercial_product_suggestions: row.commercial_product_suggestions,
      nearby_doctors: row.nearby_doctors,
      input: {
        scan_type: row.scan_type,
        body_location: row.body_location,
        duration: row.duration,
        severity: row.severity,
        symptoms: Array.isArray(row.symptoms) ? row.symptoms : [],
        notes: row.notes || '',
        issue_type: row.issue_type || '',
        skin_type_context: row.concern_category || '',
        location_text: row.raw_ai_response?.location_text || getProfileLocation(),
        location_label: row.raw_ai_response?.location_label || getCountryName(row.raw_ai_response?.location_text || getProfileLocation()),
      },
      created_at: row.created_at,
      saved_scan_id: row.id || null,
    };
  }

  function buildUnifiedScanPayload(result) {
    const scoreSet = buildScoreSet(result);
    const findings = buildDetailedFindings(result);

    return {
      title: result.title || '',
      report_title: result.title || '',
      scan_type: result.input.scan_type,
      body_location: result.input.body_location,
      duration: result.input.duration,
      severity: result.input.severity,
      symptoms: result.input.symptoms,
      notes: result.input.notes,
      issue_type: result.input.issue_type || result.issue_type || '',
      concern_category: result.input.skin_type_context || '',
      analysis_target:
        result.analysis_target || (['hair_check', 'scalp_check'].includes(result.input.scan_type) || result.input.body_location === 'scalp' ? 'hair' : 'skin'),
      image_urls: Array.isArray(result.images) ? result.images.map((item) => item.publicUrl).filter(Boolean) : [],
      images_count: Array.isArray(result.images) ? result.images.length : 0,
      language_code: state.lang,
      ai_confidence: result.ai_confidence || '',
      summary: result.summary || result.guidance || '',
      problem_description: result.guidance || '',
      urgency: mapPriorityToUrgency(result.case_priority),
      image_quality: result.image_quality || '',
      visible_findings: result.visible_patterns || [],
      care_steps: result.next_steps || [],
      reasons: result.reasons || [],
      overall_score: scoreSet.overall,
      hydration_score: scoreSet.hydration,
      pore_clarity_score: scoreSet.pore,
      fine_lines_score: scoreSet.fine,
      overall_tone_score: scoreSet.tone,
      hair_density_score: result.hair_density_score ?? null,
      hair_texture_score: result.hair_texture_score ?? null,
      hair_strength_score: result.hair_strength_score ?? null,
      scalp_health_score: result.scalp_health_score ?? null,
      morning_routine: Array.isArray(result.morning_routine) ? result.morning_routine : [],
      evening_routine: Array.isArray(result.evening_routine) ? result.evening_routine : [],
      natural_product_suggestions: Array.isArray(result.natural_product_suggestions) ? result.natural_product_suggestions : [],
      commercial_product_suggestions: Array.isArray(result.commercial_product_suggestions) ? result.commercial_product_suggestions : [],
      nearby_doctors: Array.isArray(result.nearby_doctors) ? result.nearby_doctors : [],
      raw_ai_response: {
        summary: result.summary || '',
        location_text: result.input.location_text || getProfileLocation(),
        location_label: result.input.location_label || getCountryName(result.input.location_text || getProfileLocation()),
        detailed_findings: findings,
      },
      status: 'completed',
      disclaimer:
        result.disclaimer || (state.lang === 'ar' ? 'إرشادات تعليمية وليست تشخيصًا طبيًا نهائيًا.' : 'Educational guidance only, not a final medical diagnosis.'),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      scan_images: Array.isArray(result.images)
        ? result.images
            .filter((item) => item.publicUrl)
            .map((item, index) => ({
              image_url: item.publicUrl,
              image_path: item.path || '',
              sort_order: index,
            }))
        : [],
      scan_findings: findings,
    };
  }

  function getScanFormData() {
    const formData = new FormData(elements.scanForm);
    const selectedLocation = formData.get('location_text')?.trim() || getProfileLocation();
    return {
      scan_type: formData.get('scan_type'),
      issue_type: formData.get('issue_type'),
      skin_type_context: formData.get('skin_type_context'),
      body_location: formData.get('body_location'),
      duration: formData.get('duration'),
      severity: formData.get('severity'),
      symptoms: formData.getAll('symptoms'),
      notes: formData.get('notes')?.trim() || '',
      location_text: selectedLocation,
      location_label: getCountryName(selectedLocation) || selectedLocation,
      profile_context: {
        age: state.profile?.age || null,
        gender: state.profile?.gender || '',
        skin_type: state.profile?.skin_type || '',
        allergies: state.profile?.allergies || '',
        medications: state.profile?.medications || '',
        sun_sensitive: Boolean(state.profile?.sun_sensitive),
      },
    };
  }

  function renderResult(result, navigateToPage = true) {
    result = normalizeScanRow(result) || result;
    state.currentResult = result;

    const localizedPriority = localizePriority(result.case_priority || '--');
    const localizedQuality = localizeImageQuality(result.image_quality || '--');
    const priorityClass = buildPriorityClass(result.case_priority || '--');
    const scoreSet = buildScoreSet(result);
    const morningRoutine = Array.isArray(result.morning_routine) ? result.morning_routine : [];
    const eveningRoutine = Array.isArray(result.evening_routine) ? result.evening_routine : [];
    const naturalProducts = normalizeProductArray(result.natural_product_suggestions, () => defaultNaturalProducts(result)).map((item) => ({ ...item, price: '' }));
    // Medical catalog recommendations must always be verified database records; never display generated fallbacks.
    const commercialProducts = normalizeProductArray(result.commercial_product_suggestions, () => []);
    const nearbyDoctors = normalizeDoctorArray(result.nearby_doctors, () => []);
    const reasons = Array.isArray(result.reasons) ? result.reasons : [];
    const detailedFindings = Array.isArray(result.detailed_findings) ? result.detailed_findings : [];

    if (elements.resultTitle) elements.resultTitle.textContent = result.title || t('report_title');
    if (elements.resultTitleClone) elements.resultTitleClone.textContent = result.title || t('report_title');

    if (elements.resultGuidance) {
      elements.resultGuidance.textContent = result.guidance || result.problem_description || t('results_empty_guidance');
      elements.resultGuidance.classList.toggle('empty-copy', !(result.guidance || result.problem_description));
    }

    if (elements.resultGuidanceClone) {
      elements.resultGuidanceClone.textContent = result.guidance || result.problem_description || t('results_empty_guidance');
      elements.resultGuidanceClone.classList.toggle('empty-copy', !(result.guidance || result.problem_description));
    }

    if (elements.resultPriority) elements.resultPriority.textContent = localizedPriority;
    if (elements.resultPriorityClone) elements.resultPriorityClone.textContent = localizedPriority;
    if (elements.resultConfidence) elements.resultConfidence.textContent = result.ai_confidence || '--';
    if (elements.resultConfidenceClone) elements.resultConfidenceClone.textContent = result.ai_confidence || '--';
    if (elements.resultImageQuality) elements.resultImageQuality.textContent = localizedQuality;
    if (elements.resultImageQualityClone) elements.resultImageQualityClone.textContent = localizedQuality;

    const scoreVal = scoreSet.overall == null ? 85 : Math.round(scoreSet.overall);

    if (elements.resultPriorityBadge) {
      elements.resultPriorityBadge.textContent = `${scoreVal}%`;
      elements.resultPriorityBadge.className = `pct-circle`;
    }
    if (elements.resultPriorityBadgeClone) {
      elements.resultPriorityBadgeClone.textContent = `${scoreVal}%`;
      elements.resultPriorityBadgeClone.className = `pct-circle`;
    }

    if (elements.resultPriorityIcon) {
      elements.resultPriorityIcon.textContent = `${scoreVal}%`;
      elements.resultPriorityIcon.className = `pct-circle`;
    }
    if (elements.resultPriorityIconClone) {
      elements.resultPriorityIconClone.textContent = `${scoreVal}%`;
      elements.resultPriorityIconClone.className = `pct-circle`;
    }

    const badgeResults = document.getElementById('resultPriorityBadgeResults');
    if (badgeResults) badgeResults.textContent = `${scoreVal}%`;

    const insightPct = document.getElementById('resultInsightPct');
    if (insightPct) insightPct.textContent = `${scoreVal}%`;

    if (elements.resultPrioritySupport) {
      elements.resultPrioritySupport.textContent =
        result.summary || result.guidance || result.problem_description || t('share_report_support');
    }

    [elements.resultPatterns, elements.resultPatternsClone].forEach((container) => {
      if (!container) return;
      container.innerHTML = '';
      container.className = 'result-findings-list';
      if ((result.visible_patterns || []).length) {
        result.visible_patterns.forEach((pattern) => {
          const item = document.createElement('div');
          item.className = 'finding-item';
          item.innerHTML = `<span class="finding-icon">◌</span><strong>${pattern}</strong>`;
          container.appendChild(item);
        });
      } else {
        container.className = 'result-findings-list empty-copy';
        container.textContent = t('no_patterns_yet');
      }
    });

    if (elements.resultOverallScore) elements.resultOverallScore.textContent = scoreSet.overall == null ? '--' : Math.round(scoreSet.overall);
    if (elements.resultOverallScoreClone) elements.resultOverallScoreClone.textContent = scoreSet.overall == null ? '--' : Math.round(scoreSet.overall);
    if (elements.resultScoreLabel) elements.resultScoreLabel.textContent = scoreSet.label;
    if (elements.resultScoreLabelClone) elements.resultScoreLabelClone.textContent = scoreSet.label;
    if (elements.resultScoreSummary) elements.resultScoreSummary.textContent = scoreSet.summary;
    if (elements.resultScoreSummaryClone) elements.resultScoreSummaryClone.textContent = scoreSet.summary;

    if (elements.scoreRing) elements.scoreRing.style.setProperty('--score', scoreSet.overall == null ? 0 : Math.max(0, Math.min(100, scoreSet.overall)));
    if (elements.scoreRingClone) elements.scoreRingClone.style.setProperty('--score', scoreSet.overall == null ? 0 : Math.max(0, Math.min(100, scoreSet.overall)));

    const metricMap = [
      [elements.hydrationValue, elements.hydrationBar, scoreSet.hydration],
      [elements.poreValue, elements.poreBar, scoreSet.pore],
      [elements.fineLinesValue, elements.fineLinesBar, scoreSet.fine],
      [elements.toneValue, elements.toneBar, scoreSet.tone],
      [elements.hydrationValueClone, elements.hydrationBarClone, scoreSet.hydration],
      [elements.poreValueClone, elements.poreBarClone, scoreSet.pore],
      [elements.fineLinesValueClone, elements.fineLinesBarClone, scoreSet.fine],
      [elements.toneValueClone, elements.toneBarClone, scoreSet.tone],
    ];

    metricMap.forEach(([valueEl, barEl, score]) => {
      if (valueEl) valueEl.textContent = score == null ? '--' : `${Math.round(score)}%`;
      if (barEl) barEl.style.width = score == null ? '0%' : `${Math.max(0, Math.min(100, score))}%`;
    });

    const lines = document.querySelectorAll('.score-lines');
    lines.forEach((group) => {
      const spans = group.querySelectorAll('.metric-line.big > span');
      if (spans[0]) spans[0].textContent = scoreSet.labels[0];
      if (spans[1]) spans[1].textContent = scoreSet.labels[1];
      if (spans[2]) spans[2].textContent = scoreSet.labels[2];
      if (spans[3]) spans[3].textContent = scoreSet.labels[3];
    });

    renderSteps(elements.morningRoutineList, morningRoutine);
    renderSteps(elements.eveningRoutineList, eveningRoutine);
    renderProducts(elements.naturalProductsList, naturalProducts, false);
    renderProducts(elements.commercialProductsList, commercialProducts);
    renderDoctors(elements.nearbyDoctorsList, nearbyDoctors);

    if (elements.resultReasons) {
      elements.resultReasons.innerHTML = '';
      if (!reasons.length && !detailedFindings.length) {
        const row = document.createElement('div');
        row.className = 'reason-item';
        row.innerHTML = `<span class="reason-dot">i</span><p>${state.lang === 'ar' ? 'لا توجد أسباب تفصيلية إضافية في نتيجة التحليل الحالية.' : 'No additional reasoning details were returned in this analysis.'}</p>`;
        elements.resultReasons.appendChild(row);
      } else {
        detailedFindings.forEach((finding) => {
          const row = document.createElement('div');
          row.className = 'reason-item';
          row.innerHTML = `<span class="reason-dot">i</span><p><strong>${finding.title || ''}</strong>${finding.description ? `: ${finding.description}` : ''}</p>`;
          elements.resultReasons.appendChild(row);
        });
        reasons.forEach((reason) => {
          const row = document.createElement('div');
          row.className = 'reason-item';
          row.innerHTML = `<span class="reason-dot">i</span><p>${reason}</p>`;
          elements.resultReasons.appendChild(row);
        });
      }
    }

    if (navigateToPage) window.location.hash = '#results';
  }

  async function saveCurrentScan() {
    if (!state.currentResult) return;
    if (!ensureAuthenticatedAction()) return;
    if (state.currentResult.saved_scan_id) {
      showToast(state.lang === 'ar' ? 'هذا التقرير محفوظ بالفعل في الحساب.' : 'This report is already saved to your account.');
      return;
    }

    const payload = buildUnifiedScanPayload(state.currentResult);

    try {
      const { data, error } = await window.SidarSupabase.saveScan({ user_id: state.currentUser.id, ...payload });
      if (error) throw error;

      state.currentResult.saved_scan_id = data?.id || true;
      showToast(state.lang === 'ar' ? 'تم حفظ التقرير كاملًا في الحساب.' : 'Full report saved to your account.');
      await loadDashboardData();
    } catch (error) {
      console.error(error);
      showToast(error.message || 'Unable to save.', 'error');
    }
  }

  async function analyzeScan(event) {
    event.preventDefault();

    if (!ensureAuthenticatedAction()) return;
    if (!state.selectedFiles.length) {
      showToast(t('no_images'), 'error');
      return;
    }

    const formPayload = getScanFormData();
    if (!formPayload.location_text) {
      showToast(state.lang === 'ar' ? 'اختر المنطقة السكنية أولًا من الحساب أو من نموذج التحليل.' : 'Please choose a residential location from your account or the analysis form first.', 'error');
      return;
    }

    let uploadedImages = [];
    const submitBtn = elements.scanForm?.querySelector('button[type="submit"]');
    const originalLabel = submitBtn?.textContent || '';

    try {
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = state.lang === 'ar' ? 'جارٍ التحليل...' : 'Analyzing...';
      }

      uploadedImages = await window.SidarSupabase.uploadImages(state.selectedFiles, state.currentUser.id);

      if (!window.SidarAI?.generateAnalysis) {
        throw new Error(
          state.lang === 'ar'
            ? 'خطأ في الاتصال بخدمة الذكاء الاصطناعي (Gemini/Firebase). تأكد من الربط والشبكة.'
            : 'Error connecting to Gemini/Firebase AI service. Check connection and setup.'
        );
      }

      const catalogRes = await window.SidarSupabase.getRecommendationCatalog(formPayload);
      if (catalogRes.error) throw catalogRes.error;
      const catalog = catalogRes.data || { doctors: [], products: [] };
      const result = await window.SidarAI.generateAnalysis(formPayload, state.selectedFiles, state.lang, catalog);
      if (!result) throw new Error(t('generate_result_error'));

      // Keep AI recommendations auditable: Gemini may choose IDs, but names and URLs come only from Supabase.
      const productsById = new Map((catalog.products || []).map((item) => [String(item.id), item]));
      const doctorsById = new Map((catalog.doctors || []).map((item) => [String(item.id), item]));
      const selectedProducts = (result.suggested_product_ids || []).map((id) => productsById.get(String(id))).filter(Boolean);
      const selectedDoctors = (result.suggested_doctor_ids || []).map((id) => doctorsById.get(String(id))).filter(Boolean);
      result.commercial_product_suggestions = selectedProducts.map((product) => ({
        id: product.id, name: [product.brand, product.name].filter(Boolean).join(' '), desc: product.description || '',
        price: product.price == null ? '' : `${product.price} ${product.currency || ''}`.trim(), image: product.image_url || '', link: product.product_url || '#',
      }));
      result.nearby_doctors = selectedDoctors.map((doctor) => ({
        id: doctor.id, name: doctor.full_name, specialty: doctor.specialization,
        address: [doctor.clinic_hospital, doctor.city, doctor.country].filter(Boolean).join('، '), link: doctor.booking_url || doctor.contact_url || '#',
      }));

      result.images = uploadedImages;
      result.input = formPayload;
      result.saved_scan_id = null;

      renderResult(result);
      await saveCurrentScan();
      showToast(t('report_generated'));
    } catch (error) {
      console.error(error);
      showToast(error.message || t('something_went_wrong'), 'error');
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = originalLabel || t('analyze_now');
      }
    }
  }

  function renderHistory(items = state.history) {
    if (!elements.historyList) return;

    elements.historyList.innerHTML = '';

    if (!items?.length) {
      const card = document.createElement('div');
      card.className = 'history-card';
      card.textContent = t('no_saved_scans_short');
      elements.historyList.appendChild(card);

      if (elements.totalScansKpi) elements.totalScansKpi.textContent = '0';
      if (elements.latestPriorityKpi) elements.latestPriorityKpi.textContent = '--';
      if (elements.savedPlanKpi) elements.savedPlanKpi.textContent = state.profile?.skin_goals || '--';
      return;
    }

    items.forEach((rawScan) => {
      const scan = normalizeScanRow(rawScan) || rawScan;
      const card = document.createElement('article');
      card.className = 'history-card';

      const localizedPriority = localizePriority(scan.case_priority || '--');
      const findingsCount = Array.isArray(scan.visible_patterns) ? scan.visible_patterns.length : 0;

      card.innerHTML = `
        <strong>${scan.title || scan.scan_type?.replace(/_/g, ' ') || t('history_fallback_title')}</strong>
        <div class="history-meta">
          <span>${formatDate(scan.created_at || new Date().toISOString())}</span>
          <span class="priority-chip ${buildPriorityClass(scan.case_priority)}">${localizedPriority}</span>
          <span>${scan.ai_confidence || '--'}</span>
          <span>${findingsCount} ${state.lang === 'ar' ? 'ملاحظات' : 'findings'}</span>
        </div>
        <p>${scan.guidance || scan.problem_description || ''}</p>
      `;

      card.addEventListener('click', () => renderResult(scan));
      elements.historyList.appendChild(card);
    });

    if (elements.totalScansKpi) elements.totalScansKpi.textContent = String(items.length).padStart(2, '0');
    if (elements.latestPriorityKpi) elements.latestPriorityKpi.textContent = localizePriority(items[0]?.case_priority || '--');
    if (elements.savedPlanKpi) elements.savedPlanKpi.textContent = state.profile?.skin_goals || (state.lang === 'ar' ? 'مكتمل' : 'Complete');
  }

  function setProfile(user, profile = state.profile) {
    const fullName = profile?.full_name || user?.user_metadata?.full_name || user?.email?.split('@')[0] || t('profile_default_name');
    const email = user?.email || profile?.email || '--';

    if (elements.profileName) elements.profileName.textContent = fullName;
    if (elements.profileEmail) elements.profileEmail.textContent = email;

    if (elements.profileInitials) {
      elements.profileInitials.textContent =
        fullName
          .split(' ')
          .slice(0, 2)
          .map((part) => part[0]?.toUpperCase() || '')
          .join('') || 'SI';
    }

    if (elements.profileAge) elements.profileAge.textContent = formatProfileValue(profile?.age);
    if (elements.profileGender) elements.profileGender.textContent = localizeGender(profile?.gender);
    if (elements.profileSkinType) elements.profileSkinType.textContent = profile?.skin_type || '--';
    if (elements.profileLocation) elements.profileLocation.textContent = getProfileLocationLabel(profile) || '--';
    if (elements.profileHeight) elements.profileHeight.textContent = formatProfileValue(profile?.height, ' cm');
    if (elements.profileWeight) elements.profileWeight.textContent = formatProfileValue(profile?.weight, ' kg');

    if (elements.settingsForm?.full_name) elements.settingsForm.full_name.value = fullName;
    if (elements.settingsForm?.age) elements.settingsForm.age.value = profile?.age || '';
    if (elements.settingsForm?.gender) elements.settingsForm.gender.value = profile?.gender || '';
    if (elements.settingsForm?.skin_type) elements.settingsForm.skin_type.value = profile?.skin_type || '';
    if (elements.settingsForm?.location_text) {
      setSelectValue(elements.settingsForm.location_text, getProfileLocation(profile), getProfileLocationLabel(profile));
    }
    if (elements.settingsForm?.height) elements.settingsForm.height.value = profile?.height || '';
    if (elements.settingsForm?.weight) elements.settingsForm.weight.value = profile?.weight || '';
    if (elements.settingsForm?.preferred_language) elements.settingsForm.preferred_language.value = getPreferredProfileLanguage(profile);
    if (elements.settingsForm?.allergies) elements.settingsForm.allergies.value = profile?.allergies || '';
    if (elements.settingsForm?.medications) elements.settingsForm.medications.value = profile?.medications || '';
    if (elements.settingsForm?.sun_sensitive) elements.settingsForm.sun_sensitive.value = String(Boolean(profile?.sun_sensitive));
    if (elements.settingsForm?.notifications_enabled) {
      elements.settingsForm.notifications_enabled.value = String(profile?.notifications_enabled ?? true);
    }

    syncScanLocationField();
  }

  function updateAuthUi() {
    const isLoggedIn = Boolean(state.currentUser);

    elements.logoutBtn?.classList.toggle('hidden', !isLoggedIn);

    [elements.navLoginBtn, elements.mobileLoginBtn, elements.footerLoginBtn].forEach((el) => {
      if (!el) return;
      el.classList.toggle('hidden', isLoggedIn);
      el.dataset.authState = isLoggedIn ? 'hidden' : '';
    });

    if (elements.heroLoginBtn) {
      elements.heroLoginBtn.textContent = isLoggedIn ? t('nav_my_account') : t('sign_up');
      elements.heroLoginBtn.setAttribute('href', isLoggedIn ? '#dashboard' : '#auth');
    }
  }

  async function loadDashboardData() {
    if (!state.currentUser || !window.SidarSupabase.canUseSupabase()) {
      state.history = [];
      state.profile = {};
      state.isAdmin = false;
      setProfile(null, state.profile);
      renderHistory([]);
      return;
    }

    const profileRes = await window.SidarSupabase.getProfile(state.currentUser.id);
    if (profileRes.error) throw profileRes.error;

    state.profile = profileRes.data || (await window.SidarSupabase.ensureProfile(state.currentUser)) || {};
    setProfile(state.currentUser, state.profile);

    const [scanRes] = await Promise.all([
      window.SidarSupabase.listScans(state.currentUser.id).catch((error) => ({ data: [], error })),
    ]);

    if (scanRes.error) {
      console.warn('Unable to load scans:', scanRes.error);
      state.history = [];
    } else {
      state.history = (scanRes.data || []).map(normalizeScanRow);
    }

    setProfile(state.currentUser, state.profile);
    renderHistory(state.history);
  }

  async function hydrateSession() {
    try {
      const { data } = await window.SidarSupabase.getSession();
      state.currentUser = data?.session?.user || null;
      if (state.currentUser) await window.SidarSupabase.ensureProfile(state.currentUser);
      updateAuthUi();
      await loadDashboardData();
      if (state.currentUser && ['#dashboard', '#auth'].includes(window.location.hash)) {
        navigate(window.location.hash);
      }

      const client = window.SidarSupabase.getClient();
      if (client) {
        client.auth.onAuthStateChange(async (_event, sessionState) => {
          state.currentUser = sessionState?.user || null;
          if (state.currentUser) await window.SidarSupabase.ensureProfile(state.currentUser);
          updateAuthUi();
          await loadDashboardData();
          if (state.currentUser && ['#dashboard', '#auth'].includes(window.location.hash)) {
            navigate(window.location.hash);
          }
        });
      }
    } catch (error) {
      console.error(error);
      state.history = [];
      state.profile = {};
      setProfile(null, state.profile);
      renderHistory([]);
    }
  }

  async function onSignup(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const { data: signUpData, error } = await window.SidarSupabase.signUp(data);
      if (error) throw error;

      const user = signUpData?.user || signUpData?.session?.user || null;
      if (user) {
        await window.SidarSupabase.saveSettings({
          id: user.id,
          email: data.email,
          full_name: data.full_name,
          age: data.age ? Number(data.age) : null,
          gender: data.gender || null,
          skin_type: data.skin_type || null,
          location_text: data.location_text || null,
          preferred_language: state.lang,
        });
      }

      showToast(t('account_created_short'));
      window.location.hash = '#dashboard';
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onPlanSave(event) {
    event.preventDefault();
    if (!ensureAuthenticatedAction()) return;
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const { error } = await window.SidarSupabase.savePlan({
        user_id: state.currentUser.id,
        morning_routine: data.morning_routine,
        evening_routine: data.night_routine,
      });
      if (error) throw error;

      showToast(t('plan_saved_short'));
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onSettingsSave(event) {
    event.preventDefault();
    if (!ensureAuthenticatedAction()) return;
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const preferredLanguage = data.preferred_language || state.lang;
      setLanguage(preferredLanguage);

      const payload = {
        id: state.currentUser.id,
        email: state.currentUser.email,
        full_name: data.full_name,
        age: data.age ? Number(data.age) : null,
        gender: data.gender || null,
        height: data.height ? Number(data.height) : null,
        weight: data.weight ? Number(data.weight) : null,
        skin_type: data.skin_type || null,
        skin_goals: data.skin_goals || null,
        allergies: data.allergies || null,
        medications: data.medications || null,
        sun_sensitive: data.sun_sensitive === 'true',
        location_text: data.location_text || null,
        preferred_language: preferredLanguage,
        notifications_enabled: data.notifications_enabled === 'true',
      };

      const { data: savedProfile, error } = await window.SidarSupabase.saveSettings(payload);
      if (error) throw error;

      state.profile = savedProfile || payload;
      setProfile(state.currentUser, state.profile);
      showToast(t('account_settings_saved'));
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  function restoreLocalForms() {
    const legacyLanguageField = elements.settingsForm?.querySelector('select[name="preferred_lang"]');
    if (legacyLanguageField?.closest('label')) {
      legacyLanguageField.closest('label').remove();
    }
    document.getElementById('guest')?.remove();
    document.querySelector('.pricing-grid article:first-child')?.remove();
    const faqItems = document.querySelectorAll('#faq .history-list article');
    if (faqItems[2]?.textContent?.toLowerCase().includes('guest') || faqItems[2]?.textContent?.includes('ضيف')) {
      faqItems[2].remove();
    }
    syncScanLocationField();
  }

  function getPostAuthRoute() {
    const pending = JSON.parse(localStorage.getItem('sidar_pending_scan') || 'null');
    if (pending?.resume_after_auth) return '#scan';
    return '#dashboard';
  }

  function capturePendingScanState() {
    if (!elements.scanForm) return;
    const formData = new FormData(elements.scanForm);
    const payload = {
      resume_after_auth: true,
      scan_type: formData.get('scan_type') || '',
      issue_type: formData.get('issue_type') || '',
      skin_type_context: formData.get('skin_type_context') || '',
      body_location: formData.get('body_location') || '',
      duration: formData.get('duration') || '',
      severity: formData.get('severity') || '',
      notes: formData.get('notes') || '',
      location_text: formData.get('location_text') || '',
      symptoms: formData.getAll('symptoms'),
      should_resume_analysis: state.selectedFiles.length > 0,
    };
    localStorage.setItem('sidar_pending_scan', JSON.stringify(payload));
  }

  function restorePendingScanState() {
    const pending = JSON.parse(localStorage.getItem('sidar_pending_scan') || 'null');
    if (!pending || !elements.scanForm) return false;

    const assignIfPresent = (name, value) => {
      const field = elements.scanForm.elements.namedItem(name);
      if (!field) return;
      field.value = value || '';
    };

    assignIfPresent('scan_type', pending.scan_type);
    assignIfPresent('issue_type', pending.issue_type);
    assignIfPresent('skin_type_context', pending.skin_type_context);
    assignIfPresent('body_location', pending.body_location);
    assignIfPresent('duration', pending.duration);
    assignIfPresent('severity', pending.severity);
    assignIfPresent('notes', pending.notes);
    assignIfPresent('location_text', pending.location_text || getProfileLocation());

    elements.scanForm.querySelectorAll('input[name="symptoms"][type="checkbox"]').forEach((input) => {
      input.checked = Array.isArray(pending.symptoms) ? pending.symptoms.includes(input.value) : false;
    });

    localStorage.removeItem('sidar_pending_scan');

    if (pending.should_resume_analysis && state.selectedFiles.length) {
      requestAnimationFrame(() => elements.scanForm?.requestSubmit());
    } else {
      showToast(state.lang === 'ar' ? 'تمت استعادة بيانات التحليل السابقة.' : 'Your previous analysis inputs were restored.');
    }
    return true;
  }

  function handlePostAuthSuccess() {
    const destination = getPostAuthRoute();
    window.location.hash = destination;
    if (destination === '#scan') {
      restorePendingScanState();
    }
  }

  function ensureAuthenticatedAction(messageKey) {
    if (state.currentUser && window.SidarSupabase.canUseSupabase()) return true;
    capturePendingScanState();
    const fallbackMessage =
      state.lang === 'ar'
        ? 'يجب تسجيل الدخول أولًا. سنعيدك لإكمال التحليل بنفس البيانات بعد الدخول.'
        : 'You need to sign in first. We will bring you back to continue the analysis after login.';
    showToast(messageKey ? t(messageKey) : fallbackMessage, 'error');
    window.location.hash = '#auth';
    return false;
  }

  function navigate(hash) {
    const rawId = hash.replace('#', '') || 'landing';
    let routeId = rawId === 'scan' ? 'how' : (routeIds.includes(rawId) ? rawId : 'landing');
    const anchorTarget = rawId === 'scan' ? 'scan' : (routeIds.includes(rawId) ? null : rawId);

    if ((routeId === 'dashboard' || routeId === 'auth') && state.currentUser) {
      routeId = rawId === 'auth' ? 'dashboard' : routeId;
    }

    if (routeId === 'dashboard' && !state.currentUser) {
      routeId = 'auth';
    }

    activateRoute(routeId);
    closeMobileMenu();

    requestAnimationFrame(() => {
      if (anchorTarget) {
        const target = document.getElementById(anchorTarget);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
          return;
        }
      }
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  function updateAuthUi() {
    const isLoggedIn = Boolean(state.currentUser);

    elements.logoutBtn?.classList.toggle('hidden', !isLoggedIn);

    [elements.navLoginBtn, elements.mobileLoginBtn, elements.footerLoginBtn].forEach((el) => {
      if (!el) return;
      el.classList.toggle('hidden', isLoggedIn);
      el.dataset.authState = isLoggedIn ? 'hidden' : '';
    });

    document.querySelectorAll('a[data-p="auth"]').forEach((el) => {
      el.setAttribute('href', isLoggedIn ? '#dashboard' : '#auth');
    });
    if (elements.footerMyAccountBtn) elements.footerMyAccountBtn.setAttribute('href', isLoggedIn ? '#dashboard' : '#auth');
    if (elements.mobileLoginBtn) elements.mobileLoginBtn.setAttribute('href', isLoggedIn ? '#dashboard' : '#auth');

    if (elements.heroLoginBtn) {
      elements.heroLoginBtn.textContent = isLoggedIn ? t('nav_my_account') : t('sign_up');
      elements.heroLoginBtn.setAttribute('href', isLoggedIn ? '#dashboard' : '#auth');
    }
  }

  function setProfile(user, profile = state.profile) {
    const fullName = profile?.full_name || user?.user_metadata?.full_name || user?.email?.split('@')[0] || t('profile_default_name');
    const email = user?.email || profile?.email || '--';

    if (elements.profileName) elements.profileName.textContent = fullName;
    if (elements.profileEmail) elements.profileEmail.textContent = email;

    if (elements.profileInitials) {
      elements.profileInitials.textContent =
        fullName
          .split(' ')
          .slice(0, 2)
          .map((part) => part[0]?.toUpperCase() || '')
          .join('') || 'SI';
    }

    if (elements.profileAge) elements.profileAge.textContent = formatProfileValue(profile?.age);
    if (elements.profileGender) elements.profileGender.textContent = localizeGender(profile?.gender);
    if (elements.profileSkinType) elements.profileSkinType.textContent = profile?.skin_type || '--';
    if (elements.profileLocation) elements.profileLocation.textContent = getProfileLocationLabel(profile) || '--';
    if (elements.profileHeight) elements.profileHeight.textContent = formatProfileValue(profile?.height, ' cm');
    if (elements.profileWeight) elements.profileWeight.textContent = formatProfileValue(profile?.weight, ' kg');

    if (elements.settingsForm?.full_name) elements.settingsForm.full_name.value = fullName;
    if (elements.settingsForm?.age) elements.settingsForm.age.value = profile?.age || '';
    if (elements.settingsForm?.gender) elements.settingsForm.gender.value = profile?.gender || '';
    if (elements.settingsForm?.skin_type) elements.settingsForm.skin_type.value = profile?.skin_type || '';
    if (elements.settingsForm?.location_text) elements.settingsForm.location_text.value = getProfileLocation(profile);
    if (elements.settingsForm?.height) elements.settingsForm.height.value = profile?.height || '';
    if (elements.settingsForm?.weight) elements.settingsForm.weight.value = profile?.weight || '';
    if (elements.settingsForm?.preferred_language) elements.settingsForm.preferred_language.value = getPreferredProfileLanguage(profile);
    if (elements.settingsForm?.allergies) elements.settingsForm.allergies.value = profile?.allergies || '';
    if (elements.settingsForm?.medications) elements.settingsForm.medications.value = profile?.medications || '';
    if (elements.settingsForm?.sun_sensitive) elements.settingsForm.sun_sensitive.value = String(Boolean(profile?.sun_sensitive));
    if (elements.settingsForm?.notifications_enabled) elements.settingsForm.notifications_enabled.value = String(profile?.notifications_enabled ?? true);

    if (!user) state.isAdmin = false;
    document.getElementById('catalogAdminPanel')?.toggleAttribute('hidden', !state.isAdmin);

    syncScanLocationField();
  }

  function catalogTerms(value) {
    return String(value || '').split(',').map((term) => term.trim().toLowerCase()).filter(Boolean).slice(0, 12);
  }

  async function refreshCatalogAdminStatus() {
    const status = document.getElementById('catalogAdminStatus');
    if (!status || !state.isAdmin) return;
    const { data, error } = await window.SidarSupabase.getAdminCatalog();
    if (error) throw error;
    status.textContent = state.lang === 'ar'
      ? `الدليل الحالي: ${(data.doctors || []).length} طبيب/عيادة و${(data.products || []).length} منتج.`
      : `Current directory: ${(data.doctors || []).length} doctors/clinics and ${(data.products || []).length} products.`;
  }

  function bindProviderManagement() {
    const doctorForm = document.getElementById('doctorCatalogForm');
    const productForm = document.getElementById('productCatalogForm');
    const submit = (form, save, makePayload, success) => form?.addEventListener('submit', async (event) => {
      event.preventDefault();
      if (!state.isAdmin) return showToast(state.lang === 'ar' ? 'هذه العملية للمشرف فقط.' : 'This action is restricted to administrators.', 'error');
      const button = form.querySelector('button[type="submit"]');
      try {
        button.disabled = true;
        const { error } = await save(makePayload(Object.fromEntries(new FormData(form).entries())));
        if (error) throw error;
        form.reset();
        await refreshCatalogAdminStatus();
        await syncLiveContent();
        showToast(success);
      } catch (error) {
        console.error(error);
        showToast(error.message || 'Unable to save.', 'error');
      } finally {
        button.disabled = false;
      }
    });

    submit(doctorForm, window.SidarSupabase.saveDoctor, (data) => ({
      full_name: data.full_name.trim(), specialization: data.specialization, country: data.country.trim().toUpperCase(), city: data.city.trim(),
      clinic_hospital: data.clinic_hospital.trim(), booking_url: data.booking_url.trim(), concerns: catalogTerms(data.concerns), status: 'Active', is_verified: true,
    }), state.lang === 'ar' ? 'تمت إضافة الطبيب إلى الدليل الموثّق.' : 'Doctor added to the verified directory.');

    submit(productForm, window.SidarSupabase.saveProduct, (data) => ({
      name: data.name.trim(), brand: data.brand.trim(), category: data.category, concerns: catalogTerms(data.concerns),
      price: data.price === '' ? null : Number(data.price), currency: data.currency.trim().toUpperCase(), product_url: data.product_url.trim(),
      image_url: data.image_url.trim() || null, description: data.description.trim() || null, is_active: true,
    }), state.lang === 'ar' ? 'تمت إضافة المنتج إلى الكتالوج.' : 'Product added to the catalog.');
  }

  async function loadDashboardData() {
    if (!state.currentUser || !window.SidarSupabase.canUseSupabase()) {
      state.history = [];
      state.profile = {};
      setProfile(null, state.profile);
      renderHistory([]);
      return;
    }

    const profileRes = await window.SidarSupabase.getProfile(state.currentUser.id);
    if (profileRes.error) throw profileRes.error;

    state.profile = profileRes.data || (await window.SidarSupabase.ensureProfile(state.currentUser)) || {};
    const adminRes = await window.SidarSupabase.isCurrentUserAdmin();
    if (adminRes.error) throw adminRes.error;
    state.isAdmin = Boolean(adminRes.data);
    setProfile(state.currentUser, state.profile);

    const [scanRes] = await Promise.all([
      window.SidarSupabase.listScans(state.currentUser.id).catch((error) => ({ data: [], error })),
    ]);

    if (scanRes.error) {
      console.error('Could not load saved scans', scanRes.error);
      showToast(state.lang === 'ar' ? 'تم تحميل الحساب، لكن تعذر عرض التقارير المحفوظة الآن.' : 'Account loaded, but saved reports could not be displayed right now.', 'error');
    }

    state.history = (scanRes.data || []).map(normalizeScanRow).filter(Boolean);

    setProfile(state.currentUser, state.profile);
    renderHistory(state.history);
  }

  async function onLogin(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const { data: authData, error } = await window.SidarSupabase.signIn(data);
      if (error) throw error;

      state.currentUser = authData?.user || authData?.session?.user || state.currentUser;
      if (state.currentUser) {
        await window.SidarSupabase.ensureProfile(state.currentUser);
        await loadDashboardData();
      }
      updateAuthUi();
      showToast(state.lang === 'ar' ? 'تم تسجيل الدخول بنجاح.' : 'Signed in successfully.');
      handlePostAuthSuccess();
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  async function onSignup(event) {
    event.preventDefault();
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());
    const submitBtn = event.currentTarget.querySelector('button[type="submit"]');
    const originalLabel = submitBtn?.textContent || '';

    try {
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = state.lang === 'ar' ? 'جارٍ إنشاء الحساب...' : 'Creating account...';
      }

      const { data: signUpData, error } = await window.SidarSupabase.signUp(data);
      if (error) throw error;

      const user = signUpData?.user || signUpData?.session?.user || null;
      const sessionUser = signUpData?.session?.user || null;

      if (user) {
        await window.SidarSupabase.saveSettings({
          id: user.id,
          email: data.email,
          full_name: data.full_name,
          age: data.age ? Number(data.age) : null,
          gender: data.gender || null,
          skin_type: data.skin_type || null,
          location_text: data.location_text || null,
          preferred_language: state.lang,
        });
      }

      state.currentUser = sessionUser || state.currentUser;
      if (state.currentUser) {
        await loadDashboardData();
        updateAuthUi();
        showToast(t('account_created_short'));
        handlePostAuthSuccess();
      } else {
        showToast(state.lang === 'ar' ? 'تم إنشاء الحساب. أكّد بريدك الإلكتروني ثم سجّل الدخول.' : 'Account created. Please confirm your email, then sign in.');
        authTabs.forEach((b) => b.classList.remove('active'));
        authForms.signup?.classList.remove('active-auth-form');
        authForms.login?.classList.add('active-auth-form');
        document.querySelector('[data-auth-tab="login"]')?.classList.add('active');
      }
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = originalLabel || t('sign_up');
      }
    }
  }

  async function onSettingsSave(event) {
    event.preventDefault();
    if (!ensureAuthenticatedAction()) return;
    const data = Object.fromEntries(new FormData(event.currentTarget).entries());

    try {
      const preferredLanguage = data.preferred_language || state.lang;
      const payload = {
        id: state.currentUser.id,
        email: state.currentUser.email,
        full_name: data.full_name,
        age: data.age ? Number(data.age) : null,
        gender: data.gender || null,
        height: data.height ? Number(data.height) : null,
        weight: data.weight ? Number(data.weight) : null,
        skin_type: data.skin_type || null,
        skin_goals: data.skin_goals || null,
        allergies: data.allergies || null,
        medications: data.medications || null,
        sun_sensitive: data.sun_sensitive === 'true',
        location_text: data.location_text || null,
        preferred_language: preferredLanguage,
        notifications_enabled: data.notifications_enabled === 'true',
      };

      const { data: savedProfile, error } = await window.SidarSupabase.saveSettings(payload);
      if (error) throw error;

      state.profile = savedProfile || payload;
      setLanguage(preferredLanguage);
      setProfile(state.currentUser, state.profile);
      showToast(t('account_settings_saved'));
    } catch (error) {
      console.error(error);
      showToast(error.message, 'error');
    }
  }

  function restoreLocalForms() {
    const legacyLanguageField = elements.settingsForm?.querySelector('select[name="preferred_lang"]');
    if (legacyLanguageField?.closest('label')) legacyLanguageField.closest('label').remove();
    document.getElementById('guest')?.remove();
    document.querySelector('.pricing-grid article:first-child')?.remove();
    const faqItems = document.querySelectorAll('#faq .history-list article');
    if (faqItems[2]?.textContent?.toLowerCase().includes('guest') || faqItems[2]?.textContent?.includes('ضيف')) faqItems[2].remove();
    syncScanLocationField();
    restorePendingScanState();
  }

  async function syncLiveContent() {
    if (!window.SidarSupabase || !window.SidarSupabase.canUseSupabase()) return;

    // 1. Sync Pricing Plans
    try {
      const { data: plans } = await window.SidarSupabase.listPricingPlans();
      if (plans && plans.length) renderLivePricingPlans(plans);
    } catch (e) { console.error('Plans sync error:', e); }

    // 2. Sync Doctors
    try {
      const { data: doctors } = await window.SidarSupabase.listDoctors();
      if (doctors) state.liveDoctors = doctors;
    } catch (e) { console.error('Doctors sync error:', e); }

    // 3. Notifications
    if (state.currentUser) {
      try {
        const { data: notifs } = await window.SidarSupabase.listNotifications(state.currentUser.id);
        if (notifs) renderLiveNotifications(notifs);
      } catch (e) { console.error('Notifs sync error:', e); }
    }

    // 4. Sync FAQs
    try {
      const { data: faqs } = await window.SidarSupabase.listFaqs();
      if (faqs && faqs.length) renderLiveFaqs(faqs);
    } catch (e) { console.error('FAQs sync error:', e); }
  }

  function renderLivePricingPlans(plans) {
    const container = document.getElementById('pricingPlansContainer');
    if (!container) return;
    container.innerHTML = plans.map(plan => `
      <article class="partner-card">
        <div class="tag-badge">${plan.status === 'Active' ? (state.lang === 'ar' ? 'نشط' : 'Active') : ''}</div>
        <div class="h3" style="margin-top:.8rem">${plan.name}</div>
        <div class="display compact-price">${plan.monthly_price === 0 ? (state.lang === 'ar' ? 'مجاني' : 'Free') : `$${plan.monthly_price}`}</div>
        <ul class="discover-list compact-list">
          ${(plan.features || '').split('\n').filter(f => f.trim()).map(f => `<li>${f}</li>`).join('')}
        </ul>
        <a href="#auth" class="btn btn-primary full-width" style="margin-top:1.5rem">${state.lang === 'ar' ? 'اشترك الآن' : 'Subscribe Now'}</a>
      </article>
    `).join('');
  }

  function renderLiveFaqs(faqs) {
    const container = document.getElementById('faqAccordion');
    if (!container) return;
    
    container.innerHTML = faqs.map((f, idx) => `
      <div class="faq-item rv" style="transition-delay:${idx * 0.05}s">
        <div class="faq-q" onclick="this.parentElement.classList.toggle('on')">
          <span>${f.question}</span>
          <i class="fa-solid fa-chevron-down"></i>
        </div>
        <div class="faq-a">
          <div class="faq-a-inner">
            ${f.answer}
          </div>
        </div>
      </div>
    `).join('');

    // Trigger reveal animations if any
    if (typeof bindRevealAnimations === 'function') bindRevealAnimations();
  }

  function renderLiveNotifications(notifs) {
    const container = document.getElementById('notificationsList');
    if (!container) return;
    if (!notifs.length) {
      container.innerHTML = `<p class="empty-copy">${state.lang === 'ar' ? 'لا توجد إشعارات حالياً.' : 'No notifications yet.'}</p>`;
      return;
    }
    container.innerHTML = notifs.map(n => `
      <article class="glass notif-card ${n.is_read ? '' : 'unread'}" style="margin-bottom:0.8rem; padding:1rem; border-left:4px solid ${n.type === 'alert' ? 'var(--danger)' : n.type === 'warning' ? 'var(--gold)' : 'var(--accent)'}">
        <div style="display:flex; justify-content:space-between; align-items:start; margin-bottom:0.4rem;">
          <strong style="color:var(--gold)">${n.title}</strong>
          <small style="opacity:0.6">${new Date(n.created_at).toLocaleDateString(state.lang === 'ar' ? 'ar-EG' : 'en-US')}</small>
        </div>
        <p class="body-text" style="font-size:0.9rem; margin:0;">${n.message}</p>
      </article>
    `).join('');
  }

  window.submitForm = async function() {
    const first = document.getElementById('contactFirst')?.value?.trim();
    const last = document.getElementById('contactLast')?.value?.trim();
    const email = document.getElementById('contactEmail')?.value?.trim();
    const type = document.getElementById('contactType')?.value;
    const msg = document.getElementById('contactMessage')?.value?.trim();

    if (!first || !last || !email || !msg) {
      showToast(state.lang === 'ar' ? 'يرجى ملء جميع الحقول المطلوبة.' : 'Please fill in all required fields.', 'error');
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      showToast(state.lang === 'ar' ? 'يرجى إدخال بريد إلكتروني صحيح.' : 'Please enter a valid email address.', 'error');
      return;
    }

    const submitBtn = document.querySelector('#cFormWrap button');
    const originalLabel = submitBtn?.textContent || '';

    try {
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = state.lang === 'ar' ? 'جارٍ الإرسال...' : 'Sending...';
      }

      const payload = {
        company_name: `${first} ${last}`,
        contact_person: `${first} ${last}`,
        contact_email: email,
        request_type: type,
        message: msg,
        status: 'Pending',
        created_at: new Date().toISOString()
      };

      const { error } = await window.SidarSupabase.savePartnership(payload);
      if (error) throw error;

      document.getElementById('cFormWrap').style.display = 'none';
      document.getElementById('formOk').style.display = 'block';
      showToast(state.lang === 'ar' ? 'تم إرسال طلب الشراكة بنجاح.' : 'Partnership request sent successfully.');

    } catch (error) {
      console.error(error);
      showToast(error.message || 'Error sending request.', 'error');
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = originalLabel;
      }
    }
  };

  function bindShareAction() {
    const shareNativeBtn = document.getElementById('shareNativeBtn');
    if (shareNativeBtn) {
      shareNativeBtn.addEventListener('click', function () {
        const result = state.currentResult;
        const summaryText =
          result?.summary ||
          result?.guidance ||
          result?.problem_description ||
          (state.lang === 'ar' ? 'تقرير سدر للذكاء الاصطناعي لتحليل البشرة والشعر' : 'SIDAR AI Skin & Hair Report');
        const scoreVal = result?.overall_score || result?.overallScore || 85;
        const reportText = `✨ تقرير سدر | SIDAR AI Report ✨\n\n${summaryText}\n\nدرجة التقييم: ${scoreVal}%\n\nمنصة سدر للذكاء الاصطناعي`;

        if (navigator.share) {
          navigator.share({
            title: 'تقرير سدر | SIDAR AI',
            text: reportText,
            url: window.location.href,
          }).catch((err) => console.log('Share dismissed', err));
        } else if (navigator.clipboard) {
          navigator.clipboard.writeText(reportText).then(() => {
            showToast(state.lang === 'ar' ? 'تم نسخ التقرير للمشاركة' : 'Report text copied for sharing');
          });
        }
      });
    }
  }

  async function init() {
    if (elements.year) elements.year.textContent = new Date().getFullYear();
    if (elements.reportYear) elements.reportYear.textContent = new Date().getFullYear();

    setTimeout(() => {
      const splash = document.getElementById('splashScreen');
      if (splash) splash.classList.add('splash-hidden');
    }, 1200);

    embedScanIntoHow();
    bindAuthTabs();
    bindUploader();
    bindEvents();
    bindProviderManagement();
    bindShareAction();
    bindRevealAnimations();
    setLanguage(state.lang);
    updateAuthUi();
    restoreLocalForms();
    setProfile(null, state.profile);
    renderHistory();
    await hydrateSession();
    if (state.isAdmin) await refreshCatalogAdminStatus();
    await syncLiveContent();
    bindRouter();
  }

  init();
})();
