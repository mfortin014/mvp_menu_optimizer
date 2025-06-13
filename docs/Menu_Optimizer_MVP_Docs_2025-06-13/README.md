# Menu Optimizer MVP

This is the MVP prototype of the Menu Optimizer tool used by Chef, a culinary consultant, to manage ingredients, recipes, and menu profitability.

## 🧩 Modules Implemented
- Ingredients CRUD + CSV Import/Export
- Recipes CRUD
- Reference Data Editor (UOMs, Status, Categories)
- Error-resilient import logic

## 💡 Development Notes
- Built in Streamlit for fast prototyping
- Supabase handles DB layer and REST interface
- AgGrid used for rich table interactivity

## 📦 MVP Goals
- Validate feature set for ingredient and recipe management
- Enable Chef to load, inspect, and update base data easily
- Ensure import system handles errors clearly

## 🚧 Post-MVP
- Multi-level BOM and recipe-ingredient hierarchy
- Suggestion logic (cost optimization, substitutions)
- Role-based access & multi-client support (OpsForge migration)