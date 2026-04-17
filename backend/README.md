# Backend

Phoenix backend cơ bản cho đồ án ứng dụng nghe nhạc.

Backend này có 2 phần chính:

* Web quản lý danh sách bài nhạc AI đã tạo ở `/songs`
* JSON API để app Flutter gọi ở `/api/*`

Phiên bản đầu tiên không dùng Ecto, Postgres hay SQLite.
Metadata được lưu tạm trong memory bằng `Agent` để ưu tiên code đơn giản và chạy nhanh.

## Chạy project

```bash
cd backend
mix setup
mix phx.server
```

Mở:

* `http://localhost:4000/songs`
* `http://localhost:4000/health`
* `http://localhost:4000/api/health`

## API chính

### Tạo bài nhạc giả lập

```bash
curl -X POST http://localhost:4000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uid_001",
    "prompt": "lofi chill piano, rainy night",
    "duration_sec": 30
  }'
```

### Xem chi tiết 1 generation

```bash
curl http://localhost:4000/api/generations/gen_123
```

### Xem danh sách bài của 1 user

```bash
curl "http://localhost:4000/api/my-songs?user_id=uid_001"
```

## Ghi chú kiến trúc

* `Backend.Music.Store`: lưu dữ liệu trong memory
* `Backend.Music.MusicService`: chứa logic generate fake và async
* `BackendWeb.GenerationController`: API cho Flutter
* `BackendWeb.SongPageController`: web quản lý cơ bản

Khi cần nâng cấp, bạn có thể giữ nguyên controller và thay phần `Store` bằng Firestore hoặc database thật.
