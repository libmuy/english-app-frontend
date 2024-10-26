// File: lib/main.dart
import 'package:flutter/material.dart';
import 'providers/service_locator.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'providers/setting_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingProvider = getIt<SettingProvider>();
    final authProvider = getIt<AuthProvider>();
    settingProvider.resetSettings();
    authProvider.loadToken();


    
    return ValueListenableBuilder(
        valueListenable: settingProvider.themeNotifier,
        builder: (context, themeSetting, child) {
        final themeColor = Color(themeSetting.themeColor);
        final theme = themeSetting.mode;
        final themeMode = theme.toSystemValue();
        final themeData = AppTheme.getTheme(theme.isDarkMode(context), themeColor);
        
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Libmuy English',
            themeMode: themeMode,
            theme: themeData,
            home: ValueListenableBuilder(
                valueListenable: authProvider.isLoggedInNotifier,
                builder: (contex, isLogin, _) {
                  return isLogin ? const BottomNavBar() : const LoginPage();
                }));
        });


  }
}
