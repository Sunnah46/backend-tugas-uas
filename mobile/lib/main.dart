import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(EventlyApp(prefs: prefs));
}

class EventlyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const EventlyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
      ],
      child: MaterialApp(
        title: 'Evently',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B2A4A),
          ).copyWith(
            primary: const Color(0xFF16224E),
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFE6EAF5),
            onPrimaryContainer: const Color(0xFF16224E),
            secondary: const Color(0xFFC9A227),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFF6E9C8),
            onSecondaryContainer: const Color(0xFF5C4500),
            surface: const Color(0xFFFAFAFD),
            onSurface: const Color(0xFF1A1D27),
            surfaceContainerHighest: const Color(0xFFE9EBF2),
            onSurfaceVariant: const Color(0xFF454A5A),
            outline: const Color(0xFF7B8194),
            outlineVariant: const Color(0xFFC9CDDA),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16224E),
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: Color(0xFFF6E9C8),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          cardTheme: const CardThemeData(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
