# 📘 Feature Spec: Recipes as Ingredients (v0.1.3)

## 🧩 Purpose

Enable recipes to be used as ingredients in other recipes, unlocking multi-level composition (e.g., guacamole used in burrito) while maintaining clean separation between `recipes` and `ingredients`. This is foundational for full multi-level BOM in future phases.

---

## 📌 Version

* **Feature Release:** v0.1.3
* **MVP Baseline:** v0.1.2

---

## ✅ Summary of Changes

### Database – Supabase Schema Changes

* Modify `recipes` table:

```sql
ALTER TABLE recipes
ADD COLUMN is_menu_item BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN is_ingredient BOOLEAN NOT NULL DEFAULT FALSE;
```

* Enforce frontend validation: **at least one of `is_menu_item` or `is_ingredient` must be TRUE**

### UI – Recipe Form

* Add two new checkboxes to the recipe form:

  * `Is Menu Item` (default: true)
  * `Is Ingredient` (default: false)
* Tooltip/help text:

  * **Menu Item** = recipe sold to customers (e.g. plate of food)
  * **Ingredient** = recipe used inside another recipe (e.g. spice blend, sauce)
* Form validation:

  * Show warning and block save if both checkboxes are false
  * Recommend using `Status = Inactive` to deactivate recipes

### UX – Recipe Line Ingredient Selection

* In the recipe editor (once `ingredients_recipes_link` is active):

  * Ingredient dropdown should include:

    * All rows from `ingredients` where `status = 'Active'`
    * All rows from `recipes` where `is_ingredient = true` and `status = 'Active'`
  * Display label: `[code] name (type)` → e.g. `[GUA001] Guacamole (Recipe)` or `[AVO001] Avocado (Ingredient)`
  * Internally track which table it comes from using an enum or object wrapper in memory only

### Cost Logic (Planned, Not Yet Implemented)

* If selected item is from `ingredients`, fetch `unit_cost` from `ingredient_costs` view
* If selected item is from `recipes`, fetch cost per base yield dynamically
* No duplication of recipes in `ingredients` table

---

## 🧠 Architecture Decisions

* Do **not** create shadow `ingredients` rows for recipes
* Do **not** add `yield_pct`, `storage_type`, or `category_id` to recipes at this time
* Maintain clean schema separation: `ingredients` are bought/prepped items; `recipes` are assembled dishes or preps

---

## 🔮 Future Extensions (Post-MVP)

* Add recursive cost propagation through recipe layers
* Support full `ingredients_recipes_link` with dual FK (`ingredient_id`, `recipe_id`) + validation that one is not null
* Clean up `base_yield_uom` naming → consider `output_uom`
* Allow `is_sellable` or other channel flags (e.g., `is_packaged_item`) for advanced use cases

---

## 📤 Deliverables

* [ ] Supabase migration SQL
* [ ] Updated recipe form with checkboxes
* [ ] Frontend validation logic
* [ ] Inclusion of recipes in ingredient dropdown (stub only for now)
* [ ] Update `DataDictionary.md` and `Specs.md` to reflect changes

---

**Author:** ChatGPT (Dev Co-Pilot)
**Status:** Ready for implementation
