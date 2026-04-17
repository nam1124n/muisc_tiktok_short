// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileTitle => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Do you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInSubtitle => 'Please enter your details to sign in';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String loginSuccessMessage(String fullName) {
    return 'Welcome, $fullName!';
  }

  @override
  String get likedTabTitle => 'Liked';

  @override
  String get likedTabDescription => 'Your favorite songs will appear here.';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get changeUsername => 'Change Username';

  @override
  String get enterYourUsername => 'Enter your username';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get usernameRequired => 'Username cannot be empty.';

  @override
  String get searchLabel => 'Search';

  @override
  String get genreLabel => 'By Year';

  @override
  String get discoverLabel => 'Discover';

  @override
  String get musicDiscoveryTitle => 'Discover Music';

  @override
  String get discoverSearchHint => 'Search songs, artists or albums';

  @override
  String get genreScreenTitle => 'Short Tracks by Year';

  @override
  String get genreScreenSubtitle =>
      'Short tracks are grouped by year so you can revisit the vibe of each period.';

  @override
  String get playlistsLabel => 'Playlists';

  @override
  String get recentLabel => 'Recent';

  @override
  String get favoritesLabel => 'Favorites';

  @override
  String get followersLabel => 'Followers';

  @override
  String get followingLabel => 'Following';

  @override
  String get likesLabel => 'Likes';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String get shareButton => 'Share';

  @override
  String profileShareMessage(String username, int followers) {
    return 'Check out $username\'s beautiful profile on Music Trend App! They already have $followers followers.\nDownload the app to listen to great music together!';
  }

  @override
  String profileIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get errorLabel => 'Error';

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String trackCount(int count) {
    return '$count Tracks';
  }

  @override
  String get discoverTabSuggestions => 'Suggestions';

  @override
  String get yourAudioLabel => 'Your Audio';

  @override
  String get importAudioFromVideo => 'Import audio from video';

  @override
  String get importAudioFromVideoSubtitle =>
      'Automatically extract audio from your clips';

  @override
  String get importAudioFromDevice => 'Import audio from device';

  @override
  String get importAudioFromDeviceSubtitle =>
      'Choose high-quality audio from your device';

  @override
  String get importButtonLabel => '+ Import';

  @override
  String get browseButtonLabel => 'Browse';

  @override
  String get yourAudioEmptyTitle => 'No audio yet';

  @override
  String get yourAudioEmptySubtitle =>
      'Import your favorite audio to start creating. Everything you add will appear here.';

  @override
  String get getStartedNow => 'Get started now';

  @override
  String get favoriteSongsEmpty => 'No favorite songs yet';

  @override
  String get recentSongsEmpty => 'No recently played songs yet';

  @override
  String get trendingTitle => 'Trending';

  @override
  String get forYouTitle => 'For You';

  @override
  String get fromFirestore => 'From Firestore';

  @override
  String get trendingEmptyTitle => 'Not enough listens to rank this week';

  @override
  String get trendingEmptySubtitle =>
      'The top 4 will update automatically when users listen long enough.';

  @override
  String listenersCount(String count) {
    return '$count listeners';
  }

  @override
  String playsCount(String count) {
    return '$count plays';
  }

  @override
  String get firestoreAudioLabel => 'Audio from Firestore';

  @override
  String get noSongDataTitle => 'No song data available';

  @override
  String get noSongDataSubtitle =>
      'Add songs in Firestore or from the admin page to show real data here.';

  @override
  String get searchHint => 'Search songs, artists, mood, trends...';

  @override
  String get noMatchingSongs => 'No matching songs found';

  @override
  String get enterSearchPrompt => 'Enter a query for AI to analyze';

  @override
  String searchSourceLabel(String provider) {
    return 'Source: $provider';
  }

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get sendResetEmail => 'Send reset email';

  @override
  String get emailRequiredMessage => 'Please enter your email.';

  @override
  String get invalidEmailFormatMessage => 'Invalid email format.';

  @override
  String get resetPasswordSentMessage =>
      'The password reset email has been sent.';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get createAccountSubtitle =>
      'Join us to get started with your journey.';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String signUpSuccessMessage(String fullName) {
    return 'Account created for $fullName!';
  }

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get createAudioSuccessMessage => 'Mock audio created successfully.';

  @override
  String get createAudioTitle => 'Create AI Audio';

  @override
  String get promptLabel => 'Description Prompt';

  @override
  String get promptHint =>
      'Example: Create a chill lofi music piece with soft piano, city-night rain, and a relaxing mood.';

  @override
  String get promptHelpText =>
      'The clearer the prompt is about mood, instruments, and tempo, the easier it will be to replace the mock result with a real API later.';

  @override
  String get durationLabel => 'Duration';

  @override
  String secondsLabel(int seconds) {
    return '$seconds sec';
  }

  @override
  String mockApiMessage(String baseUrl) {
    return 'Using mock API with URL: $baseUrl\nWhen the real API is ready, just change the URL in config.';
  }

  @override
  String get generatingAudio => 'Generating audio...';

  @override
  String get createShortAudio => 'Create short audio';

  @override
  String get aiAudioStudio => 'AI Audio Studio';

  @override
  String generatedAudioMeta(int seconds, String provider) {
    return '$seconds sec • $provider';
  }

  @override
  String get audioMockUrlLabel => 'Mock audio URL';

  @override
  String get previewAudio => 'Preview';

  @override
  String get promptRequiredMessage =>
      'Please enter a prompt to generate audio.';

  @override
  String get promptTooShortMessage =>
      'The prompt should be at least 10 characters so the AI can understand it better.';

  @override
  String get audioDurationRangeMessage =>
      'Audio duration must be between 5 and 60 seconds.';

  @override
  String get adminPanelTitle => 'Admin Panel — Song Management';

  @override
  String get addSongLabel => 'Add Song';

  @override
  String get accessDeniedTitle => 'Access denied';

  @override
  String get accessDeniedMessage =>
      'You do not have permission to access this page.';

  @override
  String get goBack => 'Go back';

  @override
  String get retry => 'Retry';

  @override
  String get noSongsYetTitle => 'No songs yet';

  @override
  String get noSongsYetSubtitle => 'Tap + to add your first song';

  @override
  String get deleteConfirmTitle => 'Confirm delete';

  @override
  String deleteSongConfirmMessage(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get actionSuccessMessage => 'Action completed successfully!';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get newSongTitle => 'Add New Song';

  @override
  String get yearSongAdminTitle => 'Admin Panel — By Year Music';

  @override
  String get addYearSongLabel => 'Add by Year';

  @override
  String get newYearSongTitle => 'Add By-Year Song';

  @override
  String get editYearSongTitle => 'Edit By-Year Song';

  @override
  String get editSongTitle => 'Edit Song';

  @override
  String get coverImageLabel => 'Cover Image';

  @override
  String get chooseCoverImage => 'Choose cover image';

  @override
  String get audioFilePickerLabel => 'Audio File (mp3, m4a...)';

  @override
  String get selectAudioFile => 'Tap to choose an audio file';

  @override
  String get songTitleLabel => 'Song Title';

  @override
  String get songTitleHint => 'Example: Hoa No Khong Mau';

  @override
  String get songTitleRequiredMessage => 'Please enter the song title';

  @override
  String get artistNameLabel => 'Artist Name';

  @override
  String get artistNameHint => 'Example: Hoai Lam';

  @override
  String get artistNameRequiredMessage => 'Please enter the artist name';

  @override
  String get yearLabel => 'Year';

  @override
  String get selectYearHint => 'Select year';

  @override
  String get yearRequiredMessage => 'Please select a year';

  @override
  String get songTagsLabel => 'Recommendation Tags';

  @override
  String get songTagsHint => 'Example: sad, chill, heartbreak, ballad';

  @override
  String get songTagsHelperText =>
      'Enter short tags separated by commas. Focus on mood, vibe, genre, or listening context.';

  @override
  String get searchAliasesLabel => 'Search Aliases';

  @override
  String get searchAliasesHint => 'Example: sad TikTok song, viral chorus clip';

  @override
  String get searchAliasesHelperText =>
      'Use this for how users remember the song through trends, hook lines, or informal names.';

  @override
  String get energyLevelLabel => 'Energy Level';

  @override
  String get energyLevelHelperText =>
      '1 is very soft/chill, 5 is intense/high-energy. Old records default to level 3.';

  @override
  String get uploadingSong => 'Uploading to Cloudinary...';

  @override
  String get savingSongChanges => 'Saving changes...';

  @override
  String get uploadAndSaveSong => 'Upload & Save Song';

  @override
  String get saveSongChanges => 'Save Song Changes';

  @override
  String get yearSongEmptyTitle => 'No by-year songs yet';

  @override
  String get yearSongEmptySubtitle =>
      'Tap add to place songs into the by-year archive from 2018 to 2026.';

  @override
  String deleteYearSongConfirmMessage(String title) {
    return 'Are you sure you want to delete the by-year song \"$title\"?';
  }

  @override
  String currentAudioWillBeKept(String fileName) {
    return 'Keeping current file: $fileName';
  }

  @override
  String get coverImageRequiredMessage => 'Please choose a cover image!';

  @override
  String get audioFileRequiredMessage => 'Please choose an audio file!';
}
