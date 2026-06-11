# Preflights portal (`app/`)

A role-aware rewrite of the front end: one shared auth bootstrap, a top navigation bar,
light/dark mode, and a dashboard landing page tailored to **students** vs **faculty**
(instructor/director/admin). Static HTML/CSS/JS — no build step. **No database changes.**

This is the *foundation* pass. Dashboards, navigation, theming, auth, and the AI lesson
interactions live here. The heavy grading / roster / sections / assignment-builder /
export tools still live on the legacy root pages (`admin.html`, `interactions-admin.html`)
and are reached via out-links until they're ported in a later pass.

## Structure

```
app/
  index.html            Router — resolves role, forwards to the right dashboard
  login.html            Unified login (cadet ID → @usafa.edu, or instructor email)
  student/              dashboard · assignments (submit/review) · interactions
  faculty/              dashboard (section roll-up) · interactions (completion + reports)
  css/styles.css        Tokenized design system + dark theme
  js/                   supabase · auth · nav · theme · util · student-data · faculty-data
  media/icons/          PNG icons (+ ICON-SEARCH-PROMPT.md). Missing → ic-dashboard.png → emoji.
```

### How a page boots
`<head>` loads, in order: a tiny no-flash theme snippet → `css/styles.css` → the
supabase-js CDN (classic) → `js/config.js` (classic, sets `window.db`) → the page's
`<script type="module">`. Modules are deferred, so `window.db` always exists before module
code runs. The module then: `await bootstrap({ require })` → `renderNav(ctx)` →
load + render data.

## Run locally

From the **repo root** (so the legacy pages resolve too):

```
python -m http.server 8000
```

Then open <http://localhost:8000/app/>. Log in as a student (cadet ID + last-6 password)
or an instructor (email + password). The session persists across reloads and navigation;
sign out from the user menu.

## Going live (promote to root)

Paths are intentionally **relative** (no leading `/`, safe under GitHub Pages project
URLs), and `legacyUrl()` resolves the root-level legacy links correctly in **both** phases,
so promotion needs no find/replace:

1. Copy the contents of `app/` into the repo root (this overwrites `index.html`,
   `css/styles.css`, and `js/config.js` — the CSS keeps every legacy class so the old
   pages still render, and `config.js` is byte-identical).
2. Keep the legacy `admin.html` and `interactions-admin.html` at the root; the portal's
   faculty links target them via `legacyUrl()`.
3. The Claude artifacts still post back to `interaction-submit.html` at the root — unchanged.

## Not in this pass

Grading, roster, sections, assignment builder, instructor management, and export remain on
the legacy pages. Faculty section-scoping is enforced in client JS (mirroring the existing
app), not RLS — true isolation would require new DB policies, which are out of scope here.
