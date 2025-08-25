from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "local"
    app_name: str = "SaranskAPI"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    database_url: str
    redis_url: str = "redis://localhost:6379/0"

    jwt_secret: str
    jwt_alg: str = "HS256"
    jwt_expires_min: int = 60 * 24 * 30

    s3_endpoint: str
    s3_region: str
    s3_bucket: str
    s3_access_key: str
    s3_secret_key: str

    perspective_api_key: str | None = None


settings = Settings()  # type: ignore[call-arg]

