import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/story_provider.dart';
import 'screens/story_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PebloApp());
}

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryProvider()),
      ],
      child: MaterialApp(
        title: 'Peblo - AI Story Buddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const StoryScreen(),
      ),
    );
  }
}
