from datetime import datetime
from typing import Literal

from pydantic import BaseModel, EmailStr, Field


TemplateName = Literal["prd", "compliance", "contract", "consulting", "other"]
ProviderName = Literal["demo", "openai", "anthropic", "groq", "groq-8b", "groq-gemma", "xai"]


class SignupRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class SigninRequest(BaseModel):
    email: EmailStr
    password: str


class UserView(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserView


class GenerateRequest(BaseModel):
    title: str | None = Field(default=None, max_length=220)
    input_text: str = Field(min_length=20, max_length=50000)
    template: TemplateName = "prd"
    provider: ProviderName = "demo"
    model: str | None = Field(default=None, max_length=120)
    max_iterations: int = Field(default=3, ge=1, le=4)
    custom_template_label: str | None = Field(default=None, max_length=120)
    custom_sections: list[str] | None = Field(default=None)


class ReviewFinding(BaseModel):
    severity: Literal["critical", "high", "medium", "low"]
    section: str
    issue: str
    recommendation: str


class ReviewResult(BaseModel):
    status: Literal["approved", "revision_required"]
    score: int = Field(ge=0, le=100)
    summary: str
    missing_sections: list[str] = []
    findings: list[ReviewFinding] = []
    strengths: list[str] = []


class DocumentUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=220)
    content_md: str | None = Field(default=None, min_length=20, max_length=250000)


class DocumentView(BaseModel):
    id: str
    title: str
    template: str
    source_notes: str
    content_md: str
    review: ReviewResult
    provider: str
    model: str
    status: str
    iteration_count: int
    created_at: datetime
    updated_at: datetime
    custom_template_label: str | None = None
    custom_sections: list[str] | None = None


class GenerationResult(BaseModel):
    title: str
    content_md: str
    review: ReviewResult
    provider: str
    model: str
    iteration_count: int
    status: str
    stages: list[str]
    remaining_guest_generations: int | None = None


class DashboardSummary(BaseModel):
    total_documents: int
    approved_documents: int
    needs_attention: int
    average_iterations: float
    recent_documents: list[DocumentView]


class ProviderOption(BaseModel):
    id: ProviderName
    name: str
    configured: bool
    default_model: str
    description: str

