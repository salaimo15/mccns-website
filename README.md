# MCCNS Ltd website

Static website for MCCNS Ltd, hosted on Vercel, with the fleet and crew stored in Supabase.

## Files
- `index.html`: the whole site (pages switch with the top menu).
- `img/`: photos and logos.
- `config.js`: the Supabase Project URL and anon public key (both public by design; never put the service_role key here).
- `supabase/setup.sql`: creates the fleet and crew tables, the photo storage and the access rules. Run it once in Supabase's SQL Editor.

## Editing fleet and crew
Open the site, click **Admin** in the footer (or add `#admin` to the address) and sign in with the admin account created in Supabase. The **Edit fleet** and **Edit crew** buttons then appear on the Yacht & Crew Management page.

## Publishing changes
Every push to the `main` branch on GitHub is published by Vercel automatically.
