# RepSense Deployment Guide

## 🎯 Quick Answer: Do You Need Backend?

### ✅ Works WITHOUT Backend (Supabase only):
- Authentication (Email/Password, Google Sign-in)
- Exercise browsing and favorites
- Workout logging and history
- Progress tracking and statistics
- Achievements and gamification
- Profile management (except account deletion)
- Offline mode

### ❌ Requires Backend:
- **AI Pose Analysis** (camera workout with real-time feedback)
- **AI Coach Chat** (LLM-powered fitness coaching)
- **Account Deletion** (API endpoint required)

**For testing with friends: You can skip backend initially. Most features work!**

---

## 🚀 Option 1: Test Without Backend (Recommended for MVP)

### Step 1: Update Mobile App Config

Edit `mobile/.env`:
```env
SUPABASE_URL=https://lpgmwgfjelpeqksxlug.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Leave these commented out (features will be disabled)
# API_SERVICE_URL=
# INFERENCE_SERVICE_URL=
# COACH_SERVICE_URL=
```

### Step 2: Build APK

```bash
cd mobile
flutter build apk --release
```

APK location: `mobile/build/app/outputs/apk/release/app-release.apk`

### Step 3: Share with Friends

Send them the APK file. They can:
- Sign up / Sign in
- Browse exercises
- Log workouts manually
- Track progress
- Earn achievements

**What won't work:**
- Camera-based AI analysis (button will be hidden/disabled)
- AI Coach chat (button will be hidden/disabled)
- Account deletion (will show error)

---

## 🚀 Option 2: Deploy Backend to Render (Free Tier)

**Time required:** ~30 minutes  
**Cost:** Free (with limitations: sleeps after 15min inactivity, 750 hours/month)

### Prerequisites

1. **GitHub Account** - Backend code must be on GitHub
2. **Render Account** - Sign up at https://render.com (free)
3. **Supabase Credentials** - From your Supabase dashboard
4. **OpenAI API Key** - For AI coach (optional, $5 credit free for new accounts)

---

## 📦 Step-by-Step Deployment

### Step 1: Push Code to GitHub

```bash
cd c:\dev\repsense

# Initialize git (if not already)
git init
git add .
git commit -m "Initial commit"

# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/repsense.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy API Service (Account Management)

1. Go to https://dashboard.render.com
2. Click **New +** → **Web Service**
3. Connect your GitHub repository
4. Configure:
   - **Name:** `repsense-api`
   - **Root Directory:** `backend/api_service`
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** Free

5. Add Environment Variables:
   ```
   SUPABASE_URL = https://lpgmwgfjelpeqksxlug.supabase.co
   SUPABASE_ANON_KEY = your_anon_key_here
   SUPABASE_SERVICE_ROLE_KEY = your_service_role_key_here
   ```

6. Click **Create Web Service**

7. Wait 5-10 minutes for deployment

8. Copy the URL (e.g., `https://repsense-api.onrender.com`)

### Step 3: Deploy Inference Service (AI Pose Analysis)

1. Click **New +** → **Web Service**
2. Same repository
3. Configure:
   - **Name:** `repsense-inference`
   - **Root Directory:** `backend/inference_service`
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** Free

4. No environment variables needed

5. Click **Create Web Service**

6. Copy the URL (e.g., `https://repsense-inference.onrender.com`)

### Step 4: Deploy Coach Service (AI Chat) - Optional

**Note:** Requires OpenAI API key ($5 free credit for new accounts)

1. Get OpenAI API key: https://platform.openai.com/api-keys

2. Click **New +** → **Web Service**
3. Configure:
   - **Name:** `repsense-coach`
   - **Root Directory:** `backend/llm_coach_service`
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** Free

4. Add Environment Variable:
   ```
   OPENAI_API_KEY = sk-xxxxxxxxxxxxx
   ```

5. Click **Create Web Service**

6. Copy the URL (e.g., `https://repsense-coach.onrender.com`)

### Step 5: Update Mobile App Config

Edit `mobile/.env`:
```env
SUPABASE_URL=https://lpgmwgfjelpeqksxlug.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Add your Render URLs (without trailing slash)
API_SERVICE_URL=https://repsense-api.onrender.com
INFERENCE_SERVICE_URL=https://repsense-inference.onrender.com
COACH_SERVICE_URL=https://repsense-coach.onrender.com
```

### Step 6: Update Profile Repository

Edit `mobile/lib/data/repositories/profile_repository.dart`:

Find this line (around line 205):
```dart
const backendUrl = 'http://localhost:8000'; // Change to actual URL
```

Replace with:
```dart
final backendUrl = AppConfig.apiServiceUrl;
```

### Step 7: Rebuild APK

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

### Step 8: Test and Share

1. Install APK on your phone
2. Test all features:
   - Sign up/Sign in
   - Camera workout with AI analysis
   - AI Coach chat
   - Account deletion
3. Share APK with friends!

---

## ⚠️ Important Notes

### Render Free Tier Limitations:
- **Sleeps after 15 min inactivity** - First request after sleep takes 30-60 seconds
- **750 hours/month** - Enough for 3 services running 24/7 for 10 days
- **Shared CPU** - Slower than paid plans
- **Best for:** Testing with 5-10 friends

### First Request is Slow:
When services sleep, the first API call will take 30-60 seconds. Show a loading indicator in your app.

### Upgrading Later:
If you get more users:
- **Render Paid:** $7/month per service (doesn't sleep)
- **Railway:** Similar to Render
- **Fly.io:** Better performance, more complex setup
- **AWS/GCP:** Production-grade, more expensive

---

## 🎯 Recommended Path

### For Your Friends (Testing):
1. ✅ Start with **Option 1** (No backend)
2. ✅ Get feedback on core features
3. ✅ Deploy backend if they want AI features

### For Production (100+ users):
1. Deploy to Render paid plan ($21/month for 3 services)
2. Or use Railway/Fly.io
3. Set up monitoring and auto-scaling

---

## 🐛 Troubleshooting

### "Service Unavailable" Error:
- Service is sleeping, wait 60 seconds and retry

### "Connection Timeout":
- Check Render dashboard for build errors
- Verify environment variables are set

### Build Failed on Render:
- Check `requirements.txt` has all dependencies
- Check Python version is 3.11

### AI Features Not Working:
- Verify all 3 services are deployed and healthy
- Check Render logs for errors
- Ensure `.env` URLs are correct (no trailing slash)

---

## 📊 Summary

| Feature | Supabase Only | With Backend |
|---------|---------------|--------------|
| Authentication | ✅ | ✅ |
| Exercises | ✅ | ✅ |
| Workouts | ✅ | ✅ |
| Progress | ✅ | ✅ |
| Achievements | ✅ | ✅ |
| **AI Pose Analysis** | ❌ | ✅ |
| **AI Coach Chat** | ❌ | ✅ |
| **Account Deletion** | ❌ | ✅ |

**My Recommendation:** Start with Supabase only, deploy backend when your friends want AI features.
