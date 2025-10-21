-- ------------------------------------------------------------
-- V000 bootstrap schema snapshot
-- Snapshot date: 2025-09-09 (pre-V001 baseline)
-- Source: schema/archive/supabase_schema_2025-09-09_01.sql captured via pg_dump --schema-only --no-owner --no-privileges
-- Includes app schema objects (public.*) plus required extensions (pgcrypto, uuid-ossp)
-- Sanitized to remove non-deterministic statements (SET, COMMENT, GRANT, OWNER) for migration use
-- ------------------------------------------------------------

--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.13 (Ubuntu 15.13-1.pgdg22.04+1)


--


--
--



--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;



--
--



--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;



--
-- Name: get_recipe_details(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_recipe_details(rid uuid) RETURNS TABLE(ingredient text, qty numeric, qty_uom text, ingredient_type text, package_qty numeric, package_uom text, package_cost numeric, yield_pct numeric, line_cost numeric)
    LANGUAGE sql
    AS $$
select
    i.name as ingredient,
    rl.qty,
    rl.qty_uom,
    i.ingredient_type,
    i.package_qty,
    i.package_uom,
    i.package_cost,
    i.yield_pct,
    case
        when i.package_qty > 0 and i.yield_pct > 0
        then (rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty)
        else 0
    end as line_cost
from recipe_lines rl
join ingredients i on rl.ingredient_id = i.id
where rl.recipe_id = rid
$$;



--
-- Name: get_unit_costs_for_inputs(uuid[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_unit_costs_for_inputs(ids uuid[]) RETURNS TABLE(id uuid, unit_cost numeric)
    LANGUAGE sql STABLE
    AS $$
  SELECT i.id, 
         CASE 
           WHEN i.package_qty > 0 
             THEN (i.package_cost / i.package_qty) 
           ELSE NULL 
         END AS unit_cost
  FROM ingredients i
  WHERE i.id = ANY(ids)

  UNION ALL

  SELECT pc.recipe_id AS id, pc.unit_cost
  FROM prep_costs pc
  WHERE pc.recipe_id = ANY(ids);



--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();



--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();



--
--



--
--



--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ingredient_code text NOT NULL,
    name text NOT NULL,
    ingredient_type text NOT NULL,
    status text DEFAULT 'Active'::text,
    package_qty numeric,
    package_uom text,
    package_cost numeric,
    message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    yield_pct numeric DEFAULT 100.0 NOT NULL,
    category_id uuid,
    base_uom text,
    storage_type_id uuid,
    CONSTRAINT chk_base_uom_allowed CHECK ((base_uom = ANY (ARRAY['g'::text, 'ml'::text, 'unit'::text]))),
    CONSTRAINT ingredients_status_check CHECK ((status = ANY (ARRAY['Active'::text, 'Inactive'::text])))
);



--
-- Name: ref_uom_conversion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_uom_conversion (
    from_uom text NOT NULL,
    to_uom text NOT NULL,
    factor numeric NOT NULL
);



--
-- Name: ingredient_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.ingredient_costs AS
 SELECT i.id AS ingredient_id,
    i.ingredient_code,
    i.name,
    i.package_qty,
    i.yield_pct,
    i.package_uom,
    i.base_uom,
    i.package_cost,
    c.factor AS conversion_factor,
    ((i.package_qty * i.yield_pct) / 100.0) AS package_qty_net,
    (((i.package_qty * i.yield_pct) / 100.0) * c.factor) AS package_qty_net_base_unit,
        CASE
            WHEN ((((i.package_qty * i.yield_pct) / 100.0) * c.factor) > (0)::numeric) THEN (i.package_cost / (((i.package_qty * i.yield_pct) / 100.0) * c.factor))
            ELSE NULL::numeric
        END AS unit_cost
   FROM (public.ingredients i
     LEFT JOIN public.ref_uom_conversion c ON (((i.package_uom = c.from_uom) AND (i.base_uom = c.to_uom))));



--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    recipe_code text NOT NULL,
    name text NOT NULL,
    status text DEFAULT 'Active'::text,
    yield_qty numeric,
    yield_uom text,
    price numeric,
    updated_at timestamp with time zone DEFAULT now(),
    recipe_category text,
    recipe_type text DEFAULT 'service'::text NOT NULL,
    CONSTRAINT recipes_recipe_type_check CHECK ((recipe_type = ANY (ARRAY['service'::text, 'prep'::text])))
);



--
--



--
-- Name: input_catalog; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.input_catalog AS
 SELECT ingredients.id,
    ingredients.ingredient_code AS code,
    ingredients.name,
    'ingredient'::text AS source
   FROM public.ingredients
  WHERE (ingredients.status = 'Active'::text)
UNION ALL
 SELECT recipes.id,
    recipes.recipe_code AS code,
    recipes.name,
    'recipe'::text AS source
   FROM public.recipes
  WHERE ((recipes.status = 'Active'::text) AND (recipes.recipe_type = 'prep'::text));



--
-- Name: recipe_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_lines (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    recipe_id uuid,
    ingredient_id uuid,
    qty numeric,
    qty_uom text,
    note text,
    updated_at timestamp with time zone DEFAULT now()
);



--
-- Name: missing_uom_conversions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.missing_uom_conversions AS
 SELECT rl.id AS recipe_line_id,
    r.name AS recipe,
    i.name AS ingredient,
    rl.qty_uom,
    i.package_uom
   FROM (((public.recipe_lines rl
     JOIN public.recipes r ON ((r.id = rl.recipe_id)))
     JOIN public.ingredients i ON ((i.id = rl.ingredient_id)))
     LEFT JOIN public.ref_uom_conversion c ON (((rl.qty_uom = c.from_uom) AND (i.package_uom = c.to_uom))))
  WHERE (c.factor IS NULL);



--
-- Name: recipe_line_costs_base; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.recipe_line_costs_base AS
 SELECT rl.id AS recipe_line_id,
    rl.recipe_id,
    rl.ingredient_id,
    rl.qty,
    rl.qty_uom,
    i.package_qty,
    i.package_uom,
    i.package_cost,
    i.ingredient_type,
    i.yield_pct,
        CASE
            WHEN ((i.id IS NOT NULL) AND (i.package_qty > (0)::numeric) AND ((rl.qty_uom = i.package_uom) OR (c.factor IS NOT NULL))) THEN
            CASE
                WHEN (rl.qty_uom = i.package_uom) THEN ((rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty))
                ELSE (((rl.qty * c.factor) / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty))
            END
            ELSE (0)::numeric
        END AS line_cost
   FROM ((public.recipe_lines rl
     LEFT JOIN public.ingredients i ON ((i.id = rl.ingredient_id)))
     LEFT JOIN public.ref_uom_conversion c ON (((rl.qty_uom = c.from_uom) AND (i.package_uom = c.to_uom))));



--
-- Name: prep_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.prep_costs AS
 SELECT r.id AS recipe_id,
    r.recipe_code,
    r.name,
    r.yield_qty,
    r.yield_uom,
    sum(COALESCE(rlcb.line_cost, (0)::numeric)) AS total_cost,
    conv.factor AS conversion_factor,
    (r.yield_qty * conv.factor) AS yield_qty_in_base_unit,
        CASE
            WHEN ((r.yield_qty * conv.factor) > (0)::numeric) THEN (sum(COALESCE(rlcb.line_cost, (0)::numeric)) / (r.yield_qty * conv.factor))
            ELSE NULL::numeric
        END AS unit_cost,
    conv.to_uom AS base_uom
   FROM ((public.recipes r
     LEFT JOIN public.recipe_line_costs_base rlcb ON ((rlcb.recipe_id = r.id)))
     LEFT JOIN public.ref_uom_conversion conv ON ((r.yield_uom = conv.from_uom)))
  WHERE ((r.recipe_type = 'prep'::text) AND (r.status = 'Active'::text))
  GROUP BY r.id, r.recipe_code, r.name, r.yield_qty, r.yield_uom, conv.factor, conv.to_uom;



--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    email text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);



--
-- Name: recipe_line_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.recipe_line_costs AS
 SELECT rl.id AS recipe_line_id,
    rl.recipe_id,
    rl.ingredient_id,
    rl.qty,
    rl.qty_uom,
    i.package_qty,
    i.package_uom,
    i.package_cost,
    i.ingredient_type,
    i.yield_pct,
    COALESCE(
        CASE
            WHEN ((i.id IS NOT NULL) AND (i.package_qty > (0)::numeric) AND ((rl.qty_uom = i.package_uom) OR (conv_ing.factor IS NOT NULL))) THEN
            CASE
                WHEN (rl.qty_uom = i.package_uom) THEN ((rl.qty / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty))
                ELSE (((rl.qty * conv_ing.factor) / (i.yield_pct / 100.0)) * (i.package_cost / i.package_qty))
            END
            ELSE NULL::numeric
        END,
        CASE
            WHEN ((pr.id IS NOT NULL) AND (pc.unit_cost IS NOT NULL)) THEN
            CASE
                WHEN (rl.qty_uom = pc.base_uom) THEN (rl.qty * pc.unit_cost)
                ELSE ((rl.qty * conv_prep.factor) * pc.unit_cost)
            END
            ELSE NULL::numeric
        END, (0)::numeric) AS line_cost
   FROM (((((public.recipe_lines rl
     LEFT JOIN public.ingredients i ON ((i.id = rl.ingredient_id)))
     LEFT JOIN public.ref_uom_conversion conv_ing ON (((rl.qty_uom = conv_ing.from_uom) AND (i.package_uom = conv_ing.to_uom))))
     LEFT JOIN public.recipes pr ON (((pr.id = rl.ingredient_id) AND (pr.recipe_type = 'prep'::text))))
     LEFT JOIN public.prep_costs pc ON ((pc.recipe_id = pr.id)))
     LEFT JOIN public.ref_uom_conversion conv_prep ON (((rl.qty_uom = conv_prep.from_uom) AND (pc.base_uom = conv_prep.to_uom))));



--
-- Name: recipe_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.recipe_summary AS
 SELECT r.id AS recipe_id,
    r.recipe_code,
    r.name,
    r.status,
    r.price,
    sum(COALESCE(rlc.line_cost, (0)::numeric)) AS total_cost,
        CASE
            WHEN (r.price > (0)::numeric) THEN round(((sum(COALESCE(rlc.line_cost, (0)::numeric)) / r.price) * 100.0), 2)
            ELSE NULL::numeric
        END AS cost_pct,
        CASE
            WHEN (r.price > (0)::numeric) THEN round((r.price - sum(COALESCE(rlc.line_cost, (0)::numeric))), 2)
            ELSE NULL::numeric
        END AS margin
   FROM (public.recipes r
     LEFT JOIN public.recipe_line_costs rlc ON ((r.id = rlc.recipe_id)))
  WHERE ((r.status = 'Active'::text) AND (r.recipe_type = 'service'::text))
  GROUP BY r.id, r.recipe_code, r.name, r.status, r.price;



--
-- Name: ref_ingredient_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_ingredient_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    status text DEFAULT 'Active'::text
);



--
-- Name: ref_storage_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_storage_type (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'Active'::text NOT NULL
);



--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    recipe_id uuid,
    sale_date date NOT NULL,
    qty numeric NOT NULL,
    list_price numeric,
    discount numeric,
    net_price numeric,
    created_at timestamp without time zone DEFAULT now()
);



--
-- Name: ingredients ingredients_ingredient_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_ingredient_code_key UNIQUE (ingredient_code);



--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);



--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);



--
-- Name: recipe_lines recipe_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_lines
    ADD CONSTRAINT recipe_lines_pkey PRIMARY KEY (id);



--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);



--
-- Name: recipes recipes_recipe_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_recipe_code_key UNIQUE (recipe_code);



--
-- Name: ref_ingredient_categories ref_ingredient_categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_ingredient_categories
    ADD CONSTRAINT ref_ingredient_categories_name_key UNIQUE (name);



--
-- Name: ref_ingredient_categories ref_ingredient_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_ingredient_categories
    ADD CONSTRAINT ref_ingredient_categories_pkey PRIMARY KEY (id);



--
-- Name: ref_storage_type ref_storage_type_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_storage_type
    ADD CONSTRAINT ref_storage_type_name_key UNIQUE (name);



--
-- Name: ref_storage_type ref_storage_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_storage_type
    ADD CONSTRAINT ref_storage_type_pkey PRIMARY KEY (id);



--
-- Name: ref_uom_conversion ref_uom_conversion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_uom_conversion
    ADD CONSTRAINT ref_uom_conversion_pkey PRIMARY KEY (from_uom, to_uom);



--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);



--
-- Name: ux_ref_uom_conversion_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ref_uom_conversion_pair ON public.ref_uom_conversion USING btree (from_uom, to_uom);



--
-- Name: recipe_lines set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.recipe_lines FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();



--
-- Name: recipes set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.recipes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();



--
-- Name: ingredients update_ingredients_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ingredients_updated_at BEFORE UPDATE ON public.ingredients FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();



--
-- Name: ingredients ingredients_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.ref_ingredient_categories(id);



--
-- Name: ingredients ingredients_storage_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_storage_type_id_fkey FOREIGN KEY (storage_type_id) REFERENCES public.ref_storage_type(id);



--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;



--
-- Name: recipe_lines recipe_lines_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_lines
    ADD CONSTRAINT recipe_lines_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;



--
-- Name: sales sales_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: recipe_lines Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.recipe_lines USING (true);



--
-- Name: recipes Allow all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all" ON public.recipes USING (true);



--
-- Name: ingredients Allow all for dev; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for dev" ON public.ingredients USING (true);



--
-- Name: sales Allow all sales access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all sales access" ON public.sales USING (true);



--
-- Name: ingredients Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.ingredients FOR SELECT TO authenticated USING (true);



--
-- Name: recipe_lines Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.recipe_lines FOR SELECT TO authenticated USING (true);



--
-- Name: recipes Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.recipes FOR SELECT TO authenticated USING (true);



--
-- Name: ref_ingredient_categories Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.ref_ingredient_categories FOR SELECT TO authenticated USING (true);



--
-- Name: ref_storage_type Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.ref_storage_type FOR SELECT TO authenticated USING (true);



--
-- Name: ref_uom_conversion Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.ref_uom_conversion FOR SELECT TO authenticated USING (true);



--
-- Name: sales Allow read for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read for authenticated users" ON public.sales FOR SELECT TO authenticated USING (true);



--
-- Name: ingredients Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.ingredients TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: recipe_lines Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.recipe_lines TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: recipes Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.recipes TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: ref_ingredient_categories Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.ref_ingredient_categories TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: ref_storage_type Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.ref_storage_type TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: ref_uom_conversion Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.ref_uom_conversion TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));



--
-- Name: sales Chef full access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Chef full access" ON public.sales TO authenticated USING ((auth.email() = 'davidnoireaut@surlefeu.com'::text)) WITH CHECK ((auth.email() = 'davidnoireaut@surlefeu.com'::text));
