-- BarBer Supplier initial Supabase schema
-- Run this file in Supabase SQL Editor for the project used by the app.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.supplier_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  company_name text not null,
  contact_name text,
  phone text,
  tax_number text,
  tax_office text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'suspended', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger supplier_profiles_set_updated_at
before update on public.supplier_profiles
for each row execute function public.set_updated_at();

create table if not exists public.supplier_products (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.supplier_profiles(id) on delete cascade,
  name text not null,
  category text not null default '',
  sku text,
  price numeric(12, 2) not null check (price >= 0),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  minimum_order_quantity integer not null default 1 check (minimum_order_quantity >= 1),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists supplier_products_supplier_id_idx
on public.supplier_products(supplier_id);

create trigger supplier_products_set_updated_at
before update on public.supplier_products
for each row execute function public.set_updated_at();

create table if not exists public.salons (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users(id) on delete set null,
  name text not null,
  phone text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger salons_set_updated_at
before update on public.salons
for each row execute function public.set_updated_at();

create table if not exists public.marketplace_orders (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.supplier_profiles(id) on delete restrict,
  salon_id uuid references public.salons(id) on delete set null,
  order_number text not null unique,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled')),
  total_amount numeric(12, 2) not null default 0 check (total_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists marketplace_orders_supplier_id_idx
on public.marketplace_orders(supplier_id);

create index if not exists marketplace_orders_salon_id_idx
on public.marketplace_orders(salon_id);

create trigger marketplace_orders_set_updated_at
before update on public.marketplace_orders
for each row execute function public.set_updated_at();

alter table public.supplier_profiles enable row level security;
alter table public.supplier_products enable row level security;
alter table public.salons enable row level security;
alter table public.marketplace_orders enable row level security;

drop policy if exists "supplier profiles read own" on public.supplier_profiles;
create policy "supplier profiles read own"
on public.supplier_profiles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "supplier profiles insert own pending" on public.supplier_profiles;
create policy "supplier profiles insert own pending"
on public.supplier_profiles
for insert
to authenticated
with check (user_id = auth.uid() and status = 'pending');

drop policy if exists "supplier profiles update own pending data" on public.supplier_profiles;
create policy "supplier profiles update own pending data"
on public.supplier_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid() and status in ('pending', 'approved', 'suspended', 'rejected'));

drop policy if exists "supplier products read own" on public.supplier_products;
create policy "supplier products read own"
on public.supplier_products
for select
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = supplier_products.supplier_id
      and sp.user_id = auth.uid()
  )
);

drop policy if exists "supplier products insert own approved" on public.supplier_products;
create policy "supplier products insert own approved"
on public.supplier_products
for insert
to authenticated
with check (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = supplier_products.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
);

drop policy if exists "supplier products update own approved" on public.supplier_products;
create policy "supplier products update own approved"
on public.supplier_products
for update
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = supplier_products.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
)
with check (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = supplier_products.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
);

drop policy if exists "salons read order related" on public.salons;
create policy "salons read order related"
on public.salons
for select
to authenticated
using (
  exists (
    select 1
    from public.marketplace_orders mo
    join public.supplier_profiles sp on sp.id = mo.supplier_id
    where mo.salon_id = salons.id
      and sp.user_id = auth.uid()
  )
);

drop policy if exists "marketplace orders read own supplier" on public.marketplace_orders;
create policy "marketplace orders read own supplier"
on public.marketplace_orders
for select
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = marketplace_orders.supplier_id
      and sp.user_id = auth.uid()
  )
);

create or replace function public.supplier_update_order_status(
  p_order_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_status not in ('confirmed', 'preparing', 'shipped', 'delivered', 'cancelled') then
    raise exception 'Invalid order status: %', p_status;
  end if;

  update public.marketplace_orders mo
  set status = p_status,
      updated_at = now()
  where mo.id = p_order_id
    and exists (
      select 1
      from public.supplier_profiles sp
      where sp.id = mo.supplier_id
        and sp.user_id = auth.uid()
        and sp.status = 'approved'
    );

  if not found then
    raise exception 'Order not found or not allowed';
  end if;
end;
$$;

revoke all on function public.supplier_update_order_status(uuid, text) from public;
grant execute on function public.supplier_update_order_status(uuid, text) to authenticated;

-- Supplier approval is an admin operation. Example:
-- update public.supplier_profiles set status = 'approved' where id = '<supplier-id>';
