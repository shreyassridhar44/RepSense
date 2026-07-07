import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/error/global_error_handler.dart';
import 'core/offline/cache_service.dart';
import 'core/offline/pending_operations_queue.dart';
import 'data/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('🚀 Starting RepSense App...');

  // Initialize global error handler first
  GlobalErrorHandler.initialize();

  try {
    // Load environment variables
    AppLogger.debug('📄 Loading environment variables');
    await dotenv.load(fileName: '.env');
    AppLogger.debug('✅ Environment variables loaded');

    // Initialize local storage
    AppLogger.debug('💾 Initializing Hive');
    await Hive.initFlutter();
    await CacheService.initialize();
    await PendingOperationsQueue.initialize();
    AppLogger.debug('✅ Hive initialized');

    // Initialize Supabase
    await SupabaseService.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    AppLogger.info('✅ App initialization complete');
    
    runApp(
      Phoenix(
        child: ProviderScope(
          observers: [RepSenseProviderObserver()],
          child: const RepSenseApp(),
        ),
      ),
    );
  } catch (e, stack) {
    AppLogger.error('❌ Fatal error during app initialization', e, stack);
    rethrow;
  }
}

class RepSenseApp extends ConsumerWidget {
  const RepSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RepSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
