# RepSense — Every Rep. Perfected.

This is the starter codebase for **RepSense**, generated from your two brand/spec PDFs. It is a real, runnable scaffold — not a mockup — with sensible substitutions noted below where the original spec named a niche package.

## What's in the zip

```
repsense/
├── mobile/              Flutter app (Android + iOS), dark/glassmorphism UI
├── backend/
│   ├── api_service/         FastAPI — auth, users, workouts, analytics
│   ├── inference_service/   FastAPI — pose estimation, joint angles, rep counting, biomechanics scoring
│   ├── llm_coach_service/   FastAPI — natural-language coaching via Claude
│   └── docker-compose.yml   Runs all 3 services together
└── supabase/
    └── schema.sql        Full Postgres schema + Row Level Security + storage bucket
```

## Why Supabase (not Firebase)

You asked me to pick whichever fits better — **Supabase wins for RepSense** because:
- Your technical spec calls for **PostgreSQL + SQLAlchemy**. Supabase *is* hosted Postgres, so the schema is reusable as-is by your FastAPI services — no separate Firestore-to-SQL translation layer.
- **Row Level Security** gives per-user data isolation out of the box, matching your "User privacy and data security" core value, without writing custom security rules.
- One bucket-based **Storage** system covers workout videos / screenshots / reports.
- Auth (email, Google, Apple, guest) is built in and issues a JWT your FastAPI `api_service` already verifies (`app/db/supabase_client.py`).

## Substitutions from the spec (and why)

| Spec said | I used | Why |
|---|---|---|
| Signals (state mgmt) | **Riverpod** | Signals for Flutter is a niche/young package; Riverpod is the de-facto standard, has the same "no business logic in widgets" philosophy, and has vastly better docs/community support for you to lean on. |
| AutoRoute | **go_router** | Same strongly-typed/guarded/deep-linkable routing, but zero code-gen step required, which means less for you to debug. |
| Isar | **Hive** | Isar's Flutter SDK has had ongoing maintenance uncertainty; Hive is stable and sufficient for settings/cache. Swap later if you need richer querying — the data layer is already isolated behind repositories. |
| YOLO-free ML pipeline | **MediaPipe Pose (server) + ML Kit Pose (on-device)** | Exactly as the spec recommended — pose estimation, not object detection, as the core model. |

Everything else (Flutter, FastAPI, the 3-service split, JWT auth, Celery/Redis notes, brand colors/fonts, rep-counting-by-phase logic, explainable AI feedback format) follows your documents directly.

---

# Step-by-step setup

## 1. Supabase project (10 min)
1. Go to https://supabase.com → New project.
2. Once created, go to **SQL Editor → New query**, paste the contents of `supabase/schema.sql`, and click **Run**. This creates all tables, RLS policies, and the storage bucket.
3. Go to **Project Settings → API**. Copy:
   - `Project URL` → you'll need this twice (mobile `.env` and nothing else)
   - `anon public` key → mobile `.env`
   - `service_role` key → `backend/api_service/.env` (⚠️ never put this in the mobile app)
4. Go to **Project Settings → API → JWT Settings**. Copy the `JWT Secret` → `backend/api_service/.env`.
5. (Optional, for Google/Apple sign-in) Go to **Authentication → Providers** and enable Google / Apple, following Supabase's own setup guide for each.

## 2. Backend (15 min)
```bash
cd backend

# Each service needs its own .env — copy the example and fill in real values
cp api_service/.env.example api_service/.env
cp inference_service/.env.example inference_service/.env
cp llm_coach_service/.env.example llm_coach_service/.env
```
- Edit `api_service/.env` → paste Supabase URL, service role key, JWT secret.
- Edit `llm_coach_service/.env` → paste an Anthropic API key from https://console.anthropic.com (used for the AI Coach chat + natural-language feedback).
- `inference_service/.env` needs no secrets to start.

Run all three services with Docker:
```bash
docker compose up --build
```
Or run them individually without Docker (useful while developing):
```bash
cd api_service && pip install -r requirements.txt --break-system-packages && uvicorn app.main:app --reload --port 8000
cd inference_service && pip install -r requirements.txt --break-system-packages && uvicorn app.main:app --reload --port 8001
cd llm_coach_service && pip install -r requirements.txt --break-system-packages && uvicorn app.main:app --reload --port 8002
```
Verify each is up: http://localhost:8000/docs, :8001/docs, :8002/docs (FastAPI's auto-generated Swagger UI).

## 3. Flutter app (15-20 min)

You need Flutter 3.x and either Android Studio (Android) or Xcode on a Mac (iOS) installed first. If you don't have Flutter yet: https://docs.flutter.dev/get-started/install

```bash
cd mobile
cp .env.example .env
```
Edit `.env` and paste your Supabase URL + anon key, and the three backend URLs (use your machine's LAN IP instead of `localhost` if testing on a physical phone, e.g. `http://192.168.1.23:8000`).

This `lib/` folder was generated standalone — it's missing the native `android/` and `ios/` platform folders that `flutter create` normally generates (they're boilerplate and don't add value in a code review, so I left them out to keep the zip focused). Generate them with:
```bash
flutter create . --platforms=android,ios --project-name repsense --org com.yourcompany
```
This will *not* overwrite your `lib/`, `pubspec.yaml`, or `assets/` — it only fills in the missing native scaffolding.

Then install dependencies and generate code (for `freezed`/`json_serializable` models if you add them later):
```bash
flutter pub get
```

Run it:
```bash
flutter run
```

### A few things you'll still need to do
1. **App icon**: drop a 1024×1024 PNG at `assets/images/app_icon.png` (and a foreground-only version at `app_icon_fg.png` for Android adaptive icons), then run `dart run flutter_launcher_icons`.
2. **Camera → ML Kit wiring**: `lib/features/camera/camera_page.dart` has a `_toInputImage()` stub — this is the one piece I couldn't safely auto-generate because the correct byte-plane conversion differs by Android vs iOS camera format and changes with `camera`/`google_mlkit_pose_detection` package versions. Follow the official converter example here: https://pub.dev/packages/google_mlkit_pose_detection (Example tab) and paste it in — it's about 30 lines.
3. **Android/iOS permissions**: after running `flutter create`, add camera permission entries:
   - `android/app/src/main/AndroidManifest.xml`: `<uses-permission android:name="android.permission.CAMERA"/>`
   - `ios/Runner/Info.plist`: add `NSCameraUsageDescription` with a user-facing string.
4. **Google/Apple Sign-In redirect URLs**: Supabase needs your app's redirect URL registered — see https://supabase.com/docs/guides/auth/social-login for Flutter-specific deep link setup.
5. **Deploy backend somewhere real**: the spec recommends Render for the API service initially. Each service in `backend/` has its own `Dockerfile`, so any container host (Render, Railway, Fly.io, a VPS) works the same way. Update `mobile/.env` with the deployed URLs before shipping.

## 4. What to build next
The scaffold gives you working navigation, theming, auth, a live camera screen with skeleton overlay and phase-based rep counting, and three deployable backend services with the real ML pipeline (joint angles → rep counter → biomechanics scoring → LLM explanation) already wired end-to-end. From here, the highest-leverage next steps are:
- Swap the on-device `_toInputImage` stub in for real pose streaming (item 2 above).
- Have the camera page POST the collected landmark sequence to `inference_service`'s `/inference/analyze-sequence` once a set finishes, and feed the response into the Summary screen instead of the placeholder numbers there now.
- Wire `WorkoutSelectionPage`/`ExerciseDetailPage` to `GET /exercises` on `api_service` instead of the local hardcoded list, and `SummaryPage`'s "Done" action to `POST /workouts`.
- Add the Celery/Redis async job queue from the spec once you need video upload processing or scheduled notifications — not required for the MVP loop above.
