---
name: site-update
description: "Make updates to Jude Edelman's academic website (this repo, plain HTML/CSS on GitHub Pages): replace the CV PDF, add or change a work in progress, edit the research statement or interests, add a recommended reading, add or relink a thinker on the Influences rhizome map, or add a Code Library module. Use whenever the user asks to update the site, website, homepage, CV, papers list, readings, influences, or code library, even if they only say 'add this paper' or 'new CV'."
---

# Site update

The site is deliberately plain: hand-written HTML and CSS, no framework, no build step, deployed by GitHub Pages from the repo. Keep it that way — don't add build tools, frameworks, or dependencies for an update.

## Map of the site

| Page | What it holds | Notes |
|---|---|---|
| `index.html` | Hero (name, title, research statement, interests), About, Works in Progress, CV link, Contact | Single page with `#anchors` |
| `edelman_cv.pdf` | The CV | Replaced wholesale; link in `index.html#cv` |
| `influences.html` + `rhizome.js` + `rhizome.css` | Influences map, access-gated | The `<ul class="rz-source">` list is the only source of truth; never edit the JS to change the map |
| `readings.html` | Recommended readings, access-gated | Entries are `.rdg-entry` divs |
| `code-library.html` + `code-library/NN-slug/` + `code-library.css` | 15+ annotated modules in Stata/R/Python with intuition and math docs | Code badges hidden behind the access code |
| `style.css` | Shared styles and color tokens (`--accent`, `--muted`, `--border`) | Reuse tokens rather than new colors |

Every page repeats the same `<nav>` block. **When adding or renaming a page, update the nav on every HTML page** and highlight the current page's link with `style="color: var(--accent);"` as `readings.html` does.

## Common tasks

**New CV.** Replace `edelman_cv.pdf` in place (same filename so the link keeps working). Then open the new CV and compare its papers list, titles, venues, and statuses with Works in Progress in `index.html`; sync any differences. Past updates regularly caught a changed paper title this way.

**Works in progress.** Each paper is:
```html
<div class="paper">
  <p class="paper-title">Title</p>
  <p class="paper-authors">Edelman, J.D. &amp; Coauthor, X.</p>
  <p class="paper-status">Manuscript in preparation &middot; <em>Target Journal</em></p>
</div>
```
Use HTML entities (`&amp;`, `&middot;`, `&dagger;` for equal authorship with the note paragraph below the list). Statuses in use: "Manuscript in preparation", "Data analysis phase"; natural progressions are "Under review at", "Revise and resubmit at", "Forthcoming in", "Published in" — for published work, consider adding a separate Publications section above Works in Progress.

**Reading.** Add an `.rdg-entry` inside `.rdg-list` with an ASA-style `.rdg-citation` (use the `asa-citations` skill's format), an `.rdg-link` to the publisher or DOI, and an optional italic `.rdg-note`.

**Influence.** Add an `<li id="rz-key">` to `ul.rz-source` in `influences.html` with `data-year` (year of the cited work), `data-ideology` (0–100 position used for layout; compare with neighbors), `data-links` ("key|relation" pairs, comma-separated), an `<h3>` name, `.rz-work` with the work(s), and `.rz-gloss` holding a **verbatim quote** (the page switched from paraphrase to verbatim quotes deliberately — don't write paraphrases, and don't invent quotes; ask for the passage or source if it isn't available). Relations: `alliance`, `tension`, `shared`, `lineage`; lineage is directional and is declared on the earlier thinker. Declare each link once. Update the "All thirty-six" count in the `<summary>` text when the number of thinkers changes.

**Code library module.** Create `code-library/NN-slug/` with `slug.do`, `slug.R`, `slug.py`, `slug-intuition.md/.html`, `slug-math.md/.html`, following an existing module (e.g., `03-ols-regression`) for header comments and section structure. All modules use the CES 2020 data cleaned in Module 01. Add a `<details class="cl-module">` block in `code-library.html` matching the others, and update the "N Modules" label. The page script hides the Code badges automatically.

## About the access gates

Influences, Readings, and the Code files use a shared access code checked in page JavaScript. This hides content from casual visitors only: the pages and files are public in the repository and can be fetched directly. Say this if the user plans to put anything genuinely private behind a gate. Don't print the access code in chat or commit messages.

## Before committing

- Open changed pages in a browser (Playwright/Chromium is available) and check desktop and phone widths; the influences map also re-lays out on rotation.
- Check that links and file paths resolve (case-sensitive on GitHub Pages).
- Commit messages follow the repo's style: imperative summary line ("Update CV to August 2026 version and sync paper title"), with bullet details when several things changed.
