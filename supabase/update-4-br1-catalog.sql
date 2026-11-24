-- MCCNS website update 4: the BR1 catalog, 29 products with photos.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.

alter table public.catalog add column if not exists ref text check (char_length(ref) <= 20);
alter table public.catalog add column if not exists fabric text check (char_length(fabric) <= 160);
alter table public.catalog drop constraint if exists catalog_description_check;
alter table public.catalog add constraint catalog_description_check check (char_length(description) <= 600);
alter table public.catalog drop constraint if exists catalog_category_check;
alter table public.catalog add constraint catalog_category_check check (category in ('tshirt', 'sweat', 'jacket', 'bottoms', 'headwear', 'bag', 'drink', 'polo', 'shirt', 'shorts', 'cap', 'other'));

-- Remove the six starting placeholder categories (only the untouched ones, without a photo).
delete from public.catalog where photo is null and ref is null and name in ('Polo shirts', 'Shirts', 'Shorts and trousers', 'Outerwear', 'Caps and accessories', 'Bags');

-- The products. A product whose reference already exists is skipped, so running this twice is safe.
insert into public.catalog (ref, name, category, description, fabric, photo, ord)
select v.ref, v.name, v.category, v.description, v.fabric, v.photo, v.ord from (values
  ('BR1-01', 'Ocean as Home T-shirt', 'tshirt', 'White T-shirt with the claim "Wind as fuel. Ocean as home." printed in red on the back, finished with a patch cut from an upcycled sail.', null, 'img/cat-br1-01.webp', 1),
  ('BR1-02', 'Sport T-shirt', 'tshirt', 'Short sleeve raglan T-shirt with flatlock seams, breathable fabric and a sweat-absorbing neck tape. Side-seamed for a better fit.', '100% microperforated polyester · 140 g/m²', 'img/cat-br1-02.webp', 2),
  ('BR1-03', 'Contrast Panel T-shirt', 'tshirt', 'Short sleeve T-shirt with contrast panels and twin-needle stitching. Very hard-wearing, light and breathable.', '100% polyester · 140 g/m²', 'img/cat-br1-03.webp', 3),
  ('BR1-04', 'Technical Polo', 'tshirt', 'Technical short sleeve polo with three matching buttons and raglan sleeves. Double side seams for a better fit, longer drop hem at the back, reflective details on the sleeves and back of the collar, contrast neck tape.', '140 g/m²', 'img/cat-br1-04.webp', 4),
  ('BR1-05', 'Crew Neck Sweatshirt', 'sweat', 'Interlock crew neck sweatshirt with a zipped sleeve pocket and drawcord, cuffs in the same fabric.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-05.webp', 5),
  ('BR1-06', 'Zip Hoodie', 'sweat', 'Interlock hoodie with full zip, two open front pockets, a zipped sleeve pocket with drawcord, matching cuffs and an elasticated hem.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-06.webp', 6),
  ('BR1-07', 'Hoodie', 'sweat', 'Interlock hoodie with a double-layer hood, front pocket and a zipped sleeve pocket with drawcord.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-07.webp', 7),
  ('BR1-08', 'Recycled Fleece Jacket', 'jacket', 'Soft, easy-care fleece jacket in recycled polyester with woven fabric inserts. Two side pockets, zipped chest pocket, two inner pockets, two-way front zip and high collar.', '100% recycled polyester · 280 g/m²', 'img/cat-br1-08.webp', 8),
  ('BR1-09', 'Heavy Fleece Jacket', 'jacket', 'Heavy, soft polyester fleece reinforced with ripstop on the shoulders and elbows. Quality zips, two large front pockets and elasticated cuffs for a close fit against the cold.', 'Polyester fleece with ripstop polyester · 344 g/m²', 'img/cat-br1-09.webp', 9),
  ('BR1-10', 'Hooded Jacket', 'jacket', 'Jacket with chin guard and a removable, adjustable hood. Two front pockets with double opening, elasticated hem and cuffs, inner press-stud pocket.', '88% polyester, 12% spandex', 'img/cat-br1-10.webp', 10),
  ('BR1-11', 'Softshell Gilet', 'jacket', 'Two-tone softshell gilet with metal auto-lock zip and branded puller. Two zipped side pockets, coated zip chest pocket, reflective detail on the back yoke and adjustable hem.', '95% polyester, 5% elastane · 320 g/m²', 'img/cat-br1-11.webp', 11),
  ('BR1-12', 'Technical Knit Jacket', 'jacket', 'Technical knit jacket with contrast softshell inserts, taped zip and shaped hood. Trimmed cuffs and hem, two zipped side pockets and a chest pocket.', '100% polyester · 380 g/m²', 'img/cat-br1-12.webp', 12),
  ('BR1-13', 'Softshell Jacket', 'jacket', 'Ergonomic softshell jacket with raglan sleeves, shaped hood with drawcord and taped full zip. Adjustable cuffs with rubberised tabs, two zipped side pockets, a chest pocket and a pocket on the left sleeve.', '100% polyester · 280 g/m²', 'img/cat-br1-13.webp', 13),
  ('BR1-14', 'Technical Shorts', 'bottoms', 'Light, strong, two-way stretch shorts with a water and stain repellent finish (BIONIC-FINISH® ECO). Quick drying, partly elasticated waist with belt loops, two side pockets, back pocket and leg pocket, all zipped.', '85% polyamide, 15% elastane', 'img/cat-br1-14.webp', 14),
  ('BR1-15', 'Technical Trousers', 'bottoms', 'Light, water and stain repellent trousers (BIONIC-FINISH® ECO), quick drying, with contrast inserts on the knees and back. Elasticated waist with belt loops, two side pockets, back pocket and leg pocket.', '85% polyamide, 15% elastane', 'img/cat-br1-15.webp', 15),
  ('BR1-16', 'Belt', 'bottoms', 'Strong belt with tone-on-tone metal buckle. Can be cut to length, adjustable from XS to 3XL.', '100% polyester', 'img/cat-br1-16.webp', 16),
  ('BR1-17', 'UPF50+ Cap', 'headwear', 'Six-panel cap in UPF50+ fabric with a quick-dry inner sweatband. Pre-curved peak, embroidered eyelets, velcro closure.', '75% nylon, 20% cotton, 5% elastane', 'img/cat-br1-17.webp', 17),
  ('BR1-18', 'Vented Cap', 'headwear', 'Six-panel cap with laser-cut ventilation, pre-curved peak and adjustable buckle closure. One size.', '100% recycled polyester', 'img/cat-br1-18.webp', 18),
  ('BR1-19', 'Ponytail Cap', 'headwear', 'Light, breathable cap with a ponytail opening at the back, pre-curved peak, elastic band and adjustable buckle closure. One size.', '100% recycled polyester', 'img/cat-br1-19.webp', 19),
  ('BR1-20', 'Outdoor Hat', 'headwear', 'Wide brim hat in coated polyester with taped main seams for water resistance. The brim folds up and fastens with press studs on the sides; ventilation eyelets keep it breathable.', 'Coated polyester · 85 g/m²', 'img/cat-br1-20.webp', 20),
  ('BR1-21', 'Bucket Hat', 'headwear', 'Casual bucket hat with a safety chin cord and float, a sloping brim and parallel decorative stitching.', 'Polyester', 'img/cat-br1-21.webp', 21),
  ('BR1-22', 'Beanie', 'headwear', 'Rib knit beanie with turn-up and micro fleece lining, durable water repellent finish.', '100% acrylic, lining 100% polyester', 'img/cat-br1-22.webp', 22),
  ('BR1-23', 'Waterproof Duffel', 'bag', 'Waterproof PVC duffel bag with a fully waterproof front pocket and detachable shoulder strap. Made for the deck, the tender and the dock.', 'PVC', 'img/cat-br1-23.webp', 23),
  ('BR1-24', 'Roll-top Dry Bag', 'bag', 'Fully waterproof bag with roll-top closure and shoulder straps. Available in several sizes for large capacity.', null, 'img/cat-br1-24.webp', 24),
  ('BR1-25', 'Roll-top Backpack', 'bag', 'Waterproof tarpaulin backpack with roll-top closure, a fully waterproof zipped front pocket, padded breathable shoulder straps and a mesh side pocket.', 'PVC tarpaulin', 'img/cat-br1-25.webp', 25),
  ('BR1-26', 'Waterproof Backpack', 'bag', 'Water resistant backpack with roll-top closure, vertical zipped front pocket and a stow-away carry net. Padded breathable straps, release valve to push out air and water, safety whistle on the chest strap.', null, 'img/cat-br1-26.webp', 26),
  ('BR1-27', 'Insulated Bottle', 'drink', 'Double-wall insulated bottle in recycled stainless steel with a rubber finish and silicone handle. 500 ml.', '90% recycled stainless steel, 10% stainless steel', 'img/cat-br1-27.webp', 27),
  ('BR1-28', 'Travel Tumbler', 'drink', 'Double-wall tumbler in recycled stainless steel with a PP outer layer and RPET wrist strap. 350 ml.', 'Recycled stainless steel, PP, RPET', 'img/cat-br1-28.webp', 28),
  ('BR1-29', 'Carabiner Mug', 'drink', 'Double-wall stainless steel mug with carabiner handle. 300 ml.', 'Stainless steel', 'img/cat-br1-29.webp', 29)
) as v(ref, name, category, description, fabric, photo, ord)
where not exists (select 1 from public.catalog c where c.ref = v.ref);

notify pgrst, 'reload schema';
