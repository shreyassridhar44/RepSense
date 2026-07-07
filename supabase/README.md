# RepSense Supabase Configuration

This folder contains the Supabase database schema for all modules.

## 📁 Structure

```
supabase/
├── schema.sql                   # Complete database schema (all modules)
├── README.md                    # This file
└── .gitignore                   # Git ignore rules
```

## 🚀 Deployment

### Deploy Schema to Supabase

1. Go to: https://supabase.com/dashboard
2. Click: SQL Editor → New query
3. Copy entire contents of `schema.sql`
4. Paste and click "Run"
5. Wait 30-60 seconds for completion

That's it! No other steps needed.

## 📋 What's Included

The schema includes all modules:

- **Module 1**: Auth & Profiles
- **Module 2**: Home Dashboard (workouts, exercises)
- **Module 3**: Workout & Exercises (favorites, details)
- **Module 5**: Camera & AI (rep analyses)
- **Module 8**: Gamification (achievements, challenges, leaderboard)
- **Module 9**: Profile & Settings (export, feedback, avatars)

## 🔒 Security

- All tables have Row Level Security (RLS) enabled
- Users can only access their own data
- Storage buckets have proper access policies
- Account deletion handled by backend API (not Edge Functions)

## 📝 Account Deletion

Account deletion is handled by the backend API service at `/account/delete`.

See: `backend/api_service/app/api/routes/account.py`

The endpoint uses the service role key from backend environment variables to safely delete user accounts.

