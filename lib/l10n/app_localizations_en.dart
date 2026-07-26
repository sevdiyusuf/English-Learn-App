// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yunoo';

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
  String get friendsEmpty =>
      'You do not have any friends yet. Share your code to add a friend.';

  @override
  String get incomingFriendRequests => 'Incoming requests';

  @override
  String get friendRequestsEmpty => 'There are no pending friend requests.';

  @override
  String get friendRequest => 'Friend request';

  @override
  String get friendRequestPrivacyDescription =>
      'A user wants to connect with you.';

  @override
  String get reject => 'Reject';

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

  @override
  String get communityGuidelines => 'Community Guidelines';

  @override
  String get termsDraftNotice =>
      'Draft documents — owner and legal review required.';

  @override
  String get termsBody =>
      'Use the app respectfully and lawfully. Do not misuse shared learning content or social features.';

  @override
  String get guidelinesBody =>
      'Do not post harassment, threats, hateful or abusive material, sexual or inappropriate content, spam, scams, repeated unwanted invitations, impersonation, private information, illegal content, or attempts to evade moderation.';

  @override
  String get reviewDocuments => 'Review documents';

  @override
  String get acceptCurrentPolicies => 'Accept Terms and Community Guidelines';

  @override
  String get acceptPoliciesPrompt =>
      'To publish or update public content, review both documents and explicitly accept the current versions.';

  @override
  String get acceptPoliciesCheck =>
      'I have read and accept the Terms of Use and Community Guidelines.';

  @override
  String get accept => 'Accept';

  @override
  String get policyAcceptanceFailed =>
      'We could not record your acceptance. Please try again.';

  @override
  String get report => 'Report';

  @override
  String get reportUser => 'Report user';

  @override
  String get reportSharedSet => 'Report shared set';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportDetails => 'Optional details';

  @override
  String get submitReport => 'Submit report';

  @override
  String get reportReceived => 'Thanks. Your report was received.';

  @override
  String get reportUnavailable => 'This report cannot be submitted.';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get reportAndBlock => 'Report and block';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get blockedUsersEmpty => 'You have not blocked anyone.';

  @override
  String get blockUserPrompt =>
      'Block this user? Pending social interactions will be removed.';

  @override
  String get interactionUnavailable =>
      'This interaction is currently unavailable.';

  @override
  String get rateLimited => 'Too many attempts. Please try again later.';

  @override
  String get removeSharedSet => 'Remove shared set';

  @override
  String get removeSharedSetPrompt =>
      'Remove this public share? Your private study set will remain.';

  @override
  String get sharedSetRemoved => 'The public share was removed.';

  @override
  String get remove => 'Remove';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get onboardingIntroTitle => 'Welcome';

  @override
  String get onboardingLevelTitle => 'Choose your level';

  @override
  String get onboardingGoalTitle => 'Choose a learning goal';

  @override
  String get onboardingReviewTitle => 'Review your choices';

  @override
  String get onboardingDescription =>
      'You can change these choices later in Settings.';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get onboardingComplete => 'Start learning';

  @override
  String get onboardingSaveFailed =>
      'We could not save your choices. Please try again.';

  @override
  String onboardingReviewValue(String level, String goal) {
    return 'Level: $level Goal: $goal';
  }

  @override
  String get cefrA1 => 'A1 — Beginner';

  @override
  String get cefrA2 => 'A2 — Elementary';

  @override
  String get cefrB1 => 'B1 — Intermediate';

  @override
  String get cefrB2 => 'B2 — Upper intermediate';

  @override
  String get cefrC1 => 'C1 — Advanced';

  @override
  String get cefrC2 => 'C2 — Proficient';

  @override
  String get learningGoalWords => 'Build vocabulary';

  @override
  String get learningGoalGrammar => 'Practice grammar';

  @override
  String get learningGoalGames => 'Learn with games';

  @override
  String get learningGoalMultiplayer => 'Play with others';

  @override
  String get learningProfile => 'Learning profile';

  @override
  String get learningProfileSubtitle => 'Choose your level and learning focus';

  @override
  String get startLearning => 'Start learning';

  @override
  String get continueLearning => 'Continue learning';

  @override
  String get saveFailedRetry => 'Could not save your changes. Try again.';

  @override
  String get homeLearningModes => 'Learning modes';

  @override
  String get multiplayerSubtitle => 'Practice live with other learners';

  @override
  String get onboardingSelectionRequired => 'Choose an option to continue.';

  @override
  String get multiplayerNotifications => 'Multiplayer invitations';

  @override
  String get multiplayerNotificationsSubtitle =>
      'Get notified when a friend invites you to a game.';

  @override
  String get notificationPermissionDenied =>
      'Notifications are off. You can try again from this setting.';

  @override
  String get notificationRegistrationFailed =>
      'Notifications could not be enabled. Please try again.';

  @override
  String get notificationDisableFailed =>
      'Notifications could not be disabled. Please try again.';

  @override
  String get invitationNotificationTitle => 'Game invitation';

  @override
  String get invitationNotificationBody => 'A friend invited you to play.';

  @override
  String get invitationOpen => 'Open';

  @override
  String get invitationDismiss => 'Not now';

  @override
  String get invitationUnavailable => 'This invitation is no longer available.';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationSocial => 'Social';

  @override
  String get navigationStatistics => 'Statistics';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get backAction => 'Back';

  @override
  String get closeAction => 'Close';

  @override
  String get backToHomeAction => 'Back to home';

  @override
  String get retryAction => 'Try again';

  @override
  String get emptyStateTitle => 'Nothing here yet';

  @override
  String get emptyStateMessage => 'There is no content to show yet.';

  @override
  String get genericErrorTitle => 'Something went wrong';

  @override
  String get pageUnavailableTitle => 'Page unavailable';

  @override
  String get pageUnavailableMessage => 'This page could not be opened.';

  @override
  String get accentSelectorExpand => 'Show accent colors';

  @override
  String get accentSelectorCollapse => 'Hide accent colors';

  @override
  String accentColorOption(int number) {
    return 'Accent color $number';
  }

  @override
  String onboardingProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get statisticsLoadFailed => 'Statistics could not be loaded.';

  @override
  String get statisticsEmptyTitle => 'No statistics yet';

  @override
  String get statisticsEmptyMessage =>
      'Complete your first learning session to create statistics.';

  @override
  String blockedUserNumber(int number) {
    return 'Blocked user $number';
  }

  @override
  String get multiplayerTitle => 'Multiplayer';

  @override
  String get multiplayerHeading => 'Play live with friends';

  @override
  String get multiplayerDescription =>
      'Practice words and grammar together in the existing multiplayer modes.';

  @override
  String get wordBattleTitle => 'Word Battle';

  @override
  String get wordBattleSubtitle => 'Live vocabulary game';

  @override
  String get wordBattleDescription =>
      'Create a room, invite a friend and compete using the same words.';

  @override
  String get grammarBattleTitle => 'Grammar Battle';

  @override
  String get grammarBattleSubtitle => 'Live grammar game';

  @override
  String get grammarBattleDescription =>
      'Answer questions together and compete with the round-based score system.';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get waitingForOpponent => 'Waiting for the other player';

  @override
  String elapsedTime(int minutes, int seconds) {
    return 'Elapsed time: $minutes minutes, $seconds seconds';
  }

  @override
  String playersCount(int count) {
    return 'Players: $count';
  }

  @override
  String get hostLabel => 'Host';

  @override
  String get eliminatedLabel => 'Eliminated';

  @override
  String get currentTurnLabel => 'Current turn';

  @override
  String playerScore(String player, int score) {
    return '$player, score $score';
  }

  @override
  String gameTopic(String topic) {
    return 'Topic: $topic';
  }

  @override
  String gameTask(String partOfSpeech) {
    return 'Task: enter a $partOfSpeech';
  }

  @override
  String get partOfSpeechVerb => 'verb';

  @override
  String get partOfSpeechAdjective => 'adjective';

  @override
  String get partOfSpeechNoun => 'noun';

  @override
  String get partOfSpeechAdverb => 'adverb';

  @override
  String get waitingForYourTurn => 'Wait for your turn';

  @override
  String get waitAction => 'Wait';

  @override
  String secondsRemaining(int seconds) {
    return '$seconds seconds remaining';
  }

  @override
  String secondsShort(int seconds) {
    return '${seconds}s';
  }

  @override
  String get noWordsYet => 'No words have been played yet.';

  @override
  String myPlayedWord(String word) {
    return 'Your word: $word';
  }

  @override
  String opponentPlayedWord(String word) {
    return 'Other player\'s word: $word';
  }

  @override
  String get emailSignInTitle => 'Sign in';

  @override
  String get emailRegisterTitle => 'Create account';

  @override
  String get emailSignInSubtitle => 'Sign in with your email and password.';

  @override
  String get emailRegisterSubtitle => 'Create a new account.';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameRequired => 'Enter your full name.';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get passwordTooShort => 'Password must contain at least 6 characters.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get switchToRegister => 'Don\'t have an account? Create one';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get signInSucceeded => 'Signed in successfully.';

  @override
  String get registrationSucceeded => 'Account created successfully.';

  @override
  String get authenticationFailed =>
      'Authentication could not be completed. Please try again.';

  @override
  String get passwordResetEmailRequired =>
      'Enter a valid email address for the reset link.';

  @override
  String passwordResetSent(String email) {
    return 'A password reset email was sent to $email.';
  }
}
