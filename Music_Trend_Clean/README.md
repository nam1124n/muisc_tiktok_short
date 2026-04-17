# Music Trend Clean

Ứng dụng Flutter khám phá và quản lý nhạc theo hướng Clean Architecture, kết hợp `Firebase Auth`, `Cloud Firestore`, `Cloudinary`, `just_audio` và `Ollama` để tạo trải nghiệm nghe nhạc có tìm kiếm hỗ trợ AI.

Tên thư mục dự án là `Music_Trend_Clean`, nhưng package trong `pubspec.yaml` hiện vẫn là `login_flutter`.

## Tổng quan

Dự án này gồm 2 luồng chính:

- Người dùng đăng ký, đăng nhập, khám phá bài hát, nghe nhạc, xem top thịnh hành tuần, đánh dấu yêu thích, xem lịch sử nghe gần đây và chỉnh sửa hồ sơ cá nhân.
- Admin quản lý danh sách bài hát bằng cách upload ảnh bìa và file audio, sau đó dữ liệu được lưu trên Firestore và media được upload lên Cloudinary.

Điểm nổi bật của dự án là phần tìm kiếm: thay vì chỉ lọc text thuần túy, app dùng AI để phân tích truy vấn tìm kiếm thành các từ khóa, gợi ý tên bài hát, gợi ý nghệ sĩ, rồi mới xếp hạng danh sách bài hát phù hợp.

## Công nghệ sử dụng

- Flutter
- Dart
- flutter_riverpod
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Cloudinary API qua `http`
- just_audio
- image_picker
- share_plus
- Ollama API

## Tính năng hiện có

### 1. Xác thực người dùng

- Đăng ký tài khoản với email, mật khẩu và họ tên.
- Đăng nhập bằng Firebase Authentication.
- Điều hướng sang màn hình chính sau khi đăng nhập thành công.

### 2. Khám phá nhạc

- Tab `Suggestions` hiển thị:
  - Top bài hát thịnh hành trong tuần.
  - Danh sách bài hát lấy realtime từ Firestore.
- Tab `Favorites` hiển thị danh sách bài hát đã thích.
- Tab `Recents` hiển thị lịch sử nghe gần đây.
- Tab `Your Audio` đã có UI nhưng chưa nối với backend xử lý thực tế.

### 3. Phát audio

- Phát nhạc bằng `just_audio`.
- Có mini player ở cuối màn hình khi đang phát.
- Hỗ trợ `play`, `pause`, `resume`, `seek`, `next`, `previous`.
- Tự phát bài tiếp theo khi bài hiện tại kết thúc.

### 4. Theo dõi xu hướng nghe

- Mỗi lần người dùng nghe đủ ngưỡng, app sẽ ghi nhận lượt nghe vào Firestore.
- Ngưỡng mặc định là `30 giây`.
- Nếu bài ngắn hơn 30 giây, app dùng ngưỡng `60%` thời lượng bài.
- Bảng xếp hạng tuần ưu tiên:
  - `uniqueUserCount` giảm dần
  - sau đó đến `totalPlayCount` giảm dần

### 5. Tìm kiếm có hỗ trợ AI

- Người dùng nhập truy vấn như tên bài hát, ca sĩ, mood, chủ đề.
- App gửi truy vấn sang Ollama để phân tích.
- Kết quả AI trả về 5 nhóm dữ liệu:
  - `keywords`
  - `artistHints`
  - `titleHints`
  - `tagHints`
  - `reason`
- Sau đó app tự chấm điểm từng bài hát trong danh sách hiện có để đưa ra kết quả.

Cơ chế fallback hiện tại:

1. Gọi local Ollama trước.
2. Nếu local lỗi và có cấu hình cloud endpoint, app gọi cloud.
3. Nếu cả hai đều lỗi, app rơi về rule-based search bằng cách tách từ khóa từ query gốc.

### 6. Quản trị bài hát

- Chỉ tài khoản có email `admin@gmail.com` mới thấy nút vào admin dashboard.
- Admin có thể:
  - xem danh sách bài hát
  - thêm bài hát mới
  - xoá bài hát
- Khi thêm bài hát:
  - ảnh bìa được upload lên Cloudinary
  - file audio được upload lên Cloudinary
  - metadata bài hát được lưu vào Firestore
  - admin có thể bổ sung `semanticTags`, `searchAliases`, `energyLevel` để AI search gợi ý đúng hơn

### 7. Hồ sơ người dùng

- Đọc hồ sơ từ Firestore collection `users`.
- Cập nhật username.
- Cập nhật avatar bằng cách upload ảnh lên Cloudinary rồi lưu URL về Firestore.
- Chia sẻ profile bằng `share_plus`.

## Những phần chưa hoàn thiện hoặc đang là placeholder

README này mô tả đúng trạng thái hiện tại của code. Một số phần trong app đã có giao diện nhưng chưa hoàn thiện logic:

- Tab bottom navigation `Đã thích` ở `HomeScreen` vẫn là màn hình placeholder, chưa nối vào dữ liệu favorites thật.
- Nút `+` ở giữa bottom navigation hiện chưa có action.
- Nút `Forgot password?` chưa xử lý.
- Ô search ở `DiscoverAppBar` hiện chỉ là UI, chưa nối với logic tìm kiếm.
- Tab `Your Audio` mới là giao diện tĩnh.
- `Favorites` và `Recents` hiện lưu trong memory qua Riverpod, chưa persist xuống Firestore hay local storage.
- Test widget hiện tại mới là placeholder; test đáng chú ý nhất đang nằm ở phần AI search repository.

## Kiến trúc dự án

Dự án được tổ chức theo hướng gần với Clean Architecture:

### `lib/domain`

Chứa tầng nghiệp vụ:

- `entities`: các model lõi như `SongEntity`, `ProfileEntity`, `TrendingSongEntity`, `SearchPlanEntity`
- `repositories`: abstract contract cho data layer
- `usecases`: các ca sử dụng như đăng nhập, đăng ký, lấy bài hát, thống kê bài hát thịnh hành, tìm kiếm AI, cập nhật profile

### `lib/data`

Chứa tầng làm việc với dữ liệu:

- `datasource/remote`: Firebase, Ollama, Cloudinary
- `datasource/local`: mock/local datasource cho profile
- `dto`: model map qua lại giữa Firestore và entity
- `repositories`: implement repository cho domain layer

### `lib/ui`

Chứa tầng giao diện:

- `screen/auth`: đăng nhập, đăng ký, auth state bằng Riverpod
- `screen/discover`: màn hình khám phá, tab suggestion/favorite/recent/your audio
- `screen/search`: tìm kiếm AI
- `screen/audio`: audio state bằng Riverpod
- `screen/admin`: dashboard quản trị bài hát
- `screen/profile`: xem và sửa profile
- `screen/home`: điều phối bottom navigation

### `lib/app`

Chứa config và utility:

- `config/ai_config.dart`: cấu hình endpoint/model cho Ollama qua `--dart-define`
- `utils/audio_file_picker*.dart`: chọn file audio theo từng nền tảng

## Cấu trúc thư mục chính

```text
Music_Trend_Clean/
├── lib/
│   ├── app/
│   │   ├── config/
│   │   └── utils/
│   ├── data/
│   │   ├── datasource/
│   │   ├── dto/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── ui/
│   │   └── screen/
│   ├── firebase_options.dart
│   └── main.dart
├── test/
├── android/
├── ios/
├── macos/
├── linux/
├── windows/
└── web/
```

## Cấu hình backend và dịch vụ ngoài

### 1. Firebase

App đang dùng:

- `Firebase Auth` cho đăng nhập/đăng ký
- `Cloud Firestore` cho dữ liệu bài hát, profile và thống kê lượt nghe

Các file cấu hình Firebase hiện có trong repo:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Nếu bạn dùng project Firebase khác, nên thay các file trên bằng cấu hình riêng của bạn và generate lại `firebase_options.dart` bằng FlutterFire CLI.

### 2. Firestore collections

#### `songs`

Mỗi document bài hát hiện có các field chính:

- `title`
- `artist`
- `audioUrl`
- `imageUrl`
- `semanticTags`
- `searchAliases`
- `energyLevel`

### Backfill metadata cho dữ liệu cũ

Repo có sẵn script CLI để suy đoán tag cơ bản cho các bài hát cũ từ `title` và `artist`, rồi cập nhật Firestore qua REST API.

Chạy thử trước ở chế độ dry-run:

```bash
dart run tool/backfill_song_metadata.dart \
  --email admin@gmail.com \
  --password YOUR_PASSWORD \
  --limit 20
```

Khi kết quả ổn, thêm `--apply` để ghi thật:

```bash
dart run tool/backfill_song_metadata.dart \
  --email admin@gmail.com \
  --password YOUR_PASSWORD \
  --apply
```

Các điểm an toàn:

- Mặc định script chỉ dry-run, không ghi dữ liệu.
- Mặc định script chỉ điền `semanticTags` và `energyLevel` khi document còn thiếu.
- Nếu muốn ghi đè metadata đã có, dùng thêm cờ `--overwrite`.

#### `users`

Dùng cho profile người dùng, có thể gồm:

- `username`
- `avatarUrl`
- `followers`
- `following`
- `likes`

Nếu document `users/{uid}` chưa tồn tại, màn hình profile vẫn có thể hiển thị dữ liệu fallback lấy từ Firebase Auth và giá trị mặc định.

#### `song_weekly_stats`

Dùng để lưu thống kê nghe theo tuần, cấu trúc:

```text
song_weekly_stats/{weekKey}/songs/{songId}
song_weekly_stats/{weekKey}/songs/{songId}/listeners/{userId}
```

Trong đó:

- `weekKey` có format `YYYY-MM-DD` và là ngày bắt đầu tuần
- document `songs/{songId}` có các field như:
  - `songId`
  - `title`
  - `artist`
  - `audioUrl`
  - `imageUrl`
  - `weekKey`
  - `totalPlayCount`
  - `uniqueUserCount`
  - `updatedAt`

### 3. Cloudinary

Phần upload media hiện đang hard-code cấu hình ngay trong file:

- `lib/data/datasource/remote/song_remote_data_source.dart`

Bạn cần thay các giá trị này cho phù hợp:

```dart
const cloudName = 'ddy9wgrbj';
const uploadPreset = 'musicapp';
```

App dùng:

- resource type `image` cho ảnh bìa
- resource type `video` cho audio upload

### 4. Ollama

Phần AI search đọc cấu hình từ `lib/app/config/ai_config.dart`.

Các `dart-define` hiện được hỗ trợ:

- `OLLAMA_LOCAL_BASE_URL`
- `OLLAMA_CLOUD_BASE_URL`
- `OLLAMA_LOCAL_MODEL`
- `OLLAMA_CLOUD_MODEL`
- `OLLAMA_TIMEOUT_SECONDS`

Giá trị mặc định hiện tại:

- local model: `llama3:latest`
- cloud model: `gpt-oss:20b-cloud`
- timeout: `30`

Mặc định local base URL theo nền tảng:

- Android emulator: `http://10.0.2.2:11434/api`
- Nền tảng khác: `http://127.0.0.1:11434/api`

Nếu chạy trên điện thoại thật, bạn sẽ cần trỏ về IP nội bộ của máy đang chạy Ollama thay vì `127.0.0.1`.

## Hướng dẫn cài đặt

### 1. Cài dependency

```bash
flutter pub get
```

### 2. Kiểm tra môi trường Flutter

```bash
flutter doctor
```

`pubspec.yaml` đang yêu cầu Dart SDK `^3.11.1`.

### 3. Cấu hình Firebase

- Tạo project Firebase
- Bật `Authentication` với phương thức Email/Password
- Tạo `Cloud Firestore`
- Thay cấu hình Firebase của riêng bạn vào project nếu cần

### 4. Cấu hình Cloudinary

Sửa `cloudName` và `uploadPreset` trong:

- `lib/data/datasource/remote/song_remote_data_source.dart`

### 5. Cấu hình Ollama local

Ví dụ:

```bash
ollama serve
ollama pull llama3:latest
```

Sau đó chạy app:

```bash
flutter run
```

Hoặc truyền rõ cấu hình:

```bash
flutter run \
  --dart-define=OLLAMA_LOCAL_BASE_URL=http://127.0.0.1:11434/api \
  --dart-define=OLLAMA_LOCAL_MODEL=llama3:latest
```

Ví dụ dùng cloud fallback:

```bash
flutter run \
  --dart-define=OLLAMA_LOCAL_BASE_URL=http://127.0.0.1:11434/api \
  --dart-define=OLLAMA_LOCAL_MODEL=llama3:latest \
  --dart-define=OLLAMA_CLOUD_BASE_URL=https://your-ollama-gateway.example/api \
  --dart-define=OLLAMA_CLOUD_MODEL=gpt-oss:20b-cloud
```

## Cách chạy dự án

### Chạy mobile hoặc desktop

```bash
flutter run
```

### Chạy web

```bash
flutter run -d chrome
```

## Tài khoản admin

Quyền admin hiện đang kiểm tra cứng theo email:

```text
admin@gmail.com
```

Điều này được dùng ở UI để mở dashboard quản trị. Nếu muốn thay đổi cơ chế phân quyền, bạn nên chuyển sang role-based access trong Firestore hoặc custom claims của Firebase Auth.

## Chọn file audio

App có hỗ trợ chọn file audio theo nền tảng:

- Desktop: dùng file picker
- Web: dùng `FileUploadInputElement`
- Mobile: fallback qua `ImagePicker().pickMedia()`

Các định dạng được khai báo hỗ trợ:

- `mp3`
- `m4a`
- `wav`
- `aac`
- `ogg`
- `flac`

## Kiểm thử

Chạy test:

```bash
flutter test
```

Hiện tại test đáng chú ý nhất là:

- `test/data/repositories/ai_search_repository_impl_test.dart`

File này đang kiểm tra:

- local Ollama thành công
- fallback sang cloud khi local lỗi
- fallback sang rule-based search khi tất cả provider đều lỗi

## Một số lưu ý khi phát triển tiếp

- Nên đổi package name từ `login_flutter` sang tên phản ánh đúng sản phẩm.
- Nên chuyển cấu hình Cloudinary ra `--dart-define` hoặc file secret riêng, tránh hard-code trong source.
- Nên persist favorites/recents xuống Firestore hoặc local database.
- Nên hoàn thiện `Your Audio`, `Forgot password`, nút `+` ở bottom nav và ô search tại `Discover`.
- Nên bổ sung test cho các notifier/provider của `song`, `audio player`, `search` và các use case quan trọng.

## Lệnh hữu ích

```bash
flutter analyze
flutter test
flutter build web
flutter build apk
```

## Tóm tắt nhanh

Nếu bạn cần hiểu thật nhanh dự án này đang làm gì, thì có thể xem nó như sau:

- Flutter app nghe nhạc có Firebase Auth + Firestore
- Admin upload bài hát lên Cloudinary và quản lý dữ liệu trên Firestore
- User nghe nhạc, tạo top thịnh hành tuần từ lượt nghe thật
- Search dùng Ollama để phân tích query rồi xếp hạng bài hát
- Codebase được chia theo `domain`, `data`, `ui`, `app`
# Music26
