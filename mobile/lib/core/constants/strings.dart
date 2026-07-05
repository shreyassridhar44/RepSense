/// Centralized string constants for RepSense
class AppStrings {
  AppStrings._();

  // Auth
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot password?';
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithApple = 'Continue with Apple';
  static const String continueAsGuest = 'Continue as Guest';
  static const String orContinueWith = 'Or continue with';
  
  // Auth Validation
  static const String emailRequired = 'Email is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  
  // Auth Errors
  static const String accountExists = 'An account with this email already exists. Try signing in.';
  static const String sessionExpired = 'Your session expired, please sign in again';
  static const String noInternet = 'No internet connection. Check your network and try again.';
  static const String passwordResetSent = 'Password reset email sent! Check your inbox.';
  
  // Guest Mode
  static const String guestModeBanner = "You're in guest mode — sign up to save your data";
  static const String guestModeRestriction = 'Create a free account to save your progress';
  
  // Profile Setup
  static const String profileSetup = 'Profile Setup';
  static const String tellUsAboutYourself = 'Tell us about yourself';
  static const String yourMeasurements = 'Your measurements';
  static const String yourExperience = 'Your experience';
  static const String yourGoals = 'Your goals';
  static const String continueButton = 'Continue';
  static const String finishButton = 'Finish';
  static const String backButton = 'Back';
  
  // Profile Setup - Step 1
  static const String displayName = 'Display Name';
  static const String displayNameHint = 'What should we call you?';
  static const String dateOfBirth = 'Date of Birth';
  static const String biologicalSex = 'Biological Sex';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String preferNotToSay = 'Prefer not to say';
  static const String ageRestriction = 'You must be at least 13 years old';
  
  // Profile Setup - Step 2
  static const String height = 'Height';
  static const String weight = 'Weight';
  static const String heightCm = 'Height (cm)';
  static const String heightFt = 'Height (ft\'in")';
  static const String weightKg = 'Weight (kg)';
  static const String weightLbs = 'Weight (lbs)';
  static const String heightRange = 'Height must be between 50-300 cm';
  static const String weightRange = 'Weight must be between 20-500 kg';
  
  // Profile Setup - Step 3
  static const String beginner = 'Beginner';
  static const String beginnerDesc = '< 6 months';
  static const String intermediate = 'Intermediate';
  static const String intermediateDesc = '6 months – 2 years';
  static const String advanced = 'Advanced';
  static const String advancedDesc = '2 – 5 years';
  static const String elite = 'Elite';
  static const String eliteDesc = '5+ years';
  
  // Profile Setup - Step 4
  static const String buildMuscle = 'Build Muscle';
  static const String loseFat = 'Lose Fat';
  static const String improveStrength = 'Improve Strength';
  static const String improveFlexibility = 'Improve Flexibility';
  static const String athleticPerformance = 'Athletic Performance';
  static const String injuryRehabilitation = 'Injury Rehabilitation';
  static const String generalFitness = 'General Fitness';
  static const String selectAtLeastOneGoal = 'Please select at least one goal';
  
  // Profile Setup Dialogs
  static const String exitProfileSetup = 'Are you sure?';
  static const String exitProfileSetupMessage = 'Your progress will be lost.';
  static const String cancel = 'Cancel';
  static const String exitAnyway = 'Exit Anyway';
  
  // Loading States
  static const String signingIn = 'Signing in...';
  static const String signingUp = 'Signing up...';
  static const String savingProfile = 'Saving profile...';
  static const String loading = 'Loading...';
  
  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String profileSaveError = 'Failed to save profile. Please try again.';
}
