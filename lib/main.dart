import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/filesView/navigationScreen.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Locale _locale = const Locale('en');

  void initState() {
    super.initState();
    _loadTheme();
    _loadLanguage();
    setTheme();
  }

  void changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode');
    if (code != null) {
      setState(() {
        _locale = Locale(code);
      });
    }
  }

  Future<void> setTheme() async {
    // themeMode is already available so doesn't need to create new var
    ref.listenManual<ThemeMode>(themeProvider, (previous, next) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', next == ThemeMode.dark ? 'dark' : 'light');
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme');
    if (savedTheme != null) {
      ref.read(themeProvider.notifier).state = savedTheme == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: NavigationScreen(onChangeLanguage: changeLanguage),
    );
  }
}
