import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode — card feed is portrait-only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status/nav bar for immersive feed experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepNavy,
    ),
  );

  runApp(
    // Wrap the entire app in ProviderScope for Riverpod
    const ProviderScope(child: FinBytesApp()),
  );
}

class FinBytesApp extends StatelessWidget {
  const FinBytesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinBytes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const FeedScreen(),
    );
  }
}
