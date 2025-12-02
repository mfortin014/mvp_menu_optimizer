-- ============================================
-- V017: Profile sync with auth.users
--   - Auto-create profiles row when auth.users row is created
--   - Sync email from auth.users to profiles
--   - Ensure profiles.id matches auth.users.id
-- ============================================

-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Insert or update profile when auth.users row is created/updated
  insert into public.profiles (id, email, created_at)
  values (
    new.id,
    new.email,
    coalesce(new.created_at, now())
  )
  on conflict (id) do update
  set email = new.email;
  
  return new;
end;
$$;

-- Trigger to auto-create/update profile on auth.users insert
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert or update of email on auth.users
  for each row
  execute function public.handle_new_user();

-- Sync existing auth.users to profiles (backfill)
insert into public.profiles (id, email, created_at)
select 
  id,
  email,
  coalesce(created_at, now())
from auth.users
where id not in (select id from public.profiles)
on conflict (id) do update
set email = excluded.email;

-- Comment
comment on function public.handle_new_user() is 'Auto-creates/updates profiles row when auth.users row is created or email is updated';

