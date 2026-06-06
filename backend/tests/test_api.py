import os

os.environ["DATABASE_URL"] = "sqlite:///./test_aureview.db"
os.environ["SECRET_KEY"] = "tests-use-a-specific-secret-key-for-tokens"
os.environ["GUEST_DAILY_LIMIT"] = "3"

from fastapi.testclient import TestClient
from sqlalchemy import delete

from app.database import SessionLocal
from app.main import app
from app.models import Document, GuestUsage, User
from app.schemas import GenerateRequest
from app.workflow import DocumentOrchestrator


def reset_database() -> None:
    with SessionLocal() as db:
        db.execute(delete(Document))
        db.execute(delete(GuestUsage))
        db.execute(delete(User))
        db.commit()


def sample_request(**overrides):
    payload = {
        "title": "Onboarding Portal",
        "input_text": (
            "Create an onboarding portal for enterprise clients with upload verification, "
            "status tracking, accessibility, audit history, and turnaround targets."
        ),
        "template": "prd",
        "provider": "demo",
        "model": "studio-demo",
        "max_iterations": 3,
    }
    payload.update(overrides)
    return payload


def auth_header(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/auth/signup",
        json={"name": "Review Lead", "email": "lead@example.com", "password": "strong-pass-123"},
    )
    assert response.status_code == 201
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_health_and_public_configuration() -> None:
    with TestClient(app) as client:
        reset_database()
        assert client.get("/api/health").json()["status"] == "healthy"
        providers = client.get("/api/public/providers").json()
        assert providers[0]["id"] == "demo"
        assert providers[0]["configured"] is True
        assert len(client.get("/api/public/templates").json()) == 4
        orchestration = DocumentOrchestrator(GenerateRequest(**sample_request(provider="openai", model=None)))
        assert orchestration.client.selection.model == "gpt-4o"


def test_authenticated_generation_edit_review_and_dashboard() -> None:
    with TestClient(app) as client:
        reset_database()
        headers = auth_header(client)
        response = client.post("/api/documents/generate", headers=headers, json=sample_request())
        assert response.status_code == 201
        generated = response.json()
        assert generated["status"] == "approved"
        assert "## Goals and Success Metrics" in generated["content_md"]

        incomplete = generated["content_md"].replace("## Open Questions", "## Pending Discussion")
        patched = client.patch(
            f"/api/documents/{generated['id']}",
            headers=headers,
            json={"content_md": incomplete},
        )
        assert patched.json()["status"] == "revision_required"

        refined = client.post(f"/api/documents/{generated['id']}/review", headers=headers)
        assert refined.status_code == 200
        assert refined.json()["status"] == "approved"
        assert "## Open Questions" in refined.json()["content_md"]

        dashboard = client.get("/api/documents/dashboard", headers=headers).json()
        assert dashboard["total_documents"] == 1
        assert dashboard["approved_documents"] == 1
        assert client.get(f"/api/documents/{generated['id']}/export/docx", headers=headers).status_code == 200


def test_langgraph_revision_route_and_guest_quota() -> None:
    with TestClient(app) as client:
        reset_database()
        loop_payload = sample_request(
            input_text=(
                "Produce a structured portal specification with metrics, risks, and approvals. "
                "[simulate-missing] This marker exercises the revision route in demo mode."
            )
        )
        loop_result = client.post(
            "/api/public/generate", json=loop_payload, headers={"X-Guest-Session": "route-example"}
        ).json()
        assert loop_result["status"] == "approved"
        assert loop_result["iteration_count"] == 2
        assert any("Critic scored revision 1" in stage for stage in loop_result["stages"])

        for _ in range(3):
            response = client.post(
                "/api/public/generate",
                json=sample_request(),
                headers={"X-Guest-Session": "daily-limited"},
            )
            assert response.status_code == 200
        limited = client.post(
            "/api/public/generate",
            json=sample_request(),
            headers={"X-Guest-Session": "daily-limited"},
        )
        assert limited.status_code == 429
