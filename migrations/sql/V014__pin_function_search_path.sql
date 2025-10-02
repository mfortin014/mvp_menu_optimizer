DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT n.nspname AS schema_name,
           p.proname  AS func_name,
           oidvectortypes(p.proargtypes) AS arg_types
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'enforce_same_tenant_sales',
        'enforce_same_tenant_recipe_lines',
        'enforce_same_tenant_ingredient_refs',
        'get_recipe_details_mt',
        'get_unit_costs_for_inputs_mt',
        'set_updated_at',
        'update_updated_at_column',
        'get_recipe_details',
        'get_unit_costs_for_inputs'
      )
  LOOP
    EXECUTE format(
      'ALTER FUNCTION %I.%I(%s) SET search_path = public, pg_temp',
      r.schema_name, r.func_name, r.arg_types
    );
  END LOOP;
END $$;
