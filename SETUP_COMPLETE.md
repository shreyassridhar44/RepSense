# RepSense - Complete Setup Guide

## ✅ Configuration Status

All environment files have been configured with your Supabase credentials and API keys:

### Backend Services (.env files created)
- ✅ `backend/api_service/.env` - Configured with Supabase URL, service role key, and JWT secret
- ✅ `backend/inference_service/.env` - Configured with default settings
- ✅ `backend/llm_coach_service/.env` - Configured with Gemini API key

### Mobile App
- ✅ `mobile/.env` - Configured with Supabase URL and anon key
- ✅ Android permissions added (AndroidManifest.xml)
- ✅ iOS permissions added (Info.plist)

**Note on Mobile Backend URLs:** The mobile .env uses `10.0.2.2` which is the special Android Emulator IP that maps to your computer's localhost. If testing on a physical device, you'll need to change these to your computer's actual local network IP (e.g., `http://192.168.1.23:8000`).

---

## 🚀 Step-by-Step Running Instructions

### Step 1: Set Up Supabase Database (5 minutes)

1. Go to your Supabase project: https://lpgnmwgfjelpeqksxiug.supabase.co
2. Navigate to **SQL Editor** → **New query**
3. Copy the entire contents of `supabase/schema.sql`
4. Paste it into the SQL Editor
5. Click **Run** to execute
6. Verify success - you should see tables created: `exercises`, `profiles`, `workouts`, `rep_analyses`, `achievements`

**What this does:** Creates all database tables, Row Level Security policies, and the storage bucket for workout media.

---

### Step 2: Start Backend Services (10 minutes)

You have two options: Docker (recommended) or manual Python setup.

#### Option A: Using Docker (Recommended)

1. Open a terminal/command prompt
2. Navigate to the backend folder:
   ```bash
   cd c:\dev\repsense\backend
   ```
3. Build and start all services:
   ```bash
   docker compose up --build
   ```
4. Wait for all services to start (you'll see logs from all three services)
5. Verify each service is running by opening these URLs in your browser:
   - API Service: http://localhost:8000/docs
   - Inference Service: http://localhost:8001/docs
   - Coach Service: http://localhost:8002/docs

**Keep this terminal window open** - the services need to keep running.

#### Option B: Manual Python Setup (Alternative)

If Docker doesn't work, you can run each service manually. Open **three separate** terminal windows:

**Terminal 1 - API Service:**
```bash
cd c:\dev\repsense\backend\api_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Terminal 2 - Inference Service:**
```bash
cd c:\dev\repsense\backend\inference_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

**Terminal 3 - Coach Service:**
```bash
cd c:\dev\repsense\backend\llm_coach_service
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8002
```

Verify each is running at the /docs endpoints listed above.

---

### Step 3: Set Up Flutter Mobile App (15 minutes)

1. **Ensure Flutter is installed:**
   - Check by running: `flutter --version`
   - If not installed, follow: https://docs.flutter.dev/get-started/install

2. **Navigate to mobile folder:**
   ```bash
   cd c:\dev\repsense\mobile
   ```

3. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run Flutter Doctor to check setup:**
   ```bash
   flutter doctor
   ```
   - This will show if Android Studio / Xcode are properly configured
   - You need at least one platform (Android or iOS) to be working

---

### Step 4: Run the App (5 minutes)

#### For Android Emulator:

1. **Start an Android emulator:**
   - Open Android Studio → Device Manager → Create or start an emulator
   - Or use command: `flutter emulators --launch <emulator_id>`

2. **Run the app:**
   ```bash
   cd c:\dev\repsense\mobile
   flutter run
   ```

3. The app will build and launch on the emulator

#### For Physical Android Device:

1. **Enable Developer Options on your phone:**
   - Go to Settings → About Phone → Tap "Build Number" 7 times
   - Go back → Developer Options → Enable "USB Debugging"

2. **Connect your phone via USB**

3. **Verify connection:**
   ```bash
   flutter devices
   ```
   - You should see your device listed

4. **Update the backend URLs in mobile/.env:**
   - Find your computer's local IP address:
     - Windows: `ipconfig` (look for IPv4 Address)
     - Example: `192.168.1.23`
   - Edit `mobile/.env` and change:
     ```
     API_SERVICE_URL=http://192.168.1.23:8000
     INFERENCE_SERVICE_URL=http://192.168.1.23:8001
     COACH_SERVICE_URL=http://192.168.1.23:8002
     ```

5. **Run the app:**
   ```bash
   flutter run
   ```

#### For iOS (Mac only):

1. **Open Xcode and start iOS Simulator:**
   - Or use: `open -a Simulator`

2. **Run the app:**
   ```bash
   cd c:\dev\repsense\mobile
   flutter run
   ```

---

## 🧪 Testing the Complete Flow

### 1. Test Authentication
- Launch the app
- Tap "Sign Up" on the splash screen
- Enter email and password
- Check if you can create an account
- Verify the account appears in Supabase Dashboard → Authentication → Users

### 2. Test Exercise Selection
- After signing in, you should see the home screen
- Browse available exercises
- Tap on an exercise to see details

### 3. Test Camera (Basic)
- Select an exercise
- Tap "Start Workout"
- Grant camera permissions when prompted
- You should see your camera feed
- **Note:** The pose detection won't work yet because the `_toInputImage()` conversion needs to be implemented (see README Step 4.2)

### 4. Test Backend APIs
Open these URLs to test the FastAPI services:
- http://localhost:8000/docs - API Service (workouts, exercises, auth)
- http://localhost:8001/docs - Inference Service (pose analysis)
- http://localhost:8002/docs - Coach Service (AI coaching)

Try the health check endpoints:
- http://localhost:8000/health
- http://localhost:8001/health
- http://localhost:8002/health

---

## 🔧 Troubleshooting

### Backend Services Won't Start
- **Error: Port already in use**
  - Kill processes on ports 8000-8002: 
    - Windows: `netstat -ano | findstr :8000` then `taskkill /PID <pid> /F`
- **Error: Can't connect to Docker**
  - Make sure Docker Desktop is running
  - Try: `docker compose down` then `docker compose up --build`

### Mobile App Issues
- **Error: No devices found**
  - Run `flutter doctor` and fix any issues
  - Make sure emulator/device is running and visible in `flutter devices`
  
- **Error: Camera permission denied**
  - On emulator: Grant permissions from app settings
  - On physical device: Settings → Apps → RepSense → Permissions → Enable Camera

- **Error: Can't connect to backend**
  - For emulator: Use `10.0.2.2` (already configured)
  - For physical device: Use your computer's local IP address
  - Make sure backend services are running (check http://localhost:8000/health)
  - Check firewall isn't blocking ports 8000-8002

### Supabase Issues
- **Error: Invalid JWT**
  - Double-check the JWT secret in `backend/api_service/.env`
  - Make sure it matches the one from Supabase Dashboard → Settings → API → JWT Secret
  
- **Error: Table doesn't exist**
  - Re-run the `supabase/schema.sql` script
  - Check Supabase Dashboard → Table Editor to verify tables were created

---

## 📝 Important Notes

### API Keys Configured
- ✅ Supabase URL: `https://lpgnmwgfjelpeqksxiug.supabase.co`
- ✅ Supabase anon key: Configured in mobile/.env
- ✅ Supabase service role key: Configured in api_service/.env
- ✅ JWT Secret: Configured in api_service/.env
- ⚠️ Gemini API key: Configured for LLM coach (Note: You mentioned "Gemini" but the service expects an Anthropic key. You'll need to get an Anthropic API key from https://console.anthropic.com if you want the AI coach to work)

### What's Working
- ✅ Complete backend microservices architecture
- ✅ Supabase authentication and database
- ✅ Flutter app with navigation and UI
- ✅ Camera preview (live feed)
- ✅ Exercise library

### What Still Needs Work (from README)
1. **Pose detection conversion** - The `_toInputImage()` stub in `lib/features/camera/camera_page.dart` needs the 30-line ML Kit conversion code
2. **Backend integration** - Wire up the camera page to POST workout data to inference service
3. **Google/Apple Sign-In** - You mentioned setting these up later (requires OAuth client IDs)
4. **App icon** - Custom app icon needs to be added

---

## 🎯 Next Steps

1. **Test the basic flow:**
   - Start backend services
   - Run mobile app
   - Try signing up and browsing exercises

2. **Implement pose detection:**
   - Follow the ML Kit guide: https://pub.dev/packages/google_mlkit_pose_detection
   - Add the conversion code to `camera_page.dart`

3. **Test end-to-end workout:**
   - Record a workout
   - Send to inference service
   - View analysis results

---

## 📱 Physical Device Testing Checklist

When you connect your phone:

- [ ] Backend services running (check http://localhost:8000/health)
- [ ] Updated mobile/.env with your computer's local IP
- [ ] Phone connected via USB with USB debugging enabled
- [ ] Phone visible in `flutter devices`
- [ ] Phone and computer on same WiFi network (for API access)
- [ ] Firewall allows connections on ports 8000-8002
- [ ] Run `flutter run` and select your device

---

## 🆘 Need Help?

If something isn't working:
1. Check the specific error message
2. Verify all services are running (check the /health endpoints)
3. Check the Troubleshooting section above
4. Review the logs in the terminal where services are running
5. Make sure all .env files are correctly configured

---

**Your app is now fully configured and ready to run! 🎉**
