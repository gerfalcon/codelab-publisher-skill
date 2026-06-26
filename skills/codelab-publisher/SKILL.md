---
name: codelab-publisher
description: Build a Google Codelab from scratch using the claat tool and publish it to GitHub Pages via the gh CLI. Trigger this skill whenever the user wants to create a codelab, write a step-by-step interactive tutorial, build a Google Codelab, publish a tutorial to GitHub Pages, use claat, or mentions "Google Codelabs", "googlecodelabs", or "codelabs.developers.google.com". Also use this skill when the user only says something like "I want to build a tutorial", "let's make a guided walkthrough", or "turn this README into a step-by-step lesson" — the codelab format is the right vehicle for those, and this skill produces the polished result with progress tracking, syntax-highlighted code, and the familiar codelabs.developers.google.com look. The skill always starts with a structured brainstorming phase (topic, audience, difficulty, length, supporting resources) before writing any content; do not skip it.
---

# Codelab Publisher

End-to-end workflow for authoring a Google Codelab in markdown, building it with `claat`, and publishing it to GitHub Pages. The published artifact is a polished step-by-step tutorial with a progress sidebar, per-step timing, syntax-highlighted code, and the familiar codelabs.developers.google.com look.

The skill is opinionated about three things, and that's deliberate:

1. **Always brainstorm first.** Codelabs that ship without a clear audience and scope statement read like dumped notes. The few minutes spent narrowing the topic before writing pays back tenfold in readability. The user explicitly asked for this; honour it.
2. **Markdown source by default.** It's local, version-controllable, AI-draftable. The Google Docs flow (`claat export <docId>`) is supported but only when the user explicitly wants collaborative Docs editing — surface it if they mention Docs, otherwise stick with markdown.
3. **One codelab per repo, `/docs` on `main`.** This is the simplest deploy path with the fewest moving parts and no CI required. Multi-codelab sites and `gh-pages` branch flows are documented in `references/github-pages-deploy.md` for when the user outgrows the default.

## When to use this skill

Invoke on any of these (and similar) phrasings:

- "I want to build a codelab about X"
- "Let's make a Google Codelab on X"
- "Turn this tutorial / README / blog post into a codelab"
- "Publish a step-by-step interactive tutorial to GitHub Pages"
- "Use claat to render X"
- Any mention of `claat`, `googlecodelabs`, or `codelabs.developers.google.com`

If the user gave a topic in their invocation, capture it before you do anything else — don't make them repeat themselves in step [2].

## Workflow

The flow runs **in order**, with explicit user sign-off at each gate. Resist the urge to skip the brainstorm or the outline review even if the user seems eager — those gates are where bad codelabs get caught early.

```
[1] Prereq check  →  [2] Brainstorm  →  [3] Fetch resources
                          ↓
                    [4] Outline (sign-off)
                          ↓
                    [5] Author codelab.md (sign-off)
                          ↓
                    [6] Build with claat export
                          ↓
                    [7] Deploy: repo + GitHub Pages
                          ↓
                    [8] Verify live URL  →  [9] Create feedback form prompt
```

---

## [1] Prereq check

Run the prereq check first; it's read-only and fast:

```bash
bash scripts/check_prereqs.sh
```

It reports the state of `claat`, `gh`, `git`, and `gh auth`. Three actions follow from the output:

- **`claat` missing** → propose `bash scripts/install_claat.sh` and confirm before running. The script tries `go install` first and falls back to a prebuilt binary from the [releases page](https://github.com/googlecodelabs/tools/releases).
- **`gh` not authenticated** → don't try to fix this from inside Claude. Ask the user to type `! gh auth login` directly in the prompt (the `!` prefix runs in their shell so OAuth can complete). Wait for them to confirm before continuing.
- **Multiple `gh` accounts active** → note which one is the active account; the codelab will publish under that account unless the user redirects you.

## [2] Brainstorm (mandatory)

This is the heart of the skill. The goal is a tight **scope statement** before any words go on the page.

**Step 2a — Confirm the topic in free text.** If the user's invocation included a topic ("a codelab about Flutter state management"), restate it back in one sentence and ask if it's right. If they were vague, ask for a 1–2 sentence topic description before the structured questions.

**Step 2b — Call `AskUserQuestion` with the four brainstorm questions in a single batched call.** Do not split across turns — batched is faster and signals you're treating this as one planning step. Use the exact JSON in `references/brainstorm-questions.md` so phrasings stay consistent across invocations.

The four dimensions:

1. **Audience** — role/background (backend dev, frontend dev, ML, mixed, etc.)
2. **Difficulty** — Beginner / Intermediate / Advanced
3. **Duration** — 15 min / 30 min / 1 hour / 2+ hours
4. **Format** — Hands-on coding / Concept walkthrough / Mixed

**Step 2c — Write back a scope statement** in 3–4 lines, structured as:

```
Topic: <one sentence>
Audience: <who, with assumed background>
Outcome: <what the learner will be able to do at the end>
Out of scope: <what we explicitly will NOT cover, to keep the codelab focused>
```

Get explicit confirmation before moving on. This is your contract — refer back to it if scope drifts in later phases.

## [3] Fetch supporting resources

Ask in free text: "Any specific docs, blog posts, example repos, or specs I should pull in before drafting?"

- If they provide URLs: `WebFetch` each one with a **focused prompt** scoped to the codelab's topic. Don't dump the whole page — ask the fetched content for the parts relevant to the scope statement.
- If they mention a GitHub repo: pull the README and any obvious tutorial-relevant files via `WebFetch` on raw GitHub URLs (`https://raw.githubusercontent.com/owner/repo/branch/path`).
- If they say "use your judgment" or "none": skip. Don't pad with research the user didn't ask for; they know their topic better than you do.

If the fetched content materially changes what the outline should look like (e.g., a step you planned is now redundant because the linked docs already cover it well), flag this when presenting the outline.

## [4] Outline (sign-off gate)

Draft the outline **in chat, not in a file yet**. Format:

```
Title: <title>
Estimated total: <total duration>

Step 1 — <step title> (X min)
  - Bullet: what the learner does
  - Bullet: what they learn / take away

Step 2 — <step title> (X min)
  ...
```

Rules of thumb:
- **3–10 minutes per step.** Less than 3 → consider merging into the previous step. More than 10 → split.
- **Sum of step durations within ~20% of the requested total.** If they asked for 30 min and your steps add to 45, either trim a step or ask if the longer scope is OK.
- **First step should always orient the learner**: prerequisites, what they're building, environment setup if any. Call it "Overview" or "Getting started".
- **Last step should always recap and point forward**: what they accomplished, "where to go next" links.

Show the outline. Wait for "looks good" or revisions. Iterate until approved.

## [5] Author codelab.md

Write `codelab.md` in the project root.

**Use `assets/codelab.md.template` as the skeleton.** It has the header, an overview step, three numbered steps, and a wrap-up — fill in the placeholders.

**Critical format reminders** (full spec in `references/codelab-md-format.md`):

- The header is **NOT YAML frontmatter**. No `---` fences. Bare `key: value` lines, one per line, **blank line before the H1 title**.
- `Duration: 0:05` goes on the line **immediately after** each `## Step` header — no blank line between.
- Callouts: `Positive` on its own line, next line begins `: ` (colon-space). Same for `Negative`. These render as green/red callout boxes.
- Code blocks need a language tag for syntax highlighting (` ```python `, ` ```bash `, etc.). Use ` ```console ` for shell output that should not be highlighted.
- Download buttons: wrap the link in `<button>` tags, link text must start with "Download".
- Images: standard `![alt](path)` markdown; `claat` copies referenced images into the export output.

After drafting, show the user the codelab.md (or a section-by-section summary if it's long) and confirm before building.

## [6] Build with claat

```bash
claat export -o docs codelab.md
```

This produces `docs/<id>/index.html` plus `codelab.json` and any extracted images. The `<id>` comes from the `id:` field in the header.

For local preview before deploying:

```bash
cd docs && claat serve -addr localhost:9090
```

Run that in the background; open `http://localhost:9090` in a browser. The user can iterate on `codelab.md` and re-export — `claat serve` watches the directory. If they want changes, return to step [5].

## [7] Deploy

```bash
bash scripts/deploy.sh
```

> **Never commit or push the skill itself.** The codelab repo must only contain `codelab.md` and the built `docs/` output (plus whatever the user has chosen to add to their own repo — README, license, etc.). Skill files (`SKILL.md`, `references/`, `scripts/`, `assets/`, anything under `~/.claude/skills/codelab-publisher/`) must NOT be staged, committed, or pushed to the GitHub Pages repo. `deploy.sh` enforces this by explicitly staging only `codelab.md` and the docs dir — do not bypass it with `git add -A`, and if you stage anything manually, double-check `git status` before committing. If you ever spot skill files in `git status` for the codelab repo, stop and remove them before continuing.

`deploy.sh` (read it once before running so you can explain failures):

1. Verifies `docs/<id>/index.html` exists.
2. Initializes a git repo if not already in one (`git init -b main`).
3. Stages only `codelab.md` + `$DOCS_DIR/` (never `git add -A`) and commits them. This deliberately keeps the codelab-publisher skill files out of the published repo.
4. If no `origin` remote, creates a new GitHub repo via `gh repo create` (uses `REPO_NAME` and `VISIBILITY` env vars if set; otherwise defaults to `codelab-<id>` and `public` — ask the user for these before running if defaults aren't what they want).
5. Pushes to the current branch.
6. Enables GitHub Pages on `/docs` of the pushed branch via `gh api -X POST /repos/{owner}/{repo}/pages`. If Pages is already configured with a different source, it stops and warns — it does not silently change existing config.
7. Polls Pages status until `built` (up to 90 seconds).
8. Prints the live codelab URL.

To pre-set repo name / visibility before running:

```bash
REPO_NAME=my-flutter-codelab VISIBILITY=public bash scripts/deploy.sh
```

If anything in step 4 needs choosing (repo name, visibility), ask the user via `AskUserQuestion` before invoking `deploy.sh` and pass the answers as env vars — the script does not prompt interactively.

## [8] Verify

After `deploy.sh` prints the URL, do these in order:

1. **Confirm `gh api /repos/{owner}/{repo}/pages` returns `status: "built"`.** A 200 response with `status: "building"` means it isn't live yet; wait another 30s and re-check.
2. **Construct the codelab URL**: `<pages_url><id>/`. Note the trailing `/<id>/` — claat puts the codelab in a subdirectory named after its `id`, and the Pages root by itself will 404 unless you also wrote a top-level `docs/index.html` redirect (see `references/github-pages-deploy.md` for the redirect snippet).
3. **Print the URL to the user.** Offer to screenshot it for a sanity check using the chrome-devtools MCP (`mcp__chrome-devtools__new_page` + `take_screenshot`) — useful for catching obvious rendering issues like missing images or broken code blocks.

## [9] Create feedback form prompt

Once the codelab is built and verified, create a prompt that the user can use to generate a Google Form feedback template.

1. **Extract Codelab Details:** Parse `codelab.md` to extract the H1 title (e.g., `# My Codelab Title`) and all the H2 step headings (e.g., `## 1. Introduction`).
2. **Generate the Prompt:** Load the prompt template from `references/feedback-form-prompt.md`. Replace `{{CODELAB_TITLE}}` with the codelab's title, and populate `{{STEP_SECTIONS}}` with a list of step sections extracted from the H2 headers (e.g., `- Section: "Step: 1. Introduction"`).
3. **Save to File:** Write the fully populated prompt into `feedback-form-prompt.txt` at the root of the project.
4. **Instruct the User:** Present the prompt to the user and guide them on how to paste it into an LLM (such as Gemini or Claude) to generate a Google Apps Script, which they can run at script.google.com to instantly create their multi-section Google Form.

## Iterating after publish

If the user wants changes after the codelab is live:

1. Edit `codelab.md`.
2. `claat export -o docs codelab.md` (re-runs into the same directory; overwrites cleanly).
3. `git add -A && git commit -m "Update codelab" && git push`
4. Pages rebuilds automatically — you don't need to re-hit the Pages API.

## Common pitfalls

- **`codelab/` vs `docs/<id>/` confusion.** `claat export -o docs codelab.md` creates `docs/<id>/index.html`, not `docs/index.html`. The codelab URL is `<pages_url><id>/`, not `<pages_url>/`. To put it at the Pages root, add a redirecting `docs/index.html` (template in `references/github-pages-deploy.md`).
- **Header isn't YAML.** No `---` fences. Bare `key: value` lines. One blank line before the H1.
- **`Duration:` immediately follows `##`.** No blank line between the step header and its duration.
- **claat flags come after the subcommand.** `claat export -o docs codelab.md`, never `claat -o docs export codelab.md`.
- **Pages takes 30–60s for the first build.** Don't declare success on a 404 — poll status first.
- **`gh repo create --source=.` requires at least one commit.** `deploy.sh` handles this, but if you're invoking commands manually, commit before creating the remote.

## Files in this skill

- `references/claat-reference.md` — CLI flags, install paths, output structure (load first when troubleshooting claat behaviour)
- `references/codelab-md-format.md` — full markdown format spec with annotated examples (load while authoring)
- `references/github-pages-deploy.md` — deployment patterns, redirect snippet, gh-pages branch and Actions alternatives (load when `deploy.sh` hits an edge case or user wants a different deploy pattern)
- `references/brainstorm-questions.md` — exact `AskUserQuestion` JSON for the brainstorm phase
- `references/feedback-form-prompt.md` — template and specification for generating the Google Form feedback prompt (load in step [9])
- `assets/codelab.md.template` — starter codelab.md with header + step skeletons
- `scripts/check_prereqs.sh` — verify claat / gh / git / auth
- `scripts/install_claat.sh` — install claat via Go or prebuilt binary
- `scripts/deploy.sh` — build + commit + push + enable Pages + poll until built
