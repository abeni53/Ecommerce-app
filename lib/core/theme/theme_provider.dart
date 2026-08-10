import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A Notifier that simply holds either ThemeMode.light or ThemeMode.dark
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light; // Default to light
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    
    // We update the state once we read from Local Storage!
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final isCurrentlyDark = state == ThemeMode.dark;
    
    // Flip the state!
    state = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    
    // Save to Local Storage so it remembers next time you open the app
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', !isCurrentlyDark);
  }
}

// The provider that the entire app will listen to!
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
