create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null,
  name       text not null default '',
  color      text not null default 'mint',
  bio        text not null default '',
  role       text not null default 'member'  check (role in ('admin','member')),
  status     text not null default 'pending' check (status in ('pending','active','blocked')),
  created_at timestamptz not null default now()
);

create table if not exists public.boards (
  id         text primary key,
  data       jsonb not null,
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create table if not exists public.templates (
  id         text primary key,
  data       jsonb not null,
  updated_by uuid,
  updated_at timestamptz not null default now()
);

create or replace function public.master_email() returns text
language sql immutable set search_path = public as $$ select 'grupovilane@gmail.com'::text $$;

create or replace function public.is_active() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'active')
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and status = 'active' and role = 'admin')
$$;

create or replace function public.guard_master_signup() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if lower(coalesce(new.email, '')) = public.master_email()
     and coalesce(new.raw_app_meta_data->>'provider', '') <> 'google' then
    raise exception 'O e-mail do administrador só entra com o Google.';
  end if;
  return new;
end $$;

drop trigger if exists guard_master_signup on auth.users;
create trigger guard_master_signup
  before insert on auth.users
  for each row execute function public.guard_master_signup();

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  is_master boolean;
  n int;
begin
  select count(*) into n from public.profiles;
  is_master := lower(coalesce(new.email, '')) = public.master_email();
  insert into public.profiles (id, email, name, color, role, status)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(nullif(new.raw_user_meta_data->>'name', ''), nullif(new.raw_user_meta_data->>'full_name', ''), split_part(coalesce(new.email, ''), '@', 1)),
    (array['mint','apricot','teal','gold','royal','serenity'])[1 + (n % 6)],
    case when is_master then 'admin' else 'member' end,
    case when is_master then 'active' else 'pending' end
  );
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.guard_profile() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if new.id <> old.id then
    raise exception 'Não é permitido trocar o id da conta.';
  end if;
  if new.role <> old.role then
    raise exception 'A função de uma conta não pode ser alterada.';
  end if;
  if public.is_admin() then
    if old.id = auth.uid() and new.status <> old.status then
      raise exception 'O administrador não pode mudar o próprio status.';
    end if;
    return new;
  end if;
  if old.id <> auth.uid() then
    raise exception 'Você só pode editar a sua própria conta.';
  end if;
  if new.status <> old.status or new.email <> old.email then
    raise exception 'Você não pode alterar status ou e-mail.';
  end if;
  return new;
end $$;

drop trigger if exists guard_profile_update on public.profiles;
create trigger guard_profile_update
  before update on public.profiles
  for each row execute function public.guard_profile();

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.boards, public.templates to authenticated;
grant all on public.profiles, public.boards, public.templates to service_role;

alter table public.profiles  enable row level security;
alter table public.boards    enable row level security;
alter table public.templates enable row level security;

create policy "perfis: ver" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_active());
create policy "perfis: editar" on public.profiles
  for update to authenticated using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());
create policy "quadros: tudo" on public.boards
  for all to authenticated using (public.is_active()) with check (public.is_active());
create policy "modelos: tudo" on public.templates
  for all to authenticated using (public.is_active()) with check (public.is_active());

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.boards;
alter publication supabase_realtime add table public.templates;