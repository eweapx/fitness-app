import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}