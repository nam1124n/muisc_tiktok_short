# Music Trend Suno Worker

Cloudflare Worker proxy mỏng cho Suno API. Worker giữ `SUNO_API_KEY`, còn Flutter chỉ gọi Worker.

## Endpoints

```text
GET  /health
POST /generate
POST /api/generate
GET  /generations/:taskId
GET  /api/generations/:taskId
```

`POST /generate` nhận body tối thiểu:

```json
{
  "userId": "firebase_uid",
  "prompt": "Create a chill lofi track with soft piano"
}
```

Response đã normalize theo model Flutter:

```json
{
  "taskId": "suno_task_id",
  "status": "processing",
  "provider": "suno-api",
  "outputCount": 2,
  "tracks": []
}
```

## Cấu Hình

Secret bắt buộc:

```bash
wrangler secret put SUNO_API_KEY
```

Biến tùy chọn trong `wrangler.toml`:

- `SUNO_API_BASE_URL`
- `SUNO_MODEL`
- `CORS_ORIGIN`

Nếu muốn dùng callback Suno, thêm:

```bash
wrangler secret put SUNO_CALLBACK_URL
```

## Chạy Local

```bash
npm install
npm run dev
```

## Deploy

```bash
npm run deploy
```
