## Saransk for Tourists - Backend

FastAPI backend for the Saransk for Tourists mobile application.

### Features

- **Places API**: CRUD operations for tourist points with bilingual support (RU/EN)
- **Reviews API**: User reviews with moderation and Perspective API integration
- **Database**: PostgreSQL with SQLAlchemy ORM and Alembic migrations
- **Storage**: Local MinIO (S3-compatible) for media files
- **Authentication**: JWT-based auth (Apple Sign-In, email magic links)

### Local Development

1. Copy environment file:
```bash
cp .env.example .env
```

2. Start services:
```bash
docker compose up -d --build
```

3. Run migrations:
```bash
# If you have docker compose running
docker compose exec api alembic upgrade head

# Or locally with venv
source .venv/bin/activate
alembic upgrade head
```

4. Check health:
```bash
curl http://localhost:8000/health
```

5. View API docs:
```bash
open http://localhost:8000/docs
```

### API Endpoints

- `GET /api/v1/places/` - List places with filtering
- `GET /api/v1/places/{id}` - Get specific place
- `POST /api/v1/places/` - Create place (admin)
- `PUT /api/v1/places/{id}` - Update place (admin)
- `DELETE /api/v1/places/{id}` - Delete place (admin)

- `GET /api/v1/reviews/place/{place_id}` - Get place reviews
- `POST /api/v1/reviews/` - Create review
- `PUT /api/v1/reviews/{id}` - Update review
- `DELETE /api/v1/reviews/{id}` - Delete review
- `POST /api/v1/reviews/{id}/report` - Report review

### Infrastructure

- **API**: FastAPI with ORJSON responses
- **Database**: PostgreSQL 16 with async support
- **Cache**: Redis for sessions and caching
- **Storage**: MinIO (local) / Yandex Object Storage (prod)
- **Migrations**: Alembic with auto-generation

### MinIO (Local S3)

- Console: http://localhost:9001 (minioadmin/minioadmin)
- S3 API: http://localhost:9000
- Bucket `saransk-media` created automatically (public read)

### Stack

FastAPI, SQLAlchemy, PostgreSQL, Redis, MinIO (S3-compatible). For production — Yandex Object Storage with same S3 API.

