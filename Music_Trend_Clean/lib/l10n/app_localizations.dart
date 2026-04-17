import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi'),
  ];

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get logoutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your details to sign in'**
  String get signInSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @loginSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {fullName}!'**
  String loginSuccessMessage(String fullName);

  /// No description provided for @likedTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get likedTabTitle;

  /// No description provided for @likedTabDescription.
  ///
  /// In en, this message translates to:
  /// **'Your favorite songs will appear here.'**
  String get likedTabDescription;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get changeUsername;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty.'**
  String get usernameRequired;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @genreLabel.
  ///
  /// In en, this message translates to:
  /// **'By Year'**
  String get genreLabel;

  /// No description provided for @discoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverLabel;

  /// No description provided for @musicDiscoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Music'**
  String get musicDiscoveryTitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists or albums'**
  String get discoverSearchHint;

  /// No description provided for @genreScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Short Tracks by Year'**
  String get genreScreenTitle;

  /// No description provided for @genreScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short tracks are grouped by year so you can revisit the vibe of each period.'**
  String get genreScreenSubtitle;

  /// No description provided for @playlistsLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsLabel;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @favoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesLabel;

  /// No description provided for @followersLabel.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followersLabel;

  /// No description provided for @followingLabel.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingLabel;

  /// No description provided for @likesLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @profileShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out {username}\'s beautiful profile on Music Trend App! They already have {followers} followers.\nDownload the app to listen to great music together!'**
  String profileShareMessage(String username, int followers);

  /// No description provided for @profileIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String profileIdLabel(String id);

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Tracks'**
  String trackCount(int count);

  /// No description provided for @discoverTabSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get discoverTabSuggestions;

  /// No description provided for @yourAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Audio'**
  String get yourAudioLabel;

  /// No description provided for @importAudioFromVideo.
  ///
  /// In en, this message translates to:
  /// **'Import audio from video'**
  String get importAudioFromVideo;

  /// No description provided for @importAudioFromVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically extract audio from your clips'**
  String get importAudioFromVideoSubtitle;

  /// No description provided for @importAudioFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Import audio from device'**
  String get importAudioFromDevice;

  /// No description provided for @importAudioFromDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose high-quality audio from your device'**
  String get importAudioFromDeviceSubtitle;

  /// No description provided for @importButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'+ Import'**
  String get importButtonLabel;

  /// No description provided for @browseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseButtonLabel;

  /// No description provided for @yourAudioEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No audio yet'**
  String get yourAudioEmptyTitle;

  /// No description provided for @yourAudioEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import your favorite audio to start creating. Everything you add will appear here.'**
  String get yourAudioEmptySubtitle;

  /// No description provided for @getStartedNow.
  ///
  /// In en, this message translates to:
  /// **'Get started now'**
  String get getStartedNow;

  /// No description provided for @favoriteSongsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite songs yet'**
  String get favoriteSongsEmpty;

  /// No description provided for @recentSongsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recently played songs yet'**
  String get recentSongsEmpty;

  /// No description provided for @trendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingTitle;

  /// No description provided for @forYouTitle.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYouTitle;

  /// No description provided for @fromFirestore.
  ///
  /// In en, this message translates to:
  /// **'From Firestore'**
  String get fromFirestore;

  /// No description provided for @trendingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough listens to rank this week'**
  String get trendingEmptyTitle;

  /// No description provided for @trendingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The top 4 will update automatically when users listen long enough.'**
  String get trendingEmptySubtitle;

  /// No description provided for @listenersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} listeners'**
  String listenersCount(String count);

  /// No description provided for @playsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} plays'**
  String playsCount(String count);

  /// No description provided for @firestoreAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio from Firestore'**
  String get firestoreAudioLabel;

  /// No description provided for @noSongDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No song data available'**
  String get noSongDataTitle;

  /// No description provided for @noSongDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add songs in Firestore or from the admin page to show real data here.'**
  String get noSongDataSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, mood, trends...'**
  String get searchHint;

  /// No description provided for @noMatchingSongs.
  ///
  /// In en, this message translates to:
  /// **'No matching songs found'**
  String get noMatchingSongs;

  /// No description provided for @enterSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a query for AI to analyze'**
  String get enterSearchPrompt;

  /// No description provided for @searchSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {provider}'**
  String searchSourceLabel(String provider);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmail;

  /// No description provided for @emailRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get emailRequiredMessage;

  /// No description provided for @invalidEmailFormatMessage.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get invalidEmailFormatMessage;

  /// No description provided for @resetPasswordSentMessage.
  ///
  /// In en, this message translates to:
  /// **'The password reset email has been sent.'**
  String get resetPasswordSentMessage;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us to get started with your journey.'**
  String get createAccountSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @signUpSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created for {fullName}!'**
  String signUpSuccessMessage(String fullName);

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @createAudioSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Mock audio created successfully.'**
  String get createAudioSuccessMessage;

  /// No description provided for @createAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Create AI Audio'**
  String get createAudioTitle;

  /// No description provided for @promptLabel.
  ///
  /// In en, this message translates to:
  /// **'Description Prompt'**
  String get promptLabel;

  /// No description provided for @promptHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Create a chill lofi music piece with soft piano, city-night rain, and a relaxing mood.'**
  String get promptHint;

  /// No description provided for @promptHelpText.
  ///
  /// In en, this message translates to:
  /// **'The clearer the prompt is about mood, instruments, and tempo, the easier it will be to replace the mock result with a real API later.'**
  String get promptHelpText;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String secondsLabel(int seconds);

  /// No description provided for @mockApiMessage.
  ///
  /// In en, this message translates to:
  /// **'Using mock API with URL: {baseUrl}\nWhen the real API is ready, just change the URL in config.'**
  String mockApiMessage(String baseUrl);

  /// No description provided for @generatingAudio.
  ///
  /// In en, this message translates to:
  /// **'Generating audio...'**
  String get generatingAudio;

  /// No description provided for @createShortAudio.
  ///
  /// In en, this message translates to:
  /// **'Create short audio'**
  String get createShortAudio;

  /// No description provided for @aiAudioStudio.
  ///
  /// In en, this message translates to:
  /// **'AI Audio Studio'**
  String get aiAudioStudio;

  /// No description provided for @generatedAudioMeta.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec • {provider}'**
  String generatedAudioMeta(int seconds, String provider);

  /// No description provided for @audioMockUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Mock audio URL'**
  String get audioMockUrlLabel;

  /// No description provided for @previewAudio.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewAudio;

  /// No description provided for @promptRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a prompt to generate audio.'**
  String get promptRequiredMessage;

  /// No description provided for @promptTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'The prompt should be at least 10 characters so the AI can understand it better.'**
  String get promptTooShortMessage;

  /// No description provided for @audioDurationRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Audio duration must be between 5 and 60 seconds.'**
  String get audioDurationRangeMessage;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel — Song Management'**
  String get adminPanelTitle;

  /// No description provided for @addSongLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Song'**
  String get addSongLabel;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page.'**
  String get accessDeniedMessage;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noSongsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get noSongsYetTitle;

  /// No description provided for @noSongsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first song'**
  String get noSongsYetSubtitle;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteSongConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteSongConfirmMessage(String title);

  /// No description provided for @actionSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Action completed successfully!'**
  String get actionSuccessMessage;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @newSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Song'**
  String get newSongTitle;

  /// No description provided for @yearSongAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel — By Year Music'**
  String get yearSongAdminTitle;

  /// No description provided for @addYearSongLabel.
  ///
  /// In en, this message translates to:
  /// **'Add by Year'**
  String get addYearSongLabel;

  /// No description provided for @newYearSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Add By-Year Song'**
  String get newYearSongTitle;

  /// No description provided for @editYearSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit By-Year Song'**
  String get editYearSongTitle;

  /// No description provided for @editSongTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Song'**
  String get editSongTitle;

  /// No description provided for @coverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImageLabel;

  /// No description provided for @chooseCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Choose cover image'**
  String get chooseCoverImage;

  /// No description provided for @audioFilePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio File (mp3, m4a...)'**
  String get audioFilePickerLabel;

  /// No description provided for @selectAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose an audio file'**
  String get selectAudioFile;

  /// No description provided for @songTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Song Title'**
  String get songTitleLabel;

  /// No description provided for @songTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Hoa No Khong Mau'**
  String get songTitleHint;

  /// No description provided for @songTitleRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter the song title'**
  String get songTitleRequiredMessage;

  /// No description provided for @artistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artistNameLabel;

  /// No description provided for @artistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Hoai Lam'**
  String get artistNameHint;

  /// No description provided for @artistNameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter the artist name'**
  String get artistNameRequiredMessage;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearLabel;

  /// No description provided for @selectYearHint.
  ///
  /// In en, this message translates to:
  /// **'Select year'**
  String get selectYearHint;

  /// No description provided for @yearRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a year'**
  String get yearRequiredMessage;

  /// No description provided for @songTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendation Tags'**
  String get songTagsLabel;

  /// No description provided for @songTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Example: sad, chill, heartbreak, ballad'**
  String get songTagsHint;

  /// No description provided for @songTagsHelperText.
  ///
  /// In en, this message translates to:
  /// **'Enter short tags separated by commas. Focus on mood, vibe, genre, or listening context.'**
  String get songTagsHelperText;

  /// No description provided for @searchAliasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Aliases'**
  String get searchAliasesLabel;

  /// No description provided for @searchAliasesHint.
  ///
  /// In en, this message translates to:
  /// **'Example: sad TikTok song, viral chorus clip'**
  String get searchAliasesHint;

  /// No description provided for @searchAliasesHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use this for how users remember the song through trends, hook lines, or informal names.'**
  String get searchAliasesHelperText;

  /// No description provided for @energyLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy Level'**
  String get energyLevelLabel;

  /// No description provided for @energyLevelHelperText.
  ///
  /// In en, this message translates to:
  /// **'1 is very soft/chill, 5 is intense/high-energy. Old records default to level 3.'**
  String get energyLevelHelperText;

  /// No description provided for @uploadingSong.
  ///
  /// In en, this message translates to:
  /// **'Uploading to Cloudinary...'**
  String get uploadingSong;

  /// No description provided for @savingSongChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving changes...'**
  String get savingSongChanges;

  /// No description provided for @uploadAndSaveSong.
  ///
  /// In en, this message translates to:
  /// **'Upload & Save Song'**
  String get uploadAndSaveSong;

  /// No description provided for @saveSongChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Song Changes'**
  String get saveSongChanges;

  /// No description provided for @yearSongEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No by-year songs yet'**
  String get yearSongEmptyTitle;

  /// No description provided for @yearSongEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap add to place songs into the by-year archive from 2018 to 2026.'**
  String get yearSongEmptySubtitle;

  /// No description provided for @deleteYearSongConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the by-year song \"{title}\"?'**
  String deleteYearSongConfirmMessage(String title);

  /// No description provided for @currentAudioWillBeKept.
  ///
  /// In en, this message translates to:
  /// **'Keeping current file: {fileName}'**
  String currentAudioWillBeKept(String fileName);

  /// No description provided for @coverImageRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please choose a cover image!'**
  String get coverImageRequiredMessage;

  /// No description provided for @audioFileRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please choose an audio file!'**
  String get audioFileRequiredMessage;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
