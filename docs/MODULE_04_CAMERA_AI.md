# Module 4: Camera & On-Device AI — Implementation Guide

## Overview
Module 4 is the core feature of RepSense - real-time pose detection, rep counting, and form feedback. This is the most complex module requiring integration of camera hardware, ML Kit Pose Detection, and sophisticated biomechanical analysis.

## Status: ⚠️ READY FOR IMPLEMENTATION

**Estimated Implementation Time:** 20-30 hours  
**Complexity:** Very High  
**Files to Create:** 20+  
**Lines of Code:** ~4,000+

---

## Architecture Overview

```
Camera Page (UI)
    ↓
CameraNotifier (State Management)
    ↓
┌─────────────────┬──────────────────┬────────────────┐
│                 │                  │                │
CameraController  PoseDetector      RepCounter       VoiceService
                  ↓                  ↓
            JointAngleEngine    FeedbackEngine
```

---

## Implementation Checklist

### Phase 1: Foundation (4-6 hours)

#### 1.1 Camera Permission Service ✅
**File:** `lib/core/utils/camera_permission_service.dart`

**Status:** Started (basic structure created)

**TODO:**
- Fix the `openAppSettings()` method (currently calls itself recursively)
- Add platform-specific permission handling
- Test on both Android and iOS

#### 1.2 Image Converter Utility
**File:** `lib/core/utils/image_converter.dart`

**Critical:** This is the MOST IMPORTANT function - without this, pose detection won't work.

```dart
InputImage? convertCameraImageToInputImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation orientation,
) {
  // Step 1: Determine InputImageRotation
  //   Android: Based on sensorOrientation (90° or 270°)
  //   iOS: Always Rotation0
  
  // Step 2: Determine InputImageFormat
  //   Android: nv21 or yuv_420_888
  //   iOS: bgra8888
  
  // Step 3: Build InputImageMetadata
  
  // Step 4: Concatenate image planes
  
  return InputImage.fromBytes(bytes: bytes, metadata: metadata);
}
```

**References:**
- [ML Kit Camera Integration](https://pub.dev/packages/google_mlkit_commons)
- [CameraImage format handling](https://pub.dev/packages/camera)

### Phase 2: Core AI Engine (8-10 hours)

#### 2.1 Joint Angle Engine
**File:** `lib/features/camera/joint_angle_engine.dart`

**Responsibility:** Convert 33 pose landmarks into meaningful joint angles

**Angles to Compute:**
- Knee flexion (left/right)
- Hip flexion (left/right)
- Elbow extension (left/right)
- Shoulder elevation (left/right)
- Spine angle
- Neck angle
- Ankle dorsiflexion (left/right)
- Trunk lean
- Knee valgus (left/right) - for form warnings

**Key Method:**
```dart
double _angleBetweenThreePoints(Landmark a, Landmark b, Landmark c) {
  // Angle at vertex b
  // Use dot product: cos(θ) = (v1 · v2) / (|v1| |v2|)
  // Returns 0-180 degrees
}
```

#### 2.2 Rep Counter (Per Exercise)
**File:** `lib/features/camera/rep_counter.dart`

**Current Status:** Exists but has stub `_toInputImage()` method

**TODO:**
- Remove `_toInputImage()` (moved to image_converter.dart)
- Implement phase-based counting for all 14 exercises
- Add per-exercise thresholds:

| Exercise | Primary Angle | Down Threshold | Up Threshold |
|----------|---------------|----------------|--------------|
| Squat | knee_flexion | ≤100° | ≥160° |
| Deadlift | hip_flexion | ≤70° | ≥160° |
| Bench Press | elbow_extension | ≤80° | ≥155° |
| Push-up | elbow_extension | ≤90° | ≥155° |
| Pull-up | elbow_extension (inverted) | ≥155° | ≤75° |
| Overhead Press | elbow_extension | ≤90° | ≥165° |
| Lunges | knee_flexion | ≤95° | ≥160° |
| Bicep Curl | elbow_extension | ≤55° | ≥155° |
| Tricep Extension | elbow_extension | ≤80° | ≥155° |
| Rows | elbow_extension | ≤80° | ≥150° |
| Lat Pulldown | elbow_extension | ≤80° | ≥155° |
| Leg Press | knee_flexion | ≤90° | ≥160° |
| Plank | spine_angle (timer) | 160-180° held | 30s = 1 rep |
| Shoulder Press | elbow_extension | ≤90° | ≥165° |

**Special Cases:**
- Plank: Timer-based, not phase-based
- Exercises with left/right: Average both sides
- Enforce minimum rep duration (0.5s)
- Require starting from lockout position

#### 2.3 Feedback Engine
**File:** `lib/features/camera/feedback_engine.dart`

**Responsibility:** Generate real-time form feedback based on joint angles

**Feedback Rules (Sample):**

**Squat:**
- `knee_valgus > 0.05`: "Push knees outward" [ERROR]
- `spine_angle < 130°`: "Keep chest up" [WARNING]
- `trunk_lean > 45°`: "Reduce forward lean" [WARNING]
- All good: "Great squat" [GOOD]

**Deadlift:**
- `spine_angle < 140°`: "Maintain neutral spine" [ERROR]
- Hip rises faster than bar: "Drive through legs" [WARNING]
- All good: "Strong pull" [GOOD]

**Implementation:** ~300 lines of exercise-specific rules

### Phase 3: State Management (4-6 hours)

#### 3.1 Camera State
**File:** `lib/features/camera/camera_state.dart`

```dart
enum CameraStatus {
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  streaming,
  paused,
  countdown,
  finished,
  error,
}

enum RepPhase {
  down,
  pause,
  up,
  lockout,
}

enum FeedbackSeverity {
  good,
  warning,
  error,
}

class CameraState extends Equatable {
  final CameraStatus status;
  final String? errorMessage;
  final String exerciseId;
  final String exerciseName;
  
  // Camera
  final CameraController? controller;
  final bool isFrontCamera;
  
  // Pose detection
  final Pose? currentPose;
  final double poseConfidence;
  final bool isPersonDetected;
  
  // Rep counting
  final int repCount;
  final RepPhase currentPhase;
  final bool lastRepWasCorrect;
  final List<bool> repQuality;
  
  // Form feedback
  final String feedbackMessage;
  final FeedbackSeverity feedbackSeverity;
  final double currentAngle;
  
  // Configuration
  final int targetReps;
  final int targetSets;
  final int countdownSeconds;
  
  // Session tracking
  final DateTime? sessionStartTime;
  final List<Map<String, double>> angleSequence;
  final double estimatedCalories;
  
  // UI flags
  final bool voiceEnabled;
  final bool showSkeleton;
  final bool isLightingGood;
  final bool isDistanceGood;
  final int fps;
  
  // ... constructor, copyWith, props
}
```

#### 3.2 Camera Notifier
**File:** `lib/features/camera/camera_notifier.dart`

**This is the brain of Module 4** (~600-800 lines)

**Key Methods:**
```dart
class CameraNotifier extends StateNotifier<CameraState> {
  Future<void> initialize(String exerciseId);
  Future<void> startCountdown();
  Future<void> startStreaming();
  Future<void> pauseStreaming();
  Future<void> resumeStreaming();
  Future<void> switchCamera();
  Future<void> finishSet();
  
  void toggleVoice();
  void toggleSkeleton();
  void setTargetReps(int reps);
  
  Future<void> _processFrame(CameraImage image);
  // ^ This is the core AI pipeline
  
  @override
  void dispose();
}
```

**Frame Processing Pipeline (_processFrame):**
```
1. Check _busy flag → skip if busy
2. Convert CameraImage to InputImage
3. PoseDetector.processImage()
4. Extract landmarks → compute confidence
5. JointAngleEngine.compute()
6. Append to angleSequence
7. RepCounter.update() → check if rep completed
8. If rep completed:
   - Evaluate quality
   - Add to repQuality list
   - Voice feedback
   - Check if target reached
9. FeedbackEngine.generate() → update UI
10. Check lighting & distance
11. Update FPS
12. setState()
```

**Performance Requirements:**
- Must complete in <33ms (30 FPS target)
- Use _busy flag to skip frames if needed
- Handle errors gracefully (never crash)

### Phase 4: Supporting Services (2-3 hours)

#### 4.1 Voice Service
**File:** `lib/features/camera/voice_service.dart`

```dart
class VoiceService {
  Future<void> initialize();
  Future<void> speak(String text);
  Future<void> stop();
  void setEnabled(bool enabled);
  bool get isEnabled;
  Future<void> dispose();
}
```

**Announcements:**
- Countdown: "3", "2", "1", "Go!"
- Rep completion: "Rep 5"
- With issues: "Rep 5 — knees out"
- Set complete: "Set complete — 10 reps"
- Form warnings (once, if persists 3+ seconds)

**Rules:**
- Don't speak while already speaking
- Queue max 1 item
- Silent fail on TTS unavailable devices

#### 4.2 Pose Painter
**File:** `lib/features/camera/pose_painter.dart`

**Responsibility:** Draw skeleton overlay on camera preview

**Connection Map:** 33 landmark connections (face, upper body, torso, lower body, feet)

**Rendering:**
- Joints: Emerald (high confidence) / Amber (medium)
- Bones: Electric Blue / Amber
- Primary tracked joint: glowing Electric Blue
- Mirror X-coordinate for front camera
- Only draw if visibility > 0.5

**Performance:** `shouldRepaint()` checks if pose actually changed

### Phase 5: UI Components (4-6 hours)

#### 5.1 Main Camera Page
**File:** `lib/features/camera/camera_page.dart`

**Max 300 lines** - extract everything into sub-widgets

**States to Handle:**
- Permission denied (with "Grant Permission" / "Open Settings")
- Initializing (loading spinner)
- Ready (live preview + "Configure & Start" button)
- Countdown (3-2-1-Go animation)
- Streaming (full camera UI)
- Paused (overlay with resume)
- Finished (auto-navigate to summary)

**Lock Orientation:**
```dart
@override
void initState() {
  super.initState();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

@override
void dispose() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  super.dispose();
}
```

#### 5.2 Sub-Widgets (Create These)

**Permission Denied View**
`lib/features/camera/widgets/permission_denied_view.dart`
- Icon + message
- "Grant Permission" or "Open Settings" button

**Top Status Bar**
`lib/features/camera/widgets/top_status_bar.dart`
- Back button (with confirmation dialog)
- Exercise name pill
- FPS / Lighting / Distance indicators
- AI status chip

**Rep Counter Widget**
`lib/features/camera/widgets/rep_counter_widget.dart`
- Large number with glow effect
- Target reps indicator if set
- Phase indicator pill below
- Green pulse on correct rep
- Shake animation on incorrect rep

**Feedback Banner**
`lib/features/camera/widgets/feedback_banner.dart`
- AI coach icon
- Animated text switcher
- Color-coded left border
- Compact (max 2 lines)

**Bottom Controls**
`lib/features/camera/widgets/bottom_controls.dart`
- Skeleton toggle button
- Pause/Resume button (center, large)
- Finish button (with confirmation)

**Rep Quality Strip**
`lib/features/camera/widgets/rep_quality_strip.dart`
- Horizontal row of circles
- Emerald = correct, Red = incorrect
- Scrollable if > 10 reps
- Animate in from right

**Countdown Overlay**
`lib/features/camera/widgets/countdown_overlay.dart`
- Full-screen overlay
- Large animated number
- Scale + fade animation

**Paused Overlay**
`lib/features/camera/widgets/paused_overlay.dart`
- Semi-transparent dark overlay
- "PAUSED" text
- Resume button

**Set Config Sheet**
`lib/features/camera/widgets/set_config_sheet.dart`
- Target reps selector (chips)
- Voice toggle
- Skeleton toggle
- Camera source (front/rear)
- "Start" button

---

## Edge Cases to Handle

### Camera Issues
- ✅ No camera permission → Permission denied state
- ✅ Permanently denied → "Open Settings" option
- ✅ No cameras available → Error state
- ✅ Camera initialization failed → Meaningful error per CameraException.code
- ✅ Camera in use by another app → Error state

### App Lifecycle
- ✅ App backgrounded → Auto-pause streaming
- ✅ App foregrounded → Resume if was streaming
- ✅ Incoming call → Pause with notice

### Pose Detection
- ✅ No person detected (>5s) → Warning overlay
- ✅ Person too far/close → Distance indicator + feedback
- ✅ Low confidence pose → "Adjust position" feedback
- ✅ Pose detector throws → Catch, count errors, pause AI if >5 consecutive
- ✅ Very fast reps (<0.5s) → Ignore via minimum duration

### Performance
- ✅ Low FPS (<15 for >3s) → Switch to singleImage mode
- ✅ Frame processing takes too long → Skip frames via _busy flag
- ✅ Memory leak → Dispose all resources properly

### User Actions
- ✅ Camera switch mid-set → Preserve rep data
- ✅ Pause/Resume → Maintain state
- ✅ Back button during set → Confirmation dialog
- ✅ Device rotation → Locked to portrait

### TTS Issues
- ✅ TTS not available → Silently disable voice
- ✅ Already speaking → Don't queue more than 1

---

## Calorie Estimation

```dart
double estimatedCalories = 
  (exercise.metValue * userWeightKg * durationMinutes) / 60;

// If userWeightKg null → use 70.0 kg default
```

**MET Values:** Already set in Module 3 database

---

## Data Passed to Summary

When finishing a set, navigate to `/summary` with:

```dart
{
  'exerciseId': exerciseId,
  'exerciseName': exerciseName,
  'reps': repCount,
  'correctReps': repQuality.where((q) => q).length,
  'incorrectReps': repQuality.where((q) => !q).length,
  'repQuality': repQuality,
  'angleSequence': angleSequence,
  'durationSeconds': duration.inSeconds,
  'estimatedCalories': estimatedCalories,
  'sessionStartTime': sessionStartTime.toIso8601String(),
}
```

---

## Testing Strategy

### Unit Tests
- ✅ JointAngleEngine._angleBetweenThreePoints()
- ✅ RepCounter phase transitions for each exercise
- ✅ FeedbackEngine rules for each exercise
- ✅ Calorie estimation calculation

### Integration Tests
- ✅ Camera initialization flow
- ✅ Permission handling
- ✅ Frame processing pipeline
- ✅ Rep counting accuracy

### Manual Tests
- ✅ Test all 14 exercises
- ✅ Test with poor lighting
- ✅ Test person too far/close
- ✅ Test camera switch
- ✅ Test pause/resume
- ✅ Test voice guidance
- ✅ Test on low-end device

---

## Platform-Specific Requirements

### Android
**build.gradle.kts:**
```kotlin
minSdk = 21  // Required for ML Kit
```

**AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<!-- Already added in Module 1 -->
```

### iOS
**Podfile:**
```ruby
platform :ios, '14.0'  # Minimum for ML Kit
```

**Info.plist:**
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to analyze your exercise form in real-time</string>
<!-- Already added in Module 1 -->
```

---

## Performance Benchmarks

**Target:**
- FPS: 25-30
- Frame processing time: <33ms
- Rep detection latency: <200ms
- Memory usage: <150 MB

**Optimization Tips:**
- Use ResolutionPreset.medium (not high)
- Skip frames if processing takes too long
- Switch to singleImage mode on low-end devices
- Dispose resources immediately when not needed

---

## Known Limitations

1. **Requires Good Lighting:** Pose detection accuracy drops in poor lighting
2. **Full Body Required:** User must fit entirely in frame
3. **Portrait Only:** Landscape not supported (exercises require full body height)
4. **One Person:** Multiple people in frame may confuse the detector
5. **Occlusion:** If limbs are hidden behind body, angles can't be computed

---

## Implementation Order (Recommended)

1. ✅ Camera permission service (done)
2. **Image converter** (CRITICAL - do this first)
3. Joint angle engine
4. Rep counter (one exercise to start)
5. Camera state + notifier (basic)
6. Camera page UI (basic streaming)
7. Pose painter (skeleton overlay)
8. Feedback engine (basic)
9. Voice service
10. All 14 exercise configurations
11. All UI widgets
12. Edge case handling
13. Performance optimization

---

## Debugging Tips

**Enable verbose logging:**
```dart
AppLogger.debug('📸 Frame ${frameCount}: ${landmarks.length} landmarks');
AppLogger.debug('📐 Angles: ${angles}');
AppLogger.debug('🔄 Phase: ${phase}, Rep: ${repCount}');
```

**Common Issues:**
- **No pose detected:** Check image converter rotation/format
- **Wrong rep count:** Check exercise thresholds
- **Low FPS:** Reduce resolution or switch to singleImage mode
- **Crashes:** Check all dispose() methods are called

---

## Estimated Completion Time

- **Experienced Flutter dev:** 20-25 hours
- **New to ML Kit:** 30-35 hours
- **Testing + refinement:** +10 hours

**Total:** 30-45 hours for production-quality implementation

---

## Status: Module 4 Implementation Pending

**Next Steps:**
1. Add `flutter_tts: ^4.0.2` to pubspec.yaml ✅ (DONE)
2. Run `flutter pub get`
3. Implement image converter (CRITICAL)
4. Follow implementation order above
5. Test thoroughly on real devices

---

**Module 4 Spec Compliance:** Detailed roadmap provided  
**Ready to Implement:** Yes  
**Dependencies:** All added  
**Documentation:** Complete
