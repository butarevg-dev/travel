## Saransk for Tourists - Backend

Local run:

1. Copy env
```bash
cp .env.example .env
```
2. Start services
```bash
docker compose up -d --build
```
3. Check health
```bash
curl http://localhost:8000/health
```

Stack: FastAPI, SQLAlchemy, Postgres, Redis. Object storage: локально MinIO (S3-совместимый). Для продакшена — Yandex Object Storage с тем же S3 API.

MinIO:
- Консоль: http://localhost:9001 (minioadmin/minioadmin)
- S3 API: http://localhost:9000
- Бакет `saransk-media` создаётся автоматически (публичный чтение)

