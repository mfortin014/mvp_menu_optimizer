-- Migration: add is_menu_item and is_ingredient flags to recipes
ALTER TABLE recipes
  ADD COLUMN is_menu_item BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN is_ingredient BOOLEAN NOT NULL DEFAULT FALSE;
