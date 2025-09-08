# Recipes Page – Workplan & Checklist

> Feature branch: `dev_featClean`

## Group A — Table, filters, CSV
- [ ] Status filter: All / Active / Inactive (empty-safe)
- [ ] Type filter: All / Service / Prep (empty-safe)
- [ ] Columns: Cost (% of price), Margin ($)
- [ ] CSV export mirrors current grid (filters + order)
- [ ] CSV filename includes status/type and timestamp

## Group B — Form UX & UOM
- [ ] UOM dropdown from `ref_uom_conversion` (unique set)
- [ ] When type=prep: exclude "service" UOM
- [ ] When type=service: default UOM to "Serving" (fallback "unit")
- [ ] Selecting a row loads yield_uom correctly
- [ ] Price disabled for prep
- [ ] Buttons always inline: Save / Delete / Clear
- [ ] Delete visible always, disabled when nothing loaded

## Group C — Clear behavior (spike → pick → finalize)
- [ ] Wire clear button to safe placeholder (no crash)
- [ ] Spike Option 1: page bounce via `st.switch_page`
- [ ] Spike Option 2: dummy-record reset
- [ ] Decide & implement final approach in a follow-up commit

## Group D — CSV & Docs
- [ ] Export uses exact grid snapshot and timestamped filename
- [ ] This checklist committed and kept up to date

---

## Testing notes (each checkbox verified)
- Filters: selecting “Inactive” on an all-active dataset shows info state; CSV disabled.
- Type filter: switching to “Prep” shows only prep rows; no errors when none exist.
- UOM logic: type flip changes choices/defaults immediately.
- Row selection: UOM loads correctly every time.
- Price locked for prep; editable for service.
- Clear never throws; chosen approach clears form as specified in the three cases.
- CSV rows/order match the grid exactly.
