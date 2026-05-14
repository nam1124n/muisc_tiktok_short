# Music Trend Clean

Flutter app nghe nhạc và quản trị nội dung bằng Firebase. Dự án hiện không còn phụ thuộc Phoenix backend khi chạy app.

Tên thư mục dự án là `Music_Trend_Clean`, nhưng package trong `pubspec.yaml` hiện vẫn là `login_flutter`.

## Kiến Trúc Hiện Tại

- Flutter là app chính cho user và admin.
- Firebase Auth dùng cho đăng nhập, đăng ký và phân quyền.
- Cloud Firestore là nguồn dữ liệu chính cho bài hát, profile, playlist, lịch sử nghe, yêu thích và audio đã tạo.
- Cloudinary dùng để upload ảnh bìa, file audio và avatar từ Flutter.
- `Your Audio` gọi Cloudflare Worker ở `../worker/` để tạo audio bằng Suno, sau đó lưu task/tracks vào Firestore.
- Backend Phoenix cũ đã được archive ở `../backend_legacy/` để tham chiếu, không dùng khi chạy app.

## Công Nghệ

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

## Luồng Dữ Liệu Chính

### User

- Đăng ký, đăng nhập bằng Firebase Auth.
- Nghe nhạc từ collection `songs`.
- Lưu favorites, recents và playlists dưới `users/{userId}`.
- Tạo audio qua Worker, lưu vào:
  - `users/{userId}/generation_tasks`
  - `users/{userId}/generated_tracks`

### Admin Flutter

- Admin dashboard nằm trong Flutter web.
- Admin thêm/sửa/archive bài hát trực tiếp qua Firestore.
- Upload ảnh/audio lên Cloudinary từ Flutter.
- Quyền admin dựa vào field:

```text
users/{adminUid}.role == "admin"
```

## Firestore Rules

Rules nằm ở:

```text
firestore.rules
```

Rules hiện tại:

- User chỉ đọc/ghi dữ liệu của chính họ.
- User không thể tự đổi `role` thành `admin`.
- User không thể tự sửa `followers`, `following`, `likes`.
- Chỉ admin được ghi `songs` và `yearly_songs`.
- Database không được để public bằng `allow read, write: if true`.

Nếu chưa cài Firebase CLI, deploy bằng Firebase Console:

1. Mở Firebase Console.
2. Vào Firestore Database → Rules.
3. Copy nội dung `firestore.rules`.
4. Publish.

Nếu dùng Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

## Chạy App

Cài dependency:

```bash
flutter pub get
```

Chạy web:

```bash
flutter run -d chrome
```

Chạy thiết bị/emulator:

```bash
flutter run
```

Không cần chạy backend cũ. Nếu chạy Worker local bằng `wrangler dev`, app dùng URL mặc định theo nền tảng:

- Web/iOS/macOS/desktop: `http://127.0.0.1:8787`
- Android emulator: `http://10.0.2.2:8787`

Nếu dùng Worker đã deploy hoặc chạy trên điện thoại thật, truyền:

```bash
flutter run --dart-define=AUDIO_GENERATION_WORKER_URL=https://<worker-domain>
```

## Tạo Audio

Hiện tại `generateAudio()` dùng remote datasource gọi Worker:

```text
lib/data/datasource/remote/audio_generation_remote_data_source.dart
```

Worker đã có contract tương thích với model Flutter:

```text
POST /generate
GET  /generations/:taskId
```

App tạo task qua `POST /api/generate`, lưu task `processing`, rồi My Audios tự polling `GET /api/generations/:taskId` để cập nhật tracks và ghi lại Firestore.

## Cấu Trúc Chính

```text
lib/
├── app/
│   ├── providers/
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasource/
│   │   ├── local/
│   │   └── remote/
│   ├── dto/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── ui/
│   └── screen/
├── firebase_options.dart
└── main.dart
```

## Firebase Collections

### `users/{userId}`

Profile và dữ liệu cá nhân:

- `email`
- `fullName`
- `username`
- `role`
- `ageGroup`
- `emailVerified`
- `avatarUrl`
- `followers`
- `following`
- `likes`

Subcollections:

- `favorites`
- `recents`
- `playlists`
- `generation_tasks`
- `generated_tracks`

### `songs`

Bài hát chính:

- `title`
- `artist`
- `audioUrl`
- `imageUrl`
- `status`
- `semanticTags`
- `searchAliases`
- `energyLevel`
- `createdAt`
- `updatedAt`

### `yearly_songs`

Nhạc theo năm, quản lý từ admin Flutter.

### `song_weekly_stats`

Thống kê lượt nghe theo tuần.

## Kiểm Tra

Phân tích code:

```bash
flutter analyze
```

Chạy test:

```bash
flutter test
```

## Backend Legacy

Backend Phoenix cũ đã chuyển sang:

```text
../backend_legacy/
```

Thư mục này chỉ để tham chiếu logic Suno/Cloudinary cũ. App Flutter hiện tại không cần backend này để chạy.
