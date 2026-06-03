# GitHub Pages Deploy Patterns for claat Output

Three deploy patterns, ordered by complexity. The default (and what `scripts/deploy.sh` uses) is **/docs on main** because it requires zero CI setup. Load this file when the default doesn't fit or when the user wants to switch patterns.

## Pattern 1: `/docs` on `main` (default)

**Best for:** Solo authors, simple single-codelab repos, no CI needed.

```
my-codelab-repo/
├── codelab.md          ← source
├── docs/               ← claat export -o docs output
│   ├── index.html      ← (optional) redirect to /docs/<id>/
│   └── <id>/
│       ├── index.html
│       ├── codelab.json
│       └── img/
└── README.md
```

### Enable via gh CLI

```bash
gh api -X POST repos/:owner/:repo/pages \
  -f build_type=legacy \
  -f 'source[branch]=main' \
  -f 'source[path]=/docs'
```

Pages serves `https://<owner>.github.io/<repo>/<id>/`.

### Optional: redirect from the Pages root to the codelab

By default, `https://<owner>.github.io/<repo>/` 404s — there's no `docs/index.html`. Drop in this redirect:

```html
<!-- docs/index.html -->
<!doctype html>
<meta charset="utf-8">
<title>Redirecting…</title>
<meta http-equiv="refresh" content="0; url=./<id>/">
<link rel="canonical" href="./<id>/">
<p>If you are not redirected, <a href="./<id>/">click here</a>.</p>
```

Replace `<id>` with the actual codelab id.

## Pattern 2: `gh-pages` branch (worktree)

**Best for:** Keeping the `main` branch source-only; multi-codelab repos where the build artifact is large.

```bash
# One-time setup
git checkout --orphan gh-pages
git rm -rf .
git commit --allow-empty -m "Initial gh-pages"
git push -u origin gh-pages
git checkout main

# Set up the worktree (do this once)
mkdir -p ../$(basename $PWD)-pages
git worktree add ../$(basename $PWD)-pages gh-pages

# Per-build workflow
claat export -o ../$(basename $PWD)-pages codelab.md
cd ../$(basename $PWD)-pages
git add -A
git commit -m "Build: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git push origin gh-pages
cd -
```

### Enable via gh CLI

```bash
gh api -X POST repos/:owner/:repo/pages \
  -f build_type=legacy \
  -f 'source[branch]=gh-pages' \
  -f 'source[path]=/'
```

Pages serves `https://<owner>.github.io/<repo>/<id>/`.

## Pattern 3: GitHub Actions workflow

**Best for:** Teams; automatic rebuilds on push; clean `main` (no committed `docs/`); using Go toolchain instead of shipping binaries.

```yaml
# .github/workflows/codelab.yml
name: Deploy codelab
on:
  push:
    branches: [main]
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Install claat
        run: go install github.com/googlecodelabs/tools/claat@latest
      - name: Build codelab
        run: claat export -o public codelab.md
      - name: Add root redirect
        run: |
          ID=$(ls public | head -1)
          cat > public/index.html <<EOF
          <!doctype html>
          <meta http-equiv="refresh" content="0; url=./$ID/">
          <link rel="canonical" href="./$ID/">
          EOF
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

### Enable via gh CLI

```bash
# Tell Pages to use the workflow build, not branch-based
gh api -X POST repos/:owner/:repo/pages -f build_type=workflow
```

Then push the workflow file. The Action runs on every push to `main`.

## gh CLI Pages reference

```bash
# Check current Pages config + status
gh api repos/:owner/:repo/pages

# Returns JSON with: html_url, status (built|building|errored|null), source.branch, source.path

# Enable (first time only)
gh api -X POST repos/:owner/:repo/pages \
  -f build_type=legacy \
  -f 'source[branch]=main' \
  -f 'source[path]=/docs'

# Change existing config (both branch AND path required on PUT)
gh api -X PUT repos/:owner/:repo/pages \
  -f 'source[branch]=main' \
  -f 'source[path]=/docs' \
  -F https_enforced=true

# Trigger an immediate rebuild (rare; pushing to source branch does this automatically)
gh api -X POST repos/:owner/:repo/pages/builds

# Get build history
gh api repos/:owner/:repo/pages/builds

# Disable Pages entirely
gh api -X DELETE repos/:owner/:repo/pages
```

### Caveats

- `source.path` accepts only `/` or `/docs`. Nothing else. (This is why Pattern 1 uses `/docs` specifically.)
- First build after enabling takes 30–60 seconds. Poll `GET /pages` until `status == "built"` before declaring success.
- Only one concurrent build per repo.
- HTTPS cert provisioning is automatic for `*.github.io`. Custom domains need DNS records + a `CNAME` file in the published directory first.
- Private repos can use Pages on GitHub Free with a public Pages site, or any plan with a private site. The `gh api` call is the same.
- POST returns 409 if Pages is already enabled. Catch that and fall through to a GET to read existing config — that's what `deploy.sh` does.

## Polling for `built` status

```bash
for i in $(seq 1 30); do
  STATUS="$(gh api repos/:owner/:repo/pages --jq .status 2>/dev/null || echo "")"
  echo "[$i/30] Pages status: $STATUS"
  [ "$STATUS" = "built" ] && break
  sleep 3
done
```

90 seconds total. If still building after that, the codelab will appear once the build completes — don't keep blocking; print the URL and tell the user it'll be live in a minute.

## Picking a pattern (decision flow)

```
Is this a solo, single-codelab repo with infrequent updates?
  └─ Yes → Pattern 1 (/docs on main). Use scripts/deploy.sh.

Do you want main to stay source-only (no committed build artifacts)?
  └─ Yes → Pattern 2 (gh-pages branch). Set up worktree, point Pages at gh-pages root.

Multi-author repo where rebuilds should happen automatically on push?
  └─ Yes → Pattern 3 (GitHub Actions). Use the workflow above.
```

When in doubt, start with Pattern 1 and migrate later if needed. Switching patterns is two `gh api` calls and a directory rename.
