import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Guest user profile screen
class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.electricBlue.withOpacity(0.3),
                    AppTheme.violet.withOpacity(0.3),
                  ],
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 60,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'You\'re training as a guest',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            const SizedBox(height: 24),
            
            // Benefits
            const Text(
              'Create a free account to:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefit('Save your workout history'),
            _buildBenefit('Track your progress over time'),
            _buildBenefit('Earn achievements and level up'),
            _buildBenefit('Access your AI coach'),
            const SizedBox(height: 32),
            
            // Create Account button
            GradientButton(
              onPressed: () {
                context.go('/auth', extra: {'initialTab': 'signup'});
              },
              child: const Text('Create Account'),
            ),
            const SizedBox(height: 12),
            
            // Sign In button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.go('/auth', extra: {'initialTab': 'signin'});
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.electricBlue),
                  foregroundColor: AppTheme.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Disclaimer
            Text(
              'Your recent session data will be lost when you sign in. Create an account first to keep it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
                fontStyle: FontStyle.italic,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.emerald,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
