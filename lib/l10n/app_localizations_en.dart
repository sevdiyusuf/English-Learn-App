// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get guestUser => 'Guest User';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get appLanguage => 'App Language';

  @override
  String get dailyGoalType => 'Daily Goal Type';

  @override
  String get dailyGoalValue => 'Daily Goal Value';

  @override
  String get wordCount => 'Word Count';

  @override
  String get minutes => 'Minutes';

  @override
  String get words => 'words';

  @override
  String get min => 'min';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get sound => 'Sound Effects';

  @override
  String get vibration => 'Vibration';

  @override
  String get reminders => 'Reminders';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get feedback => 'Feedback';

  @override
  String get rateApp => 'Rate App';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get version => 'Version';

  @override
  String errorUpdate(String error) {
    return 'Setting could not be updated: $error';
  }

  @override
  String get general => 'General';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get profileAndSettings => 'Profile & Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get soundAndVibration => 'Sound & Vibration';

  @override
  String get soundSubtitle => 'Turn game sounds on/off';

  @override
  String get vibrationSubtitle => 'Turn haptic feedback on/off';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get goalType => 'Goal Type';

  @override
  String get duration => 'Duration';

  @override
  String get dailyGoalDescription =>
      'Daily goal will be tracked on the statistics screen.';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderSubtitle =>
      'Send a reminder at the specified time every day';

  @override
  String get statistics => 'Statistics';

  @override
  String get progressAndStats => 'Progress & Statistics';

  @override
  String get progressAndStatsSubtitle => 'View your game statistics';

  @override
  String get dataAndPrivacy => 'Data & Privacy';

  @override
  String get resetProgress => 'Reset All Progress';

  @override
  String get resetProgressSubtitle => 'Delete local progress data';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get privacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get privacyPolicyComingSoon => 'Privacy policy coming soon';

  @override
  String get user => 'User';

  @override
  String get changeName => 'Change Name';

  @override
  String get displayName => 'Display Name';

  @override
  String get enterName => 'Enter your name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get nameUpdated => 'Name updated';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get addFriend => 'Add Friend';

  @override
  String get friendCode => 'Friend Code';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get friendRequestSent => 'Friend request sent';

  @override
  String friendRequestFailed(String error) {
    return 'Could not send request: $error';
  }

  @override
  String get resetProgressDialogTitle => 'Reset Progress';

  @override
  String get resetProgressDialogContent =>
      'All your local progress data will be deleted. This action cannot be undone. Do you want to continue?';

  @override
  String get reset => 'Reset';

  @override
  String get progressResetSuccess => 'Progress successfully reset';

  @override
  String get userNotFound => 'User not found';

  @override
  String progressResetFailed(String error) {
    return 'Progress reset failed: $error';
  }

  @override
  String get deleteAccountDialogContent =>
      'Your account and all your data will be permanently deleted. This action cannot be undone. Do you want to continue?';

  @override
  String get delete => 'Delete';

  @override
  String get finalConfirmation => 'Final Confirmation';

  @override
  String get deleteAccountFinalConfirmation =>
      'This action cannot be undone. Are you sure you want to delete your account?';

  @override
  String get yesDelete => 'Yes, Delete';

  @override
  String get accountDeletedSuccess => 'Account successfully deleted';

  @override
  String accountDeleteFailed(String error) {
    return 'Account deletion failed: $error';
  }

  @override
  String userCode(String code) {
    return 'User Code: $code';
  }

  @override
  String get linkAccount => 'Link Account';

  @override
  String get myFriends => 'My Friends';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeSubtitle => 'Learn English words without getting bored!';

  @override
  String get wordMatchTitle => 'Word Match 📚';

  @override
  String get wordMatchCardTitle => 'Word Match';

  @override
  String get wordMatchCardSubtitle => 'Match with your own cards';

  @override
  String get trainingTitle => 'Training (Grammar) 📝';

  @override
  String get trainingCardTitle => 'Grammar';

  @override
  String get trainingCardSubtitle => 'A1, A2, B1, B2 Level Exercises';

  @override
  String get miniGamesTitle => 'Fun Time 🎮';

  @override
  String get miniGamesCardTitle => 'Mini Games';

  @override
  String get miniGamesCardSubtitle => 'Test your vocabulary with games';

  @override
  String get arenaTitle => 'Grammar Arena';

  @override
  String get createRoom => 'Create Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get roomCode => 'Room Code';

  @override
  String get waitingForHost => 'Waiting for host to start...';

  @override
  String get startGame => 'Start Game';

  @override
  String get victory => 'VICTORY!';

  @override
  String get defeat => 'DEFEAT';

  @override
  String get draw => 'DRAW!';

  @override
  String get you => 'YOU';

  @override
  String get opponent => 'OPPONENT';

  @override
  String get round => 'ROUND';

  @override
  String get backToHome => 'BACK TO HOME';

  @override
  String get copied => 'Copied!';

  @override
  String get wrongAnswerTryAgain => 'Wrong answer! Try again.';

  @override
  String get wrongAnswerLocked => 'Wrong answer! Locked.';
}
