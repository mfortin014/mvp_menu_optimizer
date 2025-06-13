# 📝 Menu Optimizer – Changelog

## MVP Milestone – 2025-06-13

### Features
- Added Ingredients page (CRUD, CSV export, CSV import)
- Added Recipes page (CRUD, CSV export)
- Created Reference Data page (editable UOMs, Status, Categories)
- Added full CSV import validation pipeline
- Inline error reporting + rejected row download
- Improved import formatting (rounding, yield % interpretation)

### Fixes
- `st.experimental_rerun` replaced with `st.rerun`
- Base yield UOM now decoupled from UOM conversion table
- Improved form handling for bad data (duplicate codes, missing fields)

### Known Issues
- AgGrid clear filters UI missing
- Form cancel behavior doesn’t clear sidebar state