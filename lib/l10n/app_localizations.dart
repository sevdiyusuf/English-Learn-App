import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yunoo'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @accountSection.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get accountSection;

  /// No description provided for @guestUser.
  ///
  /// In tr, this message translates to:
  /// **'Misafir Kullanıcı'**
  String get guestUser;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı Sil'**
  String get deleteAccount;

  /// No description provided for @appLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Dili'**
  String get appLanguage;

  /// No description provided for @dailyGoalType.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hedef Tipi'**
  String get dailyGoalType;

  /// No description provided for @dailyGoalValue.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hedef Değeri'**
  String get dailyGoalValue;

  /// No description provided for @wordCount.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Sayısı'**
  String get wordCount;

  /// No description provided for @minutes.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get minutes;

  /// No description provided for @words.
  ///
  /// In tr, this message translates to:
  /// **'kelime'**
  String get words;

  /// No description provided for @min.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get min;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get system;

  /// No description provided for @light.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get dark;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @sound.
  ///
  /// In tr, this message translates to:
  /// **'Ses Efektleri'**
  String get sound;

  /// No description provided for @vibration.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get vibration;

  /// No description provided for @reminders.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar'**
  String get reminders;

  /// No description provided for @reminderTime.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma Saati'**
  String get reminderTime;

  /// No description provided for @feedback.
  ///
  /// In tr, this message translates to:
  /// **'Geri Bildirim'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı Oyla'**
  String get rateApp;

  /// No description provided for @contactUs.
  ///
  /// In tr, this message translates to:
  /// **'Bize Ulaşın'**
  String get contactUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get version;

  /// No description provided for @errorUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Ayar güncellenemedi: {error}'**
  String errorUpdate(String error);

  /// No description provided for @general.
  ///
  /// In tr, this message translates to:
  /// **'Genel'**
  String get general;

  /// No description provided for @preferences.
  ///
  /// In tr, this message translates to:
  /// **'Tercihler'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @profileAndSettings.
  ///
  /// In tr, this message translates to:
  /// **'Profil & Ayarlar'**
  String get profileAndSettings;

  /// No description provided for @appearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearance;

  /// No description provided for @soundAndVibration.
  ///
  /// In tr, this message translates to:
  /// **'Ses & Titreşim'**
  String get soundAndVibration;

  /// No description provided for @soundSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyun seslerini aç/kapat'**
  String get soundSubtitle;

  /// No description provided for @vibrationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Haptic feedback aç/kapat'**
  String get vibrationSubtitle;

  /// No description provided for @dailyGoal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hedef'**
  String get dailyGoal;

  /// No description provided for @goalType.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Türü'**
  String get goalType;

  /// No description provided for @duration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get duration;

  /// No description provided for @dailyGoalDescription.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hedef, istatistik ekranında takip edilecek.'**
  String get dailyGoalDescription;

  /// No description provided for @dailyReminder.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Hatırlatma'**
  String get dailyReminder;

  /// No description provided for @dailyReminderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her gün belirlenen saatte hatırlatma gönder'**
  String get dailyReminderSubtitle;

  /// No description provided for @statistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statistics;

  /// No description provided for @progressAndStats.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme & İstatistikler'**
  String get progressAndStats;

  /// No description provided for @progressAndStatsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyun istatistiklerinizi görüntüleyin'**
  String get progressAndStatsSubtitle;

  /// No description provided for @dataAndPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Veri & Gizlilik'**
  String get dataAndPrivacy;

  /// No description provided for @resetProgress.
  ///
  /// In tr, this message translates to:
  /// **'Tüm İlerlemeyi Sıfırla'**
  String get resetProgress;

  /// No description provided for @resetProgressSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yerel ilerleme verilerini sil'**
  String get resetProgressSubtitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızı ve tüm verilerinizi kalıcı olarak silin'**
  String get deleteAccountSubtitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik politikamızı okuyun'**
  String get privacyPolicySubtitle;

  /// No description provided for @privacyPolicyComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik politikası yakında eklenecek'**
  String get privacyPolicyComingSoon;

  /// No description provided for @user.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get user;

  /// No description provided for @changeName.
  ///
  /// In tr, this message translates to:
  /// **'İsim Değiştir'**
  String get changeName;

  /// No description provided for @displayName.
  ///
  /// In tr, this message translates to:
  /// **'Görünen İsim'**
  String get displayName;

  /// No description provided for @enterName.
  ///
  /// In tr, this message translates to:
  /// **'İsminizi girin'**
  String get enterName;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @nameUpdated.
  ///
  /// In tr, this message translates to:
  /// **'İsim güncellendi'**
  String get nameUpdated;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String errorOccurred(String error);

  /// No description provided for @addFriend.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş Ekle'**
  String get addFriend;

  /// No description provided for @friendCode.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaş kodu'**
  String get friendCode;

  /// No description provided for @sendRequest.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönder'**
  String get sendRequest;

  /// No description provided for @friendRequestSent.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlık isteği gönderildi'**
  String get friendRequestSent;

  /// No description provided for @friendRequestFailed.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderilemedi: {error}'**
  String friendRequestFailed(String error);

  /// No description provided for @friendsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz arkadaşın yok. Arkadaş eklemek için kodunu paylaş.'**
  String get friendsEmpty;

  /// No description provided for @incomingFriendRequests.
  ///
  /// In tr, this message translates to:
  /// **'Gelen istekler'**
  String get incomingFriendRequests;

  /// No description provided for @friendRequestsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen arkadaşlık isteği yok.'**
  String get friendRequestsEmpty;

  /// No description provided for @friendRequest.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlık isteği'**
  String get friendRequest;

  /// No description provided for @friendRequestPrivacyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bir kullanıcı seninle bağlantı kurmak istiyor.'**
  String get friendRequestPrivacyDescription;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @resetProgressDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlerlemeyi Sıfırla'**
  String get resetProgressDialogTitle;

  /// No description provided for @resetProgressDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yerel ilerleme verileriniz silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'**
  String get resetProgressDialogContent;

  /// No description provided for @reset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @progressResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme başarıyla sıfırlandı'**
  String get progressResetSuccess;

  /// No description provided for @userNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı'**
  String get userNotFound;

  /// No description provided for @passwordResetSent.
  ///
  /// In tr, this message translates to:
  /// **'{email} adresine şifre sıfırlama e-postası gönderildi.'**
  String passwordResetSent(String email);

  /// No description provided for @reportCategoryTypo.
  ///
  /// In tr, this message translates to:
  /// **'Yazım veya imla hatası'**
  String get reportCategoryTypo;

  /// No description provided for @reportCategoryIncorrectAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı cevap anahtarı'**
  String get reportCategoryIncorrectAnswer;

  /// No description provided for @reportCategoryUnclearExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Anlaşılmayan veya kafa karıştırıcı açıklama'**
  String get reportCategoryUnclearExplanation;

  /// No description provided for @reportCategoryAudioIssue.
  ///
  /// In tr, this message translates to:
  /// **'Ses çalma sorunu'**
  String get reportCategoryAudioIssue;

  /// No description provided for @reportCategoryWrongLevelOrCategory.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış seviye veya kategori'**
  String get reportCategoryWrongLevelOrCategory;

  /// No description provided for @reportCategoryOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer sorun'**
  String get reportCategoryOther;

  /// No description provided for @reportCategoryRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir kategori seçin'**
  String get reportCategoryRequired;

  /// No description provided for @reportCommentTooLong.
  ///
  /// In tr, this message translates to:
  /// **'Yorum maksimum sınırı aşıyor'**
  String get reportCommentTooLong;

  /// No description provided for @reportContentSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Rapor başarıyla gönderildi'**
  String get reportContentSuccess;

  /// No description provided for @reportContentAlreadyReported.
  ///
  /// In tr, this message translates to:
  /// **'Sorun zaten bildirildi'**
  String get reportContentAlreadyReported;

  /// No description provided for @reportContentSignInRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sorun bildirmek için giriş yapılması gerekiyor'**
  String get reportContentSignInRequired;

  /// No description provided for @reportContentFailure.
  ///
  /// In tr, this message translates to:
  /// **'Rapor gönderilemedi'**
  String get reportContentFailure;

  /// No description provided for @reportContentTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Sorunu Bildir'**
  String get reportContentTitle;

  /// No description provided for @reportContentDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik öğesiyle ilgili bir sorun bildirin'**
  String get reportContentDescription;

  /// No description provided for @reportOptionalComment.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı yorum'**
  String get reportOptionalComment;

  /// No description provided for @reportCommentHint.
  ///
  /// In tr, this message translates to:
  /// **'Sorunu açıklayın...'**
  String get reportCommentHint;

  /// No description provided for @reportContentCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get reportContentCancel;

  /// No description provided for @reportContentSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get reportContentSubmit;

  /// No description provided for @externalLink.
  ///
  /// In tr, this message translates to:
  /// **'Harici Bağlantı'**
  String get externalLink;

  /// No description provided for @linkCopied.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı panoya kopyalandı'**
  String get linkCopied;

  /// No description provided for @copyLink.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kopyala'**
  String get copyLink;

  /// No description provided for @linkUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı mevcut değil'**
  String get linkUnavailable;

  /// No description provided for @contentAndLicenses.
  ///
  /// In tr, this message translates to:
  /// **'İçerik ve Lisanslar'**
  String get contentAndLicenses;

  /// No description provided for @contentInformationTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Bilgileri'**
  String get contentInformationTitle;

  /// No description provided for @projectCreatedContent.
  ///
  /// In tr, this message translates to:
  /// **'Proje Orijinal İçeriği'**
  String get projectCreatedContent;

  /// No description provided for @projectContentDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulama için özel olarak oluşturulmuş içerik'**
  String get projectContentDescription;

  /// No description provided for @aiAssistedContent.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka Destekli İçerik'**
  String get aiAssistedContent;

  /// No description provided for @aiAssistedContentDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka yardımıyla oluşturulmuş içerik'**
  String get aiAssistedContentDescription;

  /// No description provided for @aiAccuracyDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka içeriği bazı durumlarda hatalar içerebilir'**
  String get aiAccuracyDisclaimer;

  /// No description provided for @attributionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Atıflar'**
  String get attributionsTitle;

  /// No description provided for @materialIconsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Materyal İkonları'**
  String get materialIconsTitle;

  /// No description provided for @materialIconsAttribution.
  ///
  /// In tr, this message translates to:
  /// **'Google Materyal İkonları'**
  String get materialIconsAttribution;

  /// No description provided for @sourceAction.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak'**
  String get sourceAction;

  /// No description provided for @licenseAction.
  ///
  /// In tr, this message translates to:
  /// **'Lisans'**
  String get licenseAction;

  /// No description provided for @softwareLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Yazılım Lisansları'**
  String get softwareLicenses;

  /// No description provided for @softwareLicensesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Üçüncü taraf açık kaynak yazılım lisansları'**
  String get softwareLicensesSubtitle;

  /// No description provided for @applicationLegalese.
  ///
  /// In tr, this message translates to:
  /// **'Yasal koşullar ve telif hakkı bilgileri'**
  String get applicationLegalese;

  /// No description provided for @contentAndLicensesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama içeriği ve açık kaynak lisansları hakkında bilgi'**
  String get contentAndLicensesSubtitle;

  /// No description provided for @progressResetFailed.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme sıfırlama başarısız: {error}'**
  String progressResetFailed(String error);

  /// No description provided for @deleteAccountDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'**
  String get deleteAccountDialogContent;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @finalConfirmation.
  ///
  /// In tr, this message translates to:
  /// **'Son Onay'**
  String get finalConfirmation;

  /// No description provided for @deleteAccountFinalConfirmation.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz. Hesabınızı silmek istediğinizden emin misiniz?'**
  String get deleteAccountFinalConfirmation;

  /// No description provided for @yesDelete.
  ///
  /// In tr, this message translates to:
  /// **'Evet, Sil'**
  String get yesDelete;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Hesap başarıyla silindi'**
  String get accountDeletedSuccess;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silme başarısız: {error}'**
  String accountDeleteFailed(String error);

  /// No description provided for @userCode.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Kodu: {code}'**
  String userCode(String code);

  /// No description provided for @linkAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Bağla'**
  String get linkAccount;

  /// No description provided for @myFriends.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarım'**
  String get myFriends;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz!'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıkılmadan İngilizce kelimeler öğrenin!'**
  String get welcomeSubtitle;

  /// No description provided for @wordMatchTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Pratiği 📚'**
  String get wordMatchTitle;

  /// No description provided for @wordMatchCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Word Practice'**
  String get wordMatchCardTitle;

  /// No description provided for @wordMatchCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kendi kartlarınızla pratik yapın'**
  String get wordMatchCardSubtitle;

  /// No description provided for @trainingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim (Gramer) 📝'**
  String get trainingTitle;

  /// No description provided for @trainingCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gramer'**
  String get trainingCardTitle;

  /// No description provided for @trainingCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'A1, A2, B1, B2 Seviye Çalışmaları'**
  String get trainingCardSubtitle;

  /// No description provided for @miniGamesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence Zamanı 🎮'**
  String get miniGamesTitle;

  /// No description provided for @miniGamesCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mini Games'**
  String get miniGamesCardTitle;

  /// No description provided for @miniGamesCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kelime bilginizi oyunlarla test edin'**
  String get miniGamesCardSubtitle;

  /// No description provided for @arenaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gramer Arenası'**
  String get arenaTitle;

  /// No description provided for @createRoom.
  ///
  /// In tr, this message translates to:
  /// **'Oda Oluştur'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In tr, this message translates to:
  /// **'Odaya Katıl'**
  String get joinRoom;

  /// No description provided for @roomCode.
  ///
  /// In tr, this message translates to:
  /// **'Oda Kodu'**
  String get roomCode;

  /// No description provided for @waitingForHost.
  ///
  /// In tr, this message translates to:
  /// **'Kurucunun başlatması bekleniyor...'**
  String get waitingForHost;

  /// No description provided for @startGame.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu Başlat'**
  String get startGame;

  /// No description provided for @victory.
  ///
  /// In tr, this message translates to:
  /// **'ZAFER!'**
  String get victory;

  /// No description provided for @defeat.
  ///
  /// In tr, this message translates to:
  /// **'YENİLGİ'**
  String get defeat;

  /// No description provided for @draw.
  ///
  /// In tr, this message translates to:
  /// **'BERABERE!'**
  String get draw;

  /// No description provided for @you.
  ///
  /// In tr, this message translates to:
  /// **'SEN'**
  String get you;

  /// No description provided for @opponent.
  ///
  /// In tr, this message translates to:
  /// **'RAKİP'**
  String get opponent;

  /// No description provided for @round.
  ///
  /// In tr, this message translates to:
  /// **'TUR'**
  String get round;

  /// No description provided for @backToHome.
  ///
  /// In tr, this message translates to:
  /// **'ANA EKRANA DÖN'**
  String get backToHome;

  /// No description provided for @copied.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı!'**
  String get copied;

  /// No description provided for @wrongAnswerTryAgain.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış cevap! Tekrar dene.'**
  String get wrongAnswerTryAgain;

  /// No description provided for @wrongAnswerLocked.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış cevap! Kilitlendi.'**
  String get wrongAnswerLocked;

  /// No description provided for @communityGuidelines.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk Kuralları'**
  String get communityGuidelines;

  /// No description provided for @termsDraftNotice.
  ///
  /// In tr, this message translates to:
  /// **'Taslak belgeler — ürün sahibi ve hukuk incelemesi gereklidir.'**
  String get termsDraftNotice;

  /// No description provided for @termsBody.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı saygılı ve hukuka uygun kullanın. Paylaşılan öğrenme içeriğini veya sosyal özellikleri kötüye kullanmayın.'**
  String get termsBody;

  /// No description provided for @guidelinesBody.
  ///
  /// In tr, this message translates to:
  /// **'Taciz, tehdit, nefret söylemi veya kötüye kullanım, cinsel ya da uygunsuz içerik, spam, dolandırıcılık, tekrarlanan istenmeyen davetler, kimliğe bürünme, başkasının özel bilgileri, yasa dışı içerik veya moderasyondan kaçma girişimleri paylaşmayın.'**
  String get guidelinesBody;

  /// No description provided for @reviewDocuments.
  ///
  /// In tr, this message translates to:
  /// **'Belgeleri incele'**
  String get reviewDocuments;

  /// No description provided for @acceptCurrentPolicies.
  ///
  /// In tr, this message translates to:
  /// **'Koşulları ve Topluluk Kurallarını kabul et'**
  String get acceptCurrentPolicies;

  /// No description provided for @acceptPoliciesPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Herkese açık içerik yayınlamak veya güncellemek için iki belgeyi inceleyip güncel sürümleri açıkça kabul etmelisiniz.'**
  String get acceptPoliciesPrompt;

  /// No description provided for @acceptPoliciesCheck.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşullarını ve Topluluk Kurallarını okudum ve kabul ediyorum.'**
  String get acceptPoliciesCheck;

  /// No description provided for @accept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul et'**
  String get accept;

  /// No description provided for @policyAcceptanceFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kabul kaydedilemedi. Lütfen tekrar deneyin.'**
  String get policyAcceptanceFailed;

  /// No description provided for @report.
  ///
  /// In tr, this message translates to:
  /// **'Bildir'**
  String get report;

  /// No description provided for @reportUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcıyı bildir'**
  String get reportUser;

  /// No description provided for @reportSharedSet.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan seti bildir'**
  String get reportSharedSet;

  /// No description provided for @reportReason.
  ///
  /// In tr, this message translates to:
  /// **'Neden'**
  String get reportReason;

  /// No description provided for @reportDetails.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı ayrıntılar'**
  String get reportDetails;

  /// No description provided for @submitReport.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimi gönder'**
  String get submitReport;

  /// No description provided for @reportReceived.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler. Bildiriminiz alındı.'**
  String get reportReceived;

  /// No description provided for @reportUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu bildirim gönderilemez.'**
  String get reportUnavailable;

  /// No description provided for @block.
  ///
  /// In tr, this message translates to:
  /// **'Engelle'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In tr, this message translates to:
  /// **'Engeli kaldır'**
  String get unblock;

  /// No description provided for @reportAndBlock.
  ///
  /// In tr, this message translates to:
  /// **'Bildir ve engelle'**
  String get reportAndBlock;

  /// No description provided for @blockedUsers.
  ///
  /// In tr, this message translates to:
  /// **'Engellenen kullanıcılar'**
  String get blockedUsers;

  /// No description provided for @blockedUsersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Engellediğiniz kullanıcı yok.'**
  String get blockedUsersEmpty;

  /// No description provided for @blockUserPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı engellensin mi? Bekleyen sosyal etkileşimler kaldırılır.'**
  String get blockUserPrompt;

  /// No description provided for @interactionUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu etkileşim şu anda kullanılamıyor.'**
  String get interactionUnavailable;

  /// No description provided for @rateLimited.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.'**
  String get rateLimited;

  /// No description provided for @removeSharedSet.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan seti kaldır'**
  String get removeSharedSet;

  /// No description provided for @removeSharedSetPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Bu herkese açık paylaşım kaldırılsın mı? Özel çalışma setiniz korunur.'**
  String get removeSharedSetPrompt;

  /// No description provided for @sharedSetRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Herkese açık paylaşım kaldırıldı.'**
  String get sharedSetRemoved;

  /// No description provided for @remove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get remove;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Lütfen tekrar deneyin.'**
  String get errorGeneric;

  /// No description provided for @onboardingIntroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldiniz'**
  String get onboardingIntroTitle;

  /// No description provided for @onboardingLevelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seviyenizi seçin'**
  String get onboardingLevelTitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenme hedefinizi seçin'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingReviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçimlerinizi gözden geçirin'**
  String get onboardingReviewTitle;

  /// No description provided for @onboardingDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu seçimleri daha sonra Ayarlar\'dan değiştirebilirsiniz.'**
  String get onboardingDescription;

  /// No description provided for @onboardingNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get onboardingNext;

  /// No description provided for @onboardingComplete.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenmeye başla'**
  String get onboardingComplete;

  /// No description provided for @onboardingSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Seçimleriniz kaydedilemedi. Lütfen tekrar deneyin.'**
  String get onboardingSaveFailed;

  /// No description provided for @onboardingReviewValue.
  ///
  /// In tr, this message translates to:
  /// **'Seviye: {level} Hedef: {goal}'**
  String onboardingReviewValue(String level, String goal);

  /// No description provided for @cefrA1.
  ///
  /// In tr, this message translates to:
  /// **'A1 — Başlangıç'**
  String get cefrA1;

  /// No description provided for @cefrA2.
  ///
  /// In tr, this message translates to:
  /// **'A2 — Temel'**
  String get cefrA2;

  /// No description provided for @cefrB1.
  ///
  /// In tr, this message translates to:
  /// **'B1 — Orta'**
  String get cefrB1;

  /// No description provided for @cefrB2.
  ///
  /// In tr, this message translates to:
  /// **'B2 — Orta üstü'**
  String get cefrB2;

  /// No description provided for @cefrC1.
  ///
  /// In tr, this message translates to:
  /// **'C1 — İleri'**
  String get cefrC1;

  /// No description provided for @cefrC2.
  ///
  /// In tr, this message translates to:
  /// **'C2 — Yetkin'**
  String get cefrC2;

  /// No description provided for @learningGoalWords.
  ///
  /// In tr, this message translates to:
  /// **'Kelime dağarcığı geliştir'**
  String get learningGoalWords;

  /// No description provided for @learningGoalGrammar.
  ///
  /// In tr, this message translates to:
  /// **'Gramer pratiği yap'**
  String get learningGoalGrammar;

  /// No description provided for @learningGoalGames.
  ///
  /// In tr, this message translates to:
  /// **'Oyunlarla öğren'**
  String get learningGoalGames;

  /// No description provided for @learningGoalMultiplayer.
  ///
  /// In tr, this message translates to:
  /// **'Diğerleriyle oyna'**
  String get learningGoalMultiplayer;

  /// No description provided for @learningProfile.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenme profili'**
  String get learningProfile;

  /// No description provided for @learningProfileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seviyenizi ve öğrenme odağınızı seçin'**
  String get learningProfileSubtitle;

  /// No description provided for @startLearning.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenmeye başla'**
  String get startLearning;

  /// No description provided for @continueLearning.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenmeye devam et'**
  String get continueLearning;

  /// No description provided for @saveFailedRetry.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikler kaydedilemedi. Tekrar deneyin.'**
  String get saveFailedRetry;

  /// No description provided for @homeLearningModes.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenme modları'**
  String get homeLearningModes;

  /// No description provided for @multiplayerSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Diğer öğrencilerle canlı pratik yapın'**
  String get multiplayerSubtitle;

  /// No description provided for @onboardingSelectionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için bir seçim yapın.'**
  String get onboardingSelectionRequired;

  /// No description provided for @multiplayerNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Çok oyunculu davetleri'**
  String get multiplayerNotifications;

  /// No description provided for @multiplayerNotificationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir arkadaşın oyuna davet ettiğinde bildirim al.'**
  String get multiplayerNotificationsSubtitle;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapalı. Bu ayardan yeniden deneyebilirsin.'**
  String get notificationPermissionDenied;

  /// No description provided for @notificationRegistrationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler etkinleştirilemedi. Lütfen tekrar deneyin.'**
  String get notificationRegistrationFailed;

  /// No description provided for @notificationDisableFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapatılamadı. Lütfen tekrar deneyin.'**
  String get notificationDisableFailed;

  /// No description provided for @invitationNotificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyun daveti'**
  String get invitationNotificationTitle;

  /// No description provided for @invitationNotificationBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir arkadaşın seni oyuna davet etti.'**
  String get invitationNotificationBody;

  /// No description provided for @invitationOpen.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get invitationOpen;

  /// No description provided for @invitationDismiss.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get invitationDismiss;

  /// No description provided for @invitationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu davet artık kullanılamıyor.'**
  String get invitationUnavailable;

  /// No description provided for @navigationHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfa'**
  String get navigationHome;

  /// No description provided for @navigationSocial.
  ///
  /// In tr, this message translates to:
  /// **'Sosyal'**
  String get navigationSocial;

  /// No description provided for @navigationStatistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistik'**
  String get navigationStatistics;

  /// No description provided for @navigationProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navigationProfile;

  /// No description provided for @backAction.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get backAction;

  /// No description provided for @closeAction.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get closeAction;

  /// No description provided for @backToHomeAction.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfaya dön'**
  String get backToHomeAction;

  /// No description provided for @retryAction.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retryAction;

  /// No description provided for @emptyStateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz burada bir şey yok'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateMessage.
  ///
  /// In tr, this message translates to:
  /// **'Gösterilecek içerik henüz bulunmuyor.'**
  String get emptyStateMessage;

  /// No description provided for @genericErrorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluştu'**
  String get genericErrorTitle;

  /// No description provided for @pageUnavailableTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa kullanılamıyor'**
  String get pageUnavailableTitle;

  /// No description provided for @pageUnavailableMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa açılamadı.'**
  String get pageUnavailableMessage;

  /// No description provided for @accentSelectorExpand.
  ///
  /// In tr, this message translates to:
  /// **'Vurgu renklerini göster'**
  String get accentSelectorExpand;

  /// No description provided for @accentSelectorCollapse.
  ///
  /// In tr, this message translates to:
  /// **'Vurgu renklerini gizle'**
  String get accentSelectorCollapse;

  /// No description provided for @accentColorOption.
  ///
  /// In tr, this message translates to:
  /// **'Vurgu rengi {number}'**
  String accentColorOption(int number);

  /// No description provided for @onboardingProgress.
  ///
  /// In tr, this message translates to:
  /// **'{total} adımın {current}. adımı'**
  String onboardingProgress(int current, int total);

  /// No description provided for @statisticsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler yüklenemedi.'**
  String get statisticsLoadFailed;

  /// No description provided for @statisticsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz istatistik yok'**
  String get statisticsEmptyTitle;

  /// No description provided for @statisticsEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'İstatistiklerini oluşturmak için ilk öğrenme oturumunu tamamla.'**
  String get statisticsEmptyMessage;

  /// No description provided for @blockedUserNumber.
  ///
  /// In tr, this message translates to:
  /// **'Engellenen kullanıcı {number}'**
  String blockedUserNumber(int number);

  /// No description provided for @multiplayerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çok oyunculu'**
  String get multiplayerTitle;

  /// No description provided for @multiplayerHeading.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarınla canlı oyna'**
  String get multiplayerHeading;

  /// No description provided for @multiplayerDescription.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut çok oyunculu modlarda birlikte kelime ve gramer pratiği yapın.'**
  String get multiplayerDescription;

  /// No description provided for @wordBattleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Savaşı'**
  String get wordBattleTitle;

  /// No description provided for @wordBattleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı kelime oyunu'**
  String get wordBattleSubtitle;

  /// No description provided for @wordBattleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Oda kur, arkadaşını davet et ve aynı kelimelerle yarış.'**
  String get wordBattleDescription;

  /// No description provided for @grammarBattleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gramer Savaşı'**
  String get grammarBattleTitle;

  /// No description provided for @grammarBattleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı gramer oyunu'**
  String get grammarBattleSubtitle;

  /// No description provided for @grammarBattleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Soruları birlikte yanıtla ve turlu skor sistemiyle yarış.'**
  String get grammarBattleDescription;

  /// No description provided for @yourTurn.
  ///
  /// In tr, this message translates to:
  /// **'Sıra sende'**
  String get yourTurn;

  /// No description provided for @waitingForOpponent.
  ///
  /// In tr, this message translates to:
  /// **'Diğer oyuncu bekleniyor'**
  String get waitingForOpponent;

  /// No description provided for @elapsedTime.
  ///
  /// In tr, this message translates to:
  /// **'Geçen süre: {minutes} dakika, {seconds} saniye'**
  String elapsedTime(int minutes, int seconds);

  /// No description provided for @playersCount.
  ///
  /// In tr, this message translates to:
  /// **'Oyuncular: {count}'**
  String playersCount(int count);

  /// No description provided for @hostLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kurucu'**
  String get hostLabel;

  /// No description provided for @eliminatedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Elendi'**
  String get eliminatedLabel;

  /// No description provided for @currentTurnLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sıra bu oyuncuda'**
  String get currentTurnLabel;

  /// No description provided for @playerScore.
  ///
  /// In tr, this message translates to:
  /// **'{player}, skor {score}'**
  String playerScore(String player, int score);

  /// No description provided for @gameTopic.
  ///
  /// In tr, this message translates to:
  /// **'Konu: {topic}'**
  String gameTopic(String topic);

  /// No description provided for @gameTask.
  ///
  /// In tr, this message translates to:
  /// **'Görev: bir {partOfSpeech} gir'**
  String gameTask(String partOfSpeech);

  /// No description provided for @partOfSpeechVerb.
  ///
  /// In tr, this message translates to:
  /// **'fiil'**
  String get partOfSpeechVerb;

  /// No description provided for @partOfSpeechAdjective.
  ///
  /// In tr, this message translates to:
  /// **'sıfat'**
  String get partOfSpeechAdjective;

  /// No description provided for @partOfSpeechNoun.
  ///
  /// In tr, this message translates to:
  /// **'isim'**
  String get partOfSpeechNoun;

  /// No description provided for @partOfSpeechAdverb.
  ///
  /// In tr, this message translates to:
  /// **'zarf'**
  String get partOfSpeechAdverb;

  /// No description provided for @waitingForYourTurn.
  ///
  /// In tr, this message translates to:
  /// **'Sıranı bekle'**
  String get waitingForYourTurn;

  /// No description provided for @waitAction.
  ///
  /// In tr, this message translates to:
  /// **'Bekle'**
  String get waitAction;

  /// No description provided for @secondsRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} saniye kaldı'**
  String secondsRemaining(int seconds);

  /// No description provided for @secondsShort.
  ///
  /// In tr, this message translates to:
  /// **'{seconds} sn'**
  String secondsShort(int seconds);

  /// No description provided for @noWordsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kelime oynanmadı.'**
  String get noWordsYet;

  /// No description provided for @myPlayedWord.
  ///
  /// In tr, this message translates to:
  /// **'Senin kelimen: {word}'**
  String myPlayedWord(String word);

  /// No description provided for @opponentPlayedWord.
  ///
  /// In tr, this message translates to:
  /// **'Diğer oyuncunun kelimesi: {word}'**
  String opponentPlayedWord(String word);

  /// No description provided for @emailSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get emailSignInTitle;

  /// No description provided for @emailRegisterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get emailRegisterTitle;

  /// No description provided for @emailSignInSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresin ve şifrenle giriş yap.'**
  String get emailSignInSubtitle;

  /// No description provided for @emailRegisterSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir hesap oluştur.'**
  String get emailRegisterSubtitle;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad soyad'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Adını ve soyadını gir.'**
  String get fullNameRequired;

  /// No description provided for @emailAddress.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get emailAddress;

  /// No description provided for @emailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresini gir.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni gir.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter içermelidir.'**
  String get passwordTooShort;

  /// No description provided for @showPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get hidePassword;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreni mi unuttun?'**
  String get forgotPassword;

  /// No description provided for @switchToRegister.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Hesap oluştur'**
  String get switchToRegister;

  /// No description provided for @switchToSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş yap'**
  String get switchToSignIn;

  /// No description provided for @signInSucceeded.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapıldı.'**
  String get signInSucceeded;

  /// No description provided for @registrationSucceeded.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluşturuldu.'**
  String get registrationSucceeded;

  /// No description provided for @authenticationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama tamamlanamadı. Lütfen tekrar dene.'**
  String get authenticationFailed;

  /// No description provided for @passwordResetEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlama bağlantısı için geçerli bir e-posta adresi gir.'**
  String get passwordResetEmailRequired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
