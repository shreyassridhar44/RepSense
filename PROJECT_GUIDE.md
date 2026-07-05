# 📁 RepSense Project Guide

Complete reference for all files and folders in your project.

---

## 📚 Documentation Files (Read These!)

### Quick Start & Setup
- **START_HERE.md** ⭐ - Your entry point, links to all other guides
- **QUICK_START.md** ⭐ - Simple 3-step guide to run the app (5 min)
- **SETUP_COMPLETE.md** - Comprehensive setup with troubleshooting (15 min)
- **CONFIGURATION_SUMMARY.md** - Technical reference of all configurations
- **TESTING_CHECKLIST.md** - Step-by-step testing guide
- **README.md** - Original project overview and architecture

### Helper Scripts
- **START_BACKEND.bat** - Windows batch file to start all backend services
- **RUN_MOBILE_APP.bat** - Windows batch file to run the Flutter app

---

## 🗂️ Project Structure

```
repsense/
├── 📱 mobile/              # Flutter mobile app
├── ⚙️ backend/             # Backend microservices
│   ├── api_service/        # Main API (auth, workouts, exercises)
│   ├── inference_service/  # Pose analysis & biomechanics
│   ├── llm_coach_service/  # AI coaching (Gemini/Claude)
│   └── docker-compose.yml  # Run all services together
├── 🗄️ supabase/            # Database schema
├── 📚 Documentation files  # All the .md files
└── 🚀 Helper scripts       # .bat files
```

---

## 📱 Mobile App (`mobile/`)

### Configuration Files
```
mobile/
├── .env                    # ✅ CONFIGURED - Backend URLs & Supabase keys
├── .env.example            # Template (not used)
├── pubspec.yaml            # Flutter dependencies
└── lib/                    # Source code
```

### Source Code Structure
```
lib/
├── main.dart               # App entry point
├── app/                    # App-wide config
│   ├── router.dart         # Navigation routes
│   └── theme.dart          # Dark theme + brand colors
├── core/                   # Shared utilities
│   ├── constants/          # Brand colors, sizes
│   ├── utils/              # Helper functions
│   └── widgets/            # Reusable UI components
├── data/                   # Data layer
│   ├── supabase/           # Supabase client
│   ├── repositories/       # Data access patterns
│   └── models/             # Data models
├── features/               # Feature modules
│   ├── auth/               # Login, signup, profile
│   ├── camera/             # Live camera + pose detection
│   ├── workout/            # Exercise selection, workout flow
│   ├── history/            # Workout history
│   ├── analytics/          # Statistics & charts
│   └── coach/              # AI coach chat
└── services/               # Business logic
```

### Platform-Specific
```
android/
└── app/src/main/
    └── AndroidManifest.xml # ✅ Camera permissions configured

ios/
└── Runner/
    └── Info.plist          # ✅ Camera permissions configured
```

### Key Files to Know
- **lib/features/camera/camera_page.dart** - Camera screen with pose detection
  - Contains `_toInputImage()` stub that needs ML Kit conversion code
- **lib/data/supabase/supabase_service.dart** - Supabase client setup
- **lib/app/router.dart** - App navigation configuration

---

## ⚙️ Backend Services (`backend/`)

### API Service (Port 8000)
```
backend/api_service/
├── .env                    # ✅ CONFIGURED - Supabase keys
├── .env.example            # Template
├── requirements.txt        # Python dependencies
├── Dockerfile              # Container config
└── app/
    ├── main.py             # FastAPI app entry
    ├── api/
    │   └── routes/
    │       ├── health.py       # Health check endpoint
    │       ├── exercises.py    # Exercise CRUD
    │       └── workouts.py     # Workout CRUD
    ├── core/
    │   └── config.py       # Environment config
    ├── db/
    │   └── supabase_client.py  # Supabase connection
    ├── models/             # Database models
    ├── schemas/            # Pydantic schemas
    └── services/           # Business logic
```

**Purpose:** Main API for authentication, user data, exercises, and workouts.

**Key Endpoints:**
- `GET /health` - Health check
- `GET /api/exercises` - List all exercises
- `POST /api/workouts` - Save workout
- `GET /api/workouts` - Get user's workouts

### Inference Service (Port 8001)
```
backend/inference_service/
├── .env                    # ✅ CONFIGURED
├── requirements.txt
├── Dockerfile
└── app/
    ├── main.py
    ├── api/
    │   ├── routes_inference.py  # Analysis endpoints
    │   └── schemas.py           # Request/response models
    ├── core/
    │   └── config.py
    └── ml/                      # ML pipeline
        ├── pose_estimator.py    # MediaPipe Pose
        ├── joint_angles.py      # Calculate joint angles
        ├── rep_counter.py       # Count reps by phase
        └── biomechanics.py      # Form scoring logic
```

**Purpose:** Pose estimation, biomechanics analysis, rep counting.

**Key Endpoints:**
- `POST /inference/analyze-frame` - Analyze single frame
- `POST /inference/analyze-sequence` - Analyze full workout sequence

### LLM Coach Service (Port 8002)
```
backend/llm_coach_service/
├── .env                    # ✅ CONFIGURED - Gemini API key
├── requirements.txt        # ✅ MODIFIED - Added google-generativeai
├── Dockerfile
└── app/
    ├── main.py
    ├── api/
    │   └── routes_coach.py      # Coaching endpoints
    ├── core/
    │   └── config.py            # ✅ MODIFIED - Added Google config
    └── services/
        └── coach_engine.py      # ✅ MODIFIED - Gemini support
```

**Purpose:** Natural language coaching feedback using AI (Gemini/Claude).

**Key Endpoints:**
- `POST /coach/feedback` - Generate rep feedback
- `POST /coach/chat` - AI coach Q&A
- `POST /coach/summarize` - Workout summary

**Modifications Made:**
- Added support for Google Gemini API
- Maintained backward compatibility with Anthropic Claude
- Provider selectable via `LLM_PROVIDER` env variable

### Docker Compose
```
backend/docker-compose.yml  # ✅ Runs all 3 services together
```

---

## 🗄️ Database (`supabase/`)

```
supabase/
└── schema.sql              # ⏳ NEEDS TO BE RUN in Supabase dashboard
```

**Creates:**
- **exercises** - Exercise library (pre-populated with 14 exercises)
- **profiles** - User profiles (auto-created on signup)
- **workouts** - Completed workout records
- **rep_analyses** - Per-rep biomechanics data
- **achievements** - User badges/achievements
- **Storage bucket:** workout-media (for videos/screenshots)

**Security:**
- Row Level Security (RLS) policies configured
- Users can only access their own data
- Service role bypasses RLS for backend operations

---

## 🔑 Environment Variables

### Mobile App (.env)
```bash
SUPABASE_URL=https://lpgnmwgfjelpeqksxiug.supabase.co
SUPABASE_ANON_KEY=eyJhbGci... (configured)

# For Android Emulator:
API_SERVICE_URL=http://10.0.2.2:8000
INFERENCE_SERVICE_URL=http://10.0.2.2:8001
COACH_SERVICE_URL=http://10.0.2.2:8002

# For Physical Device (update with your IP):
# API_SERVICE_URL=http://192.168.1.X:8000
# INFERENCE_SERVICE_URL=http://192.168.1.X:8001
# COACH_SERVICE_URL=http://192.168.1.X:8002
```

### Backend - API Service (.env)
```bash
ENVIRONMENT=development
SUPABASE_URL=https://lpgnmwgfjelpeqksxiug.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci... (configured)
SUPABASE_JWT_SECRET=Bh2Kte... (configured)
INFERENCE_SERVICE_URL=http://localhost:8001
LLM_COACH_SERVICE_URL=http://localhost:8002
CORS_ORIGINS=["*"]
```

### Backend - Inference Service (.env)
```bash
ENVIRONMENT=development
MAX_UPLOAD_MB=100
```

### Backend - LLM Coach Service (.env)
```bash
ENVIRONMENT=development
LLM_PROVIDER=google
GOOGLE_API_KEY=AIzaSyC... (configured - your Gemini key)
GOOGLE_MODEL=gemini-pro
ANTHROPIC_API_KEY=
ANTHROPIC_MODEL=claude-sonnet-4-6
```

---

## 🛠️ Commands Reference

### Backend
```bash
# Start all services with Docker
cd backend
docker compose up --build

# Or run individually
cd backend/api_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Check logs
docker compose logs -f
docker compose logs -f api_service

# Stop services
docker compose down
```

### Mobile
```bash
# Install dependencies (first time)
cd mobile
flutter pub get

# Check Flutter setup
flutter doctor

# List available devices
flutter devices

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build APK (Android)
flutter build apk

# Build for iOS
flutter build ios
```

### Database
```bash
# No commands - use Supabase Dashboard
# SQL Editor → Run schema.sql
```

---

## 🎨 Brand Assets

### Colors (lib/core/constants/colors.dart)
- **Electric Blue:** #00D9FF (Primary - used for CTAs)
- **Deep Slate:** #0A1628 (Background)
- **Steel Gray:** #1E2A3A (Cards/surfaces)
- **Warm Amber:** #FFA726 (Warnings/alerts)
- **Neon Green:** #76FF03 (Success/correct form)
- **Crimson Red:** #FF1744 (Errors/incorrect form)

### Typography
- **Headers:** Montserrat (Bold/SemiBold)
- **Body:** Inter (Regular/Medium)
- Loaded via Google Fonts

### UI Style
- Dark theme with glassmorphism effects
- Frosted glass backgrounds
- Smooth animations
- Clear hierarchy

---

## 📦 Dependencies Summary

### Mobile (Flutter)
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **supabase_flutter** - Backend integration
- **camera** - Camera access
- **google_mlkit_pose_detection** - On-device pose detection
- **dio** - HTTP client
- **hive** - Local storage
- **fl_chart** - Charts/graphs
- **lottie** - Animations

### Backend (Python)
- **fastapi** - Web framework
- **uvicorn** - ASGI server
- **pydantic** - Data validation
- **supabase** - Database client
- **mediapipe** - Pose estimation
- **anthropic** - Claude API (optional)
- **google-generativeai** - Gemini API (active)

---

## 🚀 Development Workflow

### Daily Development
1. Start backend: `docker compose up` (or START_BACKEND.bat)
2. Start Flutter: `flutter run` (or RUN_MOBILE_APP.bat)
3. Make changes
4. Hot reload automatically updates the app

### Testing
1. Use Swagger UI: http://localhost:8000/docs
2. Test endpoints before wiring to mobile
3. Check backend logs for errors
4. Use Flutter DevTools for mobile debugging

### Version Control
```bash
git add .
git commit -m "Description"
git push
```

---

## 🎯 What to Work On Next

### Priority 1: Core Functionality
1. ✅ Basic setup complete
2. ⏳ Run Supabase schema
3. ⏳ Implement `_toInputImage()` in camera_page.dart
4. ⏳ Wire camera → inference service POST
5. ⏳ Display analysis results in UI

### Priority 2: Features
6. ⏳ Workout history screen
7. ⏳ Analytics/progress tracking
8. ⏳ AI coach chat integration
9. ⏳ Achievement system
10. ⏳ Profile customization

### Priority 3: Polish
11. ⏳ Custom app icon
12. ⏳ Splash screen animations
13. ⏳ Onboarding tutorial
14. ⏳ Sound effects/haptics
15. ⏳ Google/Apple Sign-In

### Priority 4: Deployment
16. ⏳ Deploy backend to cloud (Render/Railway)
17. ⏳ Update mobile with prod URLs
18. ⏳ Build release APK
19. ⏳ Test on multiple devices
20. ⏳ Submit to app stores

---

## 📞 Support Resources

### Documentation
- Flutter: https://docs.flutter.dev
- FastAPI: https://fastapi.tiangolo.com
- Supabase: https://supabase.com/docs
- MediaPipe: https://google.github.io/mediapipe
- ML Kit: https://developers.google.com/ml-kit
- Gemini: https://ai.google.dev/docs

### Your Project Docs
- START_HERE.md - Entry point
- QUICK_START.md - Quick setup
- SETUP_COMPLETE.md - Detailed guide
- TESTING_CHECKLIST.md - Testing steps

---

**This guide covers everything in your project. Bookmark it for reference! 📚**
