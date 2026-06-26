# claat Reference

Quick reference for the `claat` CLI, install paths, output structure, and core gotchas. Load this when you hit anything unexpected with `claat` itself.

## Install (macOS)

There's no Homebrew formula. Two canonical paths:

```bash
# Preferred: Go toolchain
go install github.com/googlecodelabs/tools/claat@latest
# Binary lands in $(go env GOPATH)/bin — ensure it's on PATH

# Fallback: prebuilt binary
# https://github.com/googlecodelabs/tools/releases/latest
# Download claat-darwin-arm64 (Apple Silicon) or claat-darwin-amd64 (Intel),
# chmod +x, mv to /usr/local/bin/claat
```

Verify with `claat version`.

`scripts/install_claat.sh` in this skill handles both paths automatically.

## CLI surface

Form: `claat <cmd> [flags] src [src ...]`. Subcommands: `export`, `serve`, `update`, `version`, `help`.

**Flags MUST come after the subcommand.** `claat -o docs export codelab.md` will fail; `claat export -o docs codelab.md` is correct.

| Flag | Default | Used by | Purpose |
|---|---|---|---|
| `-o` | `.` | export | Output directory. `-` for stdout (no assets / metadata written). |
| `-f` | `html` | export | Format: `html`, `md`, `offline`, or path to a Go template. |
| `-e` | `web` | export | Codelab environment (e.g. `web`, `kiosk`). |
| `-prefix` | `https://storage.googleapis.com` | export, update | URL prefix for HTML asset paths. Set to `/` or `/<repo>/` when serving from the same Pages site. |
| `-ga` | `UA-49880327-14` | export, update | Google Analytics account. Set to your own, or empty string to disable. |
| `-extra` | `""` | export, update | JSON object of extra template vars: `'{"theme":"dark"}'`. |
| `-pass_metadata` | `""` | export, update | Comma-separated extra metadata field names to surface from the header. |
| `-auth` | `""` | export, update | OAuth2 Bearer token for Google Doc sources. |
| `-addr` | `localhost:9090` | serve | host:port for the preview server. |

### Common invocations

```bash
# Standard build into ./docs/<id>/
claat export -o docs codelab.md

# Build with local-relative asset paths (use when assets ship in the same Pages site)
claat export -o docs -prefix / codelab.md

# Re-emit markdown (useful for normalizing a Google Doc source)
claat export -f md -o out <doc-id>

# Local preview server (run from the directory containing the exported codelab)
claat serve -addr localhost:9090

# Re-export every codelab in a directory tree based on its codelab.json
claat update ./docs

# Disable the default Google Analytics account
claat export -ga "" -o docs codelab.md
```

## codelab.md header (NOT YAML)

claat does **not** use YAML frontmatter. The header is plain `key: value` lines, **no `---` fences**, separated from the H1 title by a single blank line.

```markdown
author: Jane Doe
summary: Build a real-time chat app with WebSockets in 30 minutes
id: realtime-chat-websockets
categories: codelab,web,realtime
environments: Web
status: Draft
feedback link: https://github.com/jane/realtime-chat/issues
analytics account: UA-XXXXXXXX-Y

# Build a real-time chat app
```

Recognized keys:

- `summary` — one-line description shown on index pages.
- `id` — slug used for the output directory name (`docs/<id>/`) and the URL path.
- `categories` — comma-separated; used by claat's site templates for filtering.
- `environments` — typically `Web`. Multi-value supported.
- `status` — `Draft` | `Published` | `Deprecated` | `Hidden`.
- `feedback link` — URL where readers can file issues. Linked from a footer button.
- `analytics account` — overrides the default GA tracker.

Arbitrary keys are silently ignored unless surfaced via `-pass_metadata`.

**Header rules:**

- Keys cannot contain a colon.
- One field per line.
- All header fields must precede the H1 title.
- A blank line separates the header from the H1.

## Step / content syntax

- Each `##` header starts a new step. There is no nesting — a step is a flat unit.
- `Duration: 0:05` (mm:ss) or `Duration: 0:00:05` (hh:mm:ss) goes on the line **immediately after** the step header (no blank line between).
- Callouts:
  ```
  Positive
  : Green callout text. Used for tips, "what good looks like", success indicators.

  Negative
  : Red callout text. Used for warnings, pitfalls, things to avoid.
  ```
  HTML form `<aside class="positive">…</aside>` and `<aside class="negative">…</aside>` also work.
- Fenced code blocks with language tags for syntax highlighting:
  ````
  ```python
  print("hello")
  ```
  ````
  Use ```` ```console ```` for shell output that should not be highlighted.
- Download buttons: wrap a link starting with "Download" in `<button>` tags:
  ```
  <button>
    [Download starter code](https://example.com/starter.zip)
  </button>
  ```
- Images: standard markdown `![alt](path/to/image.png)`. claat copies referenced local images into the export output.
- Fragment includes: `<<fragments/setup.md>>` inlines another file at parse time (useful for shared boilerplate steps).

## Export output structure

`claat export -o docs codelab.md` produces:

```
docs/
└── <id>/                  ← directory named after the `id:` field
    ├── index.html         ← the rendered codelab
    ├── codelab.json       ← metadata; consumed by `claat update`
    └── img/               ← extracted image assets (if any)
        └── *.png
```

There is **no top-level `docs/index.html`** by default — claat only generates per-codelab pages. If you want a landing page that links to the codelab, write `docs/index.html` yourself (a simple redirect template is in `github-pages-deploy.md`).

## Google Docs flow

When the source is a Google Doc instead of a markdown file:

```bash
claat export -auth "$ACCESS_TOKEN" <google-doc-id>
```

Notes:

- The doc must be shared (at least "Anyone with the link can view") or the auth token must belong to a user with view access.
- Get a token via the gcloud CLI: `gcloud auth print-access-token` (after running `gcloud auth login`).
- The doc must follow the codelab structure: header lines at the top, H1 title, H2 steps with Duration lines, etc. The same format rules as markdown apply, just rendered in Google Docs styling (use Heading 1 / Heading 2 / Normal text).
- This flow is best when multiple authors collaborate on the source. For solo / AI-drafted work, stick with markdown.

## Sources

- https://github.com/googlecodelabs/tools/blob/main/claat/README.md
- https://github.com/googlecodelabs/tools/blob/main/claat/parser/md/README.md
- https://github.com/googlecodelabs/tools/blob/main/claat/main.go (flag definitions)
- https://github.com/googlecodelabs/tools/releases/latest (prebuilt binaries)
