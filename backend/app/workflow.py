from typing import TypedDict

from langgraph.graph import END, START, StateGraph

from .config import get_settings
from .llm import AgentLLM, ModelSelection
from .schemas import GenerationResult, GenerateRequest, ReviewResult
from .templates import get_template


class WorkflowState(TypedDict, total=False):
    title: str
    input_text: str
    template: str
    provider: str
    model: str
    max_iterations: int
    iterations: int
    draft: str
    review: ReviewResult
    stages: list[str]


def inferred_title(request: GenerateRequest) -> str:
    if request.title and request.title.strip():
        return request.title.strip()
    first_line = request.input_text.strip().splitlines()[0].lstrip("-#* ").strip()
    return (first_line[:85] or f"New {get_template(request.template).label}").rstrip(".")


class DocumentOrchestrator:
    def __init__(self, request: GenerateRequest) -> None:
        self.request = request
        settings = get_settings()
        defaults = {
            "demo": "studio-demo",
            "openai": settings.openai_model,
            "anthropic": settings.anthropic_model,
            "groq": settings.groq_model,
            "groq-8b": "llama-3.1-8b-instant",
            "groq-gemma": "gemma2-9b-it",
        }
        model = request.model or defaults[request.provider]
        self.client = AgentLLM(ModelSelection(request.provider, model))
        self.graph = self._compile_graph(start_with_review=False)
        self.review_graph = self._compile_graph(start_with_review=True)

    def _compile_graph(self, start_with_review: bool):
        graph = StateGraph(WorkflowState)
        graph.add_node("writer", self._writer)
        graph.add_node("critic", self._critic)
        graph.add_node("finalize", self._finalize)
        graph.add_edge(START, "critic" if start_with_review else "writer")
        graph.add_edge("writer", "critic")
        graph.add_conditional_edges(
            "critic", self._route_after_review, {"revise": "writer", "finish": "finalize"}
        )
        graph.add_edge("finalize", END)
        return graph.compile()

    async def _writer(self, state: WorkflowState) -> WorkflowState:
        iteration = state.get("iterations", 0) + 1
        previous_review = state.get("review")
        feedback = previous_review.model_dump_json(indent=2) if previous_review else ""
        draft = await self.client.draft(
            get_template(state["template"]),
            state["title"],
            state["input_text"],
            iteration,
            state.get("draft", ""),
            feedback,
        )
        stages = [*state.get("stages", []), f"Writer produced revision {iteration}"]
        return {"draft": draft, "iterations": iteration, "stages": stages}

    async def _critic(self, state: WorkflowState) -> WorkflowState:
        review = await self.client.review(
            get_template(state["template"]), state["input_text"], state["draft"]
        )
        stages = [
            *state.get("stages", []),
            f"Critic scored revision {state.get('iterations', 0)} at {review.score}/100",
        ]
        return {"review": review, "stages": stages}

    @staticmethod
    def _route_after_review(state: WorkflowState) -> str:
        if (
            state["review"].status == "revision_required"
            and state.get("iterations", 0) < state["max_iterations"]
        ):
            return "revise"
        return "finish"

    @staticmethod
    async def _finalize(state: WorkflowState) -> WorkflowState:
        outcome = "approved" if state["review"].status == "approved" else "human review required"
        return {"stages": [*state.get("stages", []), f"Workflow complete: {outcome}"]}

    def initial_state(self) -> WorkflowState:
        return {
            "title": inferred_title(self.request),
            "input_text": self.request.input_text,
            "template": self.request.template,
            "provider": self.request.provider,
            "model": self.client.selection.model,
            "max_iterations": self.request.max_iterations,
            "iterations": 0,
            "stages": ["Input accepted and template rubric loaded"],
        }

    async def generate(self) -> GenerationResult:
        state = await self.graph.ainvoke(self.initial_state())
        return self._result(state)

    async def review_existing(self, title: str, draft: str) -> GenerationResult:
        state = self.initial_state()
        state.update({"title": title, "draft": draft, "stages": ["Edited draft submitted to Critic"]})
        result = await self.review_graph.ainvoke(state)
        return self._result(result)

    def _result(self, state: WorkflowState) -> GenerationResult:
        return GenerationResult(
            title=state["title"],
            content_md=state["draft"],
            review=state["review"],
            provider=self.request.provider,
            model=self.client.selection.model,
            iteration_count=state.get("iterations", 0),
            status=state["review"].status,
            stages=state["stages"],
        )
