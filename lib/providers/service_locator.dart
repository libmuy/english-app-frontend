import 'package:get_it/get_it.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/snack_bar_service.dart';
import 'auth_provider.dart';
import 'cache_provider.dart';
import 'history.dart';
import 'learning_provider.dart';
import 'setting_provider.dart';

final GetIt getIt = GetIt.instance;

/// Sets up the service locator with all required dependencies.
Future<void> setupLocator() async {
  // Register third-party services
  getIt.registerSingleton(LibmuyAudioplayer());
  getIt.registerSingleton(await SharedPreferences.getInstance());

  // Register application-specific providers
  getIt.registerSingleton(SnackBarService());
  getIt.registerSingleton(CacheProvider());
  getIt.registerSingleton(AuthProvider());
  getIt.registerSingleton(SettingProvider());
  getIt.registerSingleton(LearningProvider());
  getIt.registerSingleton(HistoryManager());
}
