// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yunoo';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get accountSection => 'Hesap';

  @override
  String get guestUser => 'Misafir Kullanıcı';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get deleteAccount => 'Hesabımı Sil';

  @override
  String get appLanguage => 'Uygulama Dili';

  @override
  String get dailyGoalType => 'Günlük Hedef Tipi';

  @override
  String get dailyGoalValue => 'Günlük Hedef Değeri';

  @override
  String get wordCount => 'Kelime Sayısı';

  @override
  String get minutes => 'Dakika';

  @override
  String get words => 'kelime';

  @override
  String get min => 'dk';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get sound => 'Ses Efektleri';

  @override
  String get vibration => 'Titreşim';

  @override
  String get reminders => 'Hatırlatıcılar';

  @override
  String get reminderTime => 'Hatırlatma Saati';

  @override
  String get feedback => 'Geri Bildirim';

  @override
  String get rateApp => 'Uygulamayı Oyla';

  @override
  String get contactUs => 'Bize Ulaşın';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfService => 'Kullanım Koşulları';

  @override
  String get version => 'Sürüm';

  @override
  String errorUpdate(String error) {
    return 'Ayar güncellenemedi: $error';
  }

  @override
  String get general => 'Genel';

  @override
  String get preferences => 'Tercihler';

  @override
  String get about => 'Hakkında';

  @override
  String get profileAndSettings => 'Profil & Ayarlar';

  @override
  String get appearance => 'Görünüm';

  @override
  String get soundAndVibration => 'Ses & Titreşim';

  @override
  String get soundSubtitle => 'Oyun seslerini aç/kapat';

  @override
  String get vibrationSubtitle => 'Haptic feedback aç/kapat';

  @override
  String get dailyGoal => 'Günlük Hedef';

  @override
  String get goalType => 'Hedef Türü';

  @override
  String get duration => 'Süre';

  @override
  String get dailyGoalDescription =>
      'Günlük hedef, istatistik ekranında takip edilecek.';

  @override
  String get dailyReminder => 'Günlük Hatırlatma';

  @override
  String get dailyReminderSubtitle =>
      'Her gün belirlenen saatte hatırlatma gönder';

  @override
  String get statistics => 'İstatistikler';

  @override
  String get progressAndStats => 'İlerleme & İstatistikler';

  @override
  String get progressAndStatsSubtitle => 'Oyun istatistiklerinizi görüntüleyin';

  @override
  String get dataAndPrivacy => 'Veri & Gizlilik';

  @override
  String get resetProgress => 'Tüm İlerlemeyi Sıfırla';

  @override
  String get resetProgressSubtitle => 'Yerel ilerleme verilerini sil';

  @override
  String get deleteAccountSubtitle =>
      'Hesabınızı ve tüm verilerinizi kalıcı olarak silin';

  @override
  String get privacyPolicySubtitle => 'Gizlilik politikamızı okuyun';

  @override
  String get privacyPolicyComingSoon => 'Gizlilik politikası yakında eklenecek';

  @override
  String get user => 'Kullanıcı';

  @override
  String get changeName => 'İsim Değiştir';

  @override
  String get displayName => 'Görünen İsim';

  @override
  String get enterName => 'İsminizi girin';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get nameUpdated => 'İsim güncellendi';

  @override
  String errorOccurred(String error) {
    return 'Hata: $error';
  }

  @override
  String get addFriend => 'Arkadaş Ekle';

  @override
  String get friendCode => 'Arkadaş kodu';

  @override
  String get sendRequest => 'İstek gönder';

  @override
  String get friendRequestSent => 'Arkadaşlık isteği gönderildi';

  @override
  String friendRequestFailed(String error) {
    return 'İstek gönderilemedi: $error';
  }

  @override
  String get friendsEmpty =>
      'Henüz arkadaşın yok. Arkadaş eklemek için kodunu paylaş.';

  @override
  String get incomingFriendRequests => 'Gelen istekler';

  @override
  String get friendRequestsEmpty => 'Bekleyen arkadaşlık isteği yok.';

  @override
  String get friendRequest => 'Arkadaşlık isteği';

  @override
  String get friendRequestPrivacyDescription =>
      'Bir kullanıcı seninle bağlantı kurmak istiyor.';

  @override
  String get reject => 'Reddet';

  @override
  String get resetProgressDialogTitle => 'İlerlemeyi Sıfırla';

  @override
  String get resetProgressDialogContent =>
      'Tüm yerel ilerleme verileriniz silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?';

  @override
  String get reset => 'Sıfırla';

  @override
  String get progressResetSuccess => 'İlerleme başarıyla sıfırlandı';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String passwordResetSent(String email) {
    return '$email adresine şifre sıfırlama e-postası gönderildi.';
  }

  @override
  String get reportCategoryTypo => 'Yazım veya imla hatası';

  @override
  String get reportCategoryIncorrectAnswer => 'Hatalı cevap anahtarı';

  @override
  String get reportCategoryUnclearExplanation =>
      'Anlaşılmayan veya kafa karıştırıcı açıklama';

  @override
  String get reportCategoryAudioIssue => 'Ses çalma sorunu';

  @override
  String get reportCategoryWrongLevelOrCategory =>
      'Yanlış seviye veya kategori';

  @override
  String get reportCategoryOther => 'Diğer sorun';

  @override
  String get reportCategoryRequired => 'Lütfen bir kategori seçin';

  @override
  String get reportCommentTooLong => 'Yorum maksimum sınırı aşıyor';

  @override
  String get reportContentSuccess => 'Rapor başarıyla gönderildi';

  @override
  String get reportContentAlreadyReported => 'Sorun zaten bildirildi';

  @override
  String get reportContentSignInRequired =>
      'Sorun bildirmek için giriş yapılması gerekiyor';

  @override
  String get reportContentFailure => 'Rapor gönderilemedi';

  @override
  String get reportContentTitle => 'İçerik Sorunu Bildir';

  @override
  String get reportContentDescription =>
      'Bu içerik öğesiyle ilgili bir sorun bildirin';

  @override
  String get reportOptionalComment => 'İsteğe bağlı yorum';

  @override
  String get reportCommentHint => 'Sorunu açıklayın...';

  @override
  String get reportContentCancel => 'İptal';

  @override
  String get reportContentSubmit => 'Gönder';

  @override
  String get externalLink => 'Harici Bağlantı';

  @override
  String get linkCopied => 'Bağlantı panoya kopyalandı';

  @override
  String get copyLink => 'Bağlantıyı kopyala';

  @override
  String get linkUnavailable => 'Bağlantı mevcut değil';

  @override
  String get contentAndLicenses => 'İçerik ve Lisanslar';

  @override
  String get contentInformationTitle => 'İçerik Bilgileri';

  @override
  String get projectCreatedContent => 'Proje Orijinal İçeriği';

  @override
  String get projectContentDescription =>
      'Bu uygulama için özel olarak oluşturulmuş içerik';

  @override
  String get aiAssistedContent => 'Yapay Zeka Destekli İçerik';

  @override
  String get aiAssistedContentDescription =>
      'Yapay zeka yardımıyla oluşturulmuş içerik';

  @override
  String get aiAccuracyDisclaimer =>
      'Yapay zeka içeriği bazı durumlarda hatalar içerebilir';

  @override
  String get attributionsTitle => 'Atıflar';

  @override
  String get materialIconsTitle => 'Materyal İkonları';

  @override
  String get materialIconsAttribution => 'Google Materyal İkonları';

  @override
  String get sourceAction => 'Kaynak';

  @override
  String get licenseAction => 'Lisans';

  @override
  String get softwareLicenses => 'Yazılım Lisansları';

  @override
  String get softwareLicensesSubtitle =>
      'Üçüncü taraf açık kaynak yazılım lisansları';

  @override
  String get applicationLegalese => 'Yasal koşullar ve telif hakkı bilgileri';

  @override
  String get contentAndLicensesSubtitle =>
      'Uygulama içeriği ve açık kaynak lisansları hakkında bilgi';

  @override
  String progressResetFailed(String error) {
    return 'İlerleme sıfırlama başarısız: $error';
  }

  @override
  String get deleteAccountDialogContent =>
      'Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?';

  @override
  String get delete => 'Sil';

  @override
  String get finalConfirmation => 'Son Onay';

  @override
  String get deleteAccountFinalConfirmation =>
      'Bu işlem geri alınamaz. Hesabınızı silmek istediğinizden emin misiniz?';

  @override
  String get yesDelete => 'Evet, Sil';

  @override
  String get accountDeletedSuccess => 'Hesap başarıyla silindi';

  @override
  String accountDeleteFailed(String error) {
    return 'Hesap silme başarısız: $error';
  }

  @override
  String userCode(String code) {
    return 'Kullanıcı Kodu: $code';
  }

  @override
  String get linkAccount => 'Hesap Bağla';

  @override
  String get myFriends => 'Arkadaşlarım';

  @override
  String get welcome => 'Hoş Geldiniz!';

  @override
  String get welcomeSubtitle => 'Sıkılmadan İngilizce kelimeler öğrenin!';

  @override
  String get wordMatchTitle => 'Kelime Pratiği 📚';

  @override
  String get wordMatchCardTitle => 'Word Practice';

  @override
  String get wordMatchCardSubtitle => 'Kendi kartlarınızla pratik yapın';

  @override
  String get trainingTitle => 'Eğitim (Gramer) 📝';

  @override
  String get trainingCardTitle => 'Gramer';

  @override
  String get trainingCardSubtitle => 'A1, A2, B1, B2 Seviye Çalışmaları';

  @override
  String get miniGamesTitle => 'Eğlence Zamanı 🎮';

  @override
  String get miniGamesCardTitle => 'Mini Games';

  @override
  String get miniGamesCardSubtitle => 'Kelime bilginizi oyunlarla test edin';

  @override
  String get arenaTitle => 'Gramer Arenası';

  @override
  String get createRoom => 'Oda Oluştur';

  @override
  String get joinRoom => 'Odaya Katıl';

  @override
  String get roomCode => 'Oda Kodu';

  @override
  String get waitingForHost => 'Kurucunun başlatması bekleniyor...';

  @override
  String get startGame => 'Oyunu Başlat';

  @override
  String get victory => 'ZAFER!';

  @override
  String get defeat => 'YENİLGİ';

  @override
  String get draw => 'BERABERE!';

  @override
  String get you => 'SEN';

  @override
  String get opponent => 'RAKİP';

  @override
  String get round => 'TUR';

  @override
  String get backToHome => 'ANA EKRANA DÖN';

  @override
  String get copied => 'Kopyalandı!';

  @override
  String get wrongAnswerTryAgain => 'Yanlış cevap! Tekrar dene.';

  @override
  String get wrongAnswerLocked => 'Yanlış cevap! Kilitlendi.';

  @override
  String get communityGuidelines => 'Topluluk Kuralları';

  @override
  String get termsDraftNotice =>
      'Taslak belgeler — ürün sahibi ve hukuk incelemesi gereklidir.';

  @override
  String get termsBody =>
      'Uygulamayı saygılı ve hukuka uygun kullanın. Paylaşılan öğrenme içeriğini veya sosyal özellikleri kötüye kullanmayın.';

  @override
  String get guidelinesBody =>
      'Taciz, tehdit, nefret söylemi veya kötüye kullanım, cinsel ya da uygunsuz içerik, spam, dolandırıcılık, tekrarlanan istenmeyen davetler, kimliğe bürünme, başkasının özel bilgileri, yasa dışı içerik veya moderasyondan kaçma girişimleri paylaşmayın.';

  @override
  String get reviewDocuments => 'Belgeleri incele';

  @override
  String get acceptCurrentPolicies =>
      'Koşulları ve Topluluk Kurallarını kabul et';

  @override
  String get acceptPoliciesPrompt =>
      'Herkese açık içerik yayınlamak veya güncellemek için iki belgeyi inceleyip güncel sürümleri açıkça kabul etmelisiniz.';

  @override
  String get acceptPoliciesCheck =>
      'Kullanım Koşullarını ve Topluluk Kurallarını okudum ve kabul ediyorum.';

  @override
  String get accept => 'Kabul et';

  @override
  String get policyAcceptanceFailed =>
      'Kabul kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get report => 'Bildir';

  @override
  String get reportUser => 'Kullanıcıyı bildir';

  @override
  String get reportSharedSet => 'Paylaşılan seti bildir';

  @override
  String get reportReason => 'Neden';

  @override
  String get reportDetails => 'İsteğe bağlı ayrıntılar';

  @override
  String get submitReport => 'Bildirimi gönder';

  @override
  String get reportReceived => 'Teşekkürler. Bildiriminiz alındı.';

  @override
  String get reportUnavailable => 'Bu bildirim gönderilemez.';

  @override
  String get block => 'Engelle';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get reportAndBlock => 'Bildir ve engelle';

  @override
  String get blockedUsers => 'Engellenen kullanıcılar';

  @override
  String get blockedUsersEmpty => 'Engellediğiniz kullanıcı yok.';

  @override
  String get blockUserPrompt =>
      'Bu kullanıcı engellensin mi? Bekleyen sosyal etkileşimler kaldırılır.';

  @override
  String get interactionUnavailable => 'Bu etkileşim şu anda kullanılamıyor.';

  @override
  String get rateLimited =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';

  @override
  String get removeSharedSet => 'Paylaşılan seti kaldır';

  @override
  String get removeSharedSetPrompt =>
      'Bu herkese açık paylaşım kaldırılsın mı? Özel çalışma setiniz korunur.';

  @override
  String get sharedSetRemoved => 'Herkese açık paylaşım kaldırıldı.';

  @override
  String get remove => 'Kaldır';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get errorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get onboardingIntroTitle => 'Hoş geldiniz';

  @override
  String get onboardingLevelTitle => 'Seviyenizi seçin';

  @override
  String get onboardingGoalTitle => 'Öğrenme hedefinizi seçin';

  @override
  String get onboardingReviewTitle => 'Seçimlerinizi gözden geçirin';

  @override
  String get onboardingDescription =>
      'Bu seçimleri daha sonra Ayarlar\'dan değiştirebilirsiniz.';

  @override
  String get onboardingNext => 'Devam et';

  @override
  String get onboardingComplete => 'Öğrenmeye başla';

  @override
  String get onboardingSaveFailed =>
      'Seçimleriniz kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String onboardingReviewValue(String level, String goal) {
    return 'Seviye: $level Hedef: $goal';
  }

  @override
  String get cefrA1 => 'A1 — Başlangıç';

  @override
  String get cefrA2 => 'A2 — Temel';

  @override
  String get cefrB1 => 'B1 — Orta';

  @override
  String get cefrB2 => 'B2 — Orta üstü';

  @override
  String get cefrC1 => 'C1 — İleri';

  @override
  String get cefrC2 => 'C2 — Yetkin';

  @override
  String get learningGoalWords => 'Kelime dağarcığı geliştir';

  @override
  String get learningGoalGrammar => 'Gramer pratiği yap';

  @override
  String get learningGoalGames => 'Oyunlarla öğren';

  @override
  String get learningGoalMultiplayer => 'Diğerleriyle oyna';

  @override
  String get learningProfile => 'Öğrenme profili';

  @override
  String get learningProfileSubtitle => 'Seviyenizi ve öğrenme odağınızı seçin';

  @override
  String get startLearning => 'Öğrenmeye başla';

  @override
  String get continueLearning => 'Öğrenmeye devam et';

  @override
  String get saveFailedRetry => 'Değişiklikler kaydedilemedi. Tekrar deneyin.';

  @override
  String get homeLearningModes => 'Öğrenme modları';

  @override
  String get multiplayerSubtitle => 'Diğer öğrencilerle canlı pratik yapın';

  @override
  String get onboardingSelectionRequired => 'Devam etmek için bir seçim yapın.';

  @override
  String get multiplayerNotifications => 'Çok oyunculu davetleri';

  @override
  String get multiplayerNotificationsSubtitle =>
      'Bir arkadaşın oyuna davet ettiğinde bildirim al.';

  @override
  String get notificationPermissionDenied =>
      'Bildirimler kapalı. Bu ayardan yeniden deneyebilirsin.';

  @override
  String get notificationRegistrationFailed =>
      'Bildirimler etkinleştirilemedi. Lütfen tekrar deneyin.';

  @override
  String get notificationDisableFailed =>
      'Bildirimler kapatılamadı. Lütfen tekrar deneyin.';

  @override
  String get invitationNotificationTitle => 'Oyun daveti';

  @override
  String get invitationNotificationBody =>
      'Bir arkadaşın seni oyuna davet etti.';

  @override
  String get invitationOpen => 'Aç';

  @override
  String get invitationDismiss => 'Şimdi değil';

  @override
  String get invitationUnavailable => 'Bu davet artık kullanılamıyor.';

  @override
  String get navigationHome => 'Ana sayfa';

  @override
  String get navigationSocial => 'Sosyal';

  @override
  String get navigationStatistics => 'İstatistik';

  @override
  String get navigationProfile => 'Profil';

  @override
  String get backAction => 'Geri';

  @override
  String get closeAction => 'Kapat';

  @override
  String get backToHomeAction => 'Ana sayfaya dön';

  @override
  String get retryAction => 'Tekrar dene';

  @override
  String get emptyStateTitle => 'Henüz burada bir şey yok';

  @override
  String get emptyStateMessage => 'Gösterilecek içerik henüz bulunmuyor.';

  @override
  String get genericErrorTitle => 'Bir sorun oluştu';

  @override
  String get pageUnavailableTitle => 'Sayfa kullanılamıyor';

  @override
  String get pageUnavailableMessage => 'Bu sayfa açılamadı.';

  @override
  String get accentSelectorExpand => 'Vurgu renklerini göster';

  @override
  String get accentSelectorCollapse => 'Vurgu renklerini gizle';

  @override
  String accentColorOption(int number) {
    return 'Vurgu rengi $number';
  }

  @override
  String onboardingProgress(int current, int total) {
    return '$total adımın $current. adımı';
  }

  @override
  String get statisticsLoadFailed => 'İstatistikler yüklenemedi.';

  @override
  String get statisticsEmptyTitle => 'Henüz istatistik yok';

  @override
  String get statisticsEmptyMessage =>
      'İstatistiklerini oluşturmak için ilk öğrenme oturumunu tamamla.';

  @override
  String blockedUserNumber(int number) {
    return 'Engellenen kullanıcı $number';
  }

  @override
  String get multiplayerTitle => 'Çok oyunculu';

  @override
  String get multiplayerHeading => 'Arkadaşlarınla canlı oyna';

  @override
  String get multiplayerDescription =>
      'Mevcut çok oyunculu modlarda birlikte kelime ve gramer pratiği yapın.';

  @override
  String get wordBattleTitle => 'Kelime Savaşı';

  @override
  String get wordBattleSubtitle => 'Canlı kelime oyunu';

  @override
  String get wordBattleDescription =>
      'Oda kur, arkadaşını davet et ve aynı kelimelerle yarış.';

  @override
  String get grammarBattleTitle => 'Gramer Savaşı';

  @override
  String get grammarBattleSubtitle => 'Canlı gramer oyunu';

  @override
  String get grammarBattleDescription =>
      'Soruları birlikte yanıtla ve turlu skor sistemiyle yarış.';

  @override
  String get yourTurn => 'Sıra sende';

  @override
  String get waitingForOpponent => 'Diğer oyuncu bekleniyor';

  @override
  String elapsedTime(int minutes, int seconds) {
    return 'Geçen süre: $minutes dakika, $seconds saniye';
  }

  @override
  String playersCount(int count) {
    return 'Oyuncular: $count';
  }

  @override
  String get hostLabel => 'Kurucu';

  @override
  String get eliminatedLabel => 'Elendi';

  @override
  String get currentTurnLabel => 'Sıra bu oyuncuda';

  @override
  String playerScore(String player, int score) {
    return '$player, skor $score';
  }

  @override
  String gameTopic(String topic) {
    return 'Konu: $topic';
  }

  @override
  String gameTask(String partOfSpeech) {
    return 'Görev: bir $partOfSpeech gir';
  }

  @override
  String get partOfSpeechVerb => 'fiil';

  @override
  String get partOfSpeechAdjective => 'sıfat';

  @override
  String get partOfSpeechNoun => 'isim';

  @override
  String get partOfSpeechAdverb => 'zarf';

  @override
  String get waitingForYourTurn => 'Sıranı bekle';

  @override
  String get waitAction => 'Bekle';

  @override
  String secondsRemaining(int seconds) {
    return '$seconds saniye kaldı';
  }

  @override
  String secondsShort(int seconds) {
    return '$seconds sn';
  }

  @override
  String get noWordsYet => 'Henüz kelime oynanmadı.';

  @override
  String myPlayedWord(String word) {
    return 'Senin kelimen: $word';
  }

  @override
  String opponentPlayedWord(String word) {
    return 'Diğer oyuncunun kelimesi: $word';
  }

  @override
  String get emailSignInTitle => 'Giriş yap';

  @override
  String get emailRegisterTitle => 'Hesap oluştur';

  @override
  String get emailSignInSubtitle => 'E-posta adresin ve şifrenle giriş yap.';

  @override
  String get emailRegisterSubtitle => 'Yeni bir hesap oluştur.';

  @override
  String get fullName => 'Ad soyad';

  @override
  String get fullNameRequired => 'Adını ve soyadını gir.';

  @override
  String get emailAddress => 'E-posta adresi';

  @override
  String get emailRequired => 'E-posta adresini gir.';

  @override
  String get emailInvalid => 'Geçerli bir e-posta adresi gir.';

  @override
  String get password => 'Şifre';

  @override
  String get passwordRequired => 'Şifreni gir.';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter içermelidir.';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get forgotPassword => 'Şifreni mi unuttun?';

  @override
  String get switchToRegister => 'Hesabın yok mu? Hesap oluştur';

  @override
  String get switchToSignIn => 'Zaten hesabın var mı? Giriş yap';

  @override
  String get signInSucceeded => 'Giriş yapıldı.';

  @override
  String get registrationSucceeded => 'Hesap oluşturuldu.';

  @override
  String get authenticationFailed =>
      'Kimlik doğrulama tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get passwordResetEmailRequired =>
      'Sıfırlama bağlantısı için geçerli bir e-posta adresi gir.';
}
