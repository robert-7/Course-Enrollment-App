import os


def _get_secret_key():
    secret_key = os.environ.get("SECRET_KEY")
    if not secret_key:
        raise RuntimeError(
            "SECRET_KEY environment variable is not set. "
            'Generate one with: python -c "import secrets;'
            ' print(secrets.token_hex(32))"'
        )
    return secret_key


class BaseConfig:
    DEBUG = False
    TESTING = False
    SESSION_COOKIE_SAMESITE = "Lax"
    SESSION_COOKIE_SECURE = False

    def __init__(self):
        self.SECRET_KEY = _get_secret_key()
        # MONGODB_SETTINGS is what Flask-MongoEngine looks for this conf key
        # for setting up the connection to the database.
        self.MONGODB_SETTINGS = {
            "db": "NOU_Enrollment",
            "host": os.environ.get("MONGO_URI"),
        }


class DevelopmentConfig(BaseConfig):
    SESSION_COOKIE_SECURE = False


class TestingConfig(BaseConfig):
    TESTING = True
    SESSION_COOKIE_SECURE = False


class ProductionConfig(BaseConfig):
    SESSION_COOKIE_SECURE = True


_CONFIG_BY_ENV = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}


def get_config_for_env():
    app_env = os.environ.get("APP_ENV", "").strip().lower() or "development"

    try:
        config_class = _CONFIG_BY_ENV[app_env]
    except KeyError as exc:
        supported_envs = ", ".join(sorted(_CONFIG_BY_ENV))
        raise RuntimeError(
            f"Unsupported APP_ENV value {app_env!r}. "
            f"Expected one of: {supported_envs}."
        ) from exc

    return config_class()
