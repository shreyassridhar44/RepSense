import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_controller.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sign Up controllers
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  
  // Sign In controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  
  // Form keys
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();
  
  // Password visibility
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;
  bool _signInPasswordVisible = false;
  
  // Validation states for inline validation
  String? _signUpEmailError;
  String? _signUpPasswordError;
  String? _signUpConfirmPasswordError;
  String? _signInEmailError;
  String? _signInPasswordError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listeners for inline validation
    _signUpEmailController.addListener(() {
      if (_signUpEmailError != null) {
        setState(() {
          _signUpEmailError = ref.read(authControllerProvider.notifier)
              .validateEmail(_signUpEmailController.text);
        });
      }
      // Clear error banner on typing
      ref.read(authControllerProvider.notifier).clearError();
    });
    
    _signUpPasswordController.addListener(() {
      if (_signUpPasswordError != null) {
        setState(() {
          _signUpPasswordError = ref.read(authControllerProvider.notifier)
              .validatePassword(_signUpPasswordController.text);
        });
      }
      // Also revalidate confirm password if it has content
      if (_signUpConfirmPasswordError != null && _signUpConfirmPasswordController.text.isNotEmpty) {
        setState(() {
          _signUpConfirmPasswordError = ref.read(authControllerProvider.notifier)
              .validateConfirmPassword(_signUpConfirmPasswordController.text, _signUpPasswordController.text);
        });
      }
      ref.read(authControllerProvider.notifier).clearError();
    });
    
    _signUpConfirmPasswordController.addListener(() {
      if (_signUpConfirmPasswordError != null) {
        setState(() {
          _signUpConfirmPasswordError = ref.read(authControllerProvider.notifier)
              .validateConfirmPassword(_signUpConfirmPasswordController.text, _signUpPasswordController.text);
        });
      }
      ref.read(authControllerProvider.notifier).clearError();
    });
    
    _signInEmailController.addListener(() {
      if (_signInEmailError != null) {
        setState(() {
          _signInEmailError = ref.read(authControllerProvider.notifier)
              .validateEmail(_signInEmailController.text);
        });
      }
      ref.read(authControllerProvider.notifier).clearError();
    });
    
    _signInPasswordController.addListener(() {
      if (_signInPasswordError != null) {
        setState(() {
          _signInPasswordError = ref.read(authControllerProvider.notifier)
              .validatePassword(_signInPasswordController.text);
        });
      }
      ref.read(authControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    setState(() {
      _signUpEmailError = ref.read(authControllerProvider.notifier)
          .validateEmail(_signUpEmailController.text);
      _signUpPasswordError = ref.read(authControllerProvider.notifier)
          .validatePassword(_signUpPasswordController.text);
      _signUpConfirmPasswordError = ref.read(authControllerProvider.notifier)
          .validateConfirmPassword(_signUpConfirmPasswordController.text, _signUpPasswordController.text);
    });
    
    if (_signUpEmailError != null || _signUpPasswordError != null || _signUpConfirmPasswordError != null) {
      return;
    }
    
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signUpWithEmail(
      _signUpEmailController.text.trim(),
      _signUpPasswordController.text,
    );
    
    if (success && mounted) {
      AppLogger.info('✅ Sign up successful, navigating to profile setup');
      context.go('/profile-setup');
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _signInEmailError = ref.read(authControllerProvider.notifier)
          .validateEmail(_signInEmailController.text);
      _signInPasswordError = ref.read(authControllerProvider.notifier)
          .validatePassword(_signInPasswordController.text);
    });
    
    if (_signInEmailError != null || _signInPasswordError != null) {
      return;
    }
    
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signInWithEmail(
      _signInEmailController.text.trim(),
      _signInPasswordController.text,
    );
    
    if (success && mounted) {
      // Router will handle redirect based on profile completeness
      AppLogger.info('✅ Sign in successful, router will handle redirect');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _signInEmailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final emailError = ref.read(authControllerProvider.notifier).validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.passwordResetSent),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signInWithGoogle();
    
    if (success && mounted) {
      AppLogger.info('✅ Google sign in successful, router will handle redirect');
    }
  }

  Future<void> _handleAppleSignIn() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signInWithApple();
    
    if (success && mounted) {
      AppLogger.info('✅ Apple sign in successful, router will handle redirect');
    }
  }

  Future<void> _handleGuestMode() async {
    await ref.read(authControllerProvider.notifier).continueAsGuest();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome to RepSense',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Every Rep. Perfected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.electricBlue,
                ),
              ),
              const SizedBox(height: 40),
              
              // Tab Bar
              GlassCard(
                padding: const EdgeInsets.all(4),
                borderRadius: 16,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: AppStrings.signIn),
                    Tab(text: AppStrings.signUp),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Error Banner
              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Tab Views
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Sign In Tab
                    _buildSignInForm(isLoading),
                    
                    // Sign Up Tab
                    _buildSignUpForm(isLoading),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Social Sign In Section
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.textSecondary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.orContinueWith,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.textSecondary)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google Sign In
              OutlinedButton.icon(
                onPressed: isLoading ? null : _handleGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                label: const Text(AppStrings.continueWithGoogle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Apple Sign In
              OutlinedButton.icon(
                onPressed: isLoading ? null : _handleAppleSignIn,
                icon: const Icon(Icons.apple_rounded, size: 22),
                label: const Text(AppStrings.continueWithApple),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Guest Mode
              TextButton(
                onPressed: isLoading ? null : _handleGuestMode,
                child: const Text(
                  AppStrings.continueAsGuest,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextField(
            controller: _signInEmailController,
            decoration: InputDecoration(
              hintText: AppStrings.email,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              errorText: _signInEmailError,
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Password
          TextField(
            controller: _signInPasswordController,
            decoration: InputDecoration(
              hintText: AppStrings.password,
              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _signInPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _signInPasswordVisible = !_signInPasswordVisible),
              ),
              errorText: _signInPasswordError,
            ),
            obscureText: !_signInPasswordVisible,
            enabled: !isLoading,
          ),
          
          const SizedBox(height: 8),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : _handleForgotPassword,
              child: const Text(
                AppStrings.forgotPassword,
                style: TextStyle(color: AppColors.electricBlue, fontSize: 13),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sign In Button
          GradientButton(
            label: isLoading ? AppStrings.signingIn : AppStrings.signIn,
            onPressed: isLoading ? () {} : _handleSignIn,
            icon: isLoading ? null : Icons.login_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(bool isLoading) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextField(
            controller: _signUpEmailController,
            decoration: InputDecoration(
              hintText: AppStrings.email,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              errorText: _signUpEmailError,
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Password
          TextField(
            controller: _signUpPasswordController,
            decoration: InputDecoration(
              hintText: AppStrings.password,
              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _signUpPasswordVisible = !_signUpPasswordVisible),
              ),
              errorText: _signUpPasswordError,
            ),
            obscureText: !_signUpPasswordVisible,
            enabled: !isLoading,
          ),
          
          const SizedBox(height: 16),
          
          // Confirm Password
          TextField(
            controller: _signUpConfirmPasswordController,
            decoration: InputDecoration(
              hintText: AppStrings.confirmPassword,
              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _signUpConfirmPasswordVisible = !_signUpConfirmPasswordVisible),
              ),
              errorText: _signUpConfirmPasswordError,
            ),
            obscureText: !_signUpConfirmPasswordVisible,
            enabled: !isLoading,
          ),
          
          const SizedBox(height: 24),
          
          // Sign Up Button
          GradientButton(
            label: isLoading ? AppStrings.signingUp : AppStrings.signUp,
            onPressed: isLoading ? () {} : _handleSignUp,
            icon: isLoading ? null : Icons.person_add_rounded,
          ),
        ],
      ),
    );
  }
}
