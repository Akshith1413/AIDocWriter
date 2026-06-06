from dataclasses import dataclass


@dataclass(frozen=True)
class DocumentTemplate:
    name: str
    label: str
    required_sections: tuple[str, ...]
    instruction: str


TEMPLATES: dict[str, DocumentTemplate] = {
    "prd": DocumentTemplate(
        name="prd",
        label="Product Requirements Document",
        required_sections=(
            "Executive Summary",
            "Problem Statement",
            "Goals and Success Metrics",
            "Personas and User Stories",
            "Scope and Requirements",
            "User Experience Flow",
            "Technical Considerations",
            "Edge Cases and Risks",
            "Rollout and Validation",
            "Open Questions",
        ),
        instruction="Write a decisive product requirements document with measurable outcomes.",
    ),
    "compliance": DocumentTemplate(
        name="compliance",
        label="Compliance Review Memo",
        required_sections=(
            "Executive Summary",
            "Matter and Scope",
            "Applicable Controls",
            "Evidence Reviewed",
            "Findings",
            "Risk Assessment",
            "Remediation Plan",
            "Approval and Sign-Off",
        ),
        instruction="Write a careful compliance memo; distinguish supplied facts from assumptions.",
    ),
    "contract": DocumentTemplate(
        name="contract",
        label="Contract Review Brief",
        required_sections=(
            "Executive Summary",
            "Parties and Purpose",
            "Key Commercial Terms",
            "Obligations",
            "Risk Clauses",
            "Negotiation Positions",
            "Missing Information",
            "Recommended Next Steps",
        ),
        instruction="Write a contract issue brief, not legal advice, highlighting negotiation risks.",
    ),
    "consulting": DocumentTemplate(
        name="consulting",
        label="Consulting Decision Memo",
        required_sections=(
            "Executive Summary",
            "Client Context",
            "Core Challenge",
            "Analysis",
            "Options Considered",
            "Recommendation",
            "Implementation Roadmap",
            "KPIs and Risks",
        ),
        instruction="Write an executive-ready decision memo with practical recommendations.",
    ),
    "other": DocumentTemplate(
        name="other",
        label="Custom Document",
        required_sections=(
            "Executive Summary",
            "Overview",
            "Details",
            "Risks and Next Steps",
        ),
        instruction="Write a high-quality document matching the custom specification.",
    ),
}


def get_template(
    name: str,
    custom_label: str | None = None,
    custom_sections: tuple[str, ...] | list[str] | None = None,
) -> DocumentTemplate:
    if name == "other":
        sections = tuple(custom_sections) if custom_sections else (
            "Executive Summary",
            "Overview",
            "Details",
            "Risks and Next Steps",
        )
        return DocumentTemplate(
            name="other",
            label=custom_label or "Custom Document",
            required_sections=sections,
            instruction=f"Write a high-quality {custom_label or 'document'} with the specified sections.",
        )
    return TEMPLATES.get(name, TEMPLATES["prd"])
