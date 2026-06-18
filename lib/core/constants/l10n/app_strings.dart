/// All app UI strings in English, Urdu, Hindi, and Arabic.
class AppStrings {
  AppStrings(this.code);

  final String code;

  String t(String en, String ur, String hi, String ar) {
    switch (code) {
      case 'ur':
        return ur;
      case 'hi':
        return hi;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  // ── Common ──────────────────────────────────────────────────────────────
  String get appName => 'Rozgar';
  String get appTagline => t(
        'Your Career, Your Way',
        'آپ کا کیریئر، آپ کا راستہ',
        'आपका करियर, आपका रास्ता',
        'مسيرتك المهنية، طريقك',
      );
  String get language => t('Language', 'زبان', 'भाषा', 'اللغة');
  String get selectLanguage => t(
        'Select Language',
        'زبان منتخب کریں',
        'भाषा चुनें',
        'اختر اللغة',
      );
  String get signOut => t('Sign Out', 'سائن آؤٹ', 'साइन आउट', 'تسجيل الخروج');
  String get loading => t('Loading...', 'لوڈ ہو رہا ہے...', 'लोड हो रहा है...', 'جاري التحميل...');
  String get tryAgain => t('Try Again', 'دوبارہ کوشش کریں', 'पुनः प्रयास', 'حاول مرة أخرى');
  String get cancel => t('Cancel', 'منسوخ', 'रद्द', 'إلغاء');
  String get continue_ => t('Continue', 'جاری رکھیں', 'जारी रखें', 'متابعة');
  String get notNow => t('Not Now', 'ابھی نہیں', 'अभी नहीं', 'ليس الآن');
  String get save => t('Save', 'محفوظ', 'सहेजें', 'حفظ');
  String get back => t('Back', 'واپس', 'वापस', 'رجوع');
  String get publish => t('Publish', 'شائع کریں', 'प्रकाशित', 'نشر');
  String get profile => t('Profile', 'پروفائل', 'प्रोफ़ाइल', 'الملف الشخصي');
  String get messages => t('Messages', 'پیغامات', 'संदेश', 'الرسائل');

  // ── Roles ───────────────────────────────────────────────────────────────
  String get roleJobSeeker =>
      t('Job Seeker', 'ملازمت طلب', 'नौकरी खोजने वाला', 'باحث عن عمل');
  String get roleRecruiter =>
      t('Recruiter', 'بھرتی کنندہ', 'भर्तीकर्ता', 'مسؤول التوظيف');
  String get roleAdmin =>
      t('Administrator', 'منتظم', 'प्रशासक', 'المسؤول');

  // ── Auth ────────────────────────────────────────────────────────────────
  String get signIn => t('Sign In', 'سائن ان', 'साइन इन', 'تسجيل الدخول');
  String get continueWithGoogle => t(
        'Continue with Google',
        'گوگل سے جاری رکھیں',
        'Google से जारी रखें',
        'المتابعة مع Google',
      );
  String get or => t('or', 'یا', 'या', 'أو');
  String get signInWithEmail =>
      t('Email', 'ای میل', 'ईमेल', 'البريد الإلكتروني');
  String get signInWithPhoneTab =>
      t('Phone', 'فون', 'फ़ोन', 'الهاتف');
  String get continueWithPhone => t(
        'Continue with Phone',
        'فون سے جاری رکھیں',
        'फ़ोन से जारी रखें',
        'المتابعة بالهاتف',
      );
  String get phoneSignInSubtitle => t(
        'Enter the phone number you used at registration and your password.',
        'وہی فون نمبر درج کریں جو رجسٹریشن میں دیا تھا اور اپنا پاس ورڈ۔',
        'पंजीकरण में दिया गया फ़ोन नंबर और पासवर्ड दर्ज करें।',
        'أدخل رقم الهاتف الذي استخدمته عند التسجيل وكلمة المرور.',
      );
  String get verifyingPhone => t(
        'Verifying your phone…',
        'آپ کے فون کی تصدیق ہو رہی ہے…',
        'आपका फ़ोन सत्यापित हो रहा है…',
        'جارٍ التحقق من هاتفك…',
      );
  String get verifyPhone =>
      t('Verify Phone', 'فون کی تصدیق', 'फ़ोन सत्यापित करें', 'تحقق من الهاتف');
  String get twoFactorTitle => t(
        'Two-Factor Authentication',
        'دو عنصری تصدیق',
        'दो-कारक प्रमाणीकरण',
        'المصادقة الثنائية',
      );
  String get twoFactorSubtitle => t(
        'Enter your mobile number. We will send a one-time OTP via SMS.',
        'اپنا موبائل نمبر درج کریں۔ ہم SMS سے OTP بھیجیں گے۔',
        'मोबाइल नंबर दर्ज करें। हम SMS से OTP भेजेंगे।',
        'أدخل رقم هاتفك. سنرسل رمز التحقق عبر الرسائل.',
      );
  String get mobileNumber =>
      t('Mobile Number', 'موبائل نمبر', 'मोबाइल नंबर', 'رقم الجوال');
  String get validPhone => t(
        'Enter a valid phone number with country code',
        'ملک کوڈ کے ساتھ درست نمبر درج کریں',
        'देश कोड के साथ वैध नंबर दर्ज करें',
        'أدخل رقماً صالحاً مع رمز الدولة',
      );
  String get phoneHint => t(
        'Include country code, e.g. +923001234567',
        'ملک کوڈ شامل کریں، مثال +923001234567',
        'देश कोड शामिल करें, जैसे +923001234567',
        'أضف رمز الدولة، مثال +923001234567',
      );
  String get sendOtp =>
      t('Send OTP', 'OTP بھیجیں', 'OTP भेजें', 'إرسال رمز التحقق');
  String get otpSent => t(
        'OTP sent to your phone',
        'آپ کے فون پر OTP بھیج دیا گیا',
        'आपके फ़ोन पर OTP भेजा गया',
        'تم إرسال رمز التحقق إلى هاتفك',
      );
  String otpSentTo(String phone) => t(
        'Enter the 6-digit code sent to $phone',
        '$phone پر بھیجا گیا 6 ہندسوں کا کوڈ درج کریں',
        '$phone पर भेजा गया 6 अंकों का कोड दर्ज करें',
        'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone',
      );
  String get enterOtpTitle =>
      t('Enter OTP', 'OTP درج کریں', 'OTP दर्ज करें', 'أدخل رمز التحقق');
  String get enterOtp => t(
        'Enter the 6-digit OTP',
        '6 ہندسوں کا OTP درج کریں',
        '6 अंकों का OTP दर्ज करें',
        'أدخل رمز التحقق المكون من 6 أرقام',
      );
  String get verifyOtp =>
      t('Verify OTP', 'OTP کی تصدیق', 'OTP सत्यापित करें', 'تحقق من الرمز');
  String get resendOtp =>
      t('Resend OTP', 'OTP دوبارہ بھیجیں', 'OTP पुनः भेजें', 'إعادة إرسال الرمز');
  String get phoneVerified => t(
        'Phone verified successfully!',
        'فون کی تصدیق ہو گئی!',
        'फ़ोन सत्यापित हो गया!',
        'تم التحقق من الهاتف بنجاح!',
      );
  String get createAccount =>
      t('Create Account', 'اکاؤنٹ بنائیں', 'खाता बनाएं', 'إنشاء حساب');
  String joinApp(String name) =>
      t('Join $name', '$name میں شامل ہوں', '$name में शामिल हों', 'انضم إلى $name');
  String get selectRole => t(
        'Select your role to get started',
        'شروع کرنے کے لیے اپنا کردار منتخب کریں',
        'शुरू करने के लिए भूमिका चुनें',
        'اختر دورك للبدء',
      );
  String get selectRoleGoogleHint => t(
        'Choose how you will use Rozgar.',
        'منتخب کریں کہ آپ Rozgar کیسے استعمال کریں گے۔',
        'चुनें कि आप Rozgar का उपयोग कैसे करेंगे।',
        'اختر كيف ستستخدم Rozgar.',
      );
  String get nameRequired =>
      t('Name is required', 'نام ضروری ہے', 'नाम आवश्यक है', 'الاسم مطلوب');
  String get accountCreated => t(
        'Account created successfully!',
        'اکاؤنٹ کامیابی سے بن گیا!',
        'खाता बन गया!',
        'تم إنشاء الحساب بنجاح!',
      );
  String get email => t('Email', 'ای میل', 'ईमेल', 'البريد الإلكتروني');
  String get password => t('Password', 'پاس ورڈ', 'पासवर्ड', 'كلمة المرور');
  String get fullName => t('Full Name', 'مکمل نام', 'पूरा नाम', 'الاسم الكامل');
  String get phoneEncrypted => t(
        'Phone (encrypted)',
        'فون (خفیہ)',
        'फ़ोन (एन्क्रिप्टेड)',
        'الهاتف (مشفر)',
      );
  String get emailRequired =>
      t('Email is required', 'ای میل ضروری ہے', 'ईमेल आवश्यक है', 'البريد مطلوب');
  String get validEmail => t(
        'Enter a valid email',
        'درست ای میل درج کریں',
        'वैध ईमेल दर्ज करें',
        'أدخل بريداً صالحاً',
      );
  String get passwordRequired => t(
        'Password is required',
        'پاس ورڈ ضروری ہے',
        'पासवर्ड आवश्यक है',
        'كلمة المرور مطلوبة',
      );
  String get passwordMin6 => t(
        'Password must be at least 6 characters',
        'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے',
        'पासवर्ड कम से कम 6 अक्षर',
        'كلمة المرور 6 أحرف على الأقل',
      );
  String get noAccountRegister => t(
        "Don't have an account? Register",
        'اکاؤنٹ نہیں؟ رجسٹر کریں',
        'खाता नहीं है? रजिस्टर करें',
        'ليس لديك حساب؟ سجّل',
      );
  String get haveAccountSignIn => t(
        'Already have an account? Sign In',
        'پہلے سے اکاؤنٹ ہے؟ سائن ان',
        'पहले से खाता है? साइन इन',
        'لديك حساب؟ سجّل الدخول',
      );
  String welcomeBack(String name) => t(
        'Welcome back, $name!',
        'خوش آمدید، $name!',
        'वापसी पर स्वागत, $name!',
        'مرحباً بعودتك، $name!',
      );
  String get checkEmail =>
      t('Check the email address you entered.', 'درج کردہ ای میل چیک کریں۔', 'ईमेल जांचें।', 'تحقق من البريد.');
  String get checkPassword => t(
        'The password does not match this account.',
        'پاس ورڈ اس اکاؤنٹ سے میل نہیں کھاتا۔',
        'पासवर्ड मेल नहीं खाता।',
        'كلمة المرور غير صحيحة.',
      );

  // ── User navigation ─────────────────────────────────────────────────────
  String get discoverJobs =>
      t('Discover Jobs', 'نوکریاں تلاش کریں', 'नौकरियां खोजें', 'اكتشف الوظائف');
  String get jobsFeed =>
      t('Jobs Feed', 'نوکریوں کی فہرست', 'नौकरी फ़ीड', 'قائمة الوظائف');
  String get jobs => t('Jobs', 'نوکریاں', 'नौकरियां', 'وظائف');
  String get applied => t('Applied', 'درخواست', 'आवेदन', 'مُقدَّم');
  String get applications =>
      t('Applications', 'درخواستیں', 'आवेदन', 'الطلبات');
  String get myApplications => t(
        'My Applications',
        'میری درخواستیں',
        'मेरे आवेदन',
        'طلباتي',
      );
  String get noJobsAvailable => t(
        'No jobs available',
        'کوئی نوکری دستیاب نہیں',
        'कोई नौकरी उपलब्ध नहीं',
        'لا توجد وظائف',
      );
  String get unableLoadJobs => t(
        'Unable to load jobs. Check your connection.',
        'نوکریاں لوڈ نہیں ہوئیں۔ کنکشن چیک کریں۔',
        'नौकरियां लोड नहीं हुईं।',
        'تعذر تحميل الوظائف.',
      );
  String get noApplicationsYet => t(
        'No applications yet',
        'ابھی کوئی درخواست نہیں',
        'अभी कोई आवेदन नहीं',
        'لا توجد طلبات بعد',
      );
  String get unableLoadApplications => t(
        'Unable to load your applications',
        'درخواستیں لوڈ نہیں ہوئیں',
        'आवेदन लोड नहीं हुए',
        'تعذر تحميل الطلبات',
      );

  // ── Company navigation ──────────────────────────────────────────────────
  String get myJobs => t('My Jobs', 'میری نوکریاں', 'मेरी नौकरियां', 'وظائفي');
  String get postJob => t('Post Job', 'نوکری پوسٹ کریں', 'नौकरी पोस्ट', 'نشر وظيفة');
  String get postAJob => t('Post a Job', 'نوکری پوسٹ کریں', 'नौकरी पोस्ट करें', 'انشر وظيفة');
  String get applicants => t('Applicants', 'درخواست دہندگان', 'आवेदक', 'المتقدمون');
  String get companyProfile =>
      t('Company Profile', 'کمپنی پروفائل', 'कंपनी प्रोफ़ाइल', 'ملف الشركة');

  // ── Admin navigation ────────────────────────────────────────────────────
  String get analytics =>
      t('Analytics', 'تجزیات', 'विश्लेषण', 'التحليلات');
  String get users => t('Users', 'صارفین', 'उपयोगकर्ता', 'المستخدمون');
  String get allJobs => t('All Jobs', 'تمام نوکریاں', 'सभी नौकरियां', 'كل الوظائف');
  String get system => t('System', 'سسٹم', 'सिस्टम', 'النظام');
  String get systemDiagnostics => t(
        'System Diagnostics',
        'سسٹم تشخیص',
        'सिस्टम निदान',
        'تشخيص النظام',
      );
  String get adminProfile =>
      t('Admin Profile', 'ایڈمن پروفائل', 'एडमिन प्रोफ़ाइल', 'ملف المسؤول');

  // ── Chat ────────────────────────────────────────────────────────────────
  String get chat => t('Chat', 'چیٹ', 'चैट', 'محادثة');
  String get noConversations => t(
        'No conversations yet.\nMessage a recruiter from a job detail page.',
        'ابھی کوئی گفتگو نہیں۔\nنوکری کی تفصیل سے پیغام بھیجیں۔',
        'अभी कोई बातचीत नहीं।',
        'لا محادثات بعد.\nراسل مسؤول التوظيف من صفحة الوظيفة.',
      );
  String get startConversation =>
      t('Start a conversation', 'گفتگو شروع کریں', 'बातचीत शुरू करें', 'ابدأ محادثة');
  String get typeMessage =>
      t('Type a message...', 'پیغام لکھیں...', 'संदेश लिखें...', 'اكتب رسالة...');
  String get unableLoadChats => t(
        'Unable to load conversations',
        'گفتگو لوڈ نہیں ہوئیں',
        'बातचीत लोड नहीं हुई',
        'تعذر تحميل المحادثات',
      );
  String get noCompanyConversations => t(
        'No messages yet.\nApplicants will appear here when they message you about a job.',
        'ابھی کوئی پیغام نہیں۔\nجب درخواست دہندگان پیغام بھیجیں گے تو یہاں نظر آئیں گے۔',
        'अभी कोई संदेश नहीं।\nजब आवेदक संदेश भेजेंगे तो यहाँ दिखेंगे।',
        'لا رسائل بعد.\nسيظهر المتقدمون هنا عند مراسلتك.',
      );

  // ── Application status ──────────────────────────────────────────────────
  String get applicationProgress => t(
        'Application Progress',
        'درخواست کی پیش رفت',
        'आवेदन प्रगति',
        'تقدم الطلب',
      );
  String get statusApplied =>
      t('Applied', 'درخواست دی', 'आवेदन किया', 'مُقدَّم');
  String get statusUnderReview => t(
        'Under Review',
        'جائزے میں',
        'समीक्षा में',
        'قيد المراجعة',
      );
  String get statusInterview => t(
        'Interview Scheduled',
        'انٹرویو طے',
        'साक्षात्कार निर्धारित',
        'مقابلة مجدولة',
      );
  String get statusOffered =>
      t('Offered', 'پیشکش', 'प्रस्ताव', 'عرض وظيفة');
  String get statusRejected => t(
        'Application was not selected at this time.',
        'اس وقت درخواست منتخب نہیں ہوئی۔',
        'आवेदन इस समय चयनित नहीं हुआ।',
        'لم يتم اختيار الطلب حالياً.',
      );
  String get statusUnavailable => t(
        'Status unavailable',
        'اسٹیٹس دستیاب نہیں',
        'स्थिति उपलब्ध नहीं',
        'الحالة غير متاحة',
      );
  String get retry => t('Retry', 'دوبارہ', 'पुनः', 'إعادة');
  String get unableLoadStatus => t(
        'Unable to load application status',
        'درخواست کی حالت لوڈ نہیں ہوئی',
        'स्थिति लोड नहीं हुई',
        'تعذر تحميل حالة الطلب',
      );

  // ── Job creator ─────────────────────────────────────────────────────────
  String get stepDetails =>
      t('Job details', 'نوکری کی تفصیل', 'नौकरी विवरण', 'تفاصيل الوظيفة');
  String get stepCompensation =>
      t('Compensation & tags', 'تنخواہ اور ٹیگز', 'वेतन और टैग', 'الراتب والوسوم');
  String get stepBanner =>
      t('Banner upload', 'بینر اپ لوڈ', 'बैनर अपलोड', 'رفع البانر');
  String get continueBtn =>
      t('Continue', 'آگے بڑھیں', 'जारी रखें', 'متابعة');
  String get publishJob =>
      t('Publish Job', 'نوکری شائع کریں', 'नौकरी प्रकाशित', 'نشر الوظيفة');
  String stepProgress(int step, String subtitle) => t(
        'Step $step of 3 · $subtitle',
        'مرحلہ $step از 3 · $subtitle',
        'चरण $step / 3 · $subtitle',
        'الخطوة $step من 3 · $subtitle',
      );
  String get stepDetailsShort =>
      t('Details', 'تفصیل', 'विवरण', 'التفاصيل');
  String get stepPayShort =>
      t('Pay', 'تنخواہ', 'वेतन', 'الراتب');
  String get stepBannerShort =>
      t('Banner', 'بینر', 'बैनर', 'البانر');
  String get sendMessageBelow => t(
        'Send a message below',
        'نیچے پیغام بھیجیں',
        'नीचे संदेश भेजें',
        'أرسل رسالة أدناه',
      );

  // ── Permissions ───────────────────────────────────────────────────────
  String get cameraAccess =>
      t('Camera Access', 'کیمرہ رسائی', 'कैमरा एक्सेस', 'الوصول للكاميرا');
  String get galleryAccess => t(
        'Photo Library Access',
        'گیلری رسائی',
        'गैलरी एक्सेस',
        'الوصول للمعرض',
      );
  String get openSettings =>
      t('Open Settings', 'سیٹنگز کھولیں', 'सेटिंग्स खोलें', 'فتح الإعدادات');

  // ── Auth error localization ─────────────────────────────────────────────
  String translateAuthError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('incorrect') || lower.contains('invalid-credential')) {
      return t(
        'The email or password is incorrect. Please verify both and try again.',
        'ای میل یا پاس ورڈ غلط ہے۔ دوبارہ چیک کریں۔',
        'ईमेल या पासवर्ड गलत है।',
        'البريد أو كلمة المرور غير صحيحة.',
      );
    }
    if (lower.contains('password')) {
      return t(
        'Incorrect password. Please check your password and try again.',
        'غلط پاس ورڈ۔ دوبارہ کوشش کریں۔',
        'गलत पासवर्ड।',
        'كلمة المرور غير صحيحة.',
      );
    }
    if (lower.contains('phone number')) {
      return t(
        'No account found with this phone number. Please register first.',
        'اس فون نمبر سے کوئی اکاؤنٹ نہیں۔ پہلے رجسٹر کریں۔',
        'इस फ़ोन नंबर से कोई खाता नहीं। पहले पंजीकरण करें।',
        'لا يوجد حساب بهذا الرقم. سجّل أولاً.',
      );
    }
    if (lower.contains('already registered')) {
      return t(
        'This phone number is already registered. Sign in with phone instead.',
        'یہ فون نمبر پہلے سے رجسٹر ہے۔ فون سے سائن ان کریں۔',
        'यह फ़ोन नंबर पहले से पंजीकृत है। फ़ोन से साइन इन करें।',
        'رقم الهاتف مسجّل مسبقاً. سجّل الدخول بالهاتف.',
      );
    }
    if (lower.contains('account') || lower.contains('user-not-found')) {
      return t(
        'No account exists with this email address. Please register first.',
        'اس ای میل سے کوئی اکاؤنٹ نہیں۔ پہلے رجسٹر کریں۔',
        'इस ईमेल से कोई खाता नहीं।',
        'لا يوجد حساب بهذا البريد.',
      );
    }
    if (lower.contains('network')) {
      return t(
        'Network error. Check your internet connection and try again.',
        'نیٹ ورک خرابی۔ انٹرنیٹ چیک کریں۔',
        'नेटवर्क त्रुटि।',
        'خطأ في الشبكة.',
      );
    }
    if (lower.contains('too many')) {
      return t(
        'Too many failed attempts. Please wait a few minutes and try again.',
        'بہت زیادہ کوششیں۔ چند منٹ بعد کوشش کریں۔',
        'बहुत प्रयास। कुछ मिनट बाद।',
        'محاولات كثيرة. انتظر قليلاً.',
      );
    }
    return error;
  }
}
