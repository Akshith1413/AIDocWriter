from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import get_settings


class Base(DeclarativeBase):
    pass


settings = get_settings()
engine_kwargs: dict[str, object] = {}
if settings.database_url.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(settings.database_url, **engine_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_db() -> None:
    from . import models  # noqa: F401
    from sqlalchemy import text

    Base.metadata.create_all(bind=engine)

    # Ensure dynamic columns exist for existing databases
    with engine.begin() as conn:
        for column_name, column_type in [("custom_template_label", "VARCHAR(120)"), ("custom_sections", "TEXT")]:
            try:
                conn.execute(text(f"ALTER TABLE documents ADD COLUMN {column_name} {column_type}"))
            except Exception:
                pass


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

