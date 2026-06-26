import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'services/connection_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();
  await NotificationService.requestPermission();
  // Sadece dikey mod
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Kayıtlı tema tercihini oku
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark') ?? true;

  runApp(PiDashboardApp(isDark: isDark));
}

class PiDashboardApp extends StatefulWidget {
  final bool isDark;
  const PiDashboardApp({super.key, required this.isDark});

  static _PiDashboardAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_PiDashboardAppState>();

  @override
  State<PiDashboardApp> createState() => _PiDashboardAppState();
}

class _PiDashboardAppState extends State<PiDashboardApp> {
  late bool _isDark;
  bool get isDark => _isDark;
  
  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
    ConnectionService.instance.startMonitoring();
  }
  
  @override
  void dispose() {
    ConnectionService.instance.stopMonitoring();
    super.dispose();
  }
  void toggleTheme() async {
    setState(() => _isDark = !_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pi Dashboard',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light(),
      darkTheme:  AppTheme.dark(),
      themeMode:  _isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainScreen(),
    );
  }
}