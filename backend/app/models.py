import uuid
from datetime import UTC, date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    documents: Mapped[list["Document"]] = relationship(
        back_populates="owner", cascade="all, delete-orphan"
    )


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(220))
    template: Mapped[str] = mapped_column(String(40), default="prd")
    source_notes: Mapped[str] = mapped_column(Text)
    content_md: Mapped[str] = mapped_column(Text)
    review_json: Mapped[str] = mapped_column(Text, default="{}")
    provider: Mapped[str] = mapped_column(String(40), default="demo")
    model: Mapped[str] = mapped_column(String(120), default="studio-demo")
    status: Mapped[str] = mapped_column(String(30), default="approved")
    iteration_count: Mapped[int] = mapped_column(Integer, default=1)
    custom_template_label: Mapped[str | None] = mapped_column(String(120), nullable=True)
    custom_sections: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow
    )

    owner: Mapped[User] = relationship(back_populates="documents")


class GuestUsage(Base):
    __tablename__ = "guest_usage"
    __table_args__ = (UniqueConstraint("fingerprint", "usage_date", name="uq_guest_daily"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fingerprint: Mapped[str] = mapped_column(String(128), index=True)
    usage_date: Mapped[date] = mapped_column(Date, default=date.today)
    count: Mapped[int] = mapped_column(Integer, default=0)

