-- SIDAR recommendation test data (USD only). Safe to run more than once.

insert into public.doctors (
  full_name, specialization, concerns, country, city, clinic_hospital,
  booking_url, contact_url, license_number, status, is_verified
)
select * from (values
  ('Dr. Sara Hassan — TEST', 'skin', array['acne','redness','pigmentation','dryness']::text[], 'EG', 'Cairo', 'SIDAR Test Dermatology Clinic', 'https://example.com/book/dr-sara-test', 'https://example.com/contact/dr-sara-test', 'SIDAR-TEST-EG-SKIN-001', 'Active', true),
  ('Dr. Omar Adel — TEST', 'hair', array['hair_loss','scalp','itching']::text[], 'EG', 'Giza', 'SIDAR Test Hair & Scalp Center', 'https://example.com/book/dr-omar-test', 'https://example.com/contact/dr-omar-test', 'SIDAR-TEST-EG-HAIR-001', 'Active', true),
  ('Dr. Noor Khaled — TEST', 'both', array['acne','sensitive','hair_loss','scalp']::text[], 'SA', 'Riyadh', 'SIDAR Test Skin & Hair Clinic', 'https://example.com/book/dr-noor-test', 'https://example.com/contact/dr-noor-test', 'SIDAR-TEST-SA-BOTH-001', 'Active', true)
) as seed(full_name, specialization, concerns, country, city, clinic_hospital, booking_url, contact_url, license_number, status, is_verified)
where not exists (select 1 from public.doctors d where d.license_number = seed.license_number);

insert into public.products (
  name, brand, category, concerns, skin_types, description, price,
  currency, product_url, image_url, is_active
)
values
  ('Barrier Repair Cream — TEST', 'SIDAR TEST', 'skin', array['dryness','redness','sensitive'], array['dry','sensitive','normal'], 'Test catalog product for dry, sensitive skin and barrier support.', 7.00, 'USD', 'https://example.com/products/barrier-repair-test', 'https://rextzhjhiktmylhwiqyk.supabase.co/storage/v1/object/public/sidar_images/products/umbiduj21ia.png', true),
  ('Clarifying Serum — TEST', 'SIDAR TEST', 'skin', array['acne','oiliness','blemishes','texture'], array['oily','combination'], 'Test catalog serum for oily and blemish-prone skin.', 8.50, 'USD', 'https://example.com/products/clarifying-serum-test', 'https://rextzhjhiktmylhwiqyk.supabase.co/storage/v1/object/public/sidar_images/products/umbiduj21ia.png', true),
  ('Scalp Support Serum — TEST', 'SIDAR TEST', 'hair', array['hair_loss','scalp','itching'], array['all'], 'Test catalog scalp serum for hair and scalp analysis results.', 10.50, 'USD', 'https://example.com/products/scalp-support-test', 'https://rextzhjhiktmylhwiqyk.supabase.co/storage/v1/object/public/sidar_images/products/umbiduj21ia.png', true)
on conflict (brand, name) do update set
  category = excluded.category, concerns = excluded.concerns,
  skin_types = excluded.skin_types, description = excluded.description,
  price = excluded.price, currency = 'USD', product_url = excluded.product_url,
  image_url = excluded.image_url, is_active = true;
