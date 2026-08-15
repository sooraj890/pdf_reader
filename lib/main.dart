// defines how navigation screen shows different screens at starting and open external documents as
// from whatsapp handling theme provider, languages with app localizations

// This app still unable to open word, ppt and excel files because of editable documents and at
// some places state management issues but can be solve by refresh the home screen system

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide Intent;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/screens/navigation_screens.dart';
import 'package:pdf_reader/screens/formats/pdf/pdfScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  runApp(const ProviderScope(child: MyApp()));
  WidgetsFlutterBinding.ensureInitialized();
  MediaStore.appFolder = 'Documents';
  await MediaStore.ensureInitialized();
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Locale _locale = const Locale('en');
  static const MethodChannel _fileChannel =
  MethodChannel('pdf_reader/file');

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadLanguage();
    setTheme();
    _setupExternalFileListener();
  }

  void _setupExternalFileListener() {
    _fileChannel.setMethodCallHandler((call) async {
      if (call.method == 'openExternalFile') {
        final uri = call.arguments as String?;
        if (uri == null || uri.isEmpty) {
          return;
        }
        await _openExternalPdf(uri);
      }
    });
  }

  Future<void> _openExternalPdf(String uri) async {
    try {
      final filePath =
      await _fileChannel.invokeMethod<String>('copyUriToCache', {'uri': uri,},);
      if (filePath == null || filePath.isEmpty) {
        return;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        return;
      }
      await Future.delayed(
        const Duration(milliseconds: 500),
      );
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => PdfScreen(
            file: file,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Error opening external PDF: $e',
      );
    }
  }

  Future<void> changeLanguage(Locale locale) async {
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
      navigatorKey: navigatorKey,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: NavigationScreen(onChangeLanguage: changeLanguage),
    );
  }
}
