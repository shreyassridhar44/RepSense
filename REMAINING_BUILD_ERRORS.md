# Remaining Build Errors to Fix

## Summary
The mobile app has extensive compilation errors preventing APK build. The main categories are:

## 1. Missing Widget Imports
Many files are missing imports for custom widgets:
- `GlassCard` - Used in achievements, profile, feedback pages
- `GradientButton` - Used in error screens, feedback page
- `authProvider` - Referenced in delete_account_page, feedback_page

**Files affected:**
- `lib/features/profile/account/delete_account_page.dart`
- `lib/features/profile/support/feedback_page.dart`
- `lib/core/error/friendly_error_screen.dart`
- `lib/features/achievements/widgets/*.dart`

**Fix:** Add imports:
```dart
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../auth/auth_provider.dart';
```

## 2. Progress Bloc Constructor Issue
`lib/features/progress/progress_page.dart` is trying to pass `authBloc` parameter which doesn't exist.

**Fix:** Remove the authBloc parameter from ProgressBloc instantiation (line 24)

## 3. Camera Permission Service
`permission_denied_view.dart` references `CameraPermissionService.openAppSettings()` which doesn't exist.

**Fix:** Use `openAppSettings()` from `permission_handler` package directly

## 4. Profile Repository Future.wait Type Issue  
Line 164 in `profile_repository.dart` has type mismatch.

**Fix:** Remove `<dynamic>` type parameter from Future.wait

## 5. All Theme Colors Added
✅ FIXED: Added surfaceDark, errorRed, platinum, richBlack, charcoal to AppColors and AppTheme

## 6. AppException Constructor
✅ FIXED: Changed all `AppException('message')` to `AppException(message: 'message')`

## Quick Fix Commands

Run these in order:

```bash
# 1. Find and add missing imports
grep -r "GlassCard" lib/features --include="*.dart" | cut -d: -f1 | sort -u
# Add: import '../../core/widgets/glass_card.dart';

# 2. Find and add GradientButton imports  
grep -r "GradientButton" lib --include="*.dart" | cut -d: -f1 | sort -u
# Add: import '../../core/widgets/gradient_button.dart';

# 3. Find and add authProvider imports
grep -r "authProvider" lib/features --include="*.dart" | cut -d: -f1 | sort -u  
# Add: import '../auth/auth_provider.dart';
```

## Alternative: Comment Out Broken Features

If imports are too complex, temporarily comment out these screens:
- Delete Account Page
- Feedback Page  
- Some Achievement Tabs

This will allow APK to build with core features working.
