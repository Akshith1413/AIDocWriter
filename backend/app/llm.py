import json
import re
from dataclasses import dataclass

import httpx

from .config import Settings, get_settings
from .prompts import critic_prompt, writer_prompt
from .schemas import ProviderOption, ReviewFinding, ReviewResult
from .templates import DocumentTemplate


class ProviderError(RuntimeError):
    """Raised when a configured external model cannot return a useful response."""


@dataclass(frozen=True)
class ModelSelection:
    provider: str
    model: str


def provider_options(settings: Settings | None = None) -> list[ProviderOption]:
    settings = settings or get_settings()
    return [
        ProviderOption(
            id="demo",
            name="Aureview Demo Engine (In Progress)",
            configured=True,
            default_model="studio-demo",
            description="Offline structured generation for evaluation and UI demos.",
        ),
        ProviderOption(
            id="openai",
            name="OpenAI",
            configured=bool(settings.openai_api_key),
            default_model=settings.openai_model,
            description="Configured through OPENAI_API_KEY on the API server.",
        ),
        ProviderOption(
            id="anthropic",
            name="Anthropic Claude",
            configured=bool(settings.anthropic_api_key),
            default_model=settings.anthropic_model,
            description="Configured through ANTHROPIC_API_KEY on the API server.",
        ),
        ProviderOption(
            id="groq",
            name="Groq (Llama 3 70B)",
            configured=bool(settings.groq_api_key),
            default_model=settings.groq_model,
            description="Ultra-fast Llama inference via Groq.",
        ),
        ProviderOption(
            id="groq-8b",
            name="Groq (Llama 3 8B)",
            configured=bool(settings.groq_api_key),
            default_model="llama-3.1-8b-instant",
            description="Ultra-fast lightweight Llama inference.",
        ),
        ProviderOption(
            id="groq-gemma",
            name="Groq (Gemma 2 9B)",
            configured=bool(settings.groq_api_key),
            default_model="gemma2-9b-it",
            description="Google Gemma 2 inference via Groq.",
        ),
    ]


class AgentLLM:
    def __init__(self, selection: ModelSelection, settings: Settings | None = None) -> None:
        self.selection = selection
        self.settings = settings or get_settings()

    def _get_chat_model(self):
        if self.selection.provider == "openai":
            if not self.settings.openai_api_key:
                raise ProviderError("OPENAI_API_KEY is not configured.")
            from langchain_openai import ChatOpenAI
            return ChatOpenAI(model=self.selection.model, api_key=self.settings.openai_api_key, temperature=0.2)
        elif self.selection.provider == "anthropic":
            if not self.settings.anthropic_api_key:
                raise ProviderError("ANTHROPIC_API_KEY is not configured.")
            from langchain_anthropic import ChatAnthropic
            return ChatAnthropic(model=self.selection.model, api_key=self.settings.anthropic_api_key, temperature=0.2)
        elif self.selection.provider.startswith("groq"):
            if not self.settings.groq_api_key:
                raise ProviderError("GROQ_API_KEY is not configured.")
            from langchain_groq import ChatGroq
            return ChatGroq(model=self.selection.model, api_key=self.settings.groq_api_key, temperature=0.2)
        else:
            raise ProviderError(f"Unknown provider: {self.selection.provider}")

    def _to_lc_messages(self, messages: list[dict[str, str]]):
        from langchain_core.messages import SystemMessage, HumanMessage, AIMessage
        lc_messages = []
        for m in messages:
            if m["role"] == "system":
                lc_messages.append(SystemMessage(content=m["content"]))
            elif m["role"] == "user":
                lc_messages.append(HumanMessage(content=m["content"]))
            elif m["role"] == "assistant":
                lc_messages.append(AIMessage(content=m["content"]))
        return lc_messages

    async def draft(
        self,
        template: DocumentTemplate,
        title: str,
        source_notes: str,
        iteration: int,
        previous_draft: str = "",
        feedback: str = "",
    ) -> str:
        if self.selection.provider == "demo":
            return self._demo_draft(template, title, source_notes, iteration)
        
        messages = writer_prompt(template, title, source_notes, previous_draft, feedback)
        lc_messages = self._to_lc_messages(messages)
        chat = self._get_chat_model()
        
        try:
            response = await chat.ainvoke(lc_messages)
            return str(response.content)
        except Exception as exc:
            raise ProviderError(f"The Writer Agent failed to generate content: {exc}") from exc

    async def review(
        self, template: DocumentTemplate, source_notes: str, draft: str
    ) -> ReviewResult:
        missing_sections = [
            section
            for section in template.required_sections
            if not re.search(rf"^##\s+{re.escape(section)}\s*$", draft, re.IGNORECASE | re.MULTILINE)
        ]
        if self.selection.provider == "demo":
            return self._demo_review(template, draft, missing_sections)
            
        messages = critic_prompt(template, source_notes, draft)
        lc_messages = self._to_lc_messages(messages)
        chat = self._get_chat_model()
        
        try:
            structured_chat = chat.with_structured_output(ReviewResult)
            review = await structured_chat.ainvoke(lc_messages)
        except Exception as exc:
            raise ProviderError("The Critic Agent failed to return valid structured JSON.") from exc

        if any(finding.severity in {"critical", "high"} for finding in review.findings):
            review.status = "revision_required"
            review.score = min(review.score, 69)
        if missing_sections:
            existing = set(review.missing_sections)
            review.missing_sections.extend(item for item in missing_sections if item not in existing)
            review.status = "revision_required"
            review.score = min(review.score, 69)
            for section in missing_sections:
                review.findings.append(
                    ReviewFinding(
                        severity="high",
                        section=section,
                        issue="Required template section is absent.",
                        recommendation=f"Add a substantive ## {section} section.",
                    )
                )
        return review

    @staticmethod
    def _demo_review(
        template: DocumentTemplate, draft: str, missing_sections: list[str]
    ) -> ReviewResult:
        findings: list[ReviewFinding] = []
        for section in missing_sections:
            findings.append(
                ReviewFinding(
                    severity="high",
                    section=section,
                    issue="Required template section is absent.",
                    recommendation=f"Add a complete ## {section} section before approval.",
                )
            )
        if len(draft) < 700:
            findings.append(
                ReviewFinding(
                    severity="medium",
                    section="Overall detail",
                    issue="The draft is brief for a professional deliverable.",
                    recommendation="Expand implementation detail, risks, and measurable validation.",
                )
            )
        requires_revision = bool(missing_sections)
        return ReviewResult(
            status="revision_required" if requires_revision else "approved",
            score=62 if requires_revision else (86 if findings else 94),
            summary=(
                "Required structure is incomplete and must be revised."
                if requires_revision
                else "Template compliance passed; review assumptions with the accountable owner."
            ),
            missing_sections=missing_sections,
            findings=findings,
            strengths=[
                f"Document follows the {template.label} review rubric.",
                "Content separates proposed actions from validation needs.",
            ],
        )

    @staticmethod
    def _demo_draft(
        template: DocumentTemplate, title: str, notes: str, iteration: int
    ) -> str:
        compact_notes = " ".join(notes.split())
        excerpt = compact_notes[:420] + ("..." if len(compact_notes) > 420 else "")
        skip_section = (
            template.required_sections[-1]
            if "[simulate-missing]" in notes.lower() and iteration == 1
            else None
        )
        generic = {
            "Executive Summary": (
                f"This {template.label.lower()} converts the supplied working notes into a "
                "review-ready decision artifact. The central input is: "
                f"**{excerpt}**\n\nThe proposal should proceed through validation gates before "
                "it is treated as an approved commitment."
            ),
            "Problem Statement": (
                "Teams currently depend on manually coordinated drafting and review, increasing "
                "cycle time and allowing omissions to reach approval. A structured workflow must "
                "preserve required sections and surface unresolved information early."
            ),
            "Goals and Success Metrics": (
                "| Outcome | Target (proposed) | Measurement |\n| --- | ---: | --- |\n"
                "| Document turnaround time | < 10 minutes | Generation-to-approval timestamps |\n"
                "| Template completeness | 100% required headings | Automated critic validation |\n"
                "| Material issue visibility | 100% high findings surfaced | Reviewer audit record |\n\n"
                "Targets are proposed assumptions until confirmed by the document owner."
            ),
            "Personas and User Stories": (
                "- **Author:** As a professional, I can turn raw notes into a structured draft so "
                "that I spend time on judgment instead of formatting.\n"
                "- **Reviewer:** As a QA owner, I can inspect flagged risks and approve deliberately.\n"
                "- **Administrator:** As an operations lead, I can track throughput and consistency."
            ),
            "Scope and Requirements": (
                "**In scope**\n\n- Guided document generation from pasted notes.\n"
                "- Writer-to-Critic routing with bounded revisions and structured findings.\n"
                "- Live editing, Markdown preview, exports, and authenticated document storage.\n\n"
                "**Out of scope for initial approval**\n\n- Autonomous legal sign-off or replacement "
                "of accountable human review.\n- Retrieval from confidential systems without access controls."
            ),
            "User Experience Flow": (
                "1. The author selects a document standard and enters source material.\n"
                "2. The Writer Agent produces a structured draft.\n"
                "3. The Critic Agent evaluates every required section and material risks.\n"
                "4. Failed checks trigger an automatic revision; passing drafts enter human review.\n"
                "5. The author edits, exports, or records final approval."
            ),
            "Technical Considerations": (
                "- Use an API-controlled provider configuration; secrets remain server-side.\n"
                "- Validate Critic output against a strict JSON schema before routing.\n"
                "- Store content and review snapshots with owner isolation and revision metadata.\n"
                "- Enforce iteration limits, input bounds, guest quotas, and explicit failure messages."
            ),
            "Edge Cases and Risks": (
                "| Risk / edge case | Impact | Mitigation |\n| --- | --- | --- |\n"
                "| Notes omit critical facts | Unsupported conclusions | Label assumptions and flag questions |\n"
                "| Model returns malformed critique | Routing failure | Schema validation and bounded error path |\n"
                "| Sensitive content pasted | Privacy exposure | Deployment policy, TLS, and controlled providers |\n"
                "| Reviewer rejects generated text | Delayed approval | Preserve editable draft and findings |"
            ),
            "Rollout and Validation": (
                "**Phase 1:** Evaluate with synthetic documents and rubric tests. **Phase 2:** Pilot "
                "with designated reviewers and measure completeness, edits, and turnaround. **Phase 3:** "
                "expand only after security, privacy, and retention decisions are approved.\n\n"
                "Release gate: no document is marked final without a human decision."
            ),
            "Open Questions": (
                "- Which organization-specific templates and approval roles govern production use?\n"
                "- What data retention, residency, and model-provider policies apply?\n"
                "- Which baselines define acceptable time savings and review accuracy?"
            ),
            "Matter and Scope": (
                f"The matter is derived from supplied notes: **{excerpt}**. This memo covers control "
                "alignment, evidence needs, observed gaps, and a remediation decision trail."
            ),
            "Applicable Controls": (
                "| Control area | Expected control | Validation needed |\n| --- | --- | --- |\n"
                "| Governance | Named owner and approval | Confirm accountable approver |\n"
                "| Data handling | Classified storage and access | Confirm retention policy |\n"
                "| Quality assurance | Recorded independent review | Preserve review findings |"
            ),
            "Evidence Reviewed": (
                "- Source notes supplied for this draft.\n- Automated structural review output.\n\n"
                "**Evidence limitation:** No external policies or executed records were supplied; "
                "control conclusions remain provisional."
            ),
            "Findings": (
                "| Finding | Classification | Action |\n| --- | --- | --- |\n"
                "| Approval evidence must be confirmed | Medium | Obtain owner sign-off record |\n"
                "| Retention rule is not supplied | Medium | Attach applicable policy before closure |"
            ),
            "Risk Assessment": (
                "Residual risk is **moderate pending verification** because the source material does "
                "not itself establish implemented controls. No compliance conclusion should be issued "
                "until supporting evidence is reviewed by the accountable professional."
            ),
            "Remediation Plan": (
                "1. Assign an accountable owner and due date for each open finding.\n"
                "2. Collect evidence and link it to control requirements.\n"
                "3. Perform independent QA review and record acceptance or escalation."
            ),
            "Approval and Sign-Off": (
                "| Role | Name | Decision | Date |\n| --- | --- | --- | --- |\n"
                "| Document owner | Pending | Pending | Pending |\n"
                "| Compliance reviewer | Pending | Pending | Pending |"
            ),
            "Parties and Purpose": (
                f"The proposed arrangement is summarized from the supplied material: **{excerpt}**. "
                "Party identities, authority, and executed purpose must be verified against source documents."
            ),
            "Key Commercial Terms": (
                "| Term | Supplied position | Review action |\n| --- | --- | --- |\n"
                "| Fees / value | Not confirmed in notes | Obtain commercial schedule |\n"
                "| Term and termination | Not confirmed | Verify notice and renewal terms |\n"
                "| Deliverables | To be validated | Attach accepted scope |"
            ),
            "Obligations": (
                "- Confirm each party's deliverables, dependencies, acceptance criteria, and payment triggers.\n"
                "- Confirm data handling, security notification, and confidentiality duties where applicable."
            ),
            "Risk Clauses": (
                "| Clause area | Risk | Proposed review position |\n| --- | --- | --- |\n"
                "| Liability | Unbounded exposure if omitted | Establish cap and carve-outs |\n"
                "| IP rights | Ownership ambiguity | Define background and created IP |\n"
                "| Data protection | Regulatory exposure | Include approved data terms |"
            ),
            "Negotiation Positions": (
                "Prioritize clear deliverables, reciprocal confidentiality, workable termination assistance, "
                "proportionate liability, and data-security commitments aligned to policy."
            ),
            "Missing Information": (
                "- Executed contracting parties and jurisdictions.\n- Commercial schedule and service levels.\n"
                "- Approved legal playbook positions and privacy assessment, if relevant."
            ),
            "Recommended Next Steps": (
                "Obtain the complete agreement and schedules, route material deviations to qualified counsel, "
                "and do not execute until authorized reviewers have recorded a decision."
            ),
            "Client Context": f"Working context captured from the provided notes: **{excerpt}**.",
            "Core Challenge": (
                "The organization needs a defensible decision based on incomplete working input while "
                "maintaining speed, clarity, and explicit accountability."
            ),
            "Analysis": (
                "The available material indicates an opportunity to standardize work and reduce avoidable "
                "review effort. The recommendation is directional because operational baselines, constraints, "
                "and stakeholder validation have not yet been supplied."
            ),
            "Options Considered": (
                "| Option | Benefit | Trade-off |\n| --- | --- | --- |\n"
                "| Maintain current workflow | No transition effort | Continued cycle-time burden |\n"
                "| Guided pilot | Evidence before scale | Limited initial reach |\n"
                "| Immediate rollout | Faster nominal adoption | Elevated governance risk |"
            ),
            "Recommendation": (
                "Launch a controlled pilot with named owners, clear success measures, and an approval "
                "checkpoint. Expand only when measured results and governance requirements are satisfied."
            ),
            "Implementation Roadmap": (
                "| Stage | Action | Exit criterion |\n| --- | --- | --- |\n"
                "| Discover | Validate inputs and baseline | Approved scope and KPIs |\n"
                "| Pilot | Execute limited implementation | Results reviewed by owners |\n"
                "| Scale | Extend proven approach | Governance approval recorded |"
            ),
            "KPIs and Risks": (
                "| KPI / risk | Treatment |\n| --- | --- |\n| Cycle time improvement | Compare before/after pilot |\n"
                "| Quality regression | Independent review sample |\n| Adoption resistance | Training and feedback loop |"
            ),
        }
        sections = []
        for section in template.required_sections:
            if section == skip_section:
                continue
            sections.append(f"## {section}\n\n{generic.get(section, 'Details require owner validation.')}")
        return (
            f"# {title}\n\n> **Aureview draft** | Standard: {template.label} | "
            f"Review cycle: {iteration} | Status: Human approval required\n\n" + "\n\n".join(sections)
        )
