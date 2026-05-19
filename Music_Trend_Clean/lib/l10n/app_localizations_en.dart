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
  String get genreLabel => 'Library';

  @override
  String get discoverLabel => 'Discover';

  @override
  String get musicDiscoveryTitle => 'Discover Music';

  @override
  String get discoverSearchHint => 'Search songs, artists or albums';

  @override
  String get genreScreenTitle => 'Music Library';

  @override
  String get genreScreenSubtitle =>
      'Filter the catalog by short clips, full tracks, and release year.';

  @override
  String get playlistsLabel => 'Playlists';

  @override
  String get recentLabel => 'Recent';

  @override
  String get historyLabel => 'History';

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
  String get copyProfileLink => 'Copy profile link';

  @override
  String get profileLinkCopiedMessage => 'Profile link copied.';

  @override
  String get shareProfileAction => 'Share profile';

  @override
  String get viewPublicProfile => 'View public profile';

  @override
  String get publicProfileTitle => 'Public Profile';

  @override
  String get publicPlaylistsTitle => 'Public Playlists';

  @override
  String get publicPlaylistsSubtitle => 'Playlists shared from this profile.';

  @override
  String get publicPlaylistsEmpty => 'No public playlists yet';

  @override
  String profileShareMessage(String username, int followers) {
    return 'Check out $username\'s beautiful profile on Music Trend App! They already have $followers followers.\nDownload the app to listen to great music together!';
  }

  @override
  String profileIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get profileSignInRequiredTitle => 'Not signed in';

  @override
  String get profileSignInRequiredSubtitle =>
      'Please sign in to view and customize your profile.';

  @override
  String get profileSignInRequiredAction => 'Sign in now';

  @override
  String get adminWorkspaceTitle => 'Admin Workspace';

  @override
  String get adminSongsSectionLabel => 'Songs';

  @override
  String get adminYearSongsSectionLabel => 'Library by year';

  @override
  String get adminAnalyticsSectionLabel => 'Analytics';

  @override
  String get adminOpenAppLabel => 'Open app';

  @override
  String get adminWebOnlyTitle => 'Admin is available on web';

  @override
  String get adminWebOnlyMessage =>
      'Use the web build to manage content with the new admin workspace.';

  @override
  String get adminAnalyticsTitle => 'Admin Analytics';

  @override
  String get adminAnalyticsOverviewTitle => 'Catalog overview';

  @override
  String get adminTotalSongsLabel => 'Total songs';

  @override
  String get adminPublishedSongsLabel => 'Published songs';

  @override
  String get adminPendingSongsLabel => 'Pending songs';

  @override
  String get adminHiddenSongsLabel => 'Hidden songs';

  @override
  String get adminArchivedSongsLabel => 'Archived songs';

  @override
  String get adminAnalyticsControlsTitle => 'Analytics filters';

  @override
  String get adminRecentlyUpdatedTitle => 'Recently updated';

  @override
  String get adminRecentlyUpdatedSubtitle =>
      'Songs that were edited or moderated most recently.';

  @override
  String get adminNoRecentlyUpdatedMessage =>
      'No recent updates match the current filters.';

  @override
  String get adminPendingOldestTitle => 'Oldest pending songs';

  @override
  String get adminPendingOldestSubtitle =>
      'Use this list to clear long-waiting review items first.';

  @override
  String get adminNoPendingOldestMessage =>
      'No pending songs match the current filters.';

  @override
  String get adminYearSongsRecentlyUpdatedTitle =>
      'Recently updated by-year songs';

  @override
  String get adminYearSongsRecentlyUpdatedSubtitle =>
      'Quickly track by-year content that changed most recently.';

  @override
  String get adminNoYearSongsRecentlyUpdatedMessage =>
      'No by-year updates match the current filters.';

  @override
  String get adminYearSongsAnalyticsTitle => 'By-year note';

  @override
  String get adminYearSongsAnalyticsSubtitle =>
      'By-year songs do not have a separate weekly trending feed yet. For now, the dashboard highlights the most recent updates so admins can still monitor that catalog slice.';

  @override
  String get adminWeeklyTrendingTitle => 'Top weekly trending';

  @override
  String get adminWeeklyTrendingSubtitle =>
      'Based on unique listeners and total plays from the current week.';

  @override
  String get errorLabel => 'Error';

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get playlistDescriptionLabel => 'Description';

  @override
  String get playlistDescriptionHint =>
      'Set the mood or purpose of this playlist.';

  @override
  String get playlistLoadingTitle => 'Loading playlists';

  @override
  String get playlistLoadingSubtitle =>
      'Your personal library is being synchronized.';

  @override
  String get playlistLoadErrorTitle => 'Unable to load playlists';

  @override
  String get playlistEmptyTitle => 'No playlists yet';

  @override
  String get playlistEmptySubtitle =>
      'Create your first playlist to start building your personal library.';

  @override
  String get playlistErrorEmptyName => 'Please enter a playlist name.';

  @override
  String get playlistErrorNotFound => 'Playlist not found.';

  @override
  String get playlistErrorAuthenticationRequiredForCreate =>
      'Please sign in before creating a playlist.';

  @override
  String get playlistErrorAuthenticationRequiredForUpdate =>
      'Please sign in before updating a playlist.';

  @override
  String get playlistErrorAuthenticationRequiredForDelete =>
      'Please sign in before deleting a playlist.';

  @override
  String get addSongsToPlaylistTitle => 'Add songs';

  @override
  String get playlistUpdatedMessage => 'Playlist updated.';

  @override
  String get deletePlaylistTitle => 'Delete playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Are you sure you want to delete the playlist \"$name\"?';
  }

  @override
  String get playlistDeletedMessage => 'Playlist deleted.';

  @override
  String get editPlaylistDetailsTitle => 'Edit playlist details';

  @override
  String get playlistDetailsUpdatedMessage => 'Playlist details updated.';

  @override
  String get renamePlaylistTitle => 'Rename playlist';

  @override
  String get playlistRenamedMessage => 'Playlist renamed.';

  @override
  String get playlistCoverLabel => 'Playlist cover';

  @override
  String get playlistCoverNoneOption => 'No cover';

  @override
  String get playlistCoverFromSongOption => 'From track';

  @override
  String get playlistReorderHint => 'Drag songs to reorder the playlist.';

  @override
  String get removeSongFromPlaylistTitle => 'Remove song';

  @override
  String removeSongFromPlaylistConfirmation(
    String songTitle,
    String playlistName,
  ) {
    return 'Remove \"$songTitle\" from playlist \"$playlistName\"?';
  }

  @override
  String songRemovedFromPlaylistMessage(String songTitle) {
    return 'Removed \"$songTitle\" from the playlist.';
  }

  @override
  String get songListNotReadyMessage =>
      'The song list is not ready yet. Please try again later.';

  @override
  String get playPlaylistAction => 'Play playlist';

  @override
  String get playlistSongsLoadingTitle => 'Loading songs';

  @override
  String get playlistSongsLoadingSubtitle =>
      'The songs in this playlist are being prepared.';

  @override
  String get playlistSongsLoadErrorTitle => 'Unable to load songs';

  @override
  String get playlistSongsEmptyTitle => 'This playlist has no songs yet';

  @override
  String get playlistSongsEmptySubtitle =>
      'Add songs to start playing and managing this playlist.';

  @override
  String get removeFromPlaylistTooltip => 'Remove from playlist';

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
      'Each AI music generation creates 2 versions. Those versions will appear here grouped by generation task.';

  @override
  String get getStartedNow => 'Get started now';

  @override
  String get favoriteSongsLoadingTitle => 'Loading favorite songs';

  @override
  String get favoriteSongsLoadingSubtitle =>
      'Your liked songs are being synchronized.';

  @override
  String get favoriteSongsLoadErrorTitle => 'Unable to load favorite songs';

  @override
  String get favoriteSongsEmpty => 'No favorite songs yet';

  @override
  String get clearAllFavoritesLabel => 'Clear all';

  @override
  String get clearAllFavoritesTitle => 'Clear all favorites';

  @override
  String clearAllFavoritesConfirmation(int count) {
    return 'Are you sure you want to remove all $count favorite songs?';
  }

  @override
  String get allFavoritesClearedMessage =>
      'All favorite songs have been removed.';

  @override
  String get removeFromFavoritesTooltip => 'Remove from favorites';

  @override
  String get recentSongsEmpty => 'No recently played songs yet';

  @override
  String get historyLoadingTitle => 'Loading listening history';

  @override
  String get historyLoadingSubtitle =>
      'Your recently played songs are being synchronized.';

  @override
  String get historyLoadErrorTitle => 'Unable to load listening history';

  @override
  String get historyEmpty => 'No listening history yet';

  @override
  String get historyContinueListeningLabel => 'Continue listening';

  @override
  String get historyRecentlyPlayedLabel => 'Recently played';

  @override
  String get historyMostPlayedLabel => 'Most played';

  @override
  String historyContinueCount(int count) {
    return '$count to continue';
  }

  @override
  String historyResumeFrom(String time) {
    return 'Resume from $time';
  }

  @override
  String get historyPlayedRecentlyLabel => 'Just now';

  @override
  String historyPlayedMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String historyPlayedHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String historyPlayedDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get clearHistoryLabel => 'Clear history';

  @override
  String get clearHistoryTitle => 'Clear listening history';

  @override
  String clearHistoryConfirmation(int count) {
    return 'Are you sure you want to remove all $count songs from your listening history?';
  }

  @override
  String get historyClearedMessage => 'Listening history cleared.';

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
  String get enterSearchPrompt => 'Enter a query for better search results';

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
  String get passwordRequiredMessage => 'Please enter your password.';

  @override
  String get passwordTooShortMessage =>
      'Password must be at least 8 characters long.';

  @override
  String get passwordWeakMessage =>
      'Password must include uppercase, lowercase, number, and special character.';

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
  String get fullNameRequiredMessage => 'Please enter your full name.';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordRequirementHint =>
      'Use at least 8 characters including uppercase, lowercase, number, and special character.';

  @override
  String get ageGroupLabel => 'Age Group';

  @override
  String get ageGroupRequiredMessage => 'Please select your age group.';

  @override
  String get selectAgeGroupHint => 'Select your age group';

  @override
  String get ageGroupUnder13 => 'Under 13';

  @override
  String get ageGroupTeens => '13 to 17';

  @override
  String get ageGroupAdults => '18 and above';

  @override
  String get ageGroupPreferNotToSay => 'Prefer not to say';

  @override
  String signUpSuccessMessage(String fullName) {
    return 'Account created for $fullName!';
  }

  @override
  String get verificationEmailSentMessage =>
      'Verification email sent. Please check your inbox.';

  @override
  String get emailVerificationRequiredMessage =>
      'Your account is not verified yet.';

  @override
  String get emailVerificationTitle => 'Verify Your Email';

  @override
  String emailVerificationSubtitle(String email) {
    return 'We sent a verification email to $email. Confirm it, then return to the app.';
  }

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String get checkVerificationStatus => 'I have verified it';

  @override
  String get genericVerificationErrorMessage =>
      'Unable to send a verification email right now.';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get createAudioSuccessMessage =>
      'Generation started. Your versions will appear in My Audios shortly.';

  @override
  String get createAudioTitle => 'Create AI Audio';

  @override
  String get promptLabel => 'Description Prompt';

  @override
  String get promptHint =>
      'Example: Create a chill lofi music piece with soft piano, city-night rain, and a relaxing mood.';

  @override
  String get promptHelpText =>
      'The clearer the prompt is about mood, instruments, and vibe, the more usable both returned versions will be. The provider decides the actual duration.';

  @override
  String get durationLabel => 'Duration';

  @override
  String secondsLabel(int seconds) {
    return '$seconds sec';
  }

  @override
  String get generatingAudio => 'Generating audio...';

  @override
  String get createShortAudio => 'Create short audio';

  @override
  String get createTwoVersions => 'Create 2 versions';

  @override
  String get aiAudioStudio => 'AI Audio Studio';

  @override
  String generatedAudioMeta(int seconds, String provider) {
    return '$seconds sec • $provider';
  }

  @override
  String generatedTaskMeta(int count, String provider) {
    return '$count versions • $provider';
  }

  @override
  String generatedTaskStatusMeta(String status, int count, int outputCount) {
    return '$status • $count/$outputCount versions';
  }

  @override
  String get generationQueuedHint =>
      'Generation is processing. Open My Audios to follow updates.';

  @override
  String generatedVersionLabel(String label) {
    return 'Version $label';
  }

  @override
  String get audioMockUrlLabel => 'Audio URL';

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
  String get deleteGeneratedTaskTitle => 'Delete generation';

  @override
  String deleteGeneratedTaskMessage(String title) {
    return 'Do you want to delete the generation \"$title\" and both of its versions?';
  }

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
  String get adminFilterAll => 'All';

  @override
  String get adminFilterPublished => 'Published';

  @override
  String get adminFilterPending => 'Pending';

  @override
  String get adminFilterHidden => 'Hidden';

  @override
  String get adminFilterArchived => 'Archived';

  @override
  String get adminNoSongsForFilterTitle => 'No songs in this filter';

  @override
  String get adminNoSongsForFilterSubtitle =>
      'Try switching the status filter or restore archived content.';

  @override
  String get songStatusPublished => 'Published';

  @override
  String get songStatusPending => 'Pending';

  @override
  String get songStatusHidden => 'Hidden';

  @override
  String get songStatusArchived => 'Archived';

  @override
  String get adminBatchActionsTitle => 'Batch actions';

  @override
  String get adminSelectAllVisibleAction => 'Select all visible';

  @override
  String get adminClearSelectionAction => 'Clear selection';

  @override
  String adminSelectedItemsSummary(int count) {
    return '$count selected';
  }

  @override
  String get adminModerationReasonLabel => 'Moderation reason';

  @override
  String get adminModerationReasonHint =>
      'Example: Content is not ready for publishing yet or metadata still needs cleanup.';

  @override
  String get adminArchiveReasonHint =>
      'Example: Content should be taken out of circulation for review or no longer fits the public catalog.';

  @override
  String get adminModerationReasonRequiredMessage =>
      'Please enter a moderation reason.';

  @override
  String adminModeratedByLabel(String value) {
    return 'Moderated by: $value';
  }

  @override
  String adminModeratedAtLabel(String value) {
    return 'At: $value';
  }

  @override
  String get adminModerationPresetMetadata =>
      'Metadata still needs cleanup before publishing';

  @override
  String get adminModerationPresetQuality =>
      'Audio quality is not ready for release';

  @override
  String get adminModerationPresetDuplicate =>
      'Content duplicates or closely overlaps another track';

  @override
  String get adminModerationPresetArchivedReview =>
      'Archive for further review before reuse';

  @override
  String get adminModerationPresetOutdated =>
      'Content is outdated and no longer fits the public catalog';

  @override
  String get adminSearchHint =>
      'Search by title, artist, status, or moderation reason';

  @override
  String get adminSortLabel => 'Sort by';

  @override
  String get adminSortUpdatedNewest => 'Newest updated';

  @override
  String get adminSortUpdatedOldest => 'Oldest updated';

  @override
  String get adminSortTitleAsc => 'Title A-Z';

  @override
  String adminUpdatedAtLabel(String value) {
    return 'Updated: $value';
  }

  @override
  String adminArchiveSelectedItemsMessage(int count) {
    return 'Archive $count selected items so listeners can no longer see them?';
  }

  @override
  String get adminPendingSubmissionNotice =>
      'New content will be saved as pending first. After review, you can publish it directly from the admin dashboard.';

  @override
  String get hideSongAction => 'Hide from app';

  @override
  String get publishSongAction => 'Publish to app';

  @override
  String get archiveSongAction => 'Archive';

  @override
  String get restoreSongAction => 'Restore';

  @override
  String get archiveSongTitle => 'Archive song';

  @override
  String archiveSongConfirmMessage(String title) {
    return 'Archive \"$title\" so it no longer appears in the app?';
  }

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
  String archiveYearSongConfirmMessage(String title) {
    return 'Archive the by-year song \"$title\" so listeners can no longer see it?';
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
