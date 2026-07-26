// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

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
}
