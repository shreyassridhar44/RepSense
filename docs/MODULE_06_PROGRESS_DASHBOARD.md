# Module 06: Progress Dashboard & Analytics

## Overview
The Progress Dashboard provides comprehensive workout analytics, trend visualization, and AI-powered insights to help users track their fitness journey.

## Architecture

### Data Flow
```
ProgressPage (UI)
    ↓
ProgressBloc (State Management)
    ↓
ProgressService (Business Logic)
    ↓
ProgressRepository (Data Access)
    ↓
SupabaseService (Database)
```

### Key Components

#### 1. Data Models (`lib/data/models/progress_models.dart`)
- **ProgressSnapshot**: Top-level summary of all workout data
  - Total workouts, reps, calories, duration
  - Average form score across all exercises
  - Current and longest streak tracking
  - Consistency percentages (weekly/monthly)
  - Rep counts and scores by muscle group

- **Trend Models**: Time-series data for charts
  - `FormScoreTrend`: Form score over time
  - `CalorieTrend`: Calorie burn over time
  - `RepVolumeTrend`: Rep volume over time

- **PersonalRecord**: Best form scores per exercise
- **ConsistencyDay**: Workout activity for heatmap
- **MuscleBalancePoint**: Normalized muscle group data
- **AiProgressPrediction**: AI-generated insights
- **WorkoutWithExercise**: Joined workout + exercise data

#### 2. Repository (`lib/data/repositories/progress_repository.dart`)
**Purpose**: Data access layer with caching

**Key Methods**:
- `getAllWorkoutsWithExercise(userId)`: Fetch all workouts with exercise details
- `getRepAnalysesForWorkouts(workoutIds)`: Get detailed rep-level data
- `getProfile(userId)`: Fetch user profile
- `clearCache()`: Clear cached data
- `refreshWorkouts(userId)`: Force refresh

**Features**:
- 5-minute cache duration
- Automatic cache invalidation
- Error handling with AppException

#### 3. Service (`lib/features/progress/services/progress_service.dart`)
**Purpose**: Business logic for computing analytics

**Key Methods**:
- `computeSnapshot(userId)`: Calculate complete progress summary
  - Aggregates all workout data
  - Computes streaks (current and longest)
  - Calculates consistency percentages
  - Groups data by muscle group

- `getFormScoreTrend(userId, period)`: Form score over time
- `getCalorieTrend(userId, period)`: Calorie burn over time
- `getRepVolumeTrend(userId, period)`: Rep volume over time
- `getPersonalRecords(userId)`: Best form scores per exercise
- `getConsistencyHeatmap(userId)`: 90-day activity heatmap
- `getMuscleBalance(userId)`: Normalized muscle group balance
- `getAiPrediction(userId)`: Generate AI insights

**Algorithms**:
- **Streak Computation**: 
  - Current: Counts consecutive days from today backwards
  - Longest: Finds maximum consecutive sequence
- **Consistency**: Active days / total days * 100
- **Muscle Balance**: Normalizes rep counts to 0-100 scale

#### 4. BLoC (`lib/features/progress/bloc/`)
**Purpose**: State management

**Events**:
- `LoadProgress`: Initial data load
- `RefreshProgress`: Force refresh (clears cache)
- `ChangeTrendPeriod`: Filter trends by period
- `RequestAiPrediction`: Generate AI insights

**States**:
- `ProgressInitial`: Before data loads
- `ProgressLoading`: Fetching data
- `ProgressLoaded`: Data successfully loaded
- `ProgressError`: Error occurred

**Features**:
- Parallel data loading with `Future.wait`
- Automatic user authentication check
- Graceful error handling

#### 5. UI Widgets

**`progress_page.dart`**: Main page
- Pull-to-refresh
- Period selector (7D, 30D, 3M, 1Y)
- Organized sections with clear hierarchy

**`progress_stats_card.dart`**: Stat display
- Icon, label, value, subtitle
- Color-coded icons

**`form_score_chart.dart`**: Line chart
- Uses fl_chart package
- Gradient fill below line
- Interactive tooltips
- Dynamic date formatting based on period

**`consistency_heatmap.dart`**: GitHub-style heatmap
- 90-day view
- Color intensity based on workout count (0-3+)
- Month labels
- Interactive tooltips
- Horizontal scroll

**`muscle_balance_radar.dart`**: Radar chart
- Custom canvas painter
- Shows balance across muscle groups
- Normalized to 0-100 scale
- Grid circles and axes

**`personal_records_list.dart`**: PR list
- Top 5 personal records
- Medal icons (gold, silver, bronze)
- Date and rep count
- Color-coded scores

**`ai_prediction_card.dart`**: AI insights
- Insight + recommendation
- Confidence score
- Color-coded sections

## Features

### 1. Progress Snapshot
- **Total Stats**: Workouts, reps, calories, duration
- **Performance**: Average form score
- **Consistency**: Current streak, longest streak
- **Muscle Analysis**: Reps and scores by muscle group

### 2. Trend Visualization
- **Form Score Trend**: Track improvement over time
- **Calorie Burn**: Monitor energy expenditure
- **Rep Volume**: Track training volume
- **Period Filters**: 7 days, 30 days, 3 months, 1 year

### 3. Personal Records
- Best form scores for each exercise
- Date achieved
- Rep count at time of PR
- Top 5 displayed with medal icons

### 4. Consistency Tracking
- **Heatmap**: 90-day GitHub-style visualization
- **Intensity Levels**: 0 (none), 1 (1 workout), 2 (2 workouts), 3+ (3+ workouts)
- **Streaks**: Current and longest streak calculation
- **Percentages**: Weekly and monthly consistency

### 5. Muscle Balance
- **Radar Chart**: Visual balance across muscle groups
- **Normalization**: Scales to 0-100 for fair comparison
- **Coverage**: All major muscle groups tracked

### 6. AI Predictions
- Rule-based insights (can be enhanced with actual AI)
- Personalized recommendations
- Confidence scoring
- Based on consistency and performance patterns

## Database Queries

### Main Query (Repository)
```sql
-- Get all workouts with exercise details
SELECT workouts.*, exercises.*
FROM workouts
INNER JOIN exercises ON workouts.exercise_id = exercises.id
WHERE workouts.user_id = $userId
ORDER BY workouts.created_at DESC;
```

### Supporting Query
```sql
-- Get rep-level analyses
SELECT *
FROM rep_analyses
WHERE workout_id IN ($workoutIds)
ORDER BY workout_id, rep_index;
```

## Performance Optimizations

### Caching Strategy
- Repository-level cache (5-minute TTL)
- Keyed by userId
- Cleared on new workout save
- Manual refresh available

### Parallel Loading
- All data fetched in parallel using `Future.wait`
- Reduces initial load time
- Better user experience

### Efficient Computations
- Date grouping with `collection.groupBy`
- Single-pass streak calculations
- Memoized muscle group aggregations

## State Management

### BLoC Pattern
- Clear separation of concerns
- Testable business logic
- Predictable state transitions
- Easy to debug

### State Updates
- `LoadProgress`: Full data refresh
- `RefreshProgress`: Cache invalidation + reload
- `ChangeTrendPeriod`: Partial update (trends only)
- `RequestAiPrediction`: Incremental update (prediction only)

## UI/UX Features

### Visual Design
- Glassmorphic cards
- Color-coded scores (green > blue > yellow > red)
- Consistent spacing and typography
- Dark theme optimized

### Interactions
- Pull-to-refresh
- Period selector buttons
- Scrollable heatmap
- Interactive chart tooltips
- Loading states
- Error handling with retry

### Accessibility
- Semantic labels
- Color contrast
- Touch targets (48x48 minimum)
- Screen reader support

## Integration Points

### 1. Home Dashboard
- Show snapshot summary
- Quick link to full progress page
- Recent trend preview

### 2. Workout Completion
- Call `repository.clearCache()` after saving workout
- Trigger progress refresh
- Show achievement unlocks

### 3. Profile Page
- Link to progress dashboard
- Share progress feature
- Export data functionality

## Future Enhancements

### Planned Features
1. **Advanced AI**: Integrate with LLM coach service
2. **Export Data**: CSV/PDF reports
3. **Social Sharing**: Share achievements
4. **Goals System**: Set and track progress goals
5. **Predictions**: ML-based performance predictions
6. **Comparisons**: Compare with past weeks/months
7. **Insights**: More detailed breakdowns
8. **Achievements**: Gamification badges

### Technical Improvements
1. **Pagination**: For large workout histories
2. **Incremental Loading**: Load data in chunks
3. **Background Sync**: Pre-fetch data
4. **Offline Support**: Local caching with Hive
5. **Real-time Updates**: WebSocket for live data

## Testing Strategy

### Unit Tests
- Service computations (streaks, consistency, etc.)
- Repository caching logic
- Model serialization

### Widget Tests
- Progress page rendering
- Chart display
- Error states
- Loading states

### Integration Tests
- End-to-end flow
- Data fetching
- State transitions

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.6       # State management
  bloc: ^8.1.4               # BLoC core
  equatable: ^2.0.5          # Value equality
  collection: ^1.18.0        # groupBy helper
  fl_chart: ^0.68.0          # Charts
  intl: ^0.19.0              # Date formatting
```

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── progress_models.dart          # All data models
│   └── repositories/
│       └── progress_repository.dart      # Data access
├── features/
│   └── progress/
│       ├── bloc/
│       │   ├── progress_bloc.dart        # BLoC
│       │   ├── progress_event.dart       # Events
│       │   └── progress_state.dart       # States
│       ├── services/
│       │   └── progress_service.dart     # Business logic
│       ├── widgets/
│       │   ├── ai_prediction_card.dart
│       │   ├── consistency_heatmap.dart
│       │   ├── form_score_chart.dart
│       │   ├── muscle_balance_radar.dart
│       │   ├── personal_records_list.dart
│       │   └── progress_stats_card.dart
│       └── progress_page.dart            # Main page
```

## Usage Example

```dart
// In main navigation
BlocProvider(
  create: (context) => ProgressBloc(
    authBloc: context.read<AuthBloc>(),
  )..add(const LoadProgress()),
  child: const ProgressPage(),
)

// Refresh after workout
context.read<ProgressRepository>().clearCache();
context.read<ProgressBloc>().add(const RefreshProgress());

// Change period
context.read<ProgressBloc>().add(
  const ChangeTrendPeriod(TrendPeriod.week),
);
```

## Troubleshooting

### Issue: Data not updating
- **Solution**: Call `repository.clearCache()` after saving workouts

### Issue: Chart not rendering
- **Solution**: Ensure trend data is not empty, check date ranges

### Issue: Heatmap scroll issues
- **Solution**: Wrap in SingleChildScrollView with horizontal scroll

### Issue: Slow loading
- **Solution**: Enable caching, use parallel loading with Future.wait

## Conclusion

Module 06 provides a comprehensive, performant, and visually appealing progress tracking system. The architecture is scalable, testable, and ready for future enhancements including advanced AI integration and social features.
