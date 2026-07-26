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
