# Progress Dashboard Feature

## Quick Start

```dart
import 'package:repsense/features/progress/progress.dart';

// Use in navigation
BlocProvider(
  create: (context) => ProgressBloc(
    authBloc: context.read<AuthBloc>(),
  )..add(const LoadProgress()),
  child: const ProgressPage(),
)
```

## What's Included

### 📊 Core Analytics
- **Progress Snapshot**: Total workouts, reps, calories, time, avg form score
- **Streaks**: Current and longest workout streaks
- **Consistency**: Weekly and monthly percentages
- **Muscle Groups**: Reps and scores by muscle group

### 📈 Visualizations
- **Form Score Trend**: Line chart with gradient fill
- **Consistency Heatmap**: GitHub-style 90-day view
- **Muscle Balance Radar**: Custom canvas radar chart
- **Personal Records**: Top 5 best performances

### 🤖 AI Features
- AI-generated insights and recommendations
- Confidence scoring
- Rule-based predictions (ready for LLM integration)

### 🎨 UI Components
All widgets follow the app's glassmorphic design system:
- `ProgressStatsCard`: Individual stat display
- `FormScoreChart`: Interactive line chart
- `ConsistencyHeatmap`: Workout activity heatmap
- `MuscleBalanceRadar`: Muscle group balance
- `PersonalRecordsList`: Best performances
- `AiPredictionCard`: AI insights display

## Architecture

```
UI Layer (progress_page.dart)
    ↓
State Management (progress_bloc.dart)
    ↓
Business Logic (progress_service.dart)
    ↓
Data Access (progress_repository.dart)
    ↓
Database (supabase_service.dart)
```

## Features

### Period Filtering
Switch between time ranges:
- 7 Days (7D)
- 30 Days (30D)
- 3 Months (3M)
- 1 Year (1Y)

### Pull-to-Refresh
Swipe down to refresh all data and clear cache.

### Caching
5-minute cache for optimal performance. Clear after saving new workouts:
```dart
context.read<ProgressRepository>().clearCache();
```

### Error Handling
Graceful error states with retry functionality.

## Files Structure

```
progress/
├── bloc/
│   ├── progress_bloc.dart      # State management
│   ├── progress_event.dart     # Events
│   └── progress_state.dart     # States
├── services/
│   └── progress_service.dart   # Analytics computation
├── widgets/
│   ├── ai_prediction_card.dart
│   ├── consistency_heatmap.dart
│   ├── form_score_chart.dart
│   ├── muscle_balance_radar.dart
│   ├── personal_records_list.dart
│   └── progress_stats_card.dart
├── progress_page.dart          # Main UI
├── progress.dart               # Barrel export
└── README.md                   # This file
```

## Usage Examples

### Load Progress
```dart
context.read<ProgressBloc>().add(const LoadProgress());
```

### Refresh Data
```dart
context.read<ProgressBloc>().add(const RefreshProgress());
```

### Change Period
```dart
context.read<ProgressBloc>().add(
  const ChangeTrendPeriod(TrendPeriod.week),
);
```

### Request AI Prediction
```dart
context.read<ProgressBloc>().add(const RequestAiPrediction());
```

## Dependencies

Required packages (already in pubspec.yaml):
- `flutter_bloc: ^8.1.6` - State management
- `bloc: ^8.1.4` - BLoC core
- `equatable: ^2.0.5` - Value equality
- `collection: ^1.18.0` - Grouping utilities
- `fl_chart: ^0.68.0` - Charts
- `intl: ^0.19.0` - Date formatting

## Testing

### Run Tests
```bash
flutter test test/features/progress/
```

### Widget Tests
```dart
testWidgets('ProgressPage loads and displays data', (tester) async {
  // Test implementation
});
```

## Performance

- **Caching**: 5-minute repository cache
- **Parallel Loading**: All data loaded concurrently
- **Efficient Algorithms**: Single-pass streak calculations
- **Optimized Charts**: Interval-based rendering

## Future Enhancements

- [ ] Advanced AI with LLM integration
- [ ] Export to CSV/PDF
- [ ] Social sharing
- [ ] Goal tracking
- [ ] Achievements/badges
- [ ] Comparison views
- [ ] Offline support with Hive

## Notes

- Always clear cache after saving new workouts
- Ensure user is authenticated before loading
- Handle empty states gracefully
- Use pull-to-refresh for manual updates
