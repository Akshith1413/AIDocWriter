import json

from .models import Document
from .schemas import DocumentView, ReviewResult


def review_from_json(raw: str) -> ReviewResult:
    try:
        return ReviewResult.model_validate_json(raw)
    except (ValueError, json.JSONDecodeError):
        return ReviewResult(
            status="revision_required",
            score=0,
            summary="Stored review output could not be parsed; submit for review again.",
            findings=[],
        )


def document_view(document: Document) -> DocumentView:
    return DocumentView(
        id=document.id,
        title=document.title,
        template=document.template,
        source_notes=document.source_notes,
        content_md=document.content_md,
        review=review_from_json(document.review_json),
        provider=document.provider,
        model=document.model,
        status=document.status,
        iteration_count=document.iteration_count,
        created_at=document.created_at,
        updated_at=document.updated_at,
    )

