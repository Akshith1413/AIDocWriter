from typing import TypedDict

from langgraph.graph import END, START, StateGraph
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()

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
    custom_template_label: str | None
    custom_sections: list[str] | None


def inferred_title(request: GenerateRequest) -> str:
    if request.title and request.title.strip():
        return request.title.strip()
    first_line = request.input_text.strip().splitlines()[0].lstrip("-#* ").strip()
    template_obj = get_template(
        request.template,
        request.custom_template_label,
        request.custom_sections,
    )
    return (first_line[:85] or f"New {template_obj.label}").rstrip(".")


class DocumentOrchestrator:
    def __init__(self, request: GenerateRequest, thread_id: str = "default") -> None:
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
        model = request.model or defaults.get(request.provider, "studio-demo")
        self.client = AgentLLM(ModelSelection(request.provider, model))
        self.thread_id = thread_id
        self.config = {"configurable": {"thread_id": self.thread_id}}
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
        return graph.compile(checkpointer=memory, interrupt_before=["finalize"])

    async def _writer(self, state: WorkflowState) -> WorkflowState:
        iteration = state.get("iterations", 0) + 1
        previous_review = state.get("review")
        feedback = previous_review.model_dump_json(indent=2) if previous_review else ""
        draft = await self.client.draft(
            get_template(
                state["template"],
                state.get("custom_template_label"),
                state.get("custom_sections"),
            ),
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
            get_template(
                state["template"],
                state.get("custom_template_label"),
                state.get("custom_sections"),
            ),
            state["input_text"],
            state["draft"],
        )
        stages = [
            *state.get("stages", []),
            f"Critic scored revision {state.get('iterations', 0)} at {review.score}/100",
        ]
        return {"review": review, "stages": stages}

    @staticmethod
    def _route_after_review(state: WorkflowState) -> str:
        score = state["review"].score if state.get("review") else 100
        if (
            (state["review"].status == "revision_required" or score < 70)
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
            "custom_template_label": self.request.custom_template_label,
            "custom_sections": self.request.custom_sections,
        }

    async def generate(self) -> GenerationResult:
        state = await self.graph.ainvoke(self.initial_state(), self.config)
        return self._result(state)

    async def review_existing(self, title: str, draft: str) -> GenerationResult:
        state = self.initial_state()
        state.update({"title": title, "draft": draft, "stages": ["Edited draft submitted to Critic"]})
        result = await self.review_graph.ainvoke(state, self.config)
        return self._result(result)

    async def resume(self) -> GenerationResult:
        state = await self.graph.ainvoke(None, self.config)
        return self._result(state)

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
