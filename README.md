# BarBer Tedarikçi

BarBer salon pazaryeri icin Flutter tabanli tedarikci paneli.

## Kurulum

1. Flutter bagimliliklarini yukleyin:

   ```bash
   flutter pub get
   ```

2. `assets/env.example.json` dosyasini `assets/env.local.json` olarak kopyalayin.

3. `assets/env.local.json` icine Supabase proje URL ve anon key degerlerini girin.

4. Uygulamayi calistirin:

   ```bash
   flutter run
   ```

## Supabase

Uygulama istemci tarafinda yalnizca Supabase anon key kullanir. Service role key veya veritabani sifresi GitHub'a eklenmemelidir.

Gerekli ana tablolar:

- `supplier_profiles`
- `supplier_products`
- `marketplace_orders`

Siparis durum guncellemesi icin `supplier_update_order_status` RPC fonksiyonu beklenir.

## GitHub'a yukleme

`assets/env.local.json`, `build/`, `.dart_tool/` ve benzeri yerel dosyalar Git disinda tutulur. GitHub'a yalniz kaynak kod ve ornek config dosyasi gonderilmelidir.
