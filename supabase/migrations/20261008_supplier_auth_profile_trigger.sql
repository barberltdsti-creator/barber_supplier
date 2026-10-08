-- Create supplier profile automatically when a supplier auth user signs up.

create or replace function public.handle_supplier_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.raw_user_meta_data ->> 'app_role' = 'supplier' then
    insert into public.supplier_profiles (
      user_id,
      company_name,
      contact_name,
      phone,
      tax_office,
      tax_number,
      status
    )
    values (
      new.id,
      coalesce(nullif(new.raw_user_meta_data ->> 'company_name', ''), 'Tedarikçi'),
      nullif(new.raw_user_meta_data ->> 'contact_name', ''),
      nullif(new.raw_user_meta_data ->> 'phone', ''),
      nullif(new.raw_user_meta_data ->> 'tax_office', ''),
      nullif(new.raw_user_meta_data ->> 'tax_number', ''),
      'pending'
    )
    on conflict (user_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_supplier_auth_user_created on auth.users;

create trigger on_supplier_auth_user_created
after insert on auth.users
for each row execute function public.handle_supplier_auth_user();
