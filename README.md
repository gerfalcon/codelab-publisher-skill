# codelab-publisher

An agent skill that builds a [Google Codelab](https://codelabs.developers.google.com/) from scratch using the [`claat`](https://github.com/googlecodelabs/tools) tool and publishes it to GitHub Pages via the `gh` CLI.

The skill takes a topic from a structured brainstorm all the way to a polished, published step-by-step tutorial — complete with a progress sidebar, per-step timing, syntax-highlighted code, and the familiar `codelabs.developers.google.com` look.

## What's here

| Path | Purpose |
| --- | --- |
| `SKILL.md` | The skill definition and end-to-end workflow. |
| `assets/codelab.md.template` | Starter `codelab.md` with the required metadata header. |
| `references/` | Deep-dive docs: codelab markdown format, `claat` reference, GitHub Pages deploy options, and the brainstorming question set. |
| `scripts/` | Helpers to check prerequisites, install `claat`, and deploy. |

## Installation & Setup

Follow these steps to configure the skill and its dependencies:

### 1. Install the Skill
Copy or symlink this directory into your agent's skills folder depending on your environment:
- **Project-level (supported by many agentic platforms like Antigravity)**:
  - `.agents/skills/codelab-publisher` (at the root of your workspace)
- **Global (Google Antigravity / Gemini)**:
  - `~/.gemini/skills/codelab-publisher`
- **Global (Claude Code CLI)**:
  - `~/.claude/skills/codelab-publisher`

### 2. Install Prerequisites
Ensure the necessary CLI tools are installed:
- **Git & GitHub CLI (`gh`)**:
  ```bash
  brew install git gh
  gh auth login
  ```
- **`claat` CLI**: Run the installer script to set up the Google Codelab CLI:
  ```bash
  bash scripts/install_claat.sh
  ```
  *(Note: The script compiles `claat` from source if Go is installed, or downloads a prebuilt binary via `gh`. On Apple Silicon, installing Go (`brew install go`) first is recommended to avoid Rosetta 2 requirements.)*

### 3. Verify Installation
Run the verification script to check your environment:
```bash
bash scripts/check_prereqs.sh
```

## Usage

Once installed, the skill triggers automatically whenever you ask the agent to:
- Build a Google Codelab
- Write a step-by-step interactive tutorial
- Publish a tutorial to GitHub Pages

The workflow is opinionated by design:

1. **Brainstorm first** — topic, audience, difficulty, length, and supporting resources before any content is written.
2. **Markdown source by default** — local, version-controllable, and easy to draft. The Google Docs flow is supported when collaborative editing is needed.
3. **One codelab per repo, `/docs` on `main`** — the simplest deploy path with no CI required. Multi-codelab and `gh-pages` flows are documented in `references/github-pages-deploy.md`.
