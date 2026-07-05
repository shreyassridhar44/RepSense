# 🚀 RepSense Quick Start Guide

## ✅ What's Already Done

All configuration is complete! Here's what's been set up:

### 1. Backend Services (All 3 .env files configured)
- ✅ **API Service** - Connected to your Supabase database
- ✅ **Inference Service** - Ready for pose analysis  
- ✅ **LLM Coach Service** - Configured with your Gemini API key

### 2. Mobile App
- ✅ Supabase credentials configured
- ✅ Camera permissions set (Android & iOS)
- ✅ Backend URLs configured for Android emulator

### 3. Gemini Integration
- ✅ Modified LLM coach service to support Google Gemini
- ✅ Your Gemini API key is configured and ready

---

## 🎯 Three Simple Steps to Run

### Step 1: Set Up Database (One Time - 2 minutes)

1. Open your browser and go to your Supabase project:
   **https://lpgnmwgfjelpeqksxiug.supabase.co**

2. Navigate to: **SQL Editor** → **New query**

3. Open the file: `c:\dev\repsense\supabase\schema.sql`

4. Copy the entire contents and paste it into the SQL Editor

5. Click **Run** 

6. ✅ Done! You should see tables created successfully

---

### Step 2: Start Backend (Every Time - 1 minute)

**Option A: Using the batch file (easiest)**
- Double-click: `c:\dev\repsense\START_BACKEND.bat`
- Wait until you see all services running
- Keep the window open while testing

**Option B: Manual command**
```bash
cd c:\dev\repsense\backend
docker compose up --build
```

**Verify it's working:**
- Open in browser: http://localhost:8000/docs
- You should see the FastAPI documentation page

---

### Step 3: Run Mobile App (Every Time - 2 minutes)

**Option A: Using the batch file**
- Make sure an Android emulator is running (or phone connected)
- Double-click: `c:\dev\repsense\RUN_MOBILE_APP.bat`

**Option B: Manual command**
```bash
cd c:\dev\repsense\mobile
flutter run
```

**First time only:**
If Flutter complains about missing packages:
```bash
cd c:\dev\repsense\mobile
flutter pub get
flutter run
```

---

## 📱 Testing on Your Physical Phone

1. **Enable USB Debugging on your phone:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable USB Debugging
   - Connect phone via USB

2. **Find your computer's IP address:**
   ```bash
   ipconfig
   ```
   Look for "IPv4 Address" (e.g., 192.168.1.23)

3. **Update mobile/.env file:**
   Edit `c:\dev\repsense\mobile\.env` and replace:
   ```
   API_SERVICE_URL=http://YOUR_IP:8000
   INFERENCE_SERVICE_URL=http://YOUR_IP:8001
   COACH_SERVICE_URL=http://YOUR_IP:8002
   ```
   Example:
   ```
   API_SERVICE_URL=http://192.168.1.23:8000
   INFERENCE_SERVICE_URL=http://192.168.1.23:8001
   COACH_SERVICE_URL=http://192.168.1.23:8002
   ```

4. **Run the app:**
   ```bash
   cd c:\dev\repsense\mobile
   flutter run
   ```
   Select your device when prompted

---

## 🧪 What You Can Test Right Now

### 1. Authentication Flow ✅
- Launch the app
- Tap "Sign Up"
- Create an account with email/password
- You should be logged in and see the home screen

### 2. Exercise Library ✅
- Browse the list of exercises
- Tap on any exercise to see details
- Check muscle groups, difficulty, etc.

### 3. Camera Preview ✅
- Select an exercise
- Tap "Start Workout"  
- Grant camera permission when asked
- You should see your camera feed

### 4. Backend APIs ✅
Open these in your browser to test:
- http://localhost:8000/health - API Service health
- http://localhost:8001/health - Inference Service health
- http://localhost:8002/health - Coach Service health
- http://localhost:8000/docs - Full API documentation

---

## ⚠️ Known Limitations

These features need additional work (as mentioned in README):

1. **Pose Detection Not Active Yet**
   - Camera shows your video feed
   - But pose landmarks aren't being detected yet
   - Needs ML Kit conversion code (30 lines)

2. **Workout Data Not Saved**
   - UI works but doesn't POST to backend yet
   - Needs integration wiring

3. **Google/Apple Sign-In**
   - Not configured yet (requires OAuth setup)
   - Email/password auth works fine

---

## 🐛 Troubleshooting

### "Port already in use"
```bash
# Windows - find and kill process on port 8000
netstat -ano | findstr :8000
taskkill /PID <number> /F
```

### "Docker not found"
- Make sure Docker Desktop is installed and running
- Download from: https://www.docker.com/products/docker-desktop

### "Flutter not found"
- Install Flutter: https://docs.flutter.dev/get-started/install
- Add Flutter to PATH
- Run: `flutter doctor` to verify setup

### "No devices found"
- For emulator: Open Android Studio → Device Manager → Start emulator
- For physical device: Enable USB debugging and connect via USB
- Verify with: `flutter devices`

### "Can't connect to backend from phone"
- Make sure phone and computer are on the same WiFi
- Use your computer's IP, not `localhost` or `10.0.2.2`
- Check Windows Firewall allows ports 8000-8002

### "Camera permission denied"
- Android: Settings → Apps → RepSense → Permissions → Camera
- iOS: Settings → Privacy → Camera → RepSense

---

## 📊 Service URLs Reference

### Backend Services (from your computer)
- API Service: http://localhost:8000
- Inference Service: http://localhost:8001  
- Coach Service: http://localhost:8002

### From Android Emulator
- Use: http://10.0.2.2:8000 (already configured)

### From Physical Device
- Use your computer's IP: http://192.168.1.X:8000

### Supabase
- Project URL: https://lpgnmwgfjelpeqksxiug.supabase.co
- Dashboard: https://supabase.com/dashboard/project/lpgnmwgfjelpeqksxiug

---

## ✨ You're All Set!

Everything is configured and ready to run. Just follow the three steps:

1. ✅ Set up database (one time)
2. ✅ Start backend services  
3. ✅ Run mobile app

The app should launch and you can sign up, browse exercises, and test the camera!

For detailed information, see `SETUP_COMPLETE.md`.

**Happy Testing! 💪**
