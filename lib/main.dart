import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edubee_app/controllers/usb_controller.dart';
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

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final usbController = UsbController();
  await usbController.initUsb();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => settingsProvider),
        ChangeNotifierProvider(create: (context) => usbController),
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
    final musicService = BackgroundMusicService();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        musicService.pauseBackgroundMusic();
        break;
      case AppLifecycleState.resumed:
        if (settingsProvider.isMusicEnabled) {
          musicService.resumeBackgroundMusic();
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
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: settings.fontScale,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: Theme.of(context).textTheme.apply(
              fontSizeFactor: settings.fontScale,
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),
          themeMode: settings.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}