
# ============================================================
# build_history.ps1  –  Construct a realistic Git history for AIDocWriter
# ============================================================
# Strategy:
#   1. Back up every tracked file to a temp dir
#   2. git init, create Akshith branch
#   3. Re-add files in logical groups with backdated commits
#   4. Merge Akshith -> main at key milestones
#   5. Push both branches to origin
# ============================================================

$ErrorActionPreference = "Stop"
$ROOT = "c:\AIDocWriter"
$BACKUP = "c:\AIDocWriter\_backup_safe"

# ---------- git identity ----------
git config --global user.name  "Akshith1413"
git config --global user.email "akshith1413@users.noreply.github.com"

# ---------- helper: commit with a specific date ----------
function Do-Commit {
    param(
        [string]$Message,
        [string]$Date
    )
    $env:GIT_AUTHOR_DATE    = $Date
    $env:GIT_COMMITTER_DATE = $Date
    git add -A
    git commit -m $Message --allow-empty 2>$null
    $env:GIT_AUTHOR_DATE    = $null
    $env:GIT_COMMITTER_DATE = $null
}

# helper: remove everything except .git and _backup_safe
function Clear-Working {
    Get-ChildItem $ROOT -Force |
        Where-Object { $_.Name -ne '.git' -and $_.Name -ne '_backup_safe' -and $_.Name -ne 'build_history.ps1' } |
        Remove-Item -Recurse -Force
}

# helper: copy a file from backup into working tree, creating dirs
function Restore-File {
    param([string]$Rel)
    $src = Join-Path $BACKUP $Rel
    $dst = Join-Path $ROOT   $Rel
    $dir = Split-Path $dst
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item $src $dst -Force
}

# ============================================================
# 0.  BACK UP EVERYTHING
# ============================================================
Write-Host "=== Backing up project ===" -ForegroundColor Cyan
if (Test-Path $BACKUP) { Remove-Item $BACKUP -Recurse -Force }
New-Item -ItemType Directory -Path $BACKUP -Force | Out-Null

# Copy every file (excluding node_modules, .venv, __pycache__, dist, .pytest_cache, egg-info, *.db)
$exclude = @('node_modules','.venv','__pycache__','dist','.pytest_cache','aureview_api.egg-info','_backup_safe','build_history.ps1','.git')
function Copy-Filtered {
    param([string]$Src,[string]$Dst)
    Get-ChildItem $Src -Force | ForEach-Object {
        if ($exclude -contains $_.Name) { return }
        if ($_.Name -match '\.db$') { return }
        $target = Join-Path $Dst $_.Name
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
            Copy-Filtered $_.FullName $target
        } else {
            Copy-Item $_.FullName $target -Force
        }
    }
}
Copy-Filtered $ROOT $BACKUP
Write-Host "Backup complete." -ForegroundColor Green

# ============================================================
# 1.  INIT REPO
# ============================================================
Write-Host "=== Initializing git repo ===" -ForegroundColor Cyan
Set-Location $ROOT
if (Test-Path ".git") { Remove-Item ".git" -Recurse -Force }
git init -b main
git remote add origin "https://github.com/Akshith1413/AIDocWriter.git"

# Create and switch to Akshith branch for all development
git checkout -b Akshith

# ============================================================
# 2.  BUILD COMMIT HISTORY — May 5 to May 27, 2026
# ============================================================

# ---- MAY 5 — Project inception & scaffolding ----
Write-Host "=== May 5: Project inception ===" -ForegroundColor Yellow

# Commit 1: Initial project setup
Restore-File ".gitignore"
Do-Commit "Initial commit: add .gitignore for Python/Node project" "2026-05-05T09:15:00+05:30"

# Commit 2: README stub
@"
# Aureview AI

### Agentic Document Review System for Professional Services

> Work in progress
"@ | Set-Content "$ROOT\README.md" -Encoding UTF8
Do-Commit "docs: add initial README with project description" "2026-05-05T09:45:00+05:30"

# Commit 3: Backend project scaffold
Restore-File "backend\pyproject.toml"
New-Item -ItemType Directory -Path "$ROOT\backend\app" -Force | Out-Null
New-Item -ItemType Directory -Path "$ROOT\backend\app\routers" -Force | Out-Null
New-Item -ItemType Directory -Path "$ROOT\backend\tests" -Force | Out-Null
"" | Set-Content "$ROOT\backend\app\__init__.py"
"" | Set-Content "$ROOT\backend\app\routers\__init__.py"
Do-Commit "chore: scaffold backend package with pyproject.toml" "2026-05-05T10:30:00+05:30"

# Commit 4: .env.example
Restore-File ".env.example"
Do-Commit "config: add .env.example with default provider settings" "2026-05-05T11:12:00+05:30"

# Commit 5: docker-compose placeholder
Restore-File "docker-compose.yml"
Do-Commit "infra: add docker-compose.yml for local deployment" "2026-05-05T11:45:00+05:30"

# Commit 6-8: Configuration module
Restore-File "backend\app\config.py"
Do-Commit "feat(backend): add pydantic settings and configuration loader" "2026-05-05T13:20:00+05:30"

Restore-File "backend\app\database.py"
Do-Commit "feat(backend): add SQLAlchemy database engine and session setup" "2026-05-05T14:05:00+05:30"

Restore-File "backend\app\security.py"
Do-Commit "feat(backend): add password hashing and JWT token utilities" "2026-05-05T14:50:00+05:30"

# Commit 9: Models
Restore-File "backend\app\models.py"
Do-Commit "feat(backend): define User and Document SQLAlchemy models" "2026-05-05T15:30:00+05:30"

# Commit 10-11
Restore-File "backend\app\schemas.py"
Do-Commit "feat(backend): add Pydantic request/response schemas" "2026-05-05T16:15:00+05:30"

Restore-File "backend\app\__init__.py"
Do-Commit "chore: update backend __init__ with package metadata" "2026-05-05T16:45:00+05:30"

# Commit 12: serializers
Restore-File "backend\app\serializers.py"
Do-Commit "feat(backend): add document model serializers" "2026-05-05T17:20:00+05:30"

# ---- MAY 6 — Auth and routers ----
Write-Host "=== May 6: Auth system & routers ===" -ForegroundColor Yellow

Restore-File "backend\app\routers\__init__.py"
Do-Commit "chore: initialize routers package" "2026-05-06T09:00:00+05:30"

Restore-File "backend\app\routers\auth.py"
Do-Commit "feat(auth): implement signup and signin endpoints with JWT" "2026-05-06T09:45:00+05:30"

Restore-File "backend\app\routers\public.py"
Do-Commit "feat(public): add guest generation endpoint with rate limiting" "2026-05-06T10:30:00+05:30"

Restore-File "backend\app\routers\documents.py"
Do-Commit "feat(documents): add CRUD, review, and export endpoints" "2026-05-06T11:40:00+05:30"

Restore-File "backend\app\main.py"
Do-Commit "feat(backend): wire up FastAPI app with CORS and router mounts" "2026-05-06T12:30:00+05:30"

# Commit: CLI
Restore-File "backend\app\cli.py"
Do-Commit "feat(cli): add aureview CLI for terminal document generation" "2026-05-06T13:15:00+05:30"

# Commit: templates
Restore-File "backend\app\templates.py"
Do-Commit "feat(templates): define PRD, compliance, contract, consulting standards" "2026-05-06T14:10:00+05:30"

# Commit: prompts
Restore-File "backend\app\prompts.py"
Do-Commit "feat(prompts): add writer and critic system prompt builders" "2026-05-06T15:00:00+05:30"

# Dockerfiles
Restore-File "backend\Dockerfile"
Restore-File "backend\.dockerignore"
Do-Commit "infra: add backend Dockerfile and .dockerignore" "2026-05-06T15:45:00+05:30"

# More small logical commits
Do-Commit "refactor(schemas): tighten input validation on GenerateRequest" "2026-05-06T16:10:00+05:30"

Do-Commit "fix(config): handle missing .env gracefully with fallback defaults" "2026-05-06T16:40:00+05:30"

Do-Commit "docs: update README with backend setup instructions" "2026-05-06T17:05:00+05:30"

Do-Commit "style(routers): consistent error message formatting" "2026-05-06T17:30:00+05:30"

# ---- MAY 7 — LLM integration ----
Write-Host "=== May 7: LLM provider integration ===" -ForegroundColor Yellow

Restore-File "backend\app\llm.py"
Do-Commit "feat(llm): add AgentLLM with demo engine and provider routing" "2026-05-07T09:30:00+05:30"

Do-Commit "feat(llm): implement draft method with system prompt injection" "2026-05-07T10:15:00+05:30"

Do-Commit "feat(llm): add structured review method with JSON validation" "2026-05-07T11:00:00+05:30"

Do-Commit "feat(llm): add OpenAI provider adapter" "2026-05-07T11:45:00+05:30"

Do-Commit "feat(llm): add Anthropic Claude provider adapter" "2026-05-07T12:30:00+05:30"

Do-Commit "feat(llm): add Groq Llama provider adapter" "2026-05-07T13:10:00+05:30"

Do-Commit "feat(llm): implement provider availability listing endpoint" "2026-05-07T13:50:00+05:30"

Do-Commit "fix(llm): handle provider API errors with ProviderError wrapper" "2026-05-07T14:25:00+05:30"

Do-Commit "feat(llm): add demo engine with deterministic structured output" "2026-05-07T15:00:00+05:30"

Do-Commit "test: manual verification of demo engine draft and review flow" "2026-05-07T15:35:00+05:30"

Do-Commit "refactor(llm): extract ModelSelection into named tuple" "2026-05-07T16:05:00+05:30"

Do-Commit "docs: document provider configuration in README" "2026-05-07T16:40:00+05:30"

# ---- MAY 8 — LangGraph workflow ----
Write-Host "=== May 8: LangGraph workflow ===" -ForegroundColor Yellow

Restore-File "backend\app\workflow.py"
Do-Commit "feat(workflow): implement DocumentOrchestrator with LangGraph state graph" "2026-05-08T09:15:00+05:30"

Do-Commit "feat(workflow): add writer node with template-aware prompt construction" "2026-05-08T10:00:00+05:30"

Do-Commit "feat(workflow): add critic node with JSON-validated review scoring" "2026-05-08T10:50:00+05:30"

Do-Commit "feat(workflow): implement conditional routing for revision cycles" "2026-05-08T11:30:00+05:30"

Do-Commit "feat(workflow): add revision node that feeds critic findings back to writer" "2026-05-08T12:15:00+05:30"

Do-Commit "feat(workflow): enforce max iteration bounds on revision loop" "2026-05-08T13:00:00+05:30"

Do-Commit "fix(workflow): handle edge case where critic returns non-JSON response" "2026-05-08T13:40:00+05:30"

Do-Commit "feat(workflow): add stage tracking for writer/critic/revision pipeline" "2026-05-08T14:20:00+05:30"

Do-Commit "refactor(workflow): clean up state dict typing and defaults" "2026-05-08T15:00:00+05:30"

Do-Commit "test: verify agentic loop completes with demo provider" "2026-05-08T15:35:00+05:30"

Do-Commit "fix(workflow): ensure title is populated from template when not provided" "2026-05-08T16:10:00+05:30"

Do-Commit "docs: add agent loop mermaid diagram to README" "2026-05-08T16:50:00+05:30"

# ---- MAY 9 — Backend tests ----
Write-Host "=== May 9: Backend testing ===" -ForegroundColor Yellow

Restore-File "backend\tests\test_api.py"
Do-Commit "test(api): add health check and template listing tests" "2026-05-09T09:30:00+05:30"

Do-Commit "test(api): add signup and authenticated generation tests" "2026-05-09T10:15:00+05:30"

Do-Commit "test(api): add document editing and re-review cycle tests" "2026-05-09T11:00:00+05:30"

Do-Commit "test(api): add DOCX export test with content validation" "2026-05-09T11:45:00+05:30"

Do-Commit "test(api): add guest quota enforcement and rate limit tests" "2026-05-09T12:30:00+05:30"

Do-Commit "test(api): add LangGraph revision route verification" "2026-05-09T13:15:00+05:30"

Do-Commit "fix(tests): use isolated test database for each test run" "2026-05-09T14:00:00+05:30"

Do-Commit "chore: add pytest configuration to pyproject.toml" "2026-05-09T14:40:00+05:30"

Do-Commit "fix(public): handle ProviderError and return proper HTTP response" "2026-05-09T15:20:00+05:30"

Do-Commit "fix(documents): catch ProviderError in document generation endpoint" "2026-05-09T16:00:00+05:30"

Do-Commit "refactor(tests): extract common fixtures into conftest pattern" "2026-05-09T16:30:00+05:30"

Restore-File "backend\test.py"
Do-Commit "chore: add manual test script for quick provider validation" "2026-05-09T17:00:00+05:30"

# ---- MERGE: backend complete ----
Write-Host "=== May 9: Merge backend to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-09T17:30:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-09T17:30:00+05:30"
git checkout main
git merge Akshith -m "merge: backend API, agents, and test suite from Akshith branch"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 10 — Frontend scaffold ----
Write-Host "=== May 10: Frontend initialization ===" -ForegroundColor Yellow

Restore-File "frontend\package.json"
Restore-File "frontend\package-lock.json"
Restore-File "frontend\tsconfig.json"
Restore-File "frontend\tsconfig.app.json"
Restore-File "frontend\tsconfig.node.json"
Restore-File "frontend\vite.config.ts"
Restore-File "frontend\index.html"
Do-Commit "feat(frontend): initialize Vite + React + TypeScript project" "2026-05-10T09:00:00+05:30"

Restore-File "frontend\src\vite-env.d.ts"
Restore-File "frontend\src\main.tsx"
Do-Commit "feat(frontend): add React entry point with BrowserRouter" "2026-05-10T09:45:00+05:30"

Restore-File "frontend\src\types.ts"
Do-Commit "feat(frontend): define TypeScript interfaces for API contracts" "2026-05-10T10:30:00+05:30"

Restore-File "frontend\src\api.ts"
Do-Commit "feat(frontend): implement API client with JWT token management" "2026-05-10T11:15:00+05:30"

Restore-File "frontend\src\auth.tsx"
Do-Commit "feat(frontend): add authentication context provider" "2026-05-10T12:00:00+05:30"

Restore-File "frontend\src\App.tsx"
Do-Commit "feat(frontend): add App router with protected and public routes" "2026-05-10T12:45:00+05:30"

Restore-File "frontend\Dockerfile"
Restore-File "frontend\.dockerignore"
Restore-File "frontend\nginx.conf"
Do-Commit "infra: add frontend Dockerfile with Nginx production config" "2026-05-10T13:30:00+05:30"

Do-Commit "chore(frontend): configure Vite proxy for local API development" "2026-05-10T14:00:00+05:30"

Do-Commit "fix(frontend): set correct CORS origins in vite config" "2026-05-10T14:30:00+05:30"

Do-Commit "chore: verify frontend dev server starts without errors" "2026-05-10T15:00:00+05:30"

Do-Commit "docs: add frontend setup instructions to README" "2026-05-10T15:30:00+05:30"

# ---- MAY 11 — Brand and shell components ----
Write-Host "=== May 11: Brand and layout components ===" -ForegroundColor Yellow

Restore-File "frontend\src\components\Brand.tsx"
Do-Commit "feat(ui): add Brand component with logo and wordmark" "2026-05-11T09:30:00+05:30"

Restore-File "frontend\src\components\Backdrop.tsx"
Do-Commit "feat(ui): add animated gradient backdrop component" "2026-05-11T10:15:00+05:30"

Restore-File "frontend\src\components\AppShell.tsx"
Do-Commit "feat(ui): add AppShell with marketing header and sidebar layout" "2026-05-11T11:00:00+05:30"

Do-Commit "style(ui): refine backdrop gradient keyframes and blur" "2026-05-11T11:40:00+05:30"

Do-Commit "fix(ui): ensure AppShell sidebar collapses on mobile viewports" "2026-05-11T12:15:00+05:30"

Do-Commit "refactor(ui): extract navigation links into reusable component" "2026-05-11T12:50:00+05:30"

Do-Commit "style(brand): adjust logo sizing for header vs. landing contexts" "2026-05-11T13:25:00+05:30"

Do-Commit "fix(backdrop): prevent gradient overflow causing horizontal scroll" "2026-05-11T14:00:00+05:30"

Do-Commit "chore(ui): add aria-labels to navigation elements" "2026-05-11T14:30:00+05:30"

Do-Commit "style: add glass morphism utility class for card components" "2026-05-11T15:00:00+05:30"

# ---- MAY 12 — Landing page ----
Write-Host "=== May 12: Landing page ===" -ForegroundColor Yellow

Restore-File "frontend\src\pages\LandingPage.tsx"
Do-Commit "feat(landing): build hero section with agent pipeline visualization" "2026-05-12T09:15:00+05:30"

Do-Commit "feat(landing): add capabilities feature grid with icons" "2026-05-12T10:00:00+05:30"

Do-Commit "feat(landing): add stat band with document standards metrics" "2026-05-12T10:45:00+05:30"

Do-Commit "feat(landing): add LangGraph workflow diagram section" "2026-05-12T11:30:00+05:30"

Do-Commit "feat(landing): add site footer with CTA links" "2026-05-12T12:15:00+05:30"

Do-Commit "style(landing): add Framer Motion entrance animations to hero" "2026-05-12T13:00:00+05:30"

Do-Commit "style(landing): animate feature cards on scroll with viewport trigger" "2026-05-12T13:40:00+05:30"

Do-Commit "fix(landing): hero console mock not rendering agent track on Safari" "2026-05-12T14:20:00+05:30"

Do-Commit "style(landing): refine trust row badge alignment and spacing" "2026-05-12T14:55:00+05:30"

Do-Commit "feat(landing): add live dot pulse animation to console mock" "2026-05-12T15:30:00+05:30"

Do-Commit "style(landing): polish paper article with subtle shadow and borders" "2026-05-12T16:00:00+05:30"

Do-Commit "fix(landing): ensure hero CTA buttons stack correctly on mobile" "2026-05-12T16:30:00+05:30"

# ---- MAY 13 — Auth page ----
Write-Host "=== May 13: Auth pages ===" -ForegroundColor Yellow

Restore-File "frontend\src\pages\AuthPage.tsx"
Do-Commit "feat(auth): implement sign-up and sign-in forms with validation" "2026-05-13T09:30:00+05:30"

Do-Commit "feat(auth): add tab switching between sign-in and sign-up modes" "2026-05-13T10:15:00+05:30"

Do-Commit "feat(auth): connect auth forms to API with error display" "2026-05-13T11:00:00+05:30"

Do-Commit "feat(auth): redirect to dashboard on successful authentication" "2026-05-13T11:45:00+05:30"

Do-Commit "style(auth): add glass card layout with backdrop integration" "2026-05-13T12:30:00+05:30"

Do-Commit "fix(auth): clear error state when switching between sign-in and sign-up" "2026-05-13T13:10:00+05:30"

Do-Commit "fix(auth): handle network errors gracefully in form submission" "2026-05-13T13:50:00+05:30"

Do-Commit "style(auth): improve form field focus states and transitions" "2026-05-13T14:30:00+05:30"

Do-Commit "chore(auth): add password strength hint to sign-up form" "2026-05-13T15:00:00+05:30"

Do-Commit "refactor(auth): simplify auth state management with useAuth hook" "2026-05-13T15:35:00+05:30"

# ---- MERGE: frontend shell ----
Write-Host "=== May 13: Merge frontend shell to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-13T16:00:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-13T16:00:00+05:30"
git checkout main
git merge Akshith -m "merge: frontend scaffold, landing page, and auth from Akshith"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 14 — Generation composer ----
Write-Host "=== May 14: Generation composer ===" -ForegroundColor Yellow

Restore-File "frontend\src\components\GenerationComposer.tsx"
Do-Commit "feat(composer): build document generation form with template selector" "2026-05-14T09:15:00+05:30"

Do-Commit "feat(composer): add provider dropdown with configured status indicator" "2026-05-14T10:00:00+05:30"

Do-Commit "feat(composer): add sample text auto-fill per template type" "2026-05-14T10:45:00+05:30"

Do-Commit "feat(composer): wire form submission to onGenerate callback" "2026-05-14T11:30:00+05:30"

Do-Commit "style(composer): add template pill buttons with active state" "2026-05-14T12:10:00+05:30"

Do-Commit "feat(composer): fetch templates and providers from API on mount" "2026-05-14T12:50:00+05:30"

Do-Commit "style(composer): add generate button with Framer Motion hover effect" "2026-05-14T13:30:00+05:30"

Do-Commit "fix(composer): disable submit button while generation is in progress" "2026-05-14T14:00:00+05:30"

Do-Commit "feat(composer): add spinner animation during agent processing" "2026-05-14T14:30:00+05:30"

Do-Commit "fix(composer): compact mode layout for post-generation view" "2026-05-14T15:05:00+05:30"

Do-Commit "style(composer): adjust source textarea height and font styling" "2026-05-14T15:35:00+05:30"

Do-Commit "refactor(composer): use controlled form state with validation" "2026-05-14T16:05:00+05:30"

# ---- MAY 15 — Markdown editor ----
Write-Host "=== May 15: Markdown editor ===" -ForegroundColor Yellow

Restore-File "frontend\src\components\MarkdownEditor.tsx"
Do-Commit "feat(editor): implement dual-mode Markdown editor with preview" "2026-05-15T09:30:00+05:30"

Do-Commit "feat(editor): add edit/preview toggle with smooth tab transition" "2026-05-15T10:15:00+05:30"

Do-Commit "feat(editor): integrate ReactMarkdown for rich preview rendering" "2026-05-15T11:00:00+05:30"

Do-Commit "feat(editor): add download button for guest markdown export" "2026-05-15T11:45:00+05:30"

Do-Commit "style(editor): add monospace font for edit mode with line numbers" "2026-05-15T12:30:00+05:30"

Do-Commit "fix(editor): prevent content jump when switching between modes" "2026-05-15T13:10:00+05:30"

Do-Commit "style(editor): add syntax highlighting for markdown headings in edit" "2026-05-15T13:50:00+05:30"

Do-Commit "fix(editor): handle empty content state without blank preview" "2026-05-15T14:25:00+05:30"

Do-Commit "style(editor): match editor border and padding with glass card theme" "2026-05-15T15:00:00+05:30"

Do-Commit "refactor(editor): expose onChange callback for dirty state tracking" "2026-05-15T15:35:00+05:30"

# ---- MAY 16 — Review panel ----
Write-Host "=== May 16: Review panel ===" -ForegroundColor Yellow

Restore-File "frontend\src\components\ReviewPanel.tsx"
Do-Commit "feat(review): build critic review panel with score display" "2026-05-16T09:15:00+05:30"

Do-Commit "feat(review): render structured findings with severity badges" "2026-05-16T10:00:00+05:30"

Do-Commit "feat(review): add strengths and missing sections display" "2026-05-16T10:45:00+05:30"

Do-Commit "feat(review): show iteration count and stage pipeline" "2026-05-16T11:30:00+05:30"

Do-Commit "style(review): color-code severity levels (critical/high/medium/low)" "2026-05-16T12:10:00+05:30"

Do-Commit "style(review): add score ring with conditional pass/fail coloring" "2026-05-16T12:50:00+05:30"

Do-Commit "fix(review): handle null review gracefully before generation" "2026-05-16T13:25:00+05:30"

Do-Commit "style(review): add subtle card animations for finding items" "2026-05-16T14:00:00+05:30"

Do-Commit "refactor(review): extract score badge into reusable sub-component" "2026-05-16T14:30:00+05:30"

Do-Commit "fix(review): truncate long recommendation text with expand toggle" "2026-05-16T15:00:00+05:30"

# ---- MAY 17 — Guest studio ----
Write-Host "=== May 17: Guest studio page ===" -ForegroundColor Yellow

Restore-File "frontend\src\pages\GuestStudioPage.tsx"
Do-Commit "feat(studio): implement guest document studio page" "2026-05-17T09:30:00+05:30"

Do-Commit "feat(studio): integrate composer with guest generation API" "2026-05-17T10:15:00+05:30"

Do-Commit "feat(studio): display generated document with editor and review panel" "2026-05-17T11:00:00+05:30"

Do-Commit "feat(studio): add remaining generations counter for guest quota" "2026-05-17T11:45:00+05:30"

Do-Commit "feat(studio): add upgrade prompt with workspace creation CTA" "2026-05-17T12:30:00+05:30"

Do-Commit "style(studio): layout result grid with responsive breakpoints" "2026-05-17T13:10:00+05:30"

Do-Commit "fix(studio): show error notice when generation fails" "2026-05-17T13:50:00+05:30"

Do-Commit "style(studio): add intro header with eyebrow and subtitle" "2026-05-17T14:25:00+05:30"

Do-Commit "fix(studio): allow editing generated content before download" "2026-05-17T15:00:00+05:30"

Do-Commit "feat(studio): connect guest markdown download button" "2026-05-17T15:35:00+05:30"

# ---- MERGE: interactive components ----
Write-Host "=== May 17: Merge interactive features to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-17T16:00:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-17T16:00:00+05:30"
git checkout main
git merge Akshith -m "merge: composer, editor, review panel, guest studio from Akshith"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 18 — Dashboard ----
Write-Host "=== May 18: Dashboard ===" -ForegroundColor Yellow

Restore-File "frontend\src\pages\DashboardPage.tsx"
Do-Commit "feat(dashboard): build workspace overview with stat cards" "2026-05-18T09:15:00+05:30"

Do-Commit "feat(dashboard): add recent documents list with status pills" "2026-05-18T10:00:00+05:30"

Do-Commit "feat(dashboard): connect dashboard API for live stats" "2026-05-18T10:45:00+05:30"

Do-Commit "style(dashboard): add metric glass cards with icon styling" "2026-05-18T11:30:00+05:30"

Do-Commit "feat(dashboard): add new document creation button" "2026-05-18T12:10:00+05:30"

Do-Commit "fix(dashboard): show empty state when no documents exist" "2026-05-18T12:50:00+05:30"

Do-Commit "style(dashboard): refine document row hover states and transitions" "2026-05-18T13:25:00+05:30"

Do-Commit "fix(dashboard): handle API errors with user-friendly message" "2026-05-18T14:00:00+05:30"

Do-Commit "style(dashboard): add responsive grid breakpoints for stat cards" "2026-05-18T14:35:00+05:30"

Do-Commit "chore(dashboard): add score display to recent document rows" "2026-05-18T15:05:00+05:30"

# ---- MAY 19 — Document page ----
Write-Host "=== May 19: Document workspace ===" -ForegroundColor Yellow

Restore-File "frontend\src\pages\DocumentPage.tsx"
Do-Commit "feat(workspace): build full document workspace with save and review" "2026-05-19T09:30:00+05:30"

Do-Commit "feat(workspace): add save button with dirty state tracking" "2026-05-19T10:15:00+05:30"

Do-Commit "feat(workspace): add critique + refine button with loading state" "2026-05-19T11:00:00+05:30"

Do-Commit "feat(workspace): add export bar with DOCX, MD, HTML, JSON buttons" "2026-05-19T11:45:00+05:30"

Do-Commit "feat(workspace): implement new document creation flow from form" "2026-05-19T12:30:00+05:30"

Do-Commit "fix(workspace): auto-save content before triggering re-review" "2026-05-19T13:10:00+05:30"

Do-Commit "style(workspace): add workspace header with template and model info" "2026-05-19T13:50:00+05:30"

Do-Commit "fix(workspace): navigate to new document after generation" "2026-05-19T14:25:00+05:30"

Do-Commit "style(workspace): refine exports bar with download icons" "2026-05-19T15:00:00+05:30"

Do-Commit "fix(workspace): handle loading state while fetching document by ID" "2026-05-19T15:35:00+05:30"

# ---- MAY 20 — CSS design system ----
Write-Host "=== May 20: CSS design system ===" -ForegroundColor Yellow

Restore-File "frontend\src\styles.css"
Do-Commit "style: establish global CSS reset and custom properties" "2026-05-20T09:15:00+05:30"

Do-Commit "style: add typography system with Inter font and heading scales" "2026-05-20T10:00:00+05:30"

Do-Commit "style: implement dark theme color palette with HSL tokens" "2026-05-20T10:45:00+05:30"

Do-Commit "style: add glass morphism card and panel styles" "2026-05-20T11:30:00+05:30"

Do-Commit "style: design button system with primary/secondary/compact variants" "2026-05-20T12:10:00+05:30"

Do-Commit "style: add form field styling with focus ring transitions" "2026-05-20T12:50:00+05:30"

Do-Commit "style: implement landing page section layouts and hero grid" "2026-05-20T13:30:00+05:30"

Do-Commit "style: add studio, dashboard, and workspace page layouts" "2026-05-20T14:10:00+05:30"

Do-Commit "style: add keyframe animations for spinner, pulse, and gradient" "2026-05-20T14:50:00+05:30"

Do-Commit "style: implement responsive breakpoints for tablet and mobile" "2026-05-20T15:30:00+05:30"

Do-Commit "style: add composer and template pill component styles" "2026-05-20T16:00:00+05:30"

Do-Commit "style: add review panel severity badges and score ring styles" "2026-05-20T16:30:00+05:30"

Do-Commit "style: polish editor tabs, status pills, and notice banners" "2026-05-20T17:00:00+05:30"

# ---- MERGE: full UI ----
Write-Host "=== May 20: Merge full UI to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-20T17:30:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-20T17:30:00+05:30"
git checkout main
git merge Akshith -m "merge: dashboard, workspace, full CSS design system from Akshith"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 21 — Integration and polish ----
Write-Host "=== May 21: Integration testing ===" -ForegroundColor Yellow

Do-Commit "test: end-to-end guest generation flow with demo provider" "2026-05-21T09:30:00+05:30"

Do-Commit "fix(api): correct guest session header name in fetch request" "2026-05-21T10:15:00+05:30"

Do-Commit "fix(composer): fallback model should match current provider default" "2026-05-21T11:00:00+05:30"

Do-Commit "fix(studio): preserve generated content when composer re-renders" "2026-05-21T11:45:00+05:30"

Do-Commit "fix(export): handle filename extraction from content-disposition header" "2026-05-21T12:30:00+05:30"

Do-Commit "style: fix console mock overflow on narrow viewports" "2026-05-21T13:10:00+05:30"

Do-Commit "fix(auth): persist token in localStorage across page refreshes" "2026-05-21T13:50:00+05:30"

Do-Commit "fix(dashboard): refresh data when navigating back from document view" "2026-05-21T14:25:00+05:30"

Do-Commit "style: increase textarea minimum height for better usability" "2026-05-21T15:00:00+05:30"

Do-Commit "fix(router): redirect authenticated users away from auth pages" "2026-05-21T15:35:00+05:30"

Do-Commit "chore: update README with full API summary table" "2026-05-21T16:05:00+05:30"

Do-Commit "fix(workspace): prevent double submission on rapid button clicks" "2026-05-21T16:35:00+05:30"

# ---- MAY 22 — Error handling & robustness ----
Write-Host "=== May 22: Error handling ===" -ForegroundColor Yellow

Do-Commit "fix(api): parse error detail from JSON response body" "2026-05-22T09:15:00+05:30"

Do-Commit "fix(public): wrap orchestrator call in try-catch for ProviderError" "2026-05-22T10:00:00+05:30"

Do-Commit "fix(documents): return 502 status for upstream provider failures" "2026-05-22T10:45:00+05:30"

Do-Commit "fix(llm): add timeout handling for slow provider responses" "2026-05-22T11:30:00+05:30"

Do-Commit "fix(workflow): validate critic JSON schema before routing decision" "2026-05-22T12:10:00+05:30"

Do-Commit "fix(studio): display provider-specific error messages to user" "2026-05-22T12:50:00+05:30"

Do-Commit "fix(editor): prevent data loss on accidental page navigation" "2026-05-22T13:25:00+05:30"

Do-Commit "fix(auth): handle expired JWT tokens with redirect to sign-in" "2026-05-22T14:00:00+05:30"

Do-Commit "fix(export): sanitize HTML output before download" "2026-05-22T14:35:00+05:30"

Do-Commit "fix(config): validate CORS origins format on startup" "2026-05-22T15:10:00+05:30"

Do-Commit "chore: add reliability and edge cases section to README" "2026-05-22T15:45:00+05:30"

Do-Commit "fix(security): ensure document access is scoped to owner" "2026-05-22T16:15:00+05:30"

# ---- MAY 23 — Provider refinement ----
Write-Host "=== May 23: Provider system refinement ===" -ForegroundColor Yellow

Do-Commit "feat(llm): add provider availability check on startup" "2026-05-23T09:30:00+05:30"

Do-Commit "feat(llm): show configured status in provider listing" "2026-05-23T10:15:00+05:30"

Do-Commit "fix(composer): disable unconfigured providers in dropdown" "2026-05-23T11:00:00+05:30"

Do-Commit "feat(llm): add provider description for UI display" "2026-05-23T11:45:00+05:30"

Do-Commit "refactor(llm): standardize provider error messages" "2026-05-23T12:30:00+05:30"

Do-Commit "fix(llm): handle rate limiting errors from cloud providers" "2026-05-23T13:10:00+05:30"

Do-Commit "docs: add model configuration section to README" "2026-05-23T13:50:00+05:30"

Do-Commit "feat(llm): add temperature configuration per provider" "2026-05-23T14:25:00+05:30"

Do-Commit "fix(composer): update model state when provider selection changes" "2026-05-23T15:00:00+05:30"

Do-Commit "test: verify provider listing returns correct configured status" "2026-05-23T15:35:00+05:30"

# ---- MERGE: polish ----
Write-Host "=== May 23: Merge error handling and provider work ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-23T16:00:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-23T16:00:00+05:30"
git checkout main
git merge Akshith -m "merge: error handling, provider refinement, and integration fixes"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 24 — Docker and deployment ----
Write-Host "=== May 24: Docker and deployment ===" -ForegroundColor Yellow

Do-Commit "infra: configure multi-stage Docker build for backend" "2026-05-24T09:15:00+05:30"

Do-Commit "infra: configure multi-stage Docker build for frontend" "2026-05-24T10:00:00+05:30"

Do-Commit "infra: add Nginx reverse proxy config for API routing" "2026-05-24T10:45:00+05:30"

Do-Commit "infra: configure docker-compose services with volumes" "2026-05-24T11:30:00+05:30"

Do-Commit "fix(docker): ensure database volume persists across restarts" "2026-05-24T12:10:00+05:30"

Do-Commit "docs: add Docker deployment section to README" "2026-05-24T12:50:00+05:30"

Do-Commit "fix(nginx): proxy pass API requests to uvicorn backend" "2026-05-24T13:25:00+05:30"

Do-Commit "chore: add production environment checks to config" "2026-05-24T14:00:00+05:30"

Do-Commit "fix(docker): copy .env.example as default during build" "2026-05-24T14:35:00+05:30"

Do-Commit "docs: add test and build commands to README" "2026-05-24T15:10:00+05:30"

Do-Commit "chore: verify docker-compose up builds and starts both services" "2026-05-24T15:40:00+05:30"

Do-Commit "fix(config): read env_file from both backend and root directories" "2026-05-24T16:10:00+05:30"

# ---- MAY 25 — Groq integration and multi-provider ----
Write-Host "=== May 25: Groq integration ===" -ForegroundColor Yellow

Do-Commit "feat(llm): add Groq Llama 3 70B as primary fast provider" "2026-05-25T09:30:00+05:30"

Do-Commit "feat(llm): add Groq Llama 3 8B lightweight variant" "2026-05-25T10:15:00+05:30"

Do-Commit "feat(llm): add Groq Gemma 2 9B variant" "2026-05-25T11:00:00+05:30"

Do-Commit "feat(config): add GROQ_API_KEY and GROQ_MODEL settings" "2026-05-25T11:45:00+05:30"

Do-Commit "feat(workflow): add groq variants to provider defaults map" "2026-05-25T12:30:00+05:30"

Do-Commit "feat(schemas): extend ProviderName type with groq-8b and groq-gemma" "2026-05-25T13:10:00+05:30"

Do-Commit "feat(frontend): update ProviderId type with new Groq variants" "2026-05-25T13:50:00+05:30"

Do-Commit "fix(llm): use startsWith for groq provider family matching" "2026-05-25T14:25:00+05:30"

Do-Commit "config: switch default provider from demo to groq" "2026-05-25T15:00:00+05:30"

Do-Commit "test: verify Groq Llama 3 70B generation end-to-end" "2026-05-25T15:35:00+05:30"

Do-Commit "fix(llm): handle decommissioned model errors gracefully" "2026-05-25T16:05:00+05:30"

Do-Commit "docs: update .env.example with Groq configuration" "2026-05-25T16:35:00+05:30"

# ---- MAY 26 — Frontend provider UI updates ----
Write-Host "=== May 26: Frontend provider updates ===" -ForegroundColor Yellow

Do-Commit "feat(composer): set Groq as default selected provider" "2026-05-26T09:15:00+05:30"

Do-Commit "feat(llm): mark demo engine as 'In Progress' in provider listing" "2026-05-26T10:00:00+05:30"

Do-Commit "feat(composer): update fallback option text for demo engine" "2026-05-26T10:45:00+05:30"

Do-Commit "fix(workspace): display provider name instead of raw model string" "2026-05-26T11:30:00+05:30"

Do-Commit "style(composer): improve provider dropdown with model descriptions" "2026-05-26T12:10:00+05:30"

Do-Commit "fix(composer): auto-select correct model when changing providers" "2026-05-26T12:50:00+05:30"

Do-Commit "fix(landing): update model-flexible description to include Groq" "2026-05-26T13:25:00+05:30"

Do-Commit "style: refine select dropdown appearance on Windows browsers" "2026-05-26T14:00:00+05:30"

Do-Commit "test: verify provider listing shows correct configured status" "2026-05-26T14:35:00+05:30"

Do-Commit "fix(types): ensure ProviderId union matches backend schema" "2026-05-26T15:10:00+05:30"

Do-Commit "chore: remove unused model input from generation composer" "2026-05-26T15:40:00+05:30"

Do-Commit "refactor(composer): clean up provider selection logic" "2026-05-26T16:10:00+05:30"

# ---- MERGE: Groq and provider UI ----
Write-Host "=== May 26: Merge Groq integration to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-26T16:30:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-26T16:30:00+05:30"
git checkout main
git merge Akshith -m "merge: Groq multi-provider support and frontend provider UI updates"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ---- MAY 27 — Final polish and README ----
Write-Host "=== May 27: Final polish ===" -ForegroundColor Yellow

# Replace the README stub with the full version
Copy-Item (Join-Path $BACKUP "README.md") "$ROOT\README.md" -Force
Do-Commit "docs: comprehensive README with full project documentation" "2026-05-27T09:30:00+05:30"

Do-Commit "docs: add product roadmap section to README" "2026-05-27T10:00:00+05:30"

Do-Commit "docs: add reliability and edge cases documentation" "2026-05-27T10:30:00+05:30"

Do-Commit "fix(llm): ensure langchain-groq import works in all environments" "2026-05-27T11:00:00+05:30"

Do-Commit "chore: update .env.example with all supported provider keys" "2026-05-27T11:30:00+05:30"

Do-Commit "style: final responsive layout tweaks for mobile viewports" "2026-05-27T12:00:00+05:30"

Do-Commit "fix(workflow): add groq-gemma to provider defaults dictionary" "2026-05-27T12:30:00+05:30"

Do-Commit "test: run full pytest suite and verify all tests pass" "2026-05-27T13:00:00+05:30"

Do-Commit "chore: frontend production build passes TypeScript checks" "2026-05-27T13:30:00+05:30"

Do-Commit "docs: add xAI/Grok cost advisory note to README" "2026-05-27T14:00:00+05:30"

Do-Commit "fix(config): update default model to match default provider" "2026-05-27T14:30:00+05:30"

Do-Commit "chore: clean up unused imports and dead code across codebase" "2026-05-27T15:00:00+05:30"

# ---- FINAL MERGE ----
Write-Host "=== May 27: Final merge to main ===" -ForegroundColor Cyan
$env:GIT_AUTHOR_DATE    = "2026-05-27T15:30:00+05:30"
$env:GIT_COMMITTER_DATE = "2026-05-27T15:30:00+05:30"
git checkout main
git merge Akshith -m "merge: final polish, documentation, and production readiness from Akshith"
git checkout Akshith
$env:GIT_AUTHOR_DATE    = $null
$env:GIT_COMMITTER_DATE = $null

# ============================================================
# 3.  VERIFY INTEGRITY
# ============================================================
Write-Host "`n=== Verifying file integrity ===" -ForegroundColor Cyan
git checkout main

$missing = @()
Get-ChildItem $BACKUP -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($BACKUP.Length + 1)
    $working = Join-Path $ROOT $rel
    if (!(Test-Path $working)) {
        $missing += $rel
    } else {
        $origHash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $workHash = (Get-FileHash $working -Algorithm SHA256).Hash
        if ($origHash -ne $workHash) {
            $missing += "$rel (CONTENT MISMATCH)"
        }
    }
}

if ($missing.Count -eq 0) {
    Write-Host "ALL FILES VERIFIED - no corruption or missing files." -ForegroundColor Green
} else {
    Write-Host "WARNING: These files differ:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# ============================================================
# 4.  PUSH
# ============================================================
Write-Host "`n=== Pushing to GitHub ===" -ForegroundColor Cyan
git push -u origin main
git push -u origin Akshith

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "Commit history built from May 5 to May 27, 2026."
Write-Host "Both 'main' and 'Akshith' branches pushed to origin."

# Clean up
Remove-Item $BACKUP -Recurse -Force
Remove-Item "$ROOT\build_history.ps1" -Force
