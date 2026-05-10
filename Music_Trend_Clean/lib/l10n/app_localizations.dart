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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
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

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

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

  /// No description provided for @copyProfileLink.
  ///
  /// In en, this message translates to:
  /// **'Copy profile link'**
  String get copyProfileLink;

  /// No description provided for @profileLinkCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied.'**
  String get profileLinkCopiedMessage;

  /// No description provided for @shareProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfileAction;

  /// No description provided for @viewPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'View public profile'**
  String get viewPublicProfile;

  /// No description provided for @publicProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfileTitle;

  /// No description provided for @publicPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Public Playlists'**
  String get publicPlaylistsTitle;

  /// No description provided for @publicPlaylistsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists shared from this profile.'**
  String get publicPlaylistsSubtitle;

  /// No description provided for @publicPlaylistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No public playlists yet'**
  String get publicPlaylistsEmpty;

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

  /// No description provided for @profileSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get profileSignInRequiredTitle;

  /// No description provided for @profileSignInRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view and customize your profile.'**
  String get profileSignInRequiredSubtitle;

  /// No description provided for @profileSignInRequiredAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in now'**
  String get profileSignInRequiredAction;

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

  /// No description provided for @playlistNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameLabel;

  /// No description provided for @playlistDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get playlistDescriptionLabel;

  /// No description provided for @playlistDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Set the mood or purpose of this playlist.'**
  String get playlistDescriptionHint;

  /// No description provided for @playlistLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading playlists'**
  String get playlistLoadingTitle;

  /// No description provided for @playlistLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal library is being synchronized.'**
  String get playlistLoadingSubtitle;

  /// No description provided for @playlistLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load playlists'**
  String get playlistLoadErrorTitle;

  /// No description provided for @playlistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get playlistEmptyTitle;

  /// No description provided for @playlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist to start building your personal library.'**
  String get playlistEmptySubtitle;

  /// No description provided for @playlistErrorEmptyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a playlist name.'**
  String get playlistErrorEmptyName;

  /// No description provided for @playlistErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found.'**
  String get playlistErrorNotFound;

  /// No description provided for @playlistErrorAuthenticationRequiredForCreate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before creating a playlist.'**
  String get playlistErrorAuthenticationRequiredForCreate;

  /// No description provided for @playlistErrorAuthenticationRequiredForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before updating a playlist.'**
  String get playlistErrorAuthenticationRequiredForUpdate;

  /// No description provided for @playlistErrorAuthenticationRequiredForDelete.
  ///
  /// In en, this message translates to:
  /// **'Please sign in before deleting a playlist.'**
  String get playlistErrorAuthenticationRequiredForDelete;

  /// No description provided for @addSongsToPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get addSongsToPlaylistTitle;

  /// No description provided for @playlistUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Playlist updated.'**
  String get playlistUpdatedMessage;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the playlist \"{name}\"?'**
  String deletePlaylistConfirmation(String name);

  /// No description provided for @playlistDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted.'**
  String get playlistDeletedMessage;

  /// No description provided for @editPlaylistDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist details'**
  String get editPlaylistDetailsTitle;

  /// No description provided for @playlistDetailsUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Playlist details updated.'**
  String get playlistDetailsUpdatedMessage;

  /// No description provided for @renamePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylistTitle;

  /// No description provided for @playlistRenamedMessage.
  ///
  /// In en, this message translates to:
  /// **'Playlist renamed.'**
  String get playlistRenamedMessage;

  /// No description provided for @playlistCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Playlist cover'**
  String get playlistCoverLabel;

  /// No description provided for @playlistCoverNoneOption.
  ///
  /// In en, this message translates to:
  /// **'No cover'**
  String get playlistCoverNoneOption;

  /// No description provided for @playlistCoverFromSongOption.
  ///
  /// In en, this message translates to:
  /// **'From track'**
  String get playlistCoverFromSongOption;

  /// No description provided for @playlistReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag songs to reorder the playlist.'**
  String get playlistReorderHint;

  /// No description provided for @removeSongFromPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove song'**
  String get removeSongFromPlaylistTitle;

  /// No description provided for @removeSongFromPlaylistConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{songTitle}\" from playlist \"{playlistName}\"?'**
  String removeSongFromPlaylistConfirmation(String songTitle, String playlistName);

  /// No description provided for @songRemovedFromPlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{songTitle}\" from the playlist.'**
  String songRemovedFromPlaylistMessage(String songTitle);

  /// No description provided for @songListNotReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'The song list is not ready yet. Please try again later.'**
  String get songListNotReadyMessage;

  /// No description provided for @playPlaylistAction.
  ///
  /// In en, this message translates to:
  /// **'Play playlist'**
  String get playPlaylistAction;

  /// No description provided for @playlistSongsLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading songs'**
  String get playlistSongsLoadingTitle;

  /// No description provided for @playlistSongsLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The songs in this playlist are being prepared.'**
  String get playlistSongsLoadingSubtitle;

  /// No description provided for @playlistSongsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load songs'**
  String get playlistSongsLoadErrorTitle;

  /// No description provided for @playlistSongsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'This playlist has no songs yet'**
  String get playlistSongsEmptyTitle;

  /// No description provided for @playlistSongsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add songs to start playing and managing this playlist.'**
  String get playlistSongsEmptySubtitle;

  /// No description provided for @removeFromPlaylistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylistTooltip;

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
  /// **'Each AI music generation creates 2 versions. Those versions will appear here grouped by generation task.'**
  String get yourAudioEmptySubtitle;

  /// No description provided for @getStartedNow.
  ///
  /// In en, this message translates to:
  /// **'Get started now'**
  String get getStartedNow;

  /// No description provided for @favoriteSongsLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading favorite songs'**
  String get favoriteSongsLoadingTitle;

  /// No description provided for @favoriteSongsLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your liked songs are being synchronized.'**
  String get favoriteSongsLoadingSubtitle;

  /// No description provided for @favoriteSongsLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load favorite songs'**
  String get favoriteSongsLoadErrorTitle;

  /// No description provided for @favoriteSongsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorite songs yet'**
  String get favoriteSongsEmpty;

  /// No description provided for @clearAllFavoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllFavoritesLabel;

  /// No description provided for @clearAllFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all favorites'**
  String get clearAllFavoritesTitle;

  /// No description provided for @clearAllFavoritesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all {count} favorite songs?'**
  String clearAllFavoritesConfirmation(int count);

  /// No description provided for @allFavoritesClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'All favorite songs have been removed.'**
  String get allFavoritesClearedMessage;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @recentSongsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recently played songs yet'**
  String get recentSongsEmpty;

  /// No description provided for @historyLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading listening history'**
  String get historyLoadingTitle;

  /// No description provided for @historyLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your recently played songs are being synchronized.'**
  String get historyLoadingSubtitle;

  /// No description provided for @historyLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load listening history'**
  String get historyLoadErrorTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listening history yet'**
  String get historyEmpty;

  /// No description provided for @historyContinueListeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get historyContinueListeningLabel;

  /// No description provided for @historyRecentlyPlayedLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get historyRecentlyPlayedLabel;

  /// No description provided for @historyMostPlayedLabel.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get historyMostPlayedLabel;

  /// No description provided for @historyContinueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to continue'**
  String historyContinueCount(int count);

  /// No description provided for @historyResumeFrom.
  ///
  /// In en, this message translates to:
  /// **'Resume from {time}'**
  String historyResumeFrom(String time);

  /// No description provided for @historyPlayedRecentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get historyPlayedRecentlyLabel;

  /// No description provided for @historyPlayedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String historyPlayedMinutesAgo(int count);

  /// No description provided for @historyPlayedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String historyPlayedHoursAgo(int count);

  /// No description provided for @historyPlayedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String historyPlayedDaysAgo(int count);

  /// No description provided for @clearHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryLabel;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all {count} songs from your listening history?'**
  String clearHistoryConfirmation(int count);

  /// No description provided for @historyClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Listening history cleared.'**
  String get historyClearedMessage;

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
  /// **'Enter a query for better search results'**
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

  /// No description provided for @passwordRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get passwordRequiredMessage;

  /// No description provided for @passwordTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long.'**
  String get passwordTooShortMessage;

  /// No description provided for @passwordWeakMessage.
  ///
  /// In en, this message translates to:
  /// **'Password must include uppercase, lowercase, number, and special character.'**
  String get passwordWeakMessage;

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

  /// No description provided for @fullNameRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get fullNameRequiredMessage;

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

  /// No description provided for @passwordRequirementHint.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters including uppercase, lowercase, number, and special character.'**
  String get passwordRequirementHint;

  /// No description provided for @ageGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroupLabel;

  /// No description provided for @ageGroupRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select your age group.'**
  String get ageGroupRequiredMessage;

  /// No description provided for @selectAgeGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Select your age group'**
  String get selectAgeGroupHint;

  /// No description provided for @ageGroupUnder13.
  ///
  /// In en, this message translates to:
  /// **'Under 13'**
  String get ageGroupUnder13;

  /// No description provided for @ageGroupTeens.
  ///
  /// In en, this message translates to:
  /// **'13 to 17'**
  String get ageGroupTeens;

  /// No description provided for @ageGroupAdults.
  ///
  /// In en, this message translates to:
  /// **'18 and above'**
  String get ageGroupAdults;

  /// No description provided for @ageGroupPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get ageGroupPreferNotToSay;

  /// No description provided for @signUpSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created for {fullName}!'**
  String signUpSuccessMessage(String fullName);

  /// No description provided for @verificationEmailSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Please check your inbox.'**
  String get verificationEmailSentMessage;

  /// No description provided for @emailVerificationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is not verified yet.'**
  String get emailVerificationRequiredMessage;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification email to {email}. Confirm it, then return to the app.'**
  String emailVerificationSubtitle(String email);

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'I have verified it'**
  String get checkVerificationStatus;

  /// No description provided for @genericVerificationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to send a verification email right now.'**
  String get genericVerificationErrorMessage;

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
  /// **'Generation started. Your versions will appear in My Audios shortly.'**
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
  /// **'The clearer the prompt is about mood, instruments, and vibe, the more usable both returned versions will be. The provider decides the actual duration.'**
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

  /// No description provided for @createTwoVersions.
  ///
  /// In en, this message translates to:
  /// **'Create 2 versions'**
  String get createTwoVersions;

  /// No description provided for @createAudioApiNotice.
  ///
  /// In en, this message translates to:
  /// **'Each generation request returns 2 versions under one task. The provider decides the actual duration, so it is not locked to 15/30/45/60 seconds.\nCurrent backend: {baseUrl}'**
  String createAudioApiNotice(String baseUrl);

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

  /// No description provided for @generatedTaskMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} versions • {provider}'**
  String generatedTaskMeta(int count, String provider);

  /// No description provided for @generatedTaskStatusMeta.
  ///
  /// In en, this message translates to:
  /// **'{status} • {count}/{outputCount} versions'**
  String generatedTaskStatusMeta(String status, int count, int outputCount);

  /// No description provided for @generationQueuedHint.
  ///
  /// In en, this message translates to:
  /// **'Generation is processing. Open My Audios to follow updates.'**
  String get generationQueuedHint;

  /// No description provided for @generatedVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {label}'**
  String generatedVersionLabel(String label);

  /// No description provided for @audioMockUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio URL'**
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

  /// No description provided for @deleteGeneratedTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete generation'**
  String get deleteGeneratedTaskTitle;

  /// No description provided for @deleteGeneratedTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the generation \"{title}\" and both of its versions?'**
  String deleteGeneratedTaskMessage(String title);

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

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
