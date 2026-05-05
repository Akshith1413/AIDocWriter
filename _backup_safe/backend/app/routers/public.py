import hashlib
from datetime import date

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..database import get_db
from ..llm import provider_options
from ..models import GuestUsage
from ..schemas import GenerationResult, GenerateRequest, ProviderOption
from ..templates import TEMPLATES
from ..workflow import DocumentOrchestrator

router = APIRouter(prefix="/public", tags=["public"])


@router.get("/providers", response_model=list[ProviderOption])
def providers() -> list[ProviderOption]:
    return provider_options()


@router.get("/templates")
def templates() -> list[dict[str, object]]:
    return [
        {"id": template.name, "name": template.label, "sections": list(template.required_sections)}
        for template in TEMPLATES.values()
    ]


def fingerprint(request: Request, session: str | None) -> str:
    host = request.client.host if request.client else "unknown"
    seed = f"{session or 'anonymous'}:{host}:{get_settings().secret_key}"
    return hashlib.sha256(seed.encode("utf-8")).hexdigest()


@router.post("/generate", response_model=GenerationResult)
async def guest_generate(
    payload: GenerateRequest,
    request: Request,
    x_guest_session: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> GenerationResult:
    settings = get_settings()
    key = fingerprint(request, x_guest_session)
    usage = db.scalar(
        select(GuestUsage).where(
            GuestUsage.fingerprint == key, GuestUsage.usage_date == date.today()
        )
    )
    if usage and usage.count >= settings.guest_daily_limit:
        raise HTTPException(
            status_code=429,
            detail="Guest generation limit reached. Create an account to continue drafting.",
        )
    if not usage:
        usage = GuestUsage(fingerprint=key, usage_date=date.today(), count=0)
        db.add(usage)
    usage.count += 1
    db.commit()

    from ..llm import ProviderError
    
    try:
        result = await DocumentOrchestrator(payload).generate()
        result.remaining_guest_generations = settings.guest_daily_limit - usage.count
        return result
    except ProviderError as exc:
        raise HTTPException(status_code=502, detail=str(exc))

