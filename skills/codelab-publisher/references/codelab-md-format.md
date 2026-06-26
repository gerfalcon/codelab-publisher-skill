# codelab.md Format — Annotated Spec

The `claat` markdown dialect is close to CommonMark but has specific conventions for the header, steps, callouts, and downloadable assets. This file is the source of truth when authoring. Load it during step [5] of the workflow.

## Anatomy of a codelab

```
┌─ Header (key: value lines, no YAML fences)
│
├─ # Title (single H1)
│
├─ ## Step 1
│  Duration: 0:05
│  
│  Content...
│
├─ ## Step 2
│  Duration: 0:10
│  ...
│
└─ ## Wrap up
   Duration: 0:02
   ...
```

## The header (gotchas)

**Wrong (looks right, but isn't):**

```markdown
---
id: my-codelab
summary: A great codelab
---

# My Codelab
```

`claat` will read the `---` as actual content. **No YAML frontmatter.**

**Right:**

```markdown
author: Jane Doe
summary: A great codelab about widgets
id: my-codelab
categories: codelab,widgets
environments: Web
status: Draft
feedback link: https://github.com/jane/my-codelab/issues

# My Codelab
```

Rules:

| Rule | Why it matters |
|---|---|
| No `---` fences | claat parses fences as horizontal rules in the body |
| One field per line | Multi-value fields use commas (categories: `web,mobile`) |
| Blank line before H1 | Separates header from title; missing it merges them |
| All metadata before H1 | Anything after the H1 is treated as step content |
| Keys cannot contain `:` | The first `:` is always the key/value delimiter |

### Recognized header keys

| Key | Required | Example | Notes |
|---|---|---|---|
| `id` | yes | `realtime-chat` | URL slug; becomes the export directory name. Use kebab-case. |
| `summary` | yes | `Build a chat app in 30 min` | Shown on landing pages and search results. |
| `author` | recommended | `Jane Doe` | Displayed in the codelab header. |
| `categories` | recommended | `web,realtime` | Comma-separated tags for filtering. |
| `environments` | recommended | `Web` | Usually just `Web`. |
| `status` | recommended | `Draft` | `Draft` / `Published` / `Deprecated` / `Hidden`. |
| `feedback link` | recommended | `https://.../issues` | Link to file feedback; rendered as a button. |
| `analytics account` | optional | `G-XXXXXXX` | Override default GA tracker. Use `""` (empty) to disable. |
| `tags` | optional | `intro,beginner` | Alternative tag mechanism. |

## Steps

A step is everything between two `##` headers. Each step gets its own page in the rendered codelab with prev/next navigation.

### Step structure

```markdown
## Set up your environment
Duration: 0:05

In this step you'll install the SDK and verify it works.

### Install the SDK

Run the following:

```bash
npm install --save-dev @example/sdk
```

### Verify the install

```bash
npx example-sdk --version
```

You should see `1.4.2` or higher.

Positive
: If you see a permission error, check that npm is using your local prefix
  (`npm config get prefix`), not `/usr/local`.
```

Notes:

- The **first line after `##` must be `Duration: …`** — no blank line.
- `### subheadings` group content within a step. They don't create new pages.
- Duration format: `mm:ss` (`0:05`) or `hh:mm:ss` (`0:01:30`). Hours rarely needed.

### Step length

Aim for **3–10 minutes per step**:

- < 3 min: probably should be merged with the previous step or made a subheading.
- > 10 min: split. Learners lose progress sense in long steps.

### First and last steps

Convention:

- **First step**: "Overview", "Getting started", or "Before you begin". Should contain:
  - What the learner will build (one paragraph).
  - "What you'll learn" — bulleted list of outcomes.
  - "What you'll need" — prerequisites (software, accounts, prior knowledge).
- **Last step**: "Wrap up", "Congratulations", or "What's next". Should contain:
  - One paragraph recapping what was built.
  - "Where to go next" — links to deeper material, related codelabs, docs.

## Callouts

Used to flag information that breaks out of the main flow.

### Syntax

```
Positive
: This text appears in a green callout. Use for tips, "what good looks like",
  success indicators, and best-practice asides.

Negative
: This text appears in a red callout. Use for warnings, common pitfalls,
  security concerns, and things to avoid.
```

The `: ` (colon + space) at the start of the next line is the magic — it's a definition-list construct that claat repurposes.

### HTML form (when the markdown form fights you)

```html
<aside class="positive">
This works too. Use when you need a code block inside the callout
or other complex content.
</aside>

<aside class="negative">
Same but red.
</aside>
```

### When to use callouts vs prose

Use callouts sparingly. If every other paragraph is a callout, none of them stand out. Reserve them for:

- A single critical tip per step (max ~2).
- Genuine warnings ("this will delete your data", "this only works on Linux").
- Optional asides ("If you're using TypeScript instead, see …").

## Code blocks

Always include a language tag for syntax highlighting:

````
```python
def hello():
    return "world"
```
````

Supported tags include: `python`, `bash`, `javascript`, `typescript`, `go`, `rust`, `java`, `kotlin`, `swift`, `c`, `cpp`, `csharp`, `ruby`, `php`, `html`, `css`, `xml`, `json`, `yaml`, `toml`, `sql`, `markdown`, `dockerfile`, `nginx`.

**Special tags:**

- ` ```console ` — shell output / terminal session. **Not** syntax highlighted. Use this for command output, REPL transcripts, etc.
- ` ```text ` — plain text, no highlighting.

**Tip:** Use `console` for the *output* of a command, and `bash` for the *command itself*:

````
Run:

```bash
npm test
```

You should see:

```console
PASS  src/index.test.js
Tests: 4 passed, 4 total
```
````

## Images

Standard markdown:

```markdown
![A diagram of the architecture](images/architecture.png)
```

- Local paths are relative to the codelab.md file.
- `claat export` copies referenced images into `docs/<id>/img/`.
- For remote images, paste the full URL — they're embedded directly.
- Keep image filenames lowercase + hyphenated, no spaces.

For zoomable / lightboxed images, the default behaviour is fine — claat wraps images with a click-to-expand handler automatically.

## Download buttons

Wrap a link in `<button>` tags. The link text must start with "Download":

```html
<button>
  [Download the starter project](https://example.com/starter.zip)
</button>
```

This renders as a styled CTA button. Use for:

- Starter code zips.
- Solution branches.
- PDFs of reference material.

## Links

Standard markdown `[text](url)`. External links open in a new tab automatically.

For links to specific steps within the codelab, use the auto-generated anchor — claat slugifies step titles:

```markdown
Skip ahead to [the deploy step](#deploy-the-app).
```

## Fragments (advanced)

Include another markdown file at parse time:

```markdown
<<fragments/install-prereqs.md>>
```

Useful when you have a "setup" or "install prereqs" step that's identical across multiple codelabs in a series. The fragment is parsed as if its content were inlined at that location.

## A full minimal example

```markdown
author: Jane Doe
summary: Build a CLI weather tool in Python in 20 minutes
id: python-weather-cli
categories: python,cli,beginner
environments: Web
status: Draft
feedback link: https://github.com/jane/python-weather-cli/issues

# Build a CLI weather tool in Python

## Overview
Duration: 0:02

You'll build a small command-line tool that prints the current weather for any
city using a free public API.

### What you'll learn

- How to make HTTP requests in Python with `requests`
- How to parse JSON responses
- How to package a script as a CLI with `argparse`

### What you'll need

- Python 3.9+
- An internet connection
- 20 minutes

## Set up
Duration: 0:03

Install the one dependency:

```bash
pip install requests
```

Verify it works:

```python
python -c "import requests; print(requests.__version__)"
```

You should see `2.x.x`.

Positive
: If `pip` is missing, install it with `python -m ensurepip --upgrade`.

## Fetch the weather
Duration: 0:08

Create `weather.py`:

```python
import requests
import sys

def get_weather(city):
    url = f"https://wttr.in/{city}?format=j1"
    r = requests.get(url, timeout=5)
    r.raise_for_status()
    return r.json()

if __name__ == "__main__":
    data = get_weather(sys.argv[1])
    print(data["current_condition"][0]["temp_C"], "°C")
```

Try it:

```bash
python weather.py London
```

You should see something like `12 °C`.

Negative
: If you get a `ConnectionError`, check your internet. `wttr.in` is a free
  service with no auth, so there's nothing else to configure.

## Wrap up
Duration: 0:02

You've built a working weather CLI in three lines of real logic.

### Where to go next

- [Add argparse for proper CLI flags](https://docs.python.org/3/library/argparse.html)
- [Cache responses with `requests-cache`](https://pypi.org/project/requests-cache/)
- [Package as a pip-installable tool with `setuptools`](https://packaging.python.org/)
```
