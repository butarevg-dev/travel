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

Stack: FastAPI, SQLAlchemy, Postgres, Redis. Object storage: Yandex Cloud (S3-compatible).

