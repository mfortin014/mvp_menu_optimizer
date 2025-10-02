ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles read own"   ON public.profiles;
DROP POLICY IF EXISTS "profiles write own"  ON public.profiles;
DROP POLICY IF EXISTS "profiles insert own" ON public.profiles;
CREATE POLICY "profiles read own"  ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "profiles write own" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "profiles insert own" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

ALTER TABLE public.schema_migrations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "deny all on schema_migrations" ON public.schema_migrations;
CREATE POLICY "deny all on schema_migrations" ON public.schema_migrations USING (false) WITH CHECK (false);
