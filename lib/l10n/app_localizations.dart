import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Min el Gasos'**
  String get appTitle;

  /// Button text for offline play
  ///
  /// In en, this message translates to:
  /// **'Play Offline'**
  String get playOffline;

  /// Button text for online play
  ///
  /// In en, this message translates to:
  /// **'Play Online'**
  String get playOnline;

  /// Settings menu option
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Message when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get noUserLoggedIn;

  /// Message when user data doesn't exist
  ///
  /// In en, this message translates to:
  /// **'No user data found'**
  String get noUserData;

  /// Dialog title for changing name
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeName;

  /// Hint text for name input
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Statistics label for games played
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// Statistics label for wins
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// Statistics label for spy wins
  ///
  /// In en, this message translates to:
  /// **'Spy Wins'**
  String get spyWins;

  /// Statistics label for detective wins
  ///
  /// In en, this message translates to:
  /// **'Detective Wins'**
  String get detectiveWins;

  /// Experience points text
  ///
  /// In en, this message translates to:
  /// **'{xp} XP Points'**
  String xpPoints(int xp);

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Guest login button text
  ///
  /// In en, this message translates to:
  /// **'Login as Guest'**
  String get loginAsGuest;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Create room button text
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// Join room button text
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// Friends list button text
  ///
  /// In en, this message translates to:
  /// **'Friends List'**
  String get friendsList;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Create account button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Link to login screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Link to signup screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Language setting option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Iron rank name
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get rankIron;

  /// Bronze rank name
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get rankBronze;

  /// Silver rank name
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get rankSilver;

  /// Gold rank name
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get rankGold;

  /// Platinum rank name
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get rankPlatinum;

  /// Emerald rank name
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get rankEmerald;

  /// Diamond rank name
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get rankDiamond;

  /// Master rank name
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get rankMaster;

  /// Grandmaster rank name
  ///
  /// In en, this message translates to:
  /// **'Grandmaster'**
  String get rankGrandmaster;

  /// Challenger rank name
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get rankChallenger;

  /// Local play button text
  ///
  /// In en, this message translates to:
  /// **'Play Local'**
  String get playLocal;

  /// Game instructions button text
  ///
  /// In en, this message translates to:
  /// **'Game Instructions'**
  String get gameInstructions;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Message about online features
  ///
  /// In en, this message translates to:
  /// **'This game is now online so we can stay together all the time❤️'**
  String get onlineMessage;

  /// Title for online terms dialog
  ///
  /// In en, this message translates to:
  /// **'Online Play Terms and Conditions'**
  String get onlineTermsTitle;

  /// Agree button text
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// Create account screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Account creation success message
  ///
  /// In en, this message translates to:
  /// **'Account created successfully ✅'**
  String get accountCreatedSuccess;

  /// Choose avatar button text
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatar;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Name field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your name here'**
  String get nameHint;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'example@mail.com'**
  String get emailHint;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'•••••••'**
  String get passwordHint;

  /// Show password tooltip
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// Hide password tooltip
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// Link to login from create account
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLogin;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get pleaseEnterName;

  /// Name length validation error
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get nameTooShort;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseEnterPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Create new account button text
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// Player count section label
  ///
  /// In en, this message translates to:
  /// **'How Many Players'**
  String get howManyPlayers;

  /// Spy count section label
  ///
  /// In en, this message translates to:
  /// **'How Many Spies'**
  String get howManySpies;

  /// Time duration section label
  ///
  /// In en, this message translates to:
  /// **'How Many Minutes'**
  String get howManyMinutes;

  /// Category selector label
  ///
  /// In en, this message translates to:
  /// **'Choose Game Type:'**
  String get chooseGameType;

  /// Start game button text
  ///
  /// In en, this message translates to:
  /// **'Start Playing'**
  String get startPlaying;

  /// Avatar picker screen title
  ///
  /// In en, this message translates to:
  /// **'Choose Avatar'**
  String get chooseAvatarTitle;

  /// Free avatars section title
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Premium avatars section title
  ///
  /// In en, this message translates to:
  /// **'Coming Soon (Premium)'**
  String get comingSoonPremium;

  /// Premium avatars locked message
  ///
  /// In en, this message translates to:
  /// **'These avatars will be available soon 🔒'**
  String get premiumAvatarsMessage;

  /// Online entry screen title
  ///
  /// In en, this message translates to:
  /// **'Play Online'**
  String get playOnlineTitle;

  /// Online entry screen introduction message
  ///
  /// In en, this message translates to:
  /// **'To start playing online, please login or create a new account'**
  String get onlineIntroMessage;

  /// Game rules screen title
  ///
  /// In en, this message translates to:
  /// **'Game Rules'**
  String get gameRules;

  /// Privacy policy screen title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Game result dialog title
  ///
  /// In en, this message translates to:
  /// **'Game Result'**
  String get gameResult;

  /// Exit game dialog title
  ///
  /// In en, this message translates to:
  /// **'Exit Game'**
  String get exitGame;

  /// Exit to home tooltip
  ///
  /// In en, this message translates to:
  /// **'Exit to Home'**
  String get exitToHome;

  /// New game button text
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// Start timer button text
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get startTimer;

  /// Result button text
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// Start voting button text
  ///
  /// In en, this message translates to:
  /// **'Start Voting'**
  String get startVoting;

  /// Game result word label
  ///
  /// In en, this message translates to:
  /// **'The word was:'**
  String get theWordWas;

  /// Time spent label
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get timeSpent;

  /// Player number label
  ///
  /// In en, this message translates to:
  /// **'Player number'**
  String get playerNumber;

  /// Spy role label
  ///
  /// In en, this message translates to:
  /// **'Spy'**
  String get spy;

  /// Detective role label
  ///
  /// In en, this message translates to:
  /// **'Detective'**
  String get detective;

  /// Confirmation to end game
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end the game?'**
  String get areYouSureEndGame;

  /// Restart round button text
  ///
  /// In en, this message translates to:
  /// **'Restart Round'**
  String get restartRound;

  /// Confirmation to restart round
  ///
  /// In en, this message translates to:
  /// **'Do you want to restart the round from the beginning?'**
  String get areYouSureRestartRound;

  /// Button to reveal player role
  ///
  /// In en, this message translates to:
  /// **'Tap to know your role'**
  String get tapToKnowRole;

  /// Spy role reveal text
  ///
  /// In en, this message translates to:
  /// **'You are the spy!'**
  String get youAreSpy;

  /// Detective role reveal text
  ///
  /// In en, this message translates to:
  /// **'You are a detective!'**
  String get youAreDetective;

  /// Start game button text
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// Next player button text
  ///
  /// In en, this message translates to:
  /// **'Next Player'**
  String get nextPlayer;

  /// Instructions for spy role
  ///
  /// In en, this message translates to:
  /// **'Try to figure out the {category} without them suspecting you!'**
  String spyInstructions(String category);

  /// Food category reveal prefix
  ///
  /// In en, this message translates to:
  /// **'The food is'**
  String get theFoodIs;

  /// Place category reveal prefix
  ///
  /// In en, this message translates to:
  /// **'The place is'**
  String get thePlaceIs;

  /// Player category reveal prefix
  ///
  /// In en, this message translates to:
  /// **'The player is'**
  String get thePlayerIs;

  /// Game description in instructions
  ///
  /// In en, this message translates to:
  /// **'🔸 Social game for 3 or more players 🔥\n🔸 Everyone knows the location or food or player etc... except the spy! 👀\n'**
  String get gameDescription;

  /// Spy objective section title
  ///
  /// In en, this message translates to:
  /// **'🎯 Spy Objective:'**
  String get spyObjective;

  /// Detailed spy objective explanation
  ///
  /// In en, this message translates to:
  /// **'- Pretend you know and don\'t get discovered.\n- Listen to questions and answers.\n- Try to figure out the location or food.\n- But ❗ you can\'t say the location or food until the round ends.\n- If you guess correctly → spies win.\n- If you\'re wrong:\n  ❌ You lose a point.\n  ✅ Everyone else gets a point.'**
  String get spyObjectiveDetails;

  /// Detective objective section title
  ///
  /// In en, this message translates to:
  /// **'🧠 Other Players\' Objective:'**
  String get detectiveObjective;

  /// Detailed detective objective explanation
  ///
  /// In en, this message translates to:
  /// **'- Ask each other yes or no questions only.\n- Try to discover who the spy is from their answers.\n- After the round ends, discuss and agree on who the spy is. If you can\'t agree, whoever guessed correctly gets a point along with the spy.'**
  String get detectiveObjectiveDetails;

  /// Full privacy policy content
  ///
  /// In en, this message translates to:
  /// **'❗ Privacy Policy for \"Min el Gasos\" App\n\nWe care about your privacy and want you to understand how we handle your data:\n\n1. 🔒 We do not collect any personal data.\n2. 📵 The app works completely offline.\n3. 👤 We do not ask you to log in or enter any information.\n4. 🙫 We do not use cookies.\n5. 🧠 Your activity within the app is not tracked.\n\n📌 Using the app means you agree to this policy.\nIf you do not agree, please do not use the app.\n\nThank you 🙏'**
  String get privacyPolicyContent;

  /// No description provided for @gameSession.
  ///
  /// In en, this message translates to:
  /// **'Game Session'**
  String get gameSession;

  /// No description provided for @playersInSession.
  ///
  /// In en, this message translates to:
  /// **'Players in Session'**
  String get playersInSession;

  /// No description provided for @votingPhase.
  ///
  /// In en, this message translates to:
  /// **'Voting Phase'**
  String get votingPhase;

  /// No description provided for @round.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get round;

  /// No description provided for @sessionStats.
  ///
  /// In en, this message translates to:
  /// **'Session Stats'**
  String get sessionStats;

  /// No description provided for @playerRoles.
  ///
  /// In en, this message translates to:
  /// **'Player Roles'**
  String get playerRoles;

  /// No description provided for @spies.
  ///
  /// In en, this message translates to:
  /// **'SPIES'**
  String get spies;

  /// No description provided for @detectives.
  ///
  /// In en, this message translates to:
  /// **'DETECTIVES'**
  String get detectives;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @gameInformation.
  ///
  /// In en, this message translates to:
  /// **'Game Information'**
  String get gameInformation;

  /// No description provided for @timerDuration.
  ///
  /// In en, this message translates to:
  /// **'Timer Duration'**
  String get timerDuration;

  /// No description provided for @totalPlayers.
  ///
  /// In en, this message translates to:
  /// **'Total Players'**
  String get totalPlayers;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @votes.
  ///
  /// In en, this message translates to:
  /// **'votes'**
  String get votes;

  /// No description provided for @voted.
  ///
  /// In en, this message translates to:
  /// **'voted'**
  String get voted;

  /// No description provided for @playersInGame.
  ///
  /// In en, this message translates to:
  /// **'Players in Game'**
  String get playersInGame;

  /// No description provided for @voteForSpy.
  ///
  /// In en, this message translates to:
  /// **'Vote for who you think is the SPY!'**
  String get voteForSpy;

  /// No description provided for @votingInstructions.
  ///
  /// In en, this message translates to:
  /// **'Choose carefully - the player with the most votes will be revealed as spy or innocent.'**
  String get votingInstructions;

  /// No description provided for @selectPlayerToVote.
  ///
  /// In en, this message translates to:
  /// **'Select a player to vote for:'**
  String get selectPlayerToVote;

  /// No description provided for @submitVote.
  ///
  /// In en, this message translates to:
  /// **'Submit Vote'**
  String get submitVote;

  /// No description provided for @voteSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Vote Submitted!'**
  String get voteSubmitted;

  /// No description provided for @youVotedFor.
  ///
  /// In en, this message translates to:
  /// **'You voted for:'**
  String get youVotedFor;

  /// No description provided for @waitingForOthers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for other players to vote...'**
  String get waitingForOthers;

  /// No description provided for @votingStatus.
  ///
  /// In en, this message translates to:
  /// **'Voting Status'**
  String get votingStatus;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResults;

  /// No description provided for @votingResults.
  ///
  /// In en, this message translates to:
  /// **'Voting Results'**
  String get votingResults;

  /// No description provided for @mostVotedPlayer.
  ///
  /// In en, this message translates to:
  /// **'Most Voted Player:'**
  String get mostVotedPlayer;

  /// No description provided for @revealRules.
  ///
  /// In en, this message translates to:
  /// **'Reveal Rules'**
  String get revealRules;

  /// No description provided for @startRound.
  ///
  /// In en, this message translates to:
  /// **'Start Round'**
  String get startRound;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next Round'**
  String get nextRound;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// No description provided for @gameInProgress.
  ///
  /// In en, this message translates to:
  /// **'Game in Progress...'**
  String get gameInProgress;

  /// No description provided for @timerPausedByHost.
  ///
  /// In en, this message translates to:
  /// **'Timer Paused by Host'**
  String get timerPausedByHost;

  /// No description provided for @waitForHostTimer.
  ///
  /// In en, this message translates to:
  /// **'Wait for the host to control the timer'**
  String get waitForHostTimer;

  /// No description provided for @voteSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vote submitted successfully!'**
  String get voteSubmittedSuccess;

  /// No description provided for @errorSubmittingVote.
  ///
  /// In en, this message translates to:
  /// **'Error submitting vote'**
  String get errorSubmittingVote;

  /// No description provided for @errorShowingResults.
  ///
  /// In en, this message translates to:
  /// **'Error showing results'**
  String get errorShowingResults;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @startRoundTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Round Timer'**
  String get startRoundTimer;

  /// No description provided for @hostControls.
  ///
  /// In en, this message translates to:
  /// **'Host Controls'**
  String get hostControls;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
