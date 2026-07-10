import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';
import 'auth_provider.dart';

enum AuthStatus { idle, loading, error, success }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  const AuthState({this.status = AuthStatus.idle, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthState(status: status ?? this.status, errorMessage: errorMessage);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState());

  final Ref ref;
  final _service = SupabaseService.instance;

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Validate password length
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validate password confirmation
  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  /// Clear error state
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    AppLogger.info('👤 AuthController: Starting email sign in for: $email');
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await _service.signInWithEmail(email, password);
      state = state.copyWith(status: AuthStatus.success);
      AppLogger.info('✅ AuthController: Sign in successful');
      
      // Refresh profile completeness check
      ref.read(profileCompletenessProvider.notifier).refresh();
      
      return true;
    } on AuthException catch (e) {
      AppLogger.error('❌ AuthController: Sign in failed', e);
      String errorMessage = AppStrings.genericError;
      
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        errorMessage = 'Please confirm your email before signing in';
      }
      
      state = AuthState(status: AuthStatus.error, errorMessage: errorMessage);
      return false;
    } on SocketException catch (e) {
      AppLogger.error('❌ AuthController: Network error', e);
      state = AuthState(status: AuthStatus.error, errorMessage: AppStrings.noInternet);
      return false;
    } catch (e, stack) {
      AppLogger.error('❌ AuthController: Sign in failed', e, stack);
      state = AuthState(status: AuthStatus.error, errorMessage: AppStrings.genericError);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    AppLogger.info('👤 AuthController: Starting email sign up for: $email');
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await _service.signUpWithEmail(email, password);
      state = state.copyWith(status: AuthStatus.success);
      AppLogger.info('✅ AuthController: Sign up successful');
      
      // Refresh profile completeness check
      ref.read(profileCompletenessProvider.notifier).refresh();
      
      return true;
    } on AuthException catch (e) {
      AppLogger.error('❌ AuthController: Sign up failed', e);
      String errorMessage = AppStrings.genericError;
      
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        errorMessage = AppStrings.accountExists;
      }
      
      state = AuthState(status: AuthStatus.error, errorMessage: errorMessage);
      return false;
    } on SocketException catch (e) {
      AppLogger.error('❌ AuthController: Network error', e);
      state = AuthState(status: AuthStatus.error, errorMessage: AppStrings.noInternet);
      return false;
    } catch (e, stack) {
      AppLogger.error('❌ AuthController: Sign up failed', e, stack);
      state = AuthState(status: AuthStatus.error, errorMessage: AppStrings.genericError);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    AppLogger.info('👤 AuthController: Starting Google sign in');
    
    try {
      await _service.signInWithGoogle();
      AppLogger.info('✅ AuthController: Google sign in successful');
      
      // Refresh profile completeness check
      ref.read(profileCompletenessProvider.notifier).refresh();
      
      return true;
    } catch (e, stack) {
      AppLogger.error('❌ AuthController: Google sign in failed', e, stack);
      state = AuthState(status: AuthStatus.error, errorMessage: AppStrings.genericError);
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    AppLogger.info('👤 AuthController: Sending password reset for: $email');
    
    try {
      await _service.sendPasswordReset(email);
      AppLogger.info('✅ AuthController: Password reset sent');
    } catch (e, stack) {
      AppLogger.error('❌ AuthController: Password reset failed', e, stack);
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    AppLogger.info('👤 AuthController: User continuing as guest');
    await setGuestMode(true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
