import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to read environment variables loaded from `.env`
/// (see `.env.example` for required keys).
class AppConfig {
  AppConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Base URL of the API Service (FastAPI) — auth, users, workouts, analytics.
  static String get apiServiceUrl =>
      dotenv.env['API_SERVICE_URL'] ?? 'http://localhost:8000';

  /// Base URL of the Inference Service (FastAPI) — pose/biomechanics ML.
  static String get inferenceServiceUrl =>
      dotenv.env['INFERENCE_SERVICE_URL'] ?? 'http://localhost:8001';

  /// Base URL of the LLM Coach Service (FastAPI) — natural language coaching.
  static String get coachServiceUrl =>
      dotenv.env['COACH_SERVICE_URL'] ?? 'http://localhost:8002';
}
