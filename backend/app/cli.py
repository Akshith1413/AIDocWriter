import asyncio
from pathlib import Path
from typing import Annotated

import typer
from rich.console import Console
from rich.markdown import Markdown

from .schemas import GenerateRequest
from .workflow import DocumentOrchestrator

app = typer.Typer(help="Generate and review professional documents from the terminal.")
console = Console()


@app.callback()
def main() -> None:
    """Aureview AI command-line document workflow."""


@app.command()
def generate(
    notes: Annotated[str, typer.Argument(help="Raw notes or bullet points to transform.")],
    template: Annotated[str, typer.Option(help="prd, compliance, contract, or consulting.")] = "prd",
    title: Annotated[str | None, typer.Option(help="Document title.")] = None,
    provider: Annotated[str, typer.Option(help="demo, openai, anthropic, or xai.")] = "demo",
    model: Annotated[str | None, typer.Option(help="Provider model override.")] = None,
    output: Annotated[Path | None, typer.Option(help="Optional Markdown output path.")] = None,
) -> None:
    """Run the Writer and Critic workflow from a terminal."""
    request = GenerateRequest(
        title=title,
        input_text=notes,
        template=template,
        provider=provider,
        model=model,
    )
    result = asyncio.run(DocumentOrchestrator(request).generate())
    if output:
        output.write_text(result.content_md, encoding="utf-8")
        console.print(f"[green]Saved[/green] {output}")
    else:
        console.print(Markdown(result.content_md))
    console.print(
        f"\n[bold]Review:[/bold] {result.review.status} | "
        f"score {result.review.score}/100 | cycles {result.iteration_count}"
    )


if __name__ == "__main__":
    app()
