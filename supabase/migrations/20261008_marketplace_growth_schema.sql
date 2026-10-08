-- BarBer Supplier marketplace growth schema
-- Product images, order items, ad campaigns, and public read helpers.

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = excluded.public;

alter table public.supplier_products
add column if not exists description text,
add column if not exists image_url text,
add column if not exists featured_until timestamptz,
add column if not exists sort_score integer not null default 0;

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.supplier_products(id) on delete cascade,
  supplier_id uuid not null references public.supplier_profiles(id) on delete cascade,
  storage_path text not null,
  public_url text not null,
  sort_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists product_images_product_id_idx
on public.product_images(product_id);

create index if not exists product_images_supplier_id_idx
on public.product_images(supplier_id);

create table if not exists public.marketplace_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.marketplace_orders(id) on delete cascade,
  product_id uuid references public.supplier_products(id) on delete set null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(12, 2) generated always as (quantity * unit_price) stored,
  created_at timestamptz not null default now()
);

create index if not exists marketplace_order_items_order_id_idx
on public.marketplace_order_items(order_id);

create index if not exists marketplace_order_items_product_id_idx
on public.marketplace_order_items(product_id);

create table if not exists public.ad_campaigns (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.supplier_profiles(id) on delete cascade,
  product_id uuid references public.supplier_products(id) on delete set null,
  title text not null,
  placement text not null default 'marketplace_featured'
    check (placement in ('marketplace_featured', 'category_top', 'search_boost')),
  status text not null default 'draft'
    check (status in ('draft', 'pending', 'active', 'paused', 'ended', 'rejected')),
  budget numeric(12, 2) not null default 0 check (budget >= 0),
  starts_at timestamptz,
  ends_at timestamptz,
  preview_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ad_campaigns_supplier_id_idx
on public.ad_campaigns(supplier_id);

create index if not exists ad_campaigns_product_id_idx
on public.ad_campaigns(product_id);

drop trigger if exists ad_campaigns_set_updated_at on public.ad_campaigns;
create trigger ad_campaigns_set_updated_at
before update on public.ad_campaigns
for each row execute function public.set_updated_at();

alter table public.product_images enable row level security;
alter table public.marketplace_order_items enable row level security;
alter table public.ad_campaigns enable row level security;

drop policy if exists "product images read own" on public.product_images;
create policy "product images read own"
on public.product_images
for select
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = product_images.supplier_id
      and sp.user_id = auth.uid()
  )
);

drop policy if exists "product images insert own approved" on public.product_images;
create policy "product images insert own approved"
on public.product_images
for insert
to authenticated
with check (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = product_images.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
);

drop policy if exists "order items read own supplier" on public.marketplace_order_items;
create policy "order items read own supplier"
on public.marketplace_order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.marketplace_orders mo
    join public.supplier_profiles sp on sp.id = mo.supplier_id
    where mo.id = marketplace_order_items.order_id
      and sp.user_id = auth.uid()
  )
);

drop policy if exists "ad campaigns read own" on public.ad_campaigns;
create policy "ad campaigns read own"
on public.ad_campaigns
for select
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = ad_campaigns.supplier_id
      and sp.user_id = auth.uid()
  )
);

drop policy if exists "ad campaigns write own approved" on public.ad_campaigns;
create policy "ad campaigns write own approved"
on public.ad_campaigns
for all
to authenticated
using (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = ad_campaigns.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
)
with check (
  exists (
    select 1
    from public.supplier_profiles sp
    where sp.id = ad_campaigns.supplier_id
      and sp.user_id = auth.uid()
      and sp.status = 'approved'
  )
);

drop policy if exists "suppliers upload own product images" on storage.objects;
create policy "suppliers upload own product images"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'product-images'
  and exists (
    select 1
    from public.supplier_profiles sp
    where sp.user_id = auth.uid()
      and sp.status = 'approved'
      and name like sp.id::text || '/%'
  )
);

drop policy if exists "suppliers update own product images" on storage.objects;
create policy "suppliers update own product images"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'product-images'
  and exists (
    select 1
    from public.supplier_profiles sp
    where sp.user_id = auth.uid()
      and sp.status = 'approved'
      and name like sp.id::text || '/%'
  )
)
with check (
  bucket_id = 'product-images'
  and exists (
    select 1
    from public.supplier_profiles sp
    where sp.user_id = auth.uid()
      and sp.status = 'approved'
      and name like sp.id::text || '/%'
  )
);

drop policy if exists "public read product images" on storage.objects;
create policy "public read product images"
on storage.objects
for select
to public
using (bucket_id = 'product-images');

create or replace view public.marketplace_public_products as
select
  p.id,
  p.supplier_id,
  sp.company_name as supplier_name,
  p.name,
  p.description,
  p.category,
  p.sku,
  p.price,
  p.stock_quantity,
  p.minimum_order_quantity,
  p.image_url,
  p.featured_until,
  p.sort_score,
  p.created_at,
  (p.featured_until is not null and p.featured_until > now()) as is_featured
from public.supplier_products p
join public.supplier_profiles sp on sp.id = p.supplier_id
where p.is_active = true
  and p.stock_quantity > 0
  and sp.status = 'approved';
