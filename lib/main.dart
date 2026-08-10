import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    // ProviderScope must wrap the entire app to use Riverpod!
    const ProviderScope(
      child: EcommerceApp(),
    ),
  );
}

class EcommerceApp extends ConsumerWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the ThemeProvider! 
    // Any time it changes, this entire EcommerceApp will rebuild!
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Flutter E-Commerce',
      debugShowCheckedModeBanner: false,
      // 2. Pass our custom Light and Dark themes!
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // 3. Tell Flutter which one to use right now!
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
