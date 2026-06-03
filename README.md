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

## Usage

Drop this directory into your agent's skills folder (e.g. `~/.claude/skills/codelab-publisher`). The skill triggers whenever you ask to build a codelab, write a step-by-step interactive tutorial, or publish a tutorial to GitHub Pages.

The workflow is opinionated by design:

1. **Brainstorm first** — topic, audience, difficulty, length, and supporting resources before any content is written.
2. **Markdown source by default** — local, version-controllable, and easy to draft. The Google Docs flow is supported when collaborative editing is needed.
3. **One codelab per repo, `/docs` on `main`** — the simplest deploy path with no CI required. Multi-codelab and `gh-pages` flows are documented in `references/github-pages-deploy.md`.

## Prerequisites

- The Go-based `claat` CLI (`scripts/install_claat.sh` installs it).
- The GitHub CLI (`gh`), authenticated.
- Run `scripts/check_prereqs.sh` to verify your environment.
