import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.selectedMuscleGroup,
    required this.showFavoritesOnly,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.onMuscleGroupChanged,
    required this.onFavoritesToggled,
    required this.onClearFilters,
    required this.hasActiveFilters,
  });

  final String? selectedCategory;
  final String? selectedDifficulty;
  final String? selectedMuscleGroup;
  final bool showFavoritesOnly;
  final Function(String?) onCategoryChanged;
  final Function(String?) onDifficultyChanged;
  final Function(String?) onMuscleGroupChanged;
  final VoidCallback onFavoritesToggled;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (hasActiveFilters) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            const Spacer(),
            if (hasActiveFilters)
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear all'),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // All chip
              _FilterChip(
                label: 'All',
                isSelected: !hasActiveFilters,
                onTap: onClearFilters,
              ),
              
              const SizedBox(width: 8),
              
              // Category chips
              _FilterChip(
                label: 'Compound',
                isSelected: selectedCategory == 'Compound',
                onTap: () => onCategoryChanged(
                  selectedCategory == 'Compound' ? null : 'Compound',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Isolation',
                isSelected: selectedCategory == 'Isolation',
                onTap: () => onCategoryChanged(
                  selectedCategory == 'Isolation' ? null : 'Isolation',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Bodyweight',
                isSelected: selectedCategory == 'Bodyweight',
                onTap: () => onCategoryChanged(
                  selectedCategory == 'Bodyweight' ? null : 'Bodyweight',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Machine',
                isSelected: selectedCategory == 'Machine',
                onTap: () => onCategoryChanged(
                  selectedCategory == 'Machine' ? null : 'Machine',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Difficulty chips
              _FilterChip(
                label: 'Beginner',
                isSelected: selectedDifficulty == 'Beginner',
                onTap: () => onDifficultyChanged(
                  selectedDifficulty == 'Beginner' ? null : 'Beginner',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Intermediate',
                isSelected: selectedDifficulty == 'Intermediate',
                onTap: () => onDifficultyChanged(
                  selectedDifficulty == 'Intermediate' ? null : 'Intermediate',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Advanced',
                isSelected: selectedDifficulty == 'Advanced',
                onTap: () => onDifficultyChanged(
                  selectedDifficulty == 'Advanced' ? null : 'Advanced',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Muscle group chips
              _FilterChip(
                label: 'Chest',
                isSelected: selectedMuscleGroup == 'Chest',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Chest' ? null : 'Chest',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Back',
                isSelected: selectedMuscleGroup == 'Back',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Back' ? null : 'Back',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Legs',
                isSelected: selectedMuscleGroup == 'Legs',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Legs' ? null : 'Legs',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Shoulders',
                isSelected: selectedMuscleGroup == 'Shoulders',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Shoulders' ? null : 'Shoulders',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Arms',
                isSelected: selectedMuscleGroup == 'Arms',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Arms' ? null : 'Arms',
                ),
              ),
              
              const SizedBox(width: 8),
              
              _FilterChip(
                label: 'Core',
                isSelected: selectedMuscleGroup == 'Core',
                onTap: () => onMuscleGroupChanged(
                  selectedMuscleGroup == 'Core' ? null : 'Core',
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Favorites chip
              _FilterChip(
                label: '♥ Favorites',
                isSelected: showFavoritesOnly,
                onTap: onFavoritesToggled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
