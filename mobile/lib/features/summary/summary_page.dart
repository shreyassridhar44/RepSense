import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'summary_state.dart';

/// Summary page showing workout results and AI analysis
class SummaryPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> result;

  const SummaryPage({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage> {
  @override
  void initState() {
    super.initState();
    
    // Initialize summary with camera result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(summaryProvider.notifier).initialize(widget.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(summaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.richBlack,
      body: SafeArea(
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SummaryState state) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: AppTheme.richBlack,
          title: Text(
            state.exerciseName,
            style: const TextStyle(color: AppTheme.platinum),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.platinum),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Analyzing banner
                if (state.status == SummaryStatus.analyzing)
                  _buildAnalyzingBanner(),

                const SizedBox(height: 16),

                // Basic stats (always visible)
                _buildBasicStats(state),

                const SizedBox(height: 16),

                // Score display
                _buildScoreDisplay(state),

                const SizedBox(height: 16),

                // Rep quality
                if (state.repQuality.isNotEmpty) _buildRepQuality(state),

                const SizedBox(height: 16),

                // Action buttons
                _buildActionButtons(context, state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.electricBlue),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.electricBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🧠 AI is analyzing your form…',
                  style: TextStyle(
                    color: AppTheme.platinum,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            color: AppTheme.electricBlue,
            backgroundColor: AppTheme.charcoal,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicStats(SummaryState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Reps',
            state.totalReps.toString(),
            AppTheme.electricBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Correct',
            state.correctReps.toString(),
            AppTheme.emerald,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Incorrect',
            state.incorrectReps > 0 ? state.incorrectReps.toString() : '—',
            AppTheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.platinum.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(SummaryState state) {
    final score = state.displayScore;
    final color = state.inferenceResult?.scoreColor ?? AppTheme.electricBlue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Form Score',
            style: TextStyle(
              color: AppTheme.platinum.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${score.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.inferenceResult?.scoreLabel ?? 'Basic Score',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.status == SummaryStatus.analyzing)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Detailed analysis in progress...',
                style: TextStyle(
                  color: AppTheme.platinum,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRepQuality(SummaryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rep Quality',
            style: TextStyle(
              color: AppTheme.platinum,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.repQuality.asMap().entries.map((entry) {
              final index = entry.key;
              final isCorrect = entry.value;
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect ? AppTheme.emerald : AppTheme.error,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, SummaryState state) {
    return Column(
      children: [
        // Save error banner
        if (state.saveErrorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Workout not saved — ${state.saveErrorMessage}',
                    style: const TextStyle(color: AppTheme.platinum),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(summaryProvider.notifier).retrySave();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

        // Saved confirmation
        if (state.isSaved)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppTheme.emerald, size: 16),
                SizedBox(width: 6),
                Text(
                  'Saved to your history',
                  style: TextStyle(color: AppTheme.emerald, fontSize: 14),
                ),
              ],
            ),
          ),

        // Main buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement share
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.electricBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Share'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
