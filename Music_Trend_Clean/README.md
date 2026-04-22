# Music Trend Clean

Ứng dụng Flutter khám phá và quản lý nhạc theo hướng Clean Architecture, kết hợp `Firebase Auth`, `Cloud Firestore`, `Cloudinary`, `just_audio` và Phoenix backend để tạo trải nghiệm nghe nhạc và sinh audio.

Tên thư mục dự án là `Music_Trend_Clean`, nhưng package trong `pubspec.yaml` hiện vẫn là `login_flutter`.

## Tổng quan

Dự án này gồm 2 luồng chính:

- Người dùng đăng ký, đăng nhập, khám phá bài hát, nghe nhạc, xem top thịnh hành tuần, đánh dấu yêu thích, xem lịch sử nghe gần đây và chỉnh sửa hồ sơ cá nhân.
- Admin quản lý danh sách bài hát bằng cách upload ảnh bìa và file audio, sau đó dữ liệu được lưu trên Firestore và media được upload lên Cloudinary.

Điểm nổi bật của dự án là kết hợp dữ liệu nhạc trên Firestore với luồng tạo audio riêng qua backend Phoenix cho tab `Your Audio`.

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

### 5. Quản trị bài hát

- Chỉ tài khoản có email `admin@gmail.com` mới thấy nút vào admin dashboard.
- Admin có thể:
  - xem danh sách bài hát
  - thêm bài hát mới
  - xoá bài hát
- Khi thêm bài hát:
  - ảnh bìa được upload lên Cloudinary
  - file audio được upload lên Cloudinary
  - metadata bài hát được lưu vào Firestore

### 6. Tạo audio qua backend

- App gọi Phoenix backend qua các endpoint `/api/generate`, `/api/generations/:id` và `/api/my-songs`.
- `AUDIO_GENERATION_BASE_URL` là cấu hình quan trọng khi chạy app trên emulator hoặc điện thoại thật.
- Tab `Your Audio` dùng backend này để đọc danh sách audio đã tạo của user.

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
- Ô search ở `DiscoverAppBar` hiện chỉ là UI.
- Tab `Your Audio` mới là giao diện tĩnh.
- `Favorites` và `Recents` hiện lưu trong memory qua Riverpod, chưa persist xuống Firestore hay local storage.
- Test widget hiện tại mới là placeholder.

## Kiến trúc dự án

Dự án được tổ chức theo hướng gần với Clean Architecture:

### `lib/domain`

Chứa tầng nghiệp vụ:

- `entities`: các model lõi như `SongEntity`, `ProfileEntity`, `TrendingSongEntity`, `SearchPlanEntity`
- `repositories`: abstract contract cho data layer
- `usecases`: các ca sử dụng như đăng nhập, đăng ký, lấy bài hát, thống kê bài hát thịnh hành, tạo audio, cập nhật profile

### `lib/data`

Chứa tầng làm việc với dữ liệu:

- `datasource/remote`: Firebase, Phoenix backend, Cloudinary
- `datasource/local`: mock/local datasource cho profile
- `dto`: model map qua lại giữa Firestore và entity
- `repositories`: implement repository cho domain layer

### `lib/ui`

Chứa tầng giao diện:

- `screen/auth`: đăng nhập, đăng ký, auth state bằng Riverpod
- `screen/discover`: màn hình khám phá, tab suggestion/favorite/recent/your audio
- `screen/search`: tìm kiếm bài hát
- `screen/audio`: audio state bằng Riverpod
- `screen/admin`: dashboard quản trị bài hát
- `screen/profile`: xem và sửa profile
- `screen/home`: điều phối bottom navigation

### `lib/app`

Chứa config và utility:

- `config/audio_generation_config.dart`: cấu hình endpoint backend tạo audio qua `--dart-define`
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

### 4. Backend tạo audio

Phần tạo audio đọc cấu hình từ `lib/app/config/audio_generation_config.dart`.

`dart-define` hiện được hỗ trợ:

- `AUDIO_GENERATION_BASE_URL`

Giá trị mặc định theo nền tảng:

- Android emulator: `http://10.0.2.2:4000`
- Nền tảng khác: `http://127.0.0.1:4000`

Nếu chạy trên điện thoại thật, bạn cần trỏ `AUDIO_GENERATION_BASE_URL` về IP nội bộ của máy đang chạy backend Phoenix, ví dụ `http://192.168.1.10:4000`.

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

### 5. Chạy backend Phoenix

Mở terminal riêng cho backend:

```bash
cd ../backend
mix setup
mix phx.server
```

Kiểm tra nhanh:

```bash
curl http://localhost:4000/api/health
```

## Cách chạy dự án

### Chạy mobile hoặc desktop

```bash
flutter run
```

Nếu chạy Android emulator:

```bash
flutter run --dart-define=AUDIO_GENERATION_BASE_URL=http://10.0.2.2:4000
```

Nếu chạy điện thoại Android thật:

```bash
flutter run --dart-define=AUDIO_GENERATION_BASE_URL=http://<IP_LAN_MAY_TINH>:4000
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

Hiện tại test chủ yếu nằm ở các provider và luồng nghiệp vụ cơ bản; widget test mặc định vẫn còn ở mức placeholder.

## Một số lưu ý khi phát triển tiếp

- Nên đổi package name từ `login_flutter` sang tên phản ánh đúng sản phẩm.
- Nên chuyển cấu hình Cloudinary ra `--dart-define` hoặc file secret riêng, tránh hard-code trong source.
- Nên persist favorites/recents xuống Firestore hoặc local database.
- Nên hoàn thiện `Your Audio`, `Forgot password`, nút `+` ở bottom nav và ô search tại `Discover`.
- Nên bổ sung test cho các notifier/provider của `song`, `audio player` và các use case quan trọng.

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
- App có thêm luồng tạo audio qua Phoenix backend
- Codebase được chia theo `domain`, `data`, `ui`, `app`
# Music26

# tool update bài hát

dart run tool/import_yearly_songs.dart \
  --root /home/namper/Downloads/music_2021 \
  --email admin@gmail.com \
  --password 123456 \
  --apply

