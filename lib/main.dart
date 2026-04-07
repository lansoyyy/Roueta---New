import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roueta/firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized before any Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    name: 'roueta-9f596',
  );

  // Notification plugin must be initialised after Firebase.
  await NotificationService().init();

  // Restore persisted driver session.
  final authProvider = AuthProvider();
  await authProvider.init();

  // Load persisted settings.
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Build app provider and kick off local + remote data loading.
  final appProvider = AppProvider();
  await appProvider.initLocalData();
  appProvider.startFirestoreListeners();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const RouetaApp(),
    ),
  );
}

class RouetaApp extends StatelessWidget {
  const RouetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouETA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Urbanist',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
