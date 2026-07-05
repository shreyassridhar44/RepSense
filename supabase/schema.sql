-- ============================================================================
-- RepSense — Supabase schema (Modules 1, 2, 3)
-- Run this in: Supabase Dashboard -> SQL Editor -> New query -> Run
-- Safe to run multiple times - won't delete existing data
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXERCISES (read-only reference data, public)
-- ----------------------------------------------------------------------------
create table if not exists public.exercises (
  id text primary key,
  name text not null,
  muscle_groups text[] not null default '{}',
  difficulty text not null default 'Beginner',
  equipment text,
  description text,
  created_at timestamptz not null default now()
);

-- Add Module 3 columns if they don't exist
alter table public.exercises
  add column if not exists primary_muscle text,
  add column if not exists secondary_muscles text[],
  add column if not exists common_mistakes text[],
  add column if not exists instructions text[],
  add column if not exists benefits text[],
  add column if not exists met_value numeric default 5.0;

-- Insert/Update exercise data with full Module 3 details
insert into public.exercises (id, name, muscle_groups, difficulty, equipment, description, primary_muscle, secondary_muscles, common_mistakes, instructions, benefits, met_value)
values
  (
    'squat',
    'Squat',
    array['Legs', 'Core'],
    'Beginner',
    'Bodyweight',
    'A fundamental lower body exercise that builds strength and power in your legs and core.',
    'Quadriceps',
    array['Glutes', 'Hamstrings', 'Core'],
    array['Knees caving inward', 'Heels lifting off the ground', 'Rounding the lower back', 'Not going deep enough'],
    array['Stand with feet shoulder-width apart, toes slightly pointed out', 'Keep your chest up and core engaged', 'Lower down by bending your knees and pushing your hips back', 'Go as low as comfortable while keeping heels on the ground', 'Push through your heels to return to standing', 'Squeeze your glutes at the top'],
    array['Builds lower body strength and power', 'Improves core stability and balance', 'Functional movement for daily activities', 'Increases metabolism and burns calories'],
    5.0
  ),
  (
    'deadlift',
    'Deadlift',
    array['Back', 'Legs'],
    'Intermediate',
    'Barbell',
    'A compound exercise that targets the entire posterior chain, building overall strength.',
    'Hamstrings',
    array['Glutes', 'Lower Back', 'Traps', 'Forearms'],
    array['Rounding the back', 'Starting with hips too high or too low', 'Not engaging lats', 'Jerking the bar off the ground'],
    array['Stand with feet hip-width apart, bar over mid-foot', 'Bend down and grip the bar just outside your legs', 'Engage your lats, flatten your back, and brace your core', 'Push through your heels and extend your hips and knees', 'Keep the bar close to your body throughout', 'Stand tall at the top, then lower with control'],
    array['Develops full-body strength', 'Builds powerful posterior chain', 'Improves grip strength', 'Enhances athletic performance'],
    6.0
  ),
  (
    'bench_press',
    'Bench Press',
    array['Chest', 'Arms'],
    'Intermediate',
    'Barbell',
    'The king of upper body pressing movements, building chest, shoulders, and triceps.',
    'Pectorals',
    array['Triceps', 'Anterior Deltoids'],
    array['Bouncing the bar off your chest', 'Flaring elbows out too wide', 'Arching back excessively', 'Not using full range of motion'],
    array['Lie flat on the bench with feet firmly on the ground', 'Grip the bar slightly wider than shoulder-width', 'Unrack the bar and position it over your chest', 'Lower the bar to your mid-chest with control', 'Press the bar back up powerfully to the starting position', 'Keep your shoulder blades retracted throughout'],
    array['Builds upper body pressing strength', 'Develops chest muscle mass', 'Improves pushing power', 'Strengthens stabilizing muscles'],
    4.5
  ),
  (
    'push_up',
    'Push Up',
    array['Chest', 'Arms', 'Core'],
    'Beginner',
    'Bodyweight',
    'A classic bodyweight exercise that builds upper body strength and core stability.',
    'Pectorals',
    array['Triceps', 'Anterior Deltoids', 'Core'],
    array['Sagging hips', 'Flaring elbows too wide', 'Not going deep enough', 'Head dropping down'],
    array['Start in a plank position with hands shoulder-width apart', 'Keep your body in a straight line from head to heels', 'Lower your chest toward the ground by bending your elbows', 'Keep elbows at about 45 degrees from your body', 'Push back up to the starting position', 'Maintain core tension throughout the movement'],
    array['Builds upper body pushing strength', 'Requires no equipment', 'Improves core stability', 'Can be done anywhere'],
    3.8
  ),
  (
    'pull_up',
    'Pull Up',
    array['Back', 'Arms'],
    'Advanced',
    'Pull-up Bar',
    'One of the best upper body pulling exercises, building back strength and muscle.',
    'Latissimus Dorsi',
    array['Biceps', 'Rear Deltoids', 'Rhomboids'],
    array['Using momentum (kipping)', 'Not achieving full range of motion', 'Shrugging shoulders up', 'Flaring elbows out'],
    array['Hang from a pull-up bar with hands slightly wider than shoulder-width', 'Engage your lats and depress your shoulders', 'Pull your body up by driving elbows down and back', 'Continue until your chin is over the bar', 'Lower yourself with control to full extension', 'Repeat while maintaining body control'],
    array['Builds powerful back muscles', 'Develops grip and arm strength', 'Improves shoulder health', 'Essential functional movement'],
    8.0
  ),
  (
    'overhead_press',
    'Overhead Press',
    array['Shoulders', 'Arms'],
    'Intermediate',
    'Barbell',
    'A fundamental shoulder exercise that builds overhead pressing strength and stability.',
    'Deltoids',
    array['Triceps', 'Upper Chest', 'Core'],
    array['Excessive back arching', 'Pressing the bar forward instead of straight up', 'Not fully locking out', 'Using legs to push (unless doing push press)'],
    array['Stand with feet shoulder-width apart, bar at shoulder level', 'Grip the bar just outside shoulder-width', 'Brace your core and squeeze your glutes', 'Press the bar straight up, moving your head back slightly', 'Lock out your arms overhead with the bar over your shoulders', 'Lower the bar with control back to shoulder level'],
    array['Builds shoulder strength and mass', 'Improves overhead stability', 'Strengthens core and upper back', 'Functional pressing movement'],
    4.8
  ),
  (
    'lunges',
    'Lunges',
    array['Legs'],
    'Beginner',
    'Bodyweight',
    'A unilateral leg exercise that improves balance, coordination, and leg strength.',
    'Quadriceps',
    array['Glutes', 'Hamstrings', 'Calves'],
    array['Knee extending past toes excessively', 'Leaning too far forward', 'Not stepping far enough', 'Allowing knee to cave inward'],
    array['Stand tall with feet hip-width apart', 'Step forward with one leg into a long stride', 'Lower your hips until both knees are bent at 90 degrees', 'Keep your front knee aligned with your ankle', 'Push through your front heel to return to standing', 'Alternate legs or complete all reps on one side'],
    array['Builds unilateral leg strength', 'Improves balance and coordination', 'Corrects muscle imbalances', 'Functional for daily movements'],
    4.0
  ),
  (
    'bicep_curl',
    'Bicep Curl',
    array['Arms'],
    'Beginner',
    'Dumbbell',
    'An isolation exercise that targets the biceps for arm strength and size.',
    'Biceps',
    array['Brachialis', 'Forearms'],
    array['Using momentum and swinging', 'Moving elbows forward', 'Not using full range of motion', 'Going too heavy'],
    array['Stand with feet shoulder-width apart, dumbbells at your sides', 'Keep your elbows close to your torso', 'Curl the weights up by bending your elbows', 'Squeeze your biceps at the top of the movement', 'Lower the weights with control', 'Keep your upper arms stationary throughout'],
    array['Builds bicep size and strength', 'Improves arm aesthetics', 'Strengthens elbow flexion', 'Simple and effective isolation'],
    3.0
  ),
  (
    'tricep_extension',
    'Tricep Extension',
    array['Arms'],
    'Beginner',
    'Dumbbell',
    'An isolation exercise for building tricep strength and size.',
    'Triceps',
    array['Anconeus'],
    array['Flaring elbows out', 'Using too much weight', 'Not maintaining elbow position', 'Arching lower back'],
    array['Stand or sit with a dumbbell held overhead', 'Keep your elbows close to your head', 'Lower the weight behind your head by bending your elbows', 'Keep your upper arms stationary and vertical', 'Extend your elbows to press the weight back up', 'Squeeze your triceps at the top'],
    array['Isolates and builds triceps', 'Improves elbow extension strength', 'Enhances arm definition', 'Complements pressing movements'],
    3.0
  ),
  (
    'rows',
    'Rows',
    array['Back'],
    'Intermediate',
    'Dumbbell',
    'A horizontal pulling exercise that builds back thickness and strength.',
    'Latissimus Dorsi',
    array['Rhomboids', 'Traps', 'Biceps', 'Rear Deltoids'],
    array['Rounding the back', 'Using too much momentum', 'Not pulling to full contraction', 'Rotating torso excessively'],
    array['Hinge forward at the hips with a flat back', 'Hold dumbbells with arms extended toward the ground', 'Pull the weights toward your hips by driving elbows back', 'Squeeze your shoulder blades together at the top', 'Lower the weights with control', 'Keep your core braced throughout'],
    array['Builds back thickness and strength', 'Improves posture', 'Balances pushing movements', 'Strengthens grip'],
    4.5
  ),
  (
    'lat_pulldown',
    'Lat Pulldown',
    array['Back', 'Arms'],
    'Beginner',
    'Machine',
    'A machine-based vertical pulling exercise that builds lat width and strength.',
    'Latissimus Dorsi',
    array['Biceps', 'Rear Deltoids', 'Rhomboids'],
    array['Leaning back too far', 'Using momentum', 'Not achieving full stretch at top', 'Pulling behind the neck'],
    array['Sit at the lat pulldown machine with knees secured', 'Grip the bar wider than shoulder-width', 'Start with arms fully extended overhead', 'Pull the bar down to your upper chest', 'Drive your elbows down and back', 'Return to the starting position with control'],
    array['Builds lat width and V-taper', 'Easier progression than pull-ups', 'Allows controlled loading', 'Improves pulling strength'],
    3.5
  ),
  (
    'leg_press',
    'Leg Press',
    array['Legs'],
    'Beginner',
    'Machine',
    'A machine-based leg exercise that allows heavy loading with less technical demand.',
    'Quadriceps',
    array['Glutes', 'Hamstrings'],
    array['Locking knees out fully', 'Lifting hips off the seat', 'Not using full range of motion', 'Going too heavy'],
    array['Sit in the leg press machine with back flat against the pad', 'Place feet shoulder-width apart on the platform', 'Release the safety and lower the weight with control', 'Lower until knees are at about 90 degrees', 'Push through your heels to extend your legs', 'Stop just short of locking out your knees'],
    array['Builds leg strength safely', 'Allows heavy loading', 'Reduces lower back stress', 'Great for muscle growth'],
    5.5
  ),
  (
    'plank',
    'Plank',
    array['Core'],
    'Beginner',
    'Bodyweight',
    'An isometric core exercise that builds stability and endurance.',
    'Core',
    array['Shoulders', 'Glutes'],
    array['Sagging hips', 'Raising hips too high', 'Holding breath', 'Not engaging core'],
    array['Start in a forearm plank position', 'Place elbows directly under your shoulders', 'Keep your body in a straight line from head to heels', 'Engage your core and squeeze your glutes', 'Hold this position while breathing steadily', 'Focus on maintaining perfect alignment'],
    array['Builds core stability and endurance', 'Improves posture', 'Requires no equipment', 'Protects spine during other lifts'],
    3.0
  ),
  (
    'shoulder_press',
    'Shoulder Press',
    array['Shoulders', 'Arms'],
    'Intermediate',
    'Dumbbell',
    'A seated or standing shoulder press that builds deltoid strength and size.',
    'Deltoids',
    array['Triceps', 'Upper Chest'],
    array['Arching back excessively', 'Not pressing straight up', 'Locking out too forcefully', 'Using momentum'],
    array['Sit or stand with dumbbells at shoulder height', 'Keep your core braced and chest up', 'Press the dumbbells straight up overhead', 'Bring the weights together at the top', 'Lower the dumbbells with control to shoulder level', 'Maintain tension throughout the movement'],
    array['Builds shoulder strength and mass', 'Allows independent arm movement', 'Improves shoulder stability', 'Great for muscle development'],
    4.5
  )
on conflict (id) do update set
  name = excluded.name,
  muscle_groups = excluded.muscle_groups,
  difficulty = excluded.difficulty,
  equipment = excluded.equipment,
  description = excluded.description,
  primary_muscle = excluded.primary_muscle,
  secondary_muscles = excluded.secondary_muscles,
  common_mistakes = excluded.common_mistakes,
  instructions = excluded.instructions,
  benefits = excluded.benefits,
  met_value = excluded.met_value;

alter table public.exercises enable row level security;

-- Safe policy creation
do $$
begin
  if not exists (
    select 1 from pg_policies 
    where schemaname = 'public'
    and tablename = 'exercises' 
    and policyname = 'Exercises are publicly readable'
  ) then
    create policy "Exercises are publicly readable" on public.exercises
      for select using (true);
  end if;
end $$;

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

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can view their own profile') then
    create policy "Users can view their own profile" on public.profiles for select using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can update their own profile') then
    create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can insert their own profile') then
    create policy "Users can insert their own profile" on public.profiles for insert with check (auth.uid() = id);
  end if;
end $$;

-- Auto-create profile trigger
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

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'workouts' and policyname = 'Users can view their own workouts') then
    create policy "Users can view their own workouts" on public.workouts for select using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'workouts' and policyname = 'Users can insert their own workouts') then
    create policy "Users can insert their own workouts" on public.workouts for insert with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'workouts' and policyname = 'Users can update their own workouts') then
    create policy "Users can update their own workouts" on public.workouts for update using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'workouts' and policyname = 'Users can delete their own workouts') then
    create policy "Users can delete their own workouts" on public.workouts for delete using (auth.uid() = user_id);
  end if;
end $$;

create index if not exists workouts_user_id_created_at_idx
  on public.workouts (user_id, created_at desc);

-- ----------------------------------------------------------------------------
-- 4. REP ANALYSIS
-- ----------------------------------------------------------------------------
create table if not exists public.rep_analyses (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  rep_index int not null,
  overall_score numeric not null,
  scores jsonb not null default '{}',
  issues jsonb not null default '[]',
  created_at timestamptz not null default now()
);

alter table public.rep_analyses enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rep_analyses' and policyname = 'Users can view rep analyses for their own workouts') then
    create policy "Users can view rep analyses for their own workouts" on public.rep_analyses
      for select using (exists (select 1 from public.workouts w where w.id = workout_id and w.user_id = auth.uid()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'rep_analyses' and policyname = 'Service role can insert rep analyses') then
    create policy "Service role can insert rep analyses" on public.rep_analyses for insert with check (true);
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 5. ACHIEVEMENTS
-- ----------------------------------------------------------------------------
create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_key text not null,
  unlocked_at timestamptz not null default now()
);

alter table public.achievements enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'achievements' and policyname = 'Users can view their own achievements') then
    create policy "Users can view their own achievements" on public.achievements for select using (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'achievements' and policyname = 'Users can insert their own achievements') then
    create policy "Users can insert their own achievements" on public.achievements for insert with check (auth.uid() = user_id);
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 6. MODULE 3: USER FAVORITES
-- ----------------------------------------------------------------------------
create table if not exists public.user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  exercise_id text not null references public.exercises(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, exercise_id)
);

alter table public.user_favorites enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'user_favorites' and policyname = 'Users manage their own favorites') then
    create policy "Users manage their own favorites" on public.user_favorites for all using (auth.uid() = user_id);
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 7. STORAGE BUCKETS
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('workout-media', 'workout-media', false)
on conflict (id) do nothing;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'Users can upload their own workout media') then
    create policy "Users can upload their own workout media"
      on storage.objects for insert
      with check (
        bucket_id = 'workout-media'
        and (storage.foldername(name))[1] = 'workouts'
        and (storage.foldername(name))[2] = auth.uid()::text
      );
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname = 'Users can view their own workout media') then
    create policy "Users can view their own workout media"
      on storage.objects for select
      using (
        bucket_id = 'workout-media'
        and (storage.foldername(name))[1] = 'workouts'
        and (storage.foldername(name))[2] = auth.uid()::text
      );
  end if;
end $$;
