import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class MistakesCard extends StatefulWidget {
  const MistakesCard({
    super.key,
    required this.mistakes,
  });

  final List<String> mistakes;

  @override
  State<MistakesCard> createState() => _MistakesCardState();
}

class _MistakesCardState extends State<MistakesCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.mistakes.isEmpty) return const SizedBox.shrink();

    final visibleMistakes = _isExpanded 
        ? widget.mistakes 
        : widget.mistakes.take(3).toList();
    final hasMore = widget.mistakes.length > 3;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Mistakes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          
          ...visibleMistakes.map((mistake) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppColors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mistake,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (hasMore)
            TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Show less' : 'Show more',
              ),
            ),
        ],
      ),
    );
  }
}
