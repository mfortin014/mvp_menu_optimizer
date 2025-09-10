--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.13 (Ubuntu 15.13-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS postgres;
--
-- Name: postgres; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE postgres WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


\connect postgres

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
begin
    raise debug 'PgBouncer auth request: %', p_usename;

    return query
    select 
        rolname::text, 
        case when rolvaliduntil < now() 
            then null 
            else rolpassword::text 
        end 
    from pg_authid 
    where rolname=$1 and rolcanlogin;
end;
$_$;


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
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  BEGIN
    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (payload, event, topic, private, extension)
    VALUES (payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
  v_order_by text;
  v_sort_order text;
begin
  case
    when sortcolumn = 'name' then
      v_order_by = 'name';
    when sortcolumn = 'updated_at' then
      v_order_by = 'updated_at';
    when sortcolumn = 'created_at' then
      v_order_by = 'created_at';
    when sortcolumn = 'last_accessed_at' then
      v_order_by = 'last_accessed_at';
    else
      v_order_by = 'name';
  end case;

  case
    when sortorder = 'asc' then
      v_sort_order = 'asc';
    when sortorder = 'desc' then
      v_sort_order = 'desc';
    else
      v_sort_order = 'asc';
  end case;

  v_order_by = v_order_by || ' ' || v_sort_order;

  return query execute
    'with folders as (
       select path_tokens[$1] as folder
       from storage.objects
         where objects.name ilike $2 || $3 || ''%''
           and bucket_id = $4
           and array_length(objects.path_tokens, 1) <> $1
       group by folder
       order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_id text NOT NULL,
    client_secret_hash text NOT NULL,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


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
-- Name: COLUMN recipes.recipe_category; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.recipe_category IS 'Free-form text category used for filtering, tagging, and grouping recipes.';


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
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	86e2fb98-3386-4240-b91e-9fad0b6b5b7c	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"davidnoireaut@surlefeu.com","user_id":"d0eb6abd-78a6-4876-895f-e242dbb9c95f","user_phone":""}}	2025-06-27 20:49:52.738934+00	
00000000-0000-0000-0000-000000000000	0e37abf3-b459-406b-a364-8abb485d9ccc	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"d83a81ae-7b15-415c-bd44-229c09646797","user_phone":""}}	2025-06-28 02:43:07.577872+00	
00000000-0000-0000-0000-000000000000	0dd623d4-7b2c-456c-befb-b37bb91f1cfc	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"d83a81ae-7b15-415c-bd44-229c09646797","user_phone":""}}	2025-06-28 03:10:52.044268+00	
00000000-0000-0000-0000-000000000000	539336b0-1a86-458c-ad51-ac2d221c0727	{"action":"user_invited","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"b0dc9089-8da6-4caf-b4ef-ccba470578e1"}}	2025-06-28 03:11:05.777538+00	
00000000-0000-0000-0000-000000000000	ca0237d0-6b6f-4723-b44c-ec540fead98d	{"action":"user_signedup","actor_id":"b0dc9089-8da6-4caf-b4ef-ccba470578e1","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"team"}	2025-06-28 03:11:19.915035+00	
00000000-0000-0000-0000-000000000000	1c26d3a0-6017-4e0e-acc2-8161b1130ca3	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"b0dc9089-8da6-4caf-b4ef-ccba470578e1","user_phone":""}}	2025-06-28 03:25:27.684452+00	
00000000-0000-0000-0000-000000000000	92081902-4e14-40c0-96df-1a84269fc6c5	{"action":"user_invited","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"042dec9e-439e-4fd5-9a69-02bcd264f164"}}	2025-06-28 03:25:38.700742+00	
00000000-0000-0000-0000-000000000000	052c4e0e-3b6e-422c-86c8-a7ecd3279e5b	{"action":"user_signedup","actor_id":"042dec9e-439e-4fd5-9a69-02bcd264f164","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"team"}	2025-06-28 03:25:47.478934+00	
00000000-0000-0000-0000-000000000000	f244eb74-849c-4828-a153-928a91cda596	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"042dec9e-439e-4fd5-9a69-02bcd264f164","user_phone":""}}	2025-06-28 03:32:03.674343+00	
00000000-0000-0000-0000-000000000000	98dfa093-9b89-4ccf-9f70-8ed4cbf0370b	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"davidnoireaut@surlefeu.com","user_id":"d0eb6abd-78a6-4876-895f-e242dbb9c95f","user_phone":""}}	2025-06-28 03:32:03.686196+00	
00000000-0000-0000-0000-000000000000	dee215bc-d81b-46f1-829c-daa6e7661771	{"action":"user_invited","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"db9f2803-1a2f-43ab-8e09-7632accaadaa"}}	2025-06-28 03:40:02.209796+00	
00000000-0000-0000-0000-000000000000	20c17d52-db66-4c01-807a-9f2deb70db39	{"action":"user_signedup","actor_id":"db9f2803-1a2f-43ab-8e09-7632accaadaa","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"team"}	2025-06-28 03:40:11.572488+00	
00000000-0000-0000-0000-000000000000	cbc9e024-c9e2-49f6-9b7d-4de39121e174	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"db9f2803-1a2f-43ab-8e09-7632accaadaa","user_phone":""}}	2025-06-28 03:50:32.184064+00	
00000000-0000-0000-0000-000000000000	9cf74d1b-6473-4949-adf4-f7695edb85b9	{"action":"user_invited","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"c688d3c0-ce27-4b9c-93d9-b07e250f52c2"}}	2025-06-28 03:50:45.451412+00	
00000000-0000-0000-0000-000000000000	e7cd0016-5a4c-4be8-af9a-513457020924	{"action":"user_signedup","actor_id":"c688d3c0-ce27-4b9c-93d9-b07e250f52c2","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"team"}	2025-06-28 03:50:55.017474+00	
00000000-0000-0000-0000-000000000000	e68688fa-7d4e-48cf-821e-b7baa7c1b934	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"c688d3c0-ce27-4b9c-93d9-b07e250f52c2","user_phone":""}}	2025-06-28 03:54:01.406323+00	
00000000-0000-0000-0000-000000000000	c092512c-7dd6-4d12-a6dc-a423bfd9c226	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"2f2de70e-06c8-4c55-812b-3ad6060801e1","user_phone":""}}	2025-06-28 03:54:27.946514+00	
00000000-0000-0000-0000-000000000000	f4c7b907-219a-4e1f-b67a-58663e57ed63	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"mfortin014@outlook.com","user_id":"2f2de70e-06c8-4c55-812b-3ad6060801e1","user_phone":""}}	2025-06-28 03:55:46.031573+00	
00000000-0000-0000-0000-000000000000	e4aa2bf6-b8df-44bf-8447-7991591c563c	{"action":"user_signedup","actor_id":"07460c52-136f-442e-9245-fdca3a3570e5","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"team","traits":{"provider":"email"}}	2025-06-28 03:58:23.276939+00	
00000000-0000-0000-0000-000000000000	f32fe7b0-3422-4ab4-bbfe-efcdb733752d	{"action":"login","actor_id":"07460c52-136f-442e-9245-fdca3a3570e5","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-06-28 03:58:23.28018+00	
00000000-0000-0000-0000-000000000000	8087c293-d7d2-41b8-8c0f-8f5424e2a89b	{"action":"login","actor_id":"07460c52-136f-442e-9245-fdca3a3570e5","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-06-28 03:59:08.264802+00	
00000000-0000-0000-0000-000000000000	914fe772-0ed6-4832-9b04-65f03f1cad9f	{"action":"login","actor_id":"07460c52-136f-442e-9245-fdca3a3570e5","actor_username":"mfortin014@outlook.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2025-06-28 04:01:10.952204+00	
00000000-0000-0000-0000-000000000000	3b6f24e4-e4fb-424b-a966-6c7c424f8f36	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"davidnoireaut@surlefeu.com","user_id":"39300d94-b4f7-464d-8d54-87bdf83008c6","user_phone":""}}	2025-06-28 04:18:02.934188+00	
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
07460c52-136f-442e-9245-fdca3a3570e5	07460c52-136f-442e-9245-fdca3a3570e5	{"sub": "07460c52-136f-442e-9245-fdca3a3570e5", "email": "mfortin014@outlook.com", "email_verified": false, "phone_verified": false}	email	2025-06-28 03:58:23.272712+00	2025-06-28 03:58:23.272757+00	2025-06-28 03:58:23.272757+00	ae454045-2e7a-40c5-b1e9-5164a0a61091
39300d94-b4f7-464d-8d54-87bdf83008c6	39300d94-b4f7-464d-8d54-87bdf83008c6	{"sub": "39300d94-b4f7-464d-8d54-87bdf83008c6", "email": "davidnoireaut@surlefeu.com", "email_verified": false, "phone_verified": false}	email	2025-06-28 04:18:02.931316+00	2025-06-28 04:18:02.931373+00	2025-06-28 04:18:02.931373+00	08270f53-38c8-4e1a-9fd9-ca52452749d6
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
696e1793-78fd-4346-ae8a-6283e7a38a52	2025-06-28 03:58:23.28464+00	2025-06-28 03:58:23.28464+00	password	30eee30f-36ca-42d7-b150-3d0f40223ccb
16a99cd6-fd6d-4c2d-ba09-34c4e63c8872	2025-06-28 03:59:08.269622+00	2025-06-28 03:59:08.269622+00	password	117581b9-6242-4f71-a1b2-96427b51be9c
97b4180b-fdf9-418e-9573-234b6d802dd8	2025-06-28 04:01:10.956149+00	2025-06-28 04:01:10.956149+00	password	e7d2a516-d878-4c71-9abc-d4930f1a1113
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	5	aa5lqoyaddc6	07460c52-136f-442e-9245-fdca3a3570e5	f	2025-06-28 03:58:23.282298+00	2025-06-28 03:58:23.282298+00	\N	696e1793-78fd-4346-ae8a-6283e7a38a52
00000000-0000-0000-0000-000000000000	6	pkqh7crhbqi3	07460c52-136f-442e-9245-fdca3a3570e5	f	2025-06-28 03:59:08.2678+00	2025-06-28 03:59:08.2678+00	\N	16a99cd6-fd6d-4c2d-ba09-34c4e63c8872
00000000-0000-0000-0000-000000000000	7	eej4qwplmfj6	07460c52-136f-442e-9245-fdca3a3570e5	f	2025-06-28 04:01:10.954281+00	2025-06-28 04:01:10.954281+00	\N	97b4180b-fdf9-418e-9573-234b6d802dd8
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag) FROM stdin;
696e1793-78fd-4346-ae8a-6283e7a38a52	07460c52-136f-442e-9245-fdca3a3570e5	2025-06-28 03:58:23.281309+00	2025-06-28 03:58:23.281309+00	\N	aal1	\N	\N	python-httpx/0.28.1	24.157.136.7	\N
16a99cd6-fd6d-4c2d-ba09-34c4e63c8872	07460c52-136f-442e-9245-fdca3a3570e5	2025-06-28 03:59:08.266339+00	2025-06-28 03:59:08.266339+00	\N	aal1	\N	\N	python-httpx/0.28.1	24.157.136.7	\N
97b4180b-fdf9-418e-9573-234b6d802dd8	07460c52-136f-442e-9245-fdca3a3570e5	2025-06-28 04:01:10.953207+00	2025-06-28 04:01:10.953207+00	\N	aal1	\N	\N	python-httpx/0.28.1	24.157.136.7	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	39300d94-b4f7-464d-8d54-87bdf83008c6	https://byztmlhsprlovkvizyks.supabase.co/auth/v1/admin/users	authenticated	davidnoireaut@surlefeu.com	$2a$10$5ZEHuLZpDbrlQRaPyXp4FeQfeJpULpT9edaE7KuuULJ2dVs4YsDf2	2025-06-28 04:18:02.937081+00	\N		\N		\N			\N	\N	{"provider": "email", "providers": ["email"]}	{"email_verified": true}	\N	2025-06-28 04:18:02.926759+00	2025-06-28 04:18:02.937948+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	07460c52-136f-442e-9245-fdca3a3570e5	authenticated	authenticated	mfortin014@outlook.com	$2a$10$WlmEjmnIKnFgErFKu5nmy.jxUP7JgNf4oF3tl3L1awLv6qNvg9AAO	2025-06-28 03:58:23.277595+00	\N		\N		\N			\N	2025-06-28 04:01:10.953136+00	{"provider": "email", "providers": ["email"]}	{"sub": "07460c52-136f-442e-9245-fdca3a3570e5", "email": "mfortin014@outlook.com", "email_verified": true, "phone_verified": false}	\N	2025-06-28 03:58:23.267998+00	2025-06-28 04:01:10.955612+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: ingredients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ingredients (id, ingredient_code, name, ingredient_type, status, package_qty, package_uom, package_cost, message, created_at, updated_at, yield_pct, category_id, base_uom, storage_type_id) FROM stdin;
45743d9c-8a60-4363-b8a7-8b83a20ff36d	IN0024	Steak surlonge (8oz)	Bought	Active	7.0	kg	98.55	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.284298+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
2d76d98e-0770-4525-8343-a811c38a0bc7	IN0025	Laitue iceberg	Bought	Active	3.5	kg	4.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.374219+00	99	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
344fd58c-5244-41ca-92e6-84dc5a4e7b62	IN0026	Riz jasmin	Bought	Active	10.0	kg	8.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.488831+00	178	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
c225e5ff-5760-4eb4-8eb5-b1a38df523c7	IN0012	Ail hache dans l'huile	Bought	Active	2.5	kg	11.2	\N	2025-06-30 15:04:08.706003+00	2025-06-30 15:25:44.975123+00	100.0	3fd17bdb-cd20-48fa-b1a5-7f09022aa6cd	g	0b30afa0-926d-4f20-855d-2a1c21681629
f59bc85b-e34c-47f4-85b8-165c413b1855	IN0020	Bacon congele	Bought	Active	13.51	kg	83.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 19:51:05.815101+00	100.0	354b0ca9-7269-4d03-b541-c87d16513389	g	6b48379a-77cb-47cc-9695-69c8a797b312
38428292-d20d-44fb-8df4-1f33753fc15c	IN0001	Poulet	Bought	Active	2.5	kg	12.99	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:13:44.275976+00	99	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
a4d436ba-8063-438e-9079-4f958e44790e	IN0002	Pain club blanc	Bought	Active	500.0	g	1.35	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:13:44.389631+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
a0e5f268-e7b0-449f-a5f7-c846810bbb66	IN0003	BBQ Sauce poudre	Bought	Active	1000.0	g	5.99	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:13:44.479236+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
801c3d66-5c0e-4908-8f70-37eaa28ae334	IN0004	Oignons	Bought	Active	12.5	kg	3.45	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:13:44.585321+00	80	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
47a870d4-ddc4-41cf-abd3-6c6b4cbc46d5	IN0005	Riz	Bought	Active	10.0	kg	5.99	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:13:44.804636+00	200.0	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
a0232bd3-4178-4ad0-8ba5-c1454701d432	IN0008	Chou vert	Bought	Active	5.0	kg	3.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.066+00	99	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
7bedcfb7-b108-464c-ba7f-8de77aa51335	IN0009	Carottes	Bought	Active	16.5	kg	22.0	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.2086+00	91	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
5b03a372-66f2-476a-84fe-6503add01166	IN0010	Oignons	Bought	Active	16.5	kg	20.0	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.313513+00	95	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
2bbe9282-cd28-4583-82c2-18b029b66eec	IN0011	Mayonaise	Bought	Active	2.5	kg	7.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.402329+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
24c1048b-a15f-458c-bc52-48c3300570c3	IN0014	Vermicelle de riz	Bought	Active	454.0	g	1.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.509869+00	200	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
df6d5322-7cd6-4098-91e3-41279d1fdfc5	IN0016	Poivrons vert	Bought	Active	4.54	kg	29.33	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.610129+00	90	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
6a270037-d8eb-4801-a930-a1813edaa0d4	IN0017	Poivrons rouge	Bought	Active	4.54	kg	37.0	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.747579+00	90	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
c6ad4206-6bb1-44cb-a25b-f3f0b6122dbb	IN0018	Orange	Bought	Active	10.0	kg	22.0	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.840341+00	95	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
2495cc39-606e-4a8a-887f-f99e4e7e88e1	IN0019	Poisson panne	Bought	Active	10.0	kg	43.95	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:45.940379+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
cea2a4dd-60ef-456b-bb0e-ab7a68f98d17	IN0021	Bouillon de poulet poudre	Bought	Active	1.0	kg	5.79	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.066841+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
dd705dd0-6e97-43c0-8c03-231e257b0291	IN0022	Tomate	Bought	Active	5.0	kg	7.55	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.16842+00	99	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
371700d0-0ffd-4ef7-b91f-186247a04adb	IN0027	Morceau de poitrine de poulet pannes	Bought	Active	13.5	kg	181.59	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.591723+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
fdf3c85a-76ec-4054-b183-02255a7cba40	IN0028	Sauce Tao	Bought	Active	18.0	kg	75.85	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:13:46.679448+00	100	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
61253cf2-7b31-4045-8958-fdb952bc5664	IN0013	Huile canola	Bought	Active	18.0	L	27.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:14:23.697885+00	100.0	e40f33f9-171c-4aac-b02e-3e9daed18896	ml	\N
1843fe84-7da8-40d6-8cf0-48b0e08d5c2b	IN0007	Petit Pois	Bought	Active	1.0	kg	2.99	\N	2025-06-27 16:02:25.762337+00	2025-06-30 20:14:35.093087+00	100.0	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
87eb4d15-7971-4932-9048-50761c988586	IN0015	Sauce hoisin	Bought	Active	1.18	L	4.59	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:14:44.644609+00	100.0	e40f33f9-171c-4aac-b02e-3e9daed18896	ml	\N
de0c9952-51eb-401d-8dda-efe2f3b89c03	IN0023	Tomate en conserve (des)	Bought	Active	1.72	L	2.99	\N	2025-06-30 15:04:08.706003+00	2025-06-30 20:14:54.164069+00	75.0	e40f33f9-171c-4aac-b02e-3e9daed18896	ml	\N
65a6f9a7-c638-467c-b875-6de2dd796b47	IN0006	Frite	Bought	Active	15.0	kg	49.99	\N	2025-06-27 16:02:25.762337+00	2025-09-08 13:28:46.482955+00	100.0	e40f33f9-171c-4aac-b02e-3e9daed18896	g	\N
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profiles (id, email, created_at) FROM stdin;
\.


--
-- Data for Name: recipe_lines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recipe_lines (id, recipe_id, ingredient_id, qty, qty_uom, note, updated_at) FROM stdin;
40ff70c9-a6c9-441f-b492-1d676ea87ecc	b3f67726-5970-4901-ad15-26f8ab643da5	2495cc39-606e-4a8a-887f-f99e4e7e88e1	300.0	g	\N	2025-06-30 15:11:34.490946+00
664f9f0b-8df4-4685-aeb9-fc42bc0533e7	e1104d81-2625-4b7b-9d62-275b404a0afb	2bbe9282-cd28-4583-82c2-18b029b66eec	875.0	g	\N	2025-07-01 13:41:07.3726+00
095709cb-c480-42be-ac7b-0726aea6899d	e1104d81-2625-4b7b-9d62-275b404a0afb	c225e5ff-5760-4eb4-8eb5-b1a38df523c7	75.0	g	\N	2025-07-01 13:41:32.754218+00
2bdd6619-f00c-41fa-8963-5b607e38ee89	b3f67726-5970-4901-ad15-26f8ab643da5	65a6f9a7-c638-467c-b875-6de2dd796b47	120.0	g	\N	2025-07-01 13:45:03.142514+00
0cdb3dff-9767-4535-8746-c2ece5102415	b3f67726-5970-4901-ad15-26f8ab643da5	a0232bd3-4178-4ad0-8ba5-c1454701d432	80.0	g	\N	2025-07-01 13:45:30.44399+00
63f4847e-f712-48f2-be17-f8e691239b81	70ca3c30-37c1-419b-ac43-077c2712ab74	7bedcfb7-b108-464c-ba7f-8de77aa51335	30.0	g	\N	2025-07-01 13:50:26.657644+00
06f87e47-4c24-4bf2-a351-fa4a40ca07dd	70ca3c30-37c1-419b-ac43-077c2712ab74	5b03a372-66f2-476a-84fe-6503add01166	50.0	g	\N	2025-07-01 13:50:39.330224+00
166f8f4f-427c-4434-b225-f8e35dac2723	70ca3c30-37c1-419b-ac43-077c2712ab74	344fd58c-5244-41ca-92e6-84dc5a4e7b62	120.0	g	\N	2025-07-01 13:51:07.177078+00
58af1952-ea1e-4b27-b6d1-96416a39d61d	70ca3c30-37c1-419b-ac43-077c2712ab74	371700d0-0ffd-4ef7-b91f-186247a04adb	120.0	g	\N	2025-07-01 13:51:21.96514+00
cacff18b-b749-451f-8e47-3581b28b41f6	70ca3c30-37c1-419b-ac43-077c2712ab74	fdf3c85a-76ec-4054-b183-02255a7cba40	100.0	g	\N	2025-07-01 13:51:53.412724+00
2c37a559-6f70-4fc1-a0fc-5e65a2f8c1f4	e1104d81-2625-4b7b-9d62-275b404a0afb	87eb4d15-7971-4932-9048-50761c988586	50.0	ml	\N	2025-09-03 19:07:28.170972+00
eb6e0504-80c2-441d-ba15-3717d0df8b98	7a367bf3-59e8-4052-b029-bd381f83e11e	dd705dd0-6e97-43c0-8c03-231e257b0291	1.0	kg	\N	2025-09-05 02:28:51.448325+00
acf951fb-3d9e-42a8-bbf4-72cffd0dc0ef	7a367bf3-59e8-4052-b029-bd381f83e11e	dd705dd0-6e97-43c0-8c03-231e257b0291	5.0	kg	\N	2025-09-05 02:33:27.912295+00
9d9d2354-ea94-4c28-8cdd-97d0bb7be4fe	b62578e3-6e78-4066-8f5a-51e6cf487366	7a367bf3-59e8-4052-b029-bd381f83e11e	150.0	ml	\N	2025-09-05 02:38:06.823717+00
ee613822-38f5-49ae-b298-bab97283ace9	7a367bf3-59e8-4052-b029-bd381f83e11e	5b03a372-66f2-476a-84fe-6503add01166	1.0	kg	\N	2025-09-08 14:53:22.650925+00
c9d87575-3030-451a-afda-7dfb417202fe	7a367bf3-59e8-4052-b029-bd381f83e11e	61253cf2-7b31-4045-8958-fdb952bc5664	29.9	ml	\N	2025-09-09 03:04:10.300506+00
\.


--
-- Data for Name: recipes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recipes (id, recipe_code, name, status, yield_qty, yield_uom, price, updated_at, recipe_category, recipe_type) FROM stdin;
b3f67726-5970-4901-ad15-26f8ab643da5	REC0003	Fish&Chips	Active	1.0	Serving	23.33	2025-06-30 15:08:27.882313+00	Service	service
ae44b82b-8403-4619-9a32-cfd5aee54dce	REC0001	Hot Chicken	Active	1.0	Serving	15.0	2025-06-30 18:55:22.996499+00	Service	service
7a367bf3-59e8-4052-b029-bd381f83e11e	PREP0002	Guacamole	Active	1.0	L	0.0	2025-09-05 01:49:20.674285+00	Prep	prep
b62578e3-6e78-4066-8f5a-51e6cf487366	REC0004	Tacos Con Carne	Active	1.0	Serving	21.99	2025-09-05 01:52:13.520557+00	Service	service
e1104d81-2625-4b7b-9d62-275b404a0afb	PREP0001	Sauce Tartare	Active	2.0	kg	0.0	2025-09-05 01:53:11.225079+00	Prep	prep
8206c16f-17ea-4b69-9e69-f1a7a9e77915	REC0005	Poutine	Active	1.0	unit	0.0	2025-09-06 04:22:39.576059+00	\N	service
70ca3c30-37c1-419b-ac43-077c2712ab74	REC0002	Poulet Tao	Active	1.0	Serving	18.99	2025-09-08 14:25:14.837726+00	Service	service
469a40a0-2c50-4c51-9b0a-f5b17c7a4640	REC0006	Steak & Frites	Active	1.0	Serving	28.99	2025-09-08 14:26:18.204113+00	Grillades	service
0ae1f9b2-2205-4eab-b9e6-6261399c7c3f	REC0011	Test4	Inactive	1.0	Serving	0.01	2025-09-09 01:38:37.295254+00	test	service
76fd80e2-14ad-48fe-ac5d-da694b1637cf	REC0007	Steak & Frites	Inactive	1.0	Serving	28.99	2025-09-09 01:38:44.709527+00	Grillades	service
dc0baee5-f13a-4e1b-bfa9-d85c33f7924a	REC00012	test	Active	1.0	Serving	0.0	2025-09-09 02:07:35.728062+00	test	service
cc5f1d16-bfff-4005-9262-f34209bd8c98	REC00013	test	Active	0.0	Serving	0.0	2025-09-09 02:09:32.33823+00	\N	service
863a7dbf-182e-494d-89ab-2d72f913ae1b	REC00014	test	Active	0.0	Serving	0.0	2025-09-09 02:26:57.533455+00	\N	service
\.


--
-- Data for Name: ref_ingredient_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ref_ingredient_categories (id, name, status) FROM stdin;
62ad0f8a-d3c7-45d2-b942-1faa5b4a32cc	Vegetables	Active
29d52687-8706-410f-9ed3-f41a1bedb4df	Fruits	Active
e5213d6d-340e-44e5-86fb-6709770ac8ff	Grains & Cereals	Active
4f8b4db7-6c80-4141-bff0-357e7daac3e7	Dairy	Active
354b0ca9-7269-4d03-b541-c87d16513389	Protein	Active
575e534d-144c-4cec-8097-e32fdc92df37	Seafood	Active
a209c281-71ec-43c5-b107-73480e823f01	Sauces & Condiments	Active
29f0857d-a8e4-47f9-b2cb-2e2e63dcce8e	Baking & Sweets	Active
93cc9a1f-9a6e-406b-961a-72600fd21d84	Beverages	Active
b48772fa-9a1f-4a97-897a-9ffb21c692a9	Prepared Ingredients	Active
5a62514b-d1d8-460d-8ffc-0cde041af5e6	Other	Active
b9c15734-9ba5-4208-9fab-ea89bd7507bd	test	Active
3fd17bdb-cd20-48fa-b1a5-7f09022aa6cd	Herbs & Spices	Active
e40f33f9-171c-4aac-b02e-3e9daed18896	TBD	Active
\.


--
-- Data for Name: ref_storage_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ref_storage_type (id, name, description, status) FROM stdin;
0b30afa0-926d-4f20-855d-2a1c21681629	Dry	Shelf-stable items stored at room temperature	Active
ce4106e5-4b55-4b8b-9f7a-40db168d0ccc	Fridge	Items that require refrigeration	Active
6b48379a-77cb-47cc-9695-69c8a797b312	Freezer	Frozen items stored at subzero temperatures	Active
2669a2f7-21ac-4b0a-88e0-6ca6169d393b	Other	For uncommon or mixed storage conditions	Active
\.


--
-- Data for Name: ref_uom_conversion; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ref_uom_conversion (from_uom, to_uom, factor) FROM stdin;
g	kg	0.001
ml	L	0.001
kg	g	1000
L	ml	1000
unit	unit	1
lb	g	453.592
g	lb	0.0022046244201837776
oz	g	28.3495
g	oz	0.03527399072294044
tbsp	g	15.0
g	tbsp	0.06666666666666667
each	unit	1
g	g	1.0
ml	ml	1.0
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales (id, recipe_id, sale_date, qty, list_price, discount, net_price, created_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2025-05-26 18:09:49
20211116045059	2025-05-26 18:09:52
20211116050929	2025-05-26 18:09:54
20211116051442	2025-05-26 18:09:56
20211116212300	2025-05-26 18:09:59
20211116213355	2025-05-26 18:10:01
20211116213934	2025-05-26 18:10:03
20211116214523	2025-05-26 18:10:06
20211122062447	2025-05-26 18:10:08
20211124070109	2025-05-26 18:10:10
20211202204204	2025-05-26 18:10:12
20211202204605	2025-05-26 18:10:14
20211210212804	2025-05-26 18:10:20
20211228014915	2025-05-26 18:10:22
20220107221237	2025-05-26 18:10:24
20220228202821	2025-05-26 18:10:26
20220312004840	2025-05-26 18:10:28
20220603231003	2025-05-26 18:10:31
20220603232444	2025-05-26 18:10:33
20220615214548	2025-05-26 18:10:36
20220712093339	2025-05-26 18:10:38
20220908172859	2025-05-26 18:10:40
20220916233421	2025-05-26 18:10:42
20230119133233	2025-05-26 18:10:44
20230128025114	2025-05-26 18:10:47
20230128025212	2025-05-26 18:10:49
20230227211149	2025-05-26 18:10:51
20230228184745	2025-05-26 18:10:53
20230308225145	2025-05-26 18:10:55
20230328144023	2025-05-26 18:10:57
20231018144023	2025-05-26 18:10:59
20231204144023	2025-05-26 18:11:03
20231204144024	2025-05-26 18:11:05
20231204144025	2025-05-26 18:11:07
20240108234812	2025-05-26 18:11:09
20240109165339	2025-05-26 18:11:11
20240227174441	2025-05-26 18:11:14
20240311171622	2025-05-26 18:11:17
20240321100241	2025-05-26 18:11:22
20240401105812	2025-05-26 18:11:27
20240418121054	2025-05-26 18:11:30
20240523004032	2025-05-26 18:11:37
20240618124746	2025-05-26 18:11:39
20240801235015	2025-05-26 18:11:41
20240805133720	2025-05-26 18:11:43
20240827160934	2025-05-26 18:11:46
20240919163303	2025-05-26 18:11:48
20240919163305	2025-05-26 18:11:50
20241019105805	2025-05-26 18:11:52
20241030150047	2025-05-26 18:12:00
20241108114728	2025-05-26 18:12:03
20241121104152	2025-05-26 18:12:05
20241130184212	2025-05-26 18:12:07
20241220035512	2025-05-26 18:12:09
20241220123912	2025-05-26 18:12:11
20241224161212	2025-05-26 18:12:13
20250107150512	2025-05-26 18:12:15
20250110162412	2025-05-26 18:12:17
20250123174212	2025-05-26 18:12:20
20250128220012	2025-05-26 18:12:22
20250506224012	2025-05-26 18:12:23
20250523164012	2025-05-28 14:30:10
20250714121412	2025-07-18 15:14:45
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2025-05-26 18:09:46.108894
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2025-05-26 18:09:46.111865
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2025-05-26 18:09:46.114107
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2025-05-26 18:09:46.131573
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2025-05-26 18:09:46.152055
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2025-05-26 18:09:46.154516
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2025-05-26 18:09:46.157196
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2025-05-26 18:09:46.16028
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2025-05-26 18:09:46.163283
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2025-05-26 18:09:46.166055
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2025-05-26 18:09:46.168757
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2025-05-26 18:09:46.172455
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2025-05-26 18:09:46.178699
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2025-05-26 18:09:46.182183
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2025-05-26 18:09:46.184489
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2025-05-26 18:09:46.206956
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2025-05-26 18:09:46.209692
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2025-05-26 18:09:46.213784
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2025-05-26 18:09:46.217636
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2025-05-26 18:09:46.22194
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2025-05-26 18:09:46.226922
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2025-05-26 18:09:46.235967
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2025-05-26 18:09:46.262044
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2025-05-26 18:09:46.720309
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2025-05-26 18:09:46.723242
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2025-05-26 18:09:46.725727
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 7, true);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_client_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_client_id_key UNIQUE (client_id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


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
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_clients_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_client_id_idx ON auth.oauth_clients USING btree (client_id);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: ux_ref_uom_conversion_pair; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_ref_uom_conversion_pair ON public.ref_uom_conversion USING btree (from_uom, to_uom);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: subscription_subscription_id_entity_filters_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_key ON realtime.subscription USING btree (subscription_id, entity, filters);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


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
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


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
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

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


--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

