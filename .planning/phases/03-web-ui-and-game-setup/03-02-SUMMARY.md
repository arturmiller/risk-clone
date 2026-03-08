---
phase: 03-web-ui-and-game-setup
plan: 02
subsystem: ui
tags: [svg, html, css, game-map, layout]

# Dependency graph
requires:
  - phase: 01-project-setup
    provides: classic.json territory/continent data
provides:
  - SVG map asset with 42 clickable territory regions and army labels
  - Single-page HTML with setup screen and game board layout
  - CSS styling with player colors and territory interaction states
affects: [03-web-ui-and-game-setup]

# Tech tracking
tech-stack:
  added: []
  patterns: [data-territory SVG attributes, data-army-label text elements, continent grouping via SVG g elements]

key-files:
  created:
    - risk/data/classic_map.svg
    - risk/static/index.html
    - risk/static/style.css
  modified: []

key-decisions:
  - "Schematic rectangle-based territory shapes for clarity and clickability over geographic accuracy"
  - "Dark theme (bg #1a1a2e) with high-contrast UI elements for readability"
  - "SVG territories use path elements with data-territory attributes matching classic.json exactly"

patterns-established:
  - "Territory identification: data-territory attribute on SVG path, data-army-label on text"
  - "Continent grouping: SVG g elements with data-continent attribute"
  - "UI state management: CSS classes (selected, valid-target, dimmed) on territory elements"

requirements-completed: [MAPV-02, MAPV-03, MAPV-07]

# Metrics
duration: 3min
completed: 2026-03-08
---

# Phase 3 Plan 2: SVG Map and HTML/CSS Layout Summary

**Schematic SVG world map with 42 clickable territory regions, single-page HTML with setup/game board views, and dark-themed CSS with 6 player colors**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-08T11:11:01Z
- **Completed:** 2026-03-08T11:13:36Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- SVG map with all 42 territories as path elements with correct data-territory attributes verified against classic.json
- Army count label text elements at territory centroids with data-army-label attributes
- HTML layout with setup screen (player count 2-6, Start button) and game board (75/25 map/sidebar split)
- Sidebar with phase banner, turn info, phase stepper, continent bonuses, action buttons, and scrollable game log
- Modal overlays for army movement, card trading, and game over states

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate SVG world map with territory regions** - `6590c19` (feat)
2. **Task 2: Create HTML layout and CSS styling** - `c2bc73a` (feat)

## Files Created/Modified
- `risk/data/classic_map.svg` - SVG map with 42 territory paths, army labels, continent groups, and connection lines
- `risk/static/index.html` - Single-page HTML with setup screen, game board, modals, and script tags
- `risk/static/style.css` - Dark theme styling with 6 player colors, territory states, phase stepper, and responsive layout

## Decisions Made
- Used schematic rectangle shapes for territories -- prioritizes clarity and clickability over geographic accuracy
- Dark theme with navy/dark blue palette for the game UI
- Territories use simple path rectangles (M/L/Z) rather than complex polygons -- easier to maintain and modify
- Cross-continent adjacencies shown as dashed connection lines in the SVG

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SVG map ready for JavaScript interaction (Plan 03 will add click handlers, coloring, army updates)
- HTML structure has all containers and IDs that Plan 03 JavaScript will target
- CSS interaction classes (selected, valid-target, dimmed) ready for JS to toggle

---
*Phase: 03-web-ui-and-game-setup*
*Completed: 2026-03-08*
