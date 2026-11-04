// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get signInToBoklo => 'تسجيل الدخول إلى بوكلو';

  @override
  String get signInSubtitle => 'وصول آمن إلى محفظتك والتحويلات والطلبات.';

  @override
  String get newToBoklo => 'جديد على بوكلو؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get pleaseCompleteProfile => 'يرجى إكمال إعداد ملفك الشخصي.';

  @override
  String welcomeBack(String name) {
    return 'مرحبًا بعودتك، $name.';
  }

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get createYourBokloAccount => 'أنشئ حساب بوكلو الخاص بك';

  @override
  String get createAccountAction => 'إنشاء حساب';

  @override
  String get signInLink => 'تسجيل الدخول';

  @override
  String get setUpYourProfile => 'إعداد ملفك الشخصي';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'john_doe';

  @override
  String get displayNameOptional => 'الاسم المعروض (اختياري)';

  @override
  String get displayNameHint => 'محمد أحمد';

  @override
  String get availableBalance => 'الرصيد المتاح';

  @override
  String get fundsReadyToSendOrRequest => 'الأموال جاهزة للإرسال أو الطلب';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get recentActivitySubtitle =>
      'تتبّع الحركات المالية المكتملة والمعلقة.';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get noTransactionsYet => 'لا توجد معاملات بعد';

  @override
  String get noTransactionsYetSubtitle => 'ستظهر إيراداتك ومصروفاتك هنا.';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterIncome => 'الوارد';

  @override
  String get filterExpense => 'الصادر';

  @override
  String get quickActionSend => 'إرسال';

  @override
  String get quickActionRequest => 'طلب';

  @override
  String get quickActionContacts => 'جهات الاتصال';

  @override
  String get quickActionAlerts => 'التنبيهات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSend => 'إرسال';

  @override
  String get navRequests => 'الطلبات';

  @override
  String get navContacts => 'جهات الاتصال';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get sendMoney => 'إرسال الأموال';

  @override
  String get transferDetails => 'تفاصيل التحويل';

  @override
  String get reviewTransfer => 'مراجعة التحويل';

  @override
  String get transferSuccessful => 'تم التحويل بنجاح';

  @override
  String get recipient => 'المستلم';

  @override
  String get recipientHint =>
      'معرّف المحفظة أو الاسم المستعار أو البريد الإلكتروني';

  @override
  String get amount => 'المبلغ';

  @override
  String get amountHint => '0.00';

  @override
  String get confirmAndSend => 'تأكيد وإرسال';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get insufficientBalance => 'الرصيد غير كافٍ';

  @override
  String get paymentRequests => 'طلبات الدفع';

  @override
  String get createPaymentRequest => 'إنشاء طلب دفع';

  @override
  String get newRequest => 'طلب جديد';

  @override
  String get incoming => 'الواردة';

  @override
  String get outgoing => 'الصادرة';

  @override
  String get noIncomingRequests => 'لا توجد طلبات واردة';

  @override
  String get noOutgoingRequests => 'لا توجد طلبات صادرة';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String get requestSent => 'تم إرسال الطلب';

  @override
  String get noteOptional => 'ملاحظة (اختيارية)';

  @override
  String get noteHint => 'ما الغرض من هذه الدفعة؟';

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get contacts => 'جهات الاتصال';

  @override
  String get yourNetwork => 'شبكتك';

  @override
  String get noContactsYet => 'لا توجد جهات اتصال بعد';

  @override
  String get noContactsYetSubtitle =>
      'أضف جهات اتصال موثوقة لإرسال الأموال أو طلبها بسرعة.';

  @override
  String get addContact => 'إضافة جهة اتصال';

  @override
  String get emailOrUsername => 'البريد الإلكتروني أو اسم المستخدم';

  @override
  String get emailOrUsernameHint => 'user@example.com أو @username';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get transferAlerts => 'تنبيهات التحويل';

  @override
  String get incomingTransfers => 'التحويلات الواردة';

  @override
  String get incomingTransfersSubtitle => 'أشعرني عند وصول الأموال';

  @override
  String get outgoingTransfers => 'التحويلات الصادرة';

  @override
  String get outgoingTransfersSubtitle => 'أشعرني عند إرسال الأموال';

  @override
  String get deleteNotification => 'حذف الإشعار';

  @override
  String get deleteNotificationBody => 'سيتم إزالة هذا الإشعار نهائيًا.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get pleaseSignInToViewProfile =>
      'يرجى تسجيل الدخول لعرض الملف الشخصي.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountBody =>
      'سيؤدي هذا إلى حذف بيانات ملفك الشخصي نهائيًا. يمكنك حذف الحساب فقط عندما يكون رصيدك صفرًا ولا يوجد سجل تحويلات أو طلبات دفع.';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get personalInformationSubtitle =>
      'راجع التفاصيل المرتبطة بحساب بوكلو الخاص بك.';

  @override
  String get notificationsSubtitle =>
      'اختر التنبيهات التي يجب أن يرسلها لك بوكلو.';

  @override
  String get security => 'الأمان';

  @override
  String get securitySubtitle => 'أدوات الحماية والأمان الخاصة بمحفظتك.';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get required => 'مطلوب';

  @override
  String get enterValidEmail => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusCompleted => 'مكتملة';

  @override
  String get statusFailed => 'فاشلة';

  @override
  String errorPrefix(String message) {
    return 'خطأ: $message';
  }

  @override
  String get ledger => 'دفتر الأستاذ';

  @override
  String get noEntriesYet => 'لا توجد قيود بعد';

  @override
  String get transferAlertsSubtitle =>
      'قرّر أي أحداث حركة الأموال تريد أن تُشعرك.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSend => 'إرسال رابط إعادة التعيين';

  @override
  String get passwordResetSent =>
      'إذا كان الحساب موجودًا، فقد تم إرسال رابط إعادة التعيين.';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get verifyEmailBody =>
      'أرسلنا رابط تحقق إلى بريدك الإلكتروني. تحقّق لتأمين حسابك.';

  @override
  String get verifyEmailResend => 'إعادة إرسال البريد';

  @override
  String get verifyEmailRefresh => 'لقد تحققت';

  @override
  String get emailVerifiedBannerDismiss => 'تجاهل';

  @override
  String get signedOutSuccessfully => 'تم تسجيل الخروج بنجاح.';

  @override
  String get transactionDetailTitle => 'تفاصيل المعاملة';

  @override
  String get detailDate => 'التاريخ';

  @override
  String get detailFrom => 'من';

  @override
  String get detailTo => 'إلى';

  @override
  String get detailDescription => 'الوصف';

  @override
  String get detailTransactionId => 'معرّف المعاملة';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get reportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get reportProblemHint => 'أخبرنا ماذا حدث';

  @override
  String get reportProblemSubmit => 'إرسال التقرير';

  @override
  String get reportProblemSubmitted => 'تم إرسال التقرير. سيراجعه فريقنا.';

  @override
  String get receivedMoney => 'أموال مستلمة';

  @override
  String get sentMoney => 'أموال مرسلة';

  @override
  String get searchTransactions => 'البحث في المعاملات';

  @override
  String get dateRange => 'نطاق التاريخ';

  @override
  String get clearDates => 'مسح التواريخ';

  @override
  String get receiptTitle => 'الإيصال';

  @override
  String get receiptRecipient => 'المستلم';

  @override
  String get receiptShare => 'مشاركة الإيصال';

  @override
  String receiptShareText(String amount, String date, String transferId) {
    return 'تم تأكيد دفعة بقيمة $amount بتاريخ $date.\nمعرّف التحويل: $transferId';
  }

  @override
  String get receiptDone => 'تم';

  @override
  String get offlineBanner =>
      'يتم عرض البيانات المحفوظة — قد تكون المبالغ قديمة. أعد الاتصال بالإنترنت للتحديث.';

  @override
  String limitsRemaining(Object amount) {
    return 'الحد اليومي المتبقي: $amount';
  }

  @override
  String get searchContacts => 'البحث في جهات الاتصال';

  @override
  String get chooseRecipient => 'اختر مَن سيستلم هذا الإجراء.';

  @override
  String get peopleYouCanPay =>
      'الأشخاص الذين يمكنك الدفع لهم أو طلب الأموال منهم.';

  @override
  String get helpTitle => 'المساعدة والدعم';

  @override
  String get helpFaqTitle => 'الأسئلة الشائعة';

  @override
  String get helpFaqTransfers =>
      'تُنفَّذ التحويلات بعد التحقق منها على الخادم. يمكنك إعادة محاولة التحويل الفاشل من صفحة تفاصيله.';

  @override
  String get helpFaqLimits =>
      'تحمي الحدود اليومية وحدود التحويل الواحد حسابك؛ ويظهر الحد اليومي المتبقي على شاشة الإرسال.';

  @override
  String get helpFaqVerification =>
      'تحقّق من بريدك الإلكتروني من الشريط أعلى محفظتك لتأمين حسابك.';

  @override
  String get helpContact => 'التواصل مع الدعم';

  @override
  String get helpContactEmail => 'support@boklo.app';

  @override
  String get selectContact => 'اختيار جهة اتصال';

  @override
  String get notFound => 'تعذّر العثور على هذا العنصر.';

  @override
  String get themePickLook => 'اختر المظهر الذي تريده لبوكلو.';

  @override
  String get accountDeletedSuccessfully => 'تم حذف حسابك بنجاح.';

  @override
  String get invalidNumber => 'رقم غير صالح';

  @override
  String get amountMustBePositive => 'يجب أن يكون المبلغ أكبر من 0';

  @override
  String get language => 'اللغة';

  @override
  String get languageSubtitle => 'اختر لغة التطبيق.';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get errTransferFailed => 'تعذّر إكمال التحويل.';

  @override
  String get errInsufficientBalance => 'الرصيد غير كافٍ لإتمام هذا التحويل.';

  @override
  String get errWalletNotFound => 'تعذّر العثور على محفظة المستلم.';

  @override
  String get errCurrencyMismatch =>
      'تم إيقاف هذا التحويل: المحفظتان تستخدمان عملتين مختلفتين.';

  @override
  String get errWalletNotMigrated => 'هذه المحفظة غير متاحة مؤقتًا للتحويلات.';

  @override
  String get errAlreadyProcessed => 'تمت معالجة هذا التحويل مسبقًا.';

  @override
  String get appLock => 'قفل التطبيق';

  @override
  String get appLockSubtitle =>
      'اطلب المصادقة البيومترية أو رمز قفل جهازك لفتح بوكلو.';

  @override
  String get appLockLockedTitle => 'بوكلو مقفل';

  @override
  String get appLockLockedBody => 'تحقّق من هويتك للمتابعة.';

  @override
  String get appLockUnlock => 'فتح القفل';

  @override
  String get appLockUnavailable =>
      'المصادقة البيومترية غير متاحة على هذا الجهاز.';

  @override
  String get contactActionSend => 'إرسال أموال';

  @override
  String get contactActionRequest => 'طلب دفعة';

  @override
  String get contactActionRemove => 'إزالة جهة الاتصال';

  @override
  String get addToFavorites => 'إضافة إلى المفضلة';

  @override
  String get removeFromFavorites => 'إزالة من المفضلة';

  @override
  String get favoritesSection => 'المفضلة';

  @override
  String get noFavoritesYet => 'أضف نجمة على جهة اتصال لتثبيتها هنا.';

  @override
  String get transferFormSubtitle => 'أدخل مَن سيستلم المبلغ وكم سيكون.';

  @override
  String get transferBackendNote =>
      'يتم تأكيد التحويلات على الخادم قبل تحديث الأرصدة.';

  @override
  String get qrTitle => 'رمز QR الخاص بي';

  @override
  String get qrSubtitle =>
      'يمكن للآخرين مسح هذا الرمز الضوئي باستخدام بوكلو لإرسال الأموال إليك فورًا.';

  @override
  String get qrYourHandle => 'معرّف بوكلو الخاص بك';

  @override
  String get qrShare => 'مشاركة الرمز';

  @override
  String qrShareText(String handle) {
    return 'ادفع لي عبر بوكلو! امسح هذا الرمز أو استخدم معرّفي: $handle';
  }

  @override
  String get qrScan => 'مسح رمز QR';

  @override
  String get qrScanHint => 'وجّه الكاميرا نحو رمز الدفع عبر QR الخاص ببوكلو.';

  @override
  String get qrInvalidCode => 'هذا ليس رمز دفع تابعًا لبوكلو.';

  @override
  String get qrNoHandle =>
      'اضبط اسم المستخدم في ملفك الشخصي للحصول على رمز QR للدفع.';

  @override
  String get qrTorch => 'تشغيل/إيقاف المصباح';
}
