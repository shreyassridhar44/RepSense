-- ============================================================================
-- RepSense — Supabase schema
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXERCISES (read-only reference data, public)
-- ----------------------------------------------------------------------------
create table if not exists public.exercises (
  id text primary key,                  -- e.g. 'squat', 'deadlift'
  name text not null,
  muscle_groups text[] not null default '{}',
  difficulty text not null default 'Beginner', -- Beginner | Intermediate | Advanced
  equipment text,
  description text,
  created_at timestamptz not null default now()
);

insert into public.exercises (id, name, muscle_groups, difficulty, equipment) values
  ('squat', 'Squat', '{"Quads","Glutes"}', 'Beginner', 'Bodyweight / Barbell'),
  ('deadlift', 'Deadlift', '{"Hamstrings","Back"}', 'Advanced', 'Barbell'),
  ('bench_press', 'Bench Press', '{"Chest","Triceps"}', 'Intermediate', 'Barbell / Bench'),
  ('push_up', 'Push-up', '{"Chest","Core"}', 'Beginner', 'Bodyweight'),
  ('pull_up', 'Pull-up', '{"Back","Biceps"}', 'Advanced', 'Pull-up Bar'),
  ('overhead_press', 'Overhead Press', '{"Shoulders"}', 'Intermediate', 'Barbell / Dumbbells'),
  ('lunges', 'Lunges', '{"Quads","Glutes"}', 'Beginner', 'Bodyweight'),
  ('bicep_curl', 'Bicep Curl', '{"Biceps"}', 'Beginner', 'Dumbbells'),
  ('tricep_extension', 'Tricep Extension', '{"Triceps"}', 'Beginner', 'Dumbbells'),
  ('rows', 'Rows', '{"Back"}', 'Intermediate', 'Barbell / Dumbbells'),
  ('lat_pulldown', 'Lat Pulldown', '{"Back"}', 'Beginner', 'Cable Machine'),
  ('leg_press', 'Leg Press', '{"Quads","Glutes"}', 'Beginner', 'Machine'),
  ('plank', 'Plank', '{"Core"}', 'Beginner', 'Bodyweight'),
  ('shoulder_press', 'Shoulder Press', '{"Shoulders"}', 'Intermediate', 'Dumbbells')
on conflict (id) do nothing;

alter table public.exercises enable row level security;
create policy "Exercises are publicly readable" on public.exercises
  for select using (true);

-- ----------------------------------------------------------------------------
-- 2. PROFILES (extends auth.users)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  height_cm numeric,
  weight_kg numeric,
  training_experience text default 'Beginner',
  preferred_units text default 'metric',
  goals text[],
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
create policy "Users can view their own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "Users can insert their own profile" on public.profiles
  for insert with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 3. WORKOUTS
-- ----------------------------------------------------------------------------
create table if not exists public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_id text not null references public.exercises(id),
  total_reps int not null default 0,
  correct_reps int not null default 0,
  incorrect_reps int not null default 0,
  avg_form_score numeric not null default 0 check (avg_form_score between 0 and 100),
  duration_seconds int not null default 0,
  calories numeric,
  video_url text,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.workouts enable row level security;
create policy "Users can view their own workouts" on public.workouts
  for select using (auth.uid() = user_id);
create policy "Users can insert their own workouts" on public.workouts
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own workouts" on public.workouts
  for update using (auth.uid() = user_id);
create policy "Users can delete their own workouts" on public.workouts
  for delete using (auth.uid() = user_id);

create index if not exists workouts_user_id_created_at_idx
  on public.workouts (user_id, created_at desc);

-- ----------------------------------------------------------------------------
-- 4. REP ANALYSIS (one row per repetition, populated by inference_service)
-- ----------------------------------------------------------------------------
create table if not exists public.rep_analyses (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  rep_index int not null,
  overall_score numeric not null,
  scores jsonb not null default '{}',   -- {"range_of_motion": 91, "symmetry": 88, ...}
  issues jsonb not null default '[]',   -- [{"problem":..., "reason":..., "correction":..., "confidence":..., "severity":...}]
  created_at timestamptz not null default now()
);

alter table public.rep_analyses enable row level security;
create policy "Users can view rep analyses for their own workouts" on public.rep_analyses
  for select using (
    exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid())
  );
create policy "Service role can insert rep analyses" on public.rep_analyses
  for insert with check (true);

-- ----------------------------------------------------------------------------
-- 5. ACHIEVEMENTS
-- ----------------------------------------------------------------------------
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_key text not null,              -- e.g. '100_reps', '30_day_streak'
  unlocked_at timestamptz not null default now()
);

alter table public.achievements enable row level security;
create policy "Users can view their own achievements" on public.achievements
  for select using (auth.uid() = user_id);
create policy "Users can insert their own achievements" on public.achievements
  for insert with check (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. STORAGE BUCKETS
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('workout-media', 'workout-media', false)
on conflict (id) do nothing;

create policy "Users can upload their own workout media"
  on storage.objects for insert
  with check (
    bucket_id = 'workout-media'
    and (storage.foldername(name))[1] = 'workouts'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

create policy "Users can view their own workout media"
  on storage.objects for select
  using (
    bucket_id = 'workout-media'
    and (storage.foldername(name))[1] = 'workouts'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
