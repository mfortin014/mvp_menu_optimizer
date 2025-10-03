ALTER VIEW public.recipe_line_costs       SET (security_invoker = true);
ALTER VIEW public.recipe_summary          SET (security_invoker = true);
ALTER VIEW public.missing_uom_conversions SET (security_invoker = true);
ALTER VIEW public.ingredient_costs        SET (security_invoker = true);
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='input_catalog' AND c.relkind='v') THEN
    EXECUTE 'ALTER VIEW public.input_catalog SET (security_invoker = true)';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='recipe_line_costs_base' AND c.relkind='v') THEN
    EXECUTE 'ALTER VIEW public.recipe_line_costs_base SET (security_invoker = true)';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
             WHERE n.nspname='public' AND c.relname='prep_costs' AND c.relkind='v') THEN
    EXECUTE 'ALTER VIEW public.prep_costs SET (security_invoker = true)';
  END IF;
END $$;
