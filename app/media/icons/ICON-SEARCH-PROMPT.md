# Icon-search prompt — Preflights portal

Run this against an AI that has Flaticon / Freepik search access. Have it return the
PNG files into **this folder** (`app/media/icons/`) using the exact filenames listed.
The portal UI already references these names; any icon that isn't present falls back to
`ic-dashboard.png` (the universal default), then to an emoji if even that is missing — so
the site works with only a handful of PNGs in place. **`ic-dashboard.png` is the most
useful one to have**, since it stands in for every icon you haven't added yet.

---

I'm building a USAFA physics-course web portal ("Preflights") and need a cohesive set
of **Lineal Color** icons from Flaticon / Freepik (outlined shapes with flat color
fills — NOT solid glyphs, NOT plain monochrome line icons).

**Requirements**

- Style: **Lineal Color** (a.k.a. "lineal color" / "flat line color"). Consistent
  ~2px stroke weight across the whole set.
- **Cohesion first:** strongly prefer pulling the entire set from ONE icon family /
  author so stroke weight, corner radius, and palette match. List the pack name(s).
- Palette should sit well on BOTH a light (`#f4f5f7`) and dark (`#0f172a`) background
  and harmonize with the site's navy/blue/gold (`#1e3a5f`, `#2a5298`, `#c8a951`).
  Avoid icons whose fills are pure white or pure black (invisible on one theme).
- Format: **PNG, 256×256 px**, transparent background, with a little padding inside the
  square (no frame/badge). The UI renders these small (16–28 px) and downscales them, so
  256 px keeps them crisp on high-DPI/Retina screens. (If a Flaticon download only offers
  512 px, that's fine too — bigger just costs a few KB. Don't go below 128 px.)
- Keep every file the SAME pixel dimensions so they align visually.
- Provide the Flaticon attribution string for each (free tier needs it).
- Deliver each file named exactly as the `filename` below, placed in `app/media/icons/`.

**Theme:** physics + aviation (these are "preflight" checklists at the Air Force
Academy). Where natural, favor atom/wave/magnet/bolt and aviation-checklist motifs.

**Icons needed** (filename — purpose):

- `ic-dashboard.png` — dashboard / home landing
- `ic-assignments.png` — assignments (clipboard checklist)
- `ic-interactions.png` — AI lesson interactions (lightbulb / idea spark)
- `ic-grades.png` — grading & reports (bar chart / report)
- `ic-roster.png` — roster (people / ID card)
- `ic-sections.png` — class sections (grouped people / layers)
- `ic-export.png` — export / download
- `ic-settings.png` — settings (gear)
- `ic-signout.png` — sign out (logout / exit door)
- `ic-user.png` — user / profile avatar
- `ic-course.png` — course switcher (atom / books)
- `ic-sun.png` — light-mode toggle
- `ic-moon.png` — dark-mode toggle
- `ic-menu.png` — mobile hamburger menu
- `ic-todo.png` — to-do (checklist + pencil)
- `ic-done.png` — completed (check circle / badge)
- `ic-due-soon.png` — due soon (clock / hourglass)
- `ic-overdue.png` — overdue (alarm clock / warning)
- `ic-award.png` — grade earned (star / medal / award)
- `ic-progress.png` — progress (gauge / ring)
- `ic-class.png` — class / teaching (chalkboard / podium)
- `ic-analytics.png` — section analytics (line/bar chart)
- `ic-submissions.png` — submissions inbox (tray)
- `ic-pending-grade.png` — pending grading (pen / marker)
- `ic-students.png` — students count (group)
- `ic-completion.png` — completion rate (donut / percent)
- `ic-success.png` — success (check)
- `ic-warning.png` — warning (triangle !)
- `ic-error.png` — error (x circle)
- `ic-info.png` — info (i circle)
- `ic-atom.png` — physics brand mark (atom)
- `ic-bolt.png` — energy / brand accent (lightning bolt)
- `ic-rocket.png` — "preflight" theme (rocket or paper plane)
- `ic-wave.png` — physics (waveform)
- `ic-magnet.png` — E&M (magnet)

**Return:** the chosen pack name(s), the per-file attribution strings, and any item
you couldn't find a good Lineal-Color match for (so I can adjust).

---

## How the UI consumes these

- Reference an icon with `<img class="ic" src="../media/icons/ic-dashboard.png" alt="">`
  (or `media/icons/…` from the top-level `app/` pages). CSS sizes/downscales it.
- Until a file exists, the UI substitutes `ic-dashboard.png` (then an emoji if that's
  also absent), so missing icons never break a page — drop PNGs in here as they arrive
  and they light up automatically.
- Keep the filenames exactly as above; that's the contract the markup relies on.
