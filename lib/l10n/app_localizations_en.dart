// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Min el Gasos';

  @override
  String get playOffline => 'Play Offline';

  @override
  String get playOnline => 'Play Online';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get noUserLoggedIn => 'No user logged in';

  @override
  String get noUserData => 'No user data found';

  @override
  String get changeName => 'Change Name';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get gamesPlayed => 'Games Played';

  @override
  String get wins => 'Wins';

  @override
  String get spyWins => 'Spy Wins';

  @override
  String get detectiveWins => 'Detective Wins';

  @override
  String xpPoints(int xp) {
    return '$xp XP Points';
  }

  @override
  String get login => 'Login';

  @override
  String get loginAsGuest => 'Login as Guest';

  @override
  String get logout => 'Logout';

  @override
  String get createRoom => 'Create Room';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get friendsList => 'Friends List';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get displayName => 'Display Name';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get rankIron => 'Iron';

  @override
  String get rankBronze => 'Bronze';

  @override
  String get rankSilver => 'Silver';

  @override
  String get rankGold => 'Gold';

  @override
  String get rankPlatinum => 'Platinum';

  @override
  String get rankEmerald => 'Emerald';

  @override
  String get rankDiamond => 'Diamond';

  @override
  String get rankMaster => 'Master';

  @override
  String get rankGrandmaster => 'Grandmaster';

  @override
  String get rankChallenger => 'Challenger';

  @override
  String get playLocal => 'Play Local';

  @override
  String get gameInstructions => 'Game Instructions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get onlineMessage =>
      'This game is now online so we can stay together all the time❤️';

  @override
  String get onlineTermsTitle => 'Online Play Terms and Conditions';

  @override
  String get agree => 'Agree';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get accountCreatedSuccess => 'Account created successfully ✅';

  @override
  String get chooseAvatar => 'Choose Avatar';

  @override
  String get name => 'Name';

  @override
  String get nameHint => 'Enter your name here';

  @override
  String get emailHint => 'example@mail.com';

  @override
  String get passwordHint => '•••••••';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Login';

  @override
  String get pleaseEnterName => 'Please enter name';

  @override
  String get nameTooShort => 'Name is too short';

  @override
  String get pleaseEnterEmail => 'Please enter email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginTitle => 'Login';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get howManyPlayers => 'How Many Players';

  @override
  String get howManySpies => 'How Many Spies';

  @override
  String get howManyMinutes => 'How Many Minutes';

  @override
  String get chooseGameType => 'Choose Game Type:';

  @override
  String get startPlaying => 'Start Playing';

  @override
  String get chooseAvatarTitle => 'Choose Avatar';

  @override
  String get free => 'Free';

  @override
  String get comingSoonPremium => 'Coming Soon (Premium)';

  @override
  String get premiumAvatarsMessage => 'These avatars will be available soon 🔒';

  @override
  String get playOnlineTitle => 'Play Online';

  @override
  String get onlineIntroMessage =>
      'To start playing online, please login or create a new account';

  @override
  String get gameRules => 'Game Rules';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get gameResult => 'Game Result';

  @override
  String get exitGame => 'Exit Game';

  @override
  String get exitToHome => 'Exit to Home';

  @override
  String get newGame => 'New Game';

  @override
  String get startTimer => 'Start Timer';

  @override
  String get result => 'Result';

  @override
  String get startVoting => 'Start Voting';

  @override
  String get theWordWas => 'The word was:';

  @override
  String get timeSpent => 'Time spent';

  @override
  String get playerNumber => 'Player number';

  @override
  String get spy => 'Spy';

  @override
  String get detective => 'Detective';

  @override
  String get areYouSureEndGame => 'Are you sure you want to end the game?';

  @override
  String get restartRound => 'Restart Round';

  @override
  String get areYouSureRestartRound =>
      'Do you want to restart the round from the beginning?';

  @override
  String get tapToKnowRole => 'Tap to know your role';

  @override
  String get youAreSpy => 'You are the spy!';

  @override
  String get youAreDetective => 'You are a detective!';

  @override
  String get startGame => 'Start Game';

  @override
  String get nextPlayer => 'Next Player';

  @override
  String spyInstructions(String category) {
    return 'Try to figure out the $category without them suspecting you!';
  }

  @override
  String get theFoodIs => 'The food is';

  @override
  String get thePlaceIs => 'The place is';

  @override
  String get thePlayerIs => 'The player is';

  @override
  String get gameDescription =>
      '🔸 Social game for 3 or more players 🔥\n🔸 Everyone knows the location or food or player etc... except the spy! 👀\n';

  @override
  String get spyObjective => '🎯 Spy Objective:';

  @override
  String get spyObjectiveDetails =>
      '- Pretend you know and don\'t get discovered.\n- Listen to questions and answers.\n- Try to figure out the location or food.\n- But ❗ you can\'t say the location or food until the round ends.\n- If you guess correctly → spies win.\n- If you\'re wrong:\n  ❌ You lose a point.\n  ✅ Everyone else gets a point.';

  @override
  String get detectiveObjective => '🧠 Other Players\' Objective:';

  @override
  String get detectiveObjectiveDetails =>
      '- Ask each other yes or no questions only.\n- Try to discover who the spy is from their answers.\n- After the round ends, discuss and agree on who the spy is. If you can\'t agree, whoever guessed correctly gets a point along with the spy.';

  @override
  String get privacyPolicyContent =>
      '❗ Privacy Policy for \"Min el Gasos\" App\n\nWe care about your privacy and want you to understand how we handle your data:\n\n1. 🔒 We do not collect any personal data.\n2. 📵 The app works completely offline.\n3. 👤 We do not ask you to log in or enter any information.\n4. 🙫 We do not use cookies.\n5. 🧠 Your activity within the app is not tracked.\n\n📌 Using the app means you agree to this policy.\nIf you do not agree, please do not use the app.\n\nThank you 🙏';

  @override
  String get gameSession => 'Game Session';

  @override
  String get playersInSession => 'Players in Session';

  @override
  String get votingPhase => 'Voting Phase';

  @override
  String get round => 'Round';

  @override
  String get sessionStats => 'Session Stats';

  @override
  String get playerRoles => 'Player Roles';

  @override
  String get spies => 'SPIES';

  @override
  String get detectives => 'DETECTIVES';

  @override
  String get location => 'Location';

  @override
  String get gameInformation => 'Game Information';

  @override
  String get timerDuration => 'Timer Duration';

  @override
  String get totalPlayers => 'Total Players';

  @override
  String get minutes => 'minutes';

  @override
  String get votes => 'votes';

  @override
  String get voted => 'voted';

  @override
  String get playersInGame => 'Players in Game';

  @override
  String get voteForSpy => 'Vote for who you think is the SPY!';

  @override
  String get votingInstructions =>
      'Choose carefully - the player with the most votes will be revealed as spy or innocent.';

  @override
  String get selectPlayerToVote => 'Select a player to vote for:';

  @override
  String get submitVote => 'Submit Vote';

  @override
  String get voteSubmitted => 'Vote Submitted!';

  @override
  String get youVotedFor => 'You voted for:';

  @override
  String get waitingForOthers => 'Waiting for other players to vote...';

  @override
  String get votingStatus => 'Voting Status';

  @override
  String get showResults => 'Show Results';

  @override
  String get votingResults => 'Voting Results';

  @override
  String get mostVotedPlayer => 'Most Voted Player:';

  @override
  String get revealRules => 'Reveal Rules';

  @override
  String get startRound => 'Start Round';

  @override
  String get nextRound => 'Next Round';

  @override
  String get endSession => 'End Session';

  @override
  String get gameInProgress => 'Game in Progress...';

  @override
  String get timerPausedByHost => 'Timer Paused by Host';

  @override
  String get waitForHostTimer => 'Wait for the host to control the timer';

  @override
  String get voteSubmittedSuccess => 'Vote submitted successfully!';

  @override
  String get errorSubmittingVote => 'Error submitting vote';

  @override
  String get errorShowingResults => 'Error showing results';

  @override
  String get host => 'Host';

  @override
  String get startRoundTimer => 'Start Round Timer';

  @override
  String get hostControls => 'Host Controls';
}
