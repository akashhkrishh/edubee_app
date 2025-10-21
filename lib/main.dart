import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edubee_app/controllers/usb_controller.dart';
import 'package:edubee_app/providers/music_policy_provider.dart'; // Import new provider
import 'package:edubee_app/providers/settings_provider.dart';
import 'package:edubee_app/screens/home_screen.dart';
import 'package:edubee_app/services/background_music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Create instances of all providers
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final usbController = UsbController();
  await usbController.initUsb();

  final musicPolicyProvider = MusicPolicyProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: usbController),
        ChangeNotifierProvider.value(value: musicPolicyProvider), // Add new provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final BackgroundMusicService _musicService = BackgroundMusicService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    // Get the music policy provider
    final musicPolicy = Provider.of<MusicPolicyProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _musicService.stopBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
      // FIXED: Check both settings AND the policy before playing music.
        if (settingsProvider.isMusicEnabled && musicPolicy.isMusicAllowed) {
          _musicService.playBackgroundMusic();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Edubee',
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: settings.themeMode,
          home: const HomeScreen(),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: widget!,
            );
          },
        );
      },
    );
  }
}