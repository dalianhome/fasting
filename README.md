# Cyberism Fasting App

Simple intermittent fasting companion built with SwiftUI.

**Appmaker:** Cyberism App

## Theme selection

Pick between neon, midnight, and sunrise palettes from **Home ▸ Settings ▸ Appearance ▸ Theme** to match the app to your preferred look.

## Refreshing the app after code updates

If changes are not showing up on device or simulator, try the following steps:

1. Clean the build folder in Xcode (`Shift` + `Command` + `K`).
2. Delete the app from your simulator or device to remove any stale cached data.
3. Build and run again to ensure the latest code and persisted state are loaded.

## Syncing fasting data across devices with Supabase

The app currently stores history, active fasts, and settings in local `UserDefaults`, so each device keeps its own copy. To see the same data after signing in on any phone or web client, add a Supabase-backed sync layer:

1. **Create tables** (SQL in the Supabase SQL editor):
   ```sql
   create table profiles (
     id uuid primary key references auth.users on delete cascade,
     display_name text,
     theme text,
     auto_start_after_eating boolean default false,
     daily_reminder_enabled boolean default false,
     last_synced_at timestamptz
   );

   create table fasts (
     id uuid primary key default gen_random_uuid(),
     user_id uuid references auth.users on delete cascade,
     plan_name text not null,
     start_date timestamptz not null,
     end_date timestamptz not null,
     duration_hours numeric not null,
     is_successful boolean not null,
     created_at timestamptz default now()
   );
   ```

2. **Enable Row-Level Security (RLS)** and add policies so each user can only access their own rows:
   ```sql
   alter table profiles enable row level security;
   alter table fasts enable row level security;

   create policy "Users read/write own profile" on profiles
     for all using (auth.uid() = id) with check (auth.uid() = id);

   create policy "Users read/write own fasts" on fasts
     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
   ```

3. **Add Supabase client code** in the app:
   - When a user signs in, fetch `profiles` and `fasts` for `auth.uid()` and replace the locally loaded `FastingStore` state.
   - When starting/stopping/deleting fasts or changing settings, write to Supabase (insert/update) and update local cache so the UI stays instant.
   - Store `last_synced_at` locally to skip redundant downloads and use it to drive incremental sync if desired.

4. **Handle offline support** by queueing pending writes while offline and replaying them once a Supabase call succeeds. Until then, keep saving to `UserDefaults` so nothing is lost.

5. **Migrate existing local data** by uploading the current `history`, active fast state, and settings the next time the user signs in, then marking them as synced.

6. **Reuse the existing Supabase keys** in `SupabaseConfig.swift` for the client. Use the anon key in the app; reserve the service role key for secure backend utilities (never ship it in clients).

Following these steps ensures every device shows the same fasting history and settings immediately after login.
