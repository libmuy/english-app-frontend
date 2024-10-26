import 'package:get_it/get_it.dart';
import 'package:libmuy_audioplayer/libmuy_audioplayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'learning_provider.dart';
import 'setting_provider.dart';
import 'history.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton(LibmuyAudioplayer());
  getIt.registerSingleton(await SharedPreferences.getInstance());
  getIt.registerSingleton(AuthProvider());
  getIt.registerSingleton(SettingProvider());
  getIt.registerSingleton(LearningProvider());
  getIt.registerSingleton(HistoryManager());
}
