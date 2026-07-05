# ✅ RepSense Testing Checklist

Use this checklist to verify your complete setup is working properly.

---

## 🔧 Pre-Testing Setup

### Database Setup (One Time Only)
- [ ] Opened Supabase dashboard: https://lpgnmwgfjelpeqksxiug.supabase.co
- [ ] Navigated to SQL Editor → New query
- [ ] Copied contents from `supabase/schema.sql`
- [ ] Pasted and clicked **Run**
- [ ] Verified tables created: exercises, profiles, workouts, rep_analyses, achievements
- [ ] Checked Storage → Buckets → Verified `workout-media` bucket exists

---

## 🚀 Backend Services Testing

### Starting Services
- [ ] Opened terminal/command prompt
- [ ] Navigated to `c:\dev\repsense\backend`
- [ ] Ran `docker compose up --build` (or double-clicked START_BACKEND.bat)
- [ ] Waited for "Application startup complete" messages from all services
- [ ] Kept terminal window open

### Verifying Services
- [ ] **API Service:** Opened http://localhost:8000/docs in browser
  - [ ] Saw FastAPI Swagger UI
  - [ ] Tested http://localhost:8000/health - Got `{"status":"healthy"}` response

- [ ] **Inference Service:** Opened http://localhost:8001/docs
  - [ ] Saw FastAPI Swagger UI  
  - [ ] Tested http://localhost:8001/health - Got healthy response

- [ ] **LLM Coach Service:** Opened http://localhost:8002/docs
  - [ ] Saw FastAPI Swagger UI
  - [ ] Tested http://localhost:8002/health - Got healthy response

### Testing API Endpoints

#### Test Exercises Endpoint
- [ ] Opened http://localhost:8000/docs
- [ ] Found `GET /api/exercises` endpoint
- [ ] Clicked "Try it out" → "Execute"
- [ ] Got list of 14 exercises (squat, deadlift, bench_press, etc.)

#### Test Inference Endpoint
- [ ] Opened http://localhost:8001/docs
- [ ] Verified `/inference/analyze-sequence` endpoint exists
- [ ] Verified `/inference/analyze-frame` endpoint exists

#### Test Coach Endpoint
- [ ] Opened http://localhost:8002/docs  
- [ ] Verified `/coach/feedback` endpoint exists
- [ ] Verified `/coach/chat` endpoint exists

---

## 📱 Mobile App Testing

### Setup
- [ ] Ran `flutter doctor` - Verified Flutter is installed
- [ ] Checked for Android Studio/Xcode setup
- [ ] Started Android emulator OR connected physical device
- [ ] Verified device with `flutter devices`

### Running the App
- [ ] Opened new terminal
- [ ] Navigated to `c:\dev\repsense\mobile`
- [ ] Ran `flutter pub get` (first time only)
- [ ] Ran `flutter run` (or double-clicked RUN_MOBILE_APP.bat)
- [ ] App built successfully
- [ ] App launched on device/emulator

---

## 🧪 Functional Testing

### 1. Authentication Flow
- [ ] App launched to splash/welcome screen
- [ ] Tapped "Sign Up" button
- [ ] Entered email: `test@example.com`
- [ ] Entered password: `Test123456!`
- [ ] Tapped "Sign Up" or "Create Account"
- [ ] Successfully created account
- [ ] Automatically logged in
- [ ] Landed on home/dashboard screen

**Verify in Supabase:**
- [ ] Went to Supabase Dashboard → Authentication → Users
- [ ] Saw new user `test@example.com` listed
- [ ] Went to Table Editor → profiles table
- [ ] Saw corresponding profile row created

### 2. Sign Out and Sign In
- [ ] Found and tapped profile/menu button
- [ ] Tapped "Sign Out" or "Logout"
- [ ] Returned to welcome screen
- [ ] Tapped "Sign In" or "Login"
- [ ] Entered same credentials
- [ ] Successfully logged back in

### 3. Exercise Library
- [ ] Saw list of exercises on home screen
- [ ] Verified exercises displayed: Squat, Deadlift, Push-up, etc.
- [ ] Each exercise showed:
  - [ ] Exercise name
  - [ ] Difficulty level (Beginner/Intermediate/Advanced)
  - [ ] Muscle groups
  - [ ] Equipment needed

### 4. Exercise Details
- [ ] Tapped on "Squat" exercise
- [ ] Opened exercise detail screen
- [ ] Saw full exercise information
- [ ] Saw "Start Workout" or similar button
- [ ] Went back to exercise list
- [ ] Tapped different exercise (e.g., "Push-up")
- [ ] Verified different exercise details shown

### 5. Camera Access
- [ ] Tapped "Start Workout" on any exercise
- [ ] Got camera permission prompt
- [ ] Granted camera permission
- [ ] Camera screen loaded
- [ ] Saw live camera feed/preview
- [ ] Camera showed current video in real-time

**Expected Behavior:**
- ✅ Camera feed should display
- ⚠️ Pose skeleton overlay won't show yet (needs ML Kit implementation)
- ⚠️ Rep counter won't work yet (needs backend integration)

### 6. Navigation
- [ ] Used back button to exit camera
- [ ] Returned to exercise detail screen
- [ ] Used back button again
- [ ] Returned to exercise list
- [ ] Tapped profile/settings icon (if visible)
- [ ] Navigated through all main screens

### 7. UI/UX Check
- [ ] Dark theme applied correctly
- [ ] Glassmorphism effects visible (frosted glass backgrounds)
- [ ] RepSense branding colors visible (Electric Blue #00D9FF, etc.)
- [ ] Text readable and well-formatted
- [ ] Buttons responsive to taps
- [ ] Smooth animations/transitions
- [ ] No obvious UI glitches

---

## 🔄 Physical Device Testing (Optional)

If testing on physical Android device:

### Setup
- [ ] Enabled Developer Options on phone
- [ ] Enabled USB Debugging
- [ ] Connected phone via USB
- [ ] Phone appeared in `flutter devices`
- [ ] Found computer's IP address with `ipconfig`
- [ ] Updated `mobile/.env` with computer's IP:
  ```
  API_SERVICE_URL=http://YOUR_IP:8000
  INFERENCE_SERVICE_URL=http://YOUR_IP:8001
  COACH_SERVICE_URL=http://YOUR_IP:8002
  ```
- [ ] Phone and computer on same WiFi network

### Testing
- [ ] Ran `flutter run` and selected physical device
- [ ] App installed and launched on phone
- [ ] Repeated all functional tests above
- [ ] Verified backend connectivity (able to sign up/login)
- [ ] Camera worked properly
- [ ] No connection errors

---

## 🐛 Issue Tracking

### Backend Issues Encountered
| Issue | Solution | Status |
|-------|----------|--------|
| | | |

### Mobile Issues Encountered
| Issue | Solution | Status |
|-------|----------|--------|
| | | |

### Database Issues Encountered
| Issue | Solution | Status |
|-------|----------|--------|
| | | |

---

## ✅ Testing Summary

### What's Working
- [ ] Backend services running
- [ ] Database connected
- [ ] User authentication (email/password)
- [ ] Exercise library loading
- [ ] Camera preview displaying
- [ ] Navigation between screens
- [ ] UI/UX rendering correctly

### Known Limitations (Expected)
- [ ] Pose detection not active (needs ML Kit conversion)
- [ ] Rep counting not working (needs backend integration)
- [ ] Workout data not saving (needs POST wiring)
- [ ] Google/Apple sign-in not configured
- [ ] AI coach chat not fully wired up

### Unexpected Issues
List any issues not mentioned in "Known Limitations":
1. ___________________________________
2. ___________________________________
3. ___________________________________

---

## 📊 Test Results

**Date:** _______________  
**Tester:** _______________  
**Device:** _______________  
**OS Version:** _______________

**Overall Status:**
- [ ] ✅ All critical features working
- [ ] ⚠️ Some issues but app functional
- [ ] ❌ Major issues preventing testing

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________

---

## 🎯 Next Steps After Testing

1. [ ] Document any unexpected issues
2. [ ] Implement ML Kit pose detection conversion
3. [ ] Wire camera → inference service integration
4. [ ] Test workout recording flow end-to-end
5. [ ] Add workout history/analytics screens
6. [ ] Set up Google/Apple OAuth
7. [ ] Add custom app icon
8. [ ] Deploy backend to production
9. [ ] Build release APK/IPA
10. [ ] Submit to app stores

---

**Testing Complete! 🎉**

Save this checklist with your results for reference.
