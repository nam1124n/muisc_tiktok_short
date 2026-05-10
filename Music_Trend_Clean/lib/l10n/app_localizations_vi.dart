// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutTitle => 'Đăng xuất';

  @override
  String get logoutMessage => 'Bạn có muốn đăng xuất không?';

  @override
  String get cancel => 'Không';

  @override
  String get confirm => 'Có';

  @override
  String get welcomeBack => 'Chào mừng quay lại';

  @override
  String get signInSubtitle => 'Vui lòng nhập thông tin để đăng nhập';

  @override
  String get emailAddress => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get login => 'Đăng nhập';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get signUp => 'Đăng ký';

  @override
  String loginSuccessMessage(String fullName) {
    return 'Chào mừng, $fullName!';
  }

  @override
  String get likedTabTitle => 'Đã thích';

  @override
  String get likedTabDescription => 'Danh sách bài hát yêu thích sẽ hiển thị tại đây.';

  @override
  String get editProfileTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get changeUsername => 'Đổi tên người dùng';

  @override
  String get enterYourUsername => 'Nhập tên người dùng';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get usernameRequired => 'Tên người dùng không được để trống.';

  @override
  String get searchLabel => 'Tìm kiếm';

  @override
  String get genreLabel => 'Theo năm';

  @override
  String get discoverLabel => 'Khám phá';

  @override
  String get musicDiscoveryTitle => 'Khám phá âm nhạc';

  @override
  String get discoverSearchHint => 'Tìm kiếm bài hát, nghệ sĩ hoặc album';

  @override
  String get genreScreenTitle => 'Nhạc ngắn theo năm';

  @override
  String get genreScreenSubtitle => 'Những đoạn nhạc ngắn được gom theo từng năm để bạn nghe lại đúng vibe của từng giai đoạn.';

  @override
  String get playlistsLabel => 'Danh sách phát';

  @override
  String get recentLabel => 'Gần đây';

  @override
  String get historyLabel => 'Lịch sử';

  @override
  String get favoritesLabel => 'Yêu thích';

  @override
  String get followersLabel => 'Người theo dõi';

  @override
  String get followingLabel => 'Đang theo dõi';

  @override
  String get likesLabel => 'Lượt thích';

  @override
  String get editProfileButton => 'Chỉnh sửa hồ sơ';

  @override
  String get shareButton => 'Chia sẻ';

  @override
  String profileShareMessage(String username, int followers) {
    return 'Xem hồ sơ của $username trên Music Trend App! Họ đã có $followers người theo dõi.\nTải app để cùng nghe nhạc ngay.';
  }

  @override
  String profileIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get profileSignInRequiredTitle => 'Chưa đăng nhập';

  @override
  String get profileSignInRequiredSubtitle => 'Vui lòng đăng nhập để xem và tùy chỉnh hồ sơ cá nhân của bạn.';

  @override
  String get profileSignInRequiredAction => 'Đăng nhập ngay';

  @override
  String get errorLabel => 'Lỗi';

  @override
  String get createNewPlaylist => 'Tạo playlist mới';

  @override
  String get playlistNameLabel => 'Tên playlist';

  @override
  String get playlistDescriptionLabel => 'Mô tả';

  @override
  String get playlistDescriptionHint => 'Thêm cảm hứng hoặc mục đích cho playlist này.';

  @override
  String get playlistLoadingTitle => 'Đang tải playlist';

  @override
  String get playlistLoadingSubtitle => 'Thư viện cá nhân của bạn đang được đồng bộ.';

  @override
  String get playlistLoadErrorTitle => 'Không thể tải playlist';

  @override
  String get playlistEmptyTitle => 'Chưa có playlist nào';

  @override
  String get playlistEmptySubtitle => 'Tạo playlist đầu tiên để bắt đầu lưu thư viện cá nhân.';

  @override
  String get playlistErrorEmptyName => 'Vui lòng nhập tên playlist.';

  @override
  String get playlistErrorNotFound => 'Không tìm thấy playlist.';

  @override
  String get playlistErrorAuthenticationRequiredForCreate => 'Vui lòng đăng nhập trước khi tạo playlist.';

  @override
  String get playlistErrorAuthenticationRequiredForUpdate => 'Vui lòng đăng nhập trước khi cập nhật playlist.';

  @override
  String get playlistErrorAuthenticationRequiredForDelete => 'Vui lòng đăng nhập trước khi xóa playlist.';

  @override
  String get addSongsToPlaylistTitle => 'Thêm bài hát';

  @override
  String get playlistUpdatedMessage => 'Đã cập nhật playlist.';

  @override
  String get deletePlaylistTitle => 'Xóa playlist';

  @override
  String deletePlaylistConfirmation(String name) {
    return 'Bạn có chắc muốn xóa playlist \"$name\" không?';
  }

  @override
  String get playlistDeletedMessage => 'Đã xóa playlist.';

  @override
  String get editPlaylistDetailsTitle => 'Chỉnh sửa playlist';

  @override
  String get playlistDetailsUpdatedMessage => 'Đã cập nhật thông tin playlist.';

  @override
  String get renamePlaylistTitle => 'Đổi tên playlist';

  @override
  String get playlistRenamedMessage => 'Đã đổi tên playlist.';

  @override
  String get playlistCoverLabel => 'Ảnh bìa playlist';

  @override
  String get playlistCoverNoneOption => 'Không dùng ảnh';

  @override
  String get playlistCoverFromSongOption => 'Từ bài hát';

  @override
  String get playlistReorderHint => 'Kéo thả để sắp xếp lại thứ tự bài hát.';

  @override
  String get removeSongFromPlaylistTitle => 'Xóa bài hát';

  @override
  String removeSongFromPlaylistConfirmation(String songTitle, String playlistName) {
    return 'Xóa \"$songTitle\" khỏi playlist \"$playlistName\"?';
  }

  @override
  String songRemovedFromPlaylistMessage(String songTitle) {
    return 'Đã xóa \"$songTitle\" khỏi playlist.';
  }

  @override
  String get songListNotReadyMessage => 'Danh sách bài hát chưa sẵn sàng. Vui lòng thử lại sau.';

  @override
  String get playPlaylistAction => 'Phát playlist';

  @override
  String get playlistSongsLoadingTitle => 'Đang tải bài hát';

  @override
  String get playlistSongsLoadingSubtitle => 'Danh sách bài hát trong playlist đang được chuẩn bị.';

  @override
  String get playlistSongsLoadErrorTitle => 'Không thể tải bài hát';

  @override
  String get playlistSongsEmptyTitle => 'Playlist này chưa có bài hát nào';

  @override
  String get playlistSongsEmptySubtitle => 'Thêm bài hát để bắt đầu phát và quản lý danh sách này.';

  @override
  String get removeFromPlaylistTooltip => 'Xóa khỏi playlist';

  @override
  String trackCount(int count) {
    return '$count bài';
  }

  @override
  String get discoverTabSuggestions => 'Gợi ý';

  @override
  String get yourAudioLabel => 'Âm thanh';

  @override
  String get importAudioFromVideo => 'Nhập âm thanh từ video';

  @override
  String get importAudioFromVideoSubtitle => 'Tự động trích xuất âm thanh từ clip của bạn';

  @override
  String get importAudioFromDevice => 'Nhập âm thanh từ thiết bị';

  @override
  String get importAudioFromDeviceSubtitle => 'Chọn âm thanh chất lượng cao từ máy của bạn';

  @override
  String get importButtonLabel => '+ Nhập';

  @override
  String get browseButtonLabel => 'Duyệt';

  @override
  String get yourAudioEmptyTitle => 'Chưa có âm thanh nào';

  @override
  String get yourAudioEmptySubtitle => 'Mỗi lần tạo nhạc AI sẽ sinh ra 2 phiên bản. Các phiên bản đó sẽ xuất hiện tại đây theo từng lượt tạo.';

  @override
  String get getStartedNow => 'Bắt đầu ngay';

  @override
  String get favoriteSongsLoadingTitle => 'Đang tải bài hát yêu thích';

  @override
  String get favoriteSongsLoadingSubtitle => 'Danh sách bài hát bạn đã thích đang được đồng bộ.';

  @override
  String get favoriteSongsLoadErrorTitle => 'Không thể tải bài hát yêu thích';

  @override
  String get favoriteSongsEmpty => 'Chưa có bài hát yêu thích nào';

  @override
  String get clearAllFavoritesLabel => 'Bỏ thích tất cả';

  @override
  String get clearAllFavoritesTitle => 'Bỏ thích tất cả';

  @override
  String clearAllFavoritesConfirmation(int count) {
    return 'Bạn có chắc muốn bỏ thích toàn bộ $count bài hát không?';
  }

  @override
  String get allFavoritesClearedMessage => 'Đã bỏ thích toàn bộ bài hát.';

  @override
  String get removeFromFavoritesTooltip => 'Bỏ khỏi yêu thích';

  @override
  String get recentSongsEmpty => 'Chưa có bài hát nghe gần đây';

  @override
  String get historyLoadingTitle => 'Đang tải lịch sử nghe';

  @override
  String get historyLoadingSubtitle => 'Các bài hát bạn đã nghe gần đây đang được đồng bộ.';

  @override
  String get historyLoadErrorTitle => 'Không thể tải lịch sử nghe';

  @override
  String get historyEmpty => 'Chưa có lịch sử nghe nào';

  @override
  String get historyContinueListeningLabel => 'Tiếp tục nghe';

  @override
  String get historyRecentlyPlayedLabel => 'Nghe gần đây';

  @override
  String get historyMostPlayedLabel => 'Nghe nhiều nhất';

  @override
  String historyContinueCount(int count) {
    return '$count bài nghe dở';
  }

  @override
  String historyResumeFrom(String time) {
    return 'Nghe tiếp từ $time';
  }

  @override
  String get historyPlayedRecentlyLabel => 'Vừa xong';

  @override
  String historyPlayedMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String historyPlayedHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String historyPlayedDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get clearHistoryLabel => 'Xóa lịch sử';

  @override
  String get clearHistoryTitle => 'Xóa lịch sử nghe';

  @override
  String clearHistoryConfirmation(int count) {
    return 'Bạn có chắc muốn xóa toàn bộ $count bài hát khỏi lịch sử nghe không?';
  }

  @override
  String get historyClearedMessage => 'Đã xóa lịch sử nghe.';

  @override
  String get trendingTitle => 'Thịnh hành';

  @override
  String get forYouTitle => 'Dành cho bạn';

  @override
  String get fromFirestore => 'Từ Firestore';

  @override
  String get trendingEmptyTitle => 'Chưa có đủ lượt nghe để xếp hạng tuần này';

  @override
  String get trendingEmptySubtitle => 'Top 4 sẽ tự cập nhật khi người dùng nghe đủ thời lượng.';

  @override
  String listenersCount(String count) {
    return '$count người nghe';
  }

  @override
  String playsCount(String count) {
    return '$count lượt nghe';
  }

  @override
  String get firestoreAudioLabel => 'Audio từ Firestore';

  @override
  String get noSongDataTitle => 'Chưa có dữ liệu bài hát';

  @override
  String get noSongDataSubtitle => 'Thêm bài hát trong Firestore hoặc từ trang admin để giao diện này hiển thị dữ liệu thật.';

  @override
  String get searchHint => 'Tìm bài hát, ca sĩ, mood, trend...';

  @override
  String get noMatchingSongs => 'Không tìm thấy bài hát phù hợp';

  @override
  String get enterSearchPrompt => 'Nhập câu tìm kiếm để khám phá âm nhạc mới... ';

  @override
  String searchSourceLabel(String provider) {
    return 'Nguồn: $provider';
  }

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get sendResetEmail => 'Gửi email đặt lại mật khẩu';

  @override
  String get emailRequiredMessage => 'Vui lòng nhập email.';

  @override
  String get invalidEmailFormatMessage => 'Email không đúng định dạng.';

  @override
  String get passwordRequiredMessage => 'Vui lòng nhập mật khẩu.';

  @override
  String get passwordTooShortMessage => 'Mật khẩu phải có ít nhất 8 ký tự.';

  @override
  String get passwordWeakMessage => 'Mật khẩu cần có chữ hoa, chữ thường, số và ký tự đặc biệt.';

  @override
  String get resetPasswordSentMessage => 'Email đặt lại mật khẩu đã được gửi.';

  @override
  String get createAccountTitle => 'Tạo tài khoản';

  @override
  String get createAccountSubtitle => 'Tham gia để bắt đầu hành trình của bạn.';

  @override
  String get fullNameLabel => 'Họ và tên';

  @override
  String get fullNameRequiredMessage => 'Vui lòng nhập họ và tên.';

  @override
  String get confirmPasswordLabel => 'Xác nhận mật khẩu';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get passwordRequirementHint => 'Mật khẩu nên có ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.';

  @override
  String get ageGroupLabel => 'Nhóm tuổi';

  @override
  String get ageGroupRequiredMessage => 'Vui lòng chọn nhóm tuổi.';

  @override
  String get selectAgeGroupHint => 'Chọn nhóm tuổi của bạn';

  @override
  String get ageGroupUnder13 => 'Dưới 13 tuổi';

  @override
  String get ageGroupTeens => 'Từ 13 đến 17 tuổi';

  @override
  String get ageGroupAdults => 'Từ 18 tuổi trở lên';

  @override
  String get ageGroupPreferNotToSay => 'Không muốn chia sẻ';

  @override
  String signUpSuccessMessage(String fullName) {
    return 'Đã tạo tài khoản cho $fullName!';
  }

  @override
  String get verificationEmailSentMessage => 'Đã gửi email xác thực. Vui lòng kiểm tra hộp thư của bạn.';

  @override
  String get emailVerificationRequiredMessage => 'Tài khoản của bạn chưa xác thực email.';

  @override
  String get emailVerificationTitle => 'Xác thực email của bạn';

  @override
  String emailVerificationSubtitle(String email) {
    return 'Chúng tôi đã gửi email xác thực đến $email. Hãy xác nhận email rồi quay lại ứng dụng.';
  }

  @override
  String get resendVerificationEmail => 'Gửi lại email xác thực';

  @override
  String get checkVerificationStatus => 'Tôi đã xác thực xong';

  @override
  String get genericVerificationErrorMessage => 'Không thể gửi email xác thực lúc này.';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản?';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get createAudioSuccessMessage => 'Đã gửi yêu cầu tạo audio AI. Các phiên bản sẽ sớm xuất hiện trong My Audios.';

  @override
  String get createAudioTitle => 'Tạo Audio AI';

  @override
  String get promptLabel => 'Prompt mô tả';

  @override
  String get promptHint => 'Ví dụ: Tạo một đoạn nhạc chill lofi, piano nhẹ, mưa đêm thành phố, cảm giác thư giãn.';

  @override
  String get promptHelpText => 'Prompt càng rõ về mood, nhạc cụ và vibe thì 2 phiên bản trả về càng dễ dùng. API Suno-style sẽ tự quyết định thời lượng thực tế.';

  @override
  String get durationLabel => 'Thời lượng';

  @override
  String secondsLabel(int seconds) {
    return '$seconds giây';
  }

  @override
  String mockApiMessage(String baseUrl) {
    return 'Đang dùng API giả lập với URL: $baseUrl\nKhi có API thật, chỉ cần đổi URL trong config.';
  }

  @override
  String get generatingAudio => 'Đang tạo audio...';

  @override
  String get createShortAudio => 'Tạo audio ngắn';

  @override
  String get createTwoVersions => 'Tạo 2 phiên bản';

  @override
  String createAudioApiNotice(String baseUrl) {
    return 'Mỗi lần tạo sẽ nhận 2 phiên bản từ một task. Thời lượng thực tế do provider quyết định, không bị khóa ở 15/30/45/60 giây.\nBackend hiện dùng: $baseUrl';
  }

  @override
  String get aiAudioStudio => 'AI Audio Studio';

  @override
  String generatedAudioMeta(int seconds, String provider) {
    return '$seconds giây • $provider';
  }

  @override
  String generatedTaskMeta(int count, String provider) {
    return '$count phiên bản • $provider';
  }

  @override
  String generatedTaskStatusMeta(String status, int count, int outputCount) {
    return '$status • $count/$outputCount phiên bản';
  }

  @override
  String get generationQueuedHint => 'Task đang được xử lý. Mở My Audios để theo dõi cập nhật.';

  @override
  String generatedVersionLabel(String label) {
    return 'Phiên bản $label';
  }

  @override
  String get audioMockUrlLabel => 'Audio URL';

  @override
  String get previewAudio => 'Nghe thử';

  @override
  String get promptRequiredMessage => 'Vui lòng nhập prompt để tạo audio.';

  @override
  String get promptTooShortMessage => 'Prompt nên có ít nhất 10 ký tự để AI hiểu tốt hơn.';

  @override
  String get audioDurationRangeMessage => 'Thời lượng audio phải từ 5 đến 60 giây.';

  @override
  String get deleteGeneratedTaskTitle => 'Xóa lượt tạo nhạc';

  @override
  String deleteGeneratedTaskMessage(String title) {
    return 'Bạn có chắc muốn xóa lượt tạo \"$title\" và cả 2 phiên bản của nó không?';
  }

  @override
  String get adminPanelTitle => 'Admin Panel — Quản lý bài hát';

  @override
  String get addSongLabel => 'Thêm bài hát';

  @override
  String get accessDeniedTitle => 'Truy cập bị từ chối';

  @override
  String get accessDeniedMessage => 'Bạn không có quyền truy cập vào trang này.';

  @override
  String get goBack => 'Quay lại';

  @override
  String get retry => 'Thử lại';

  @override
  String get noSongsYetTitle => 'Chưa có bài hát nào';

  @override
  String get noSongsYetSubtitle => 'Nhấn + để thêm bài hát đầu tiên';

  @override
  String get deleteConfirmTitle => 'Xác nhận xoá';

  @override
  String deleteSongConfirmMessage(String title) {
    return 'Bạn có chắc muốn xoá \"$title\" không?';
  }

  @override
  String get actionSuccessMessage => 'Thao tác thành công!';

  @override
  String get deleteLabel => 'Xoá';

  @override
  String get newSongTitle => 'Thêm bài hát mới';

  @override
  String get yearSongAdminTitle => 'Admin Panel — Nhạc theo năm';

  @override
  String get addYearSongLabel => 'Thêm theo năm';

  @override
  String get newYearSongTitle => 'Thêm nhạc theo năm';

  @override
  String get editYearSongTitle => 'Sửa nhạc theo năm';

  @override
  String get editSongTitle => 'Chỉnh sửa bài hát';

  @override
  String get coverImageLabel => 'Ảnh bìa';

  @override
  String get chooseCoverImage => 'Chọn ảnh bìa';

  @override
  String get audioFilePickerLabel => 'File Audio (mp3, m4a...)';

  @override
  String get selectAudioFile => 'Nhấn để chọn file âm thanh';

  @override
  String get songTitleLabel => 'Tên bài hát';

  @override
  String get songTitleHint => 'Ví dụ: Hoa Nở Không Màu';

  @override
  String get songTitleRequiredMessage => 'Vui lòng nhập tên bài hát';

  @override
  String get artistNameLabel => 'Tên nghệ sĩ';

  @override
  String get artistNameHint => 'Ví dụ: Hoài Lâm';

  @override
  String get artistNameRequiredMessage => 'Vui lòng nhập tên nghệ sĩ';

  @override
  String get yearLabel => 'Năm';

  @override
  String get selectYearHint => 'Chọn năm';

  @override
  String get yearRequiredMessage => 'Vui lòng chọn năm';

  @override
  String get uploadingSong => 'Đang upload lên Cloudinary...';

  @override
  String get savingSongChanges => 'Đang lưu thay đổi...';

  @override
  String get uploadAndSaveSong => 'Upload & Lưu bài hát';

  @override
  String get saveSongChanges => 'Lưu thay đổi bài hát';

  @override
  String get yearSongEmptyTitle => 'Chưa có bài nào theo năm';

  @override
  String get yearSongEmptySubtitle => 'Nhấn nút thêm để đưa bài hát vào kho nhạc theo năm từ 2018 đến 2026.';

  @override
  String deleteYearSongConfirmMessage(String title) {
    return 'Bạn có chắc muốn xoá bài theo năm \"$title\" không?';
  }

  @override
  String currentAudioWillBeKept(String fileName) {
    return 'Giữ file hiện tại: $fileName';
  }

  @override
  String get coverImageRequiredMessage => 'Vui lòng chọn ảnh bìa!';

  @override
  String get audioFileRequiredMessage => 'Vui lòng chọn file audio!';
}
