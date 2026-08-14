import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/screens/home.dart';
import 'package:pdf_reader/screens/setting.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:permission_handler/permission_handler.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final Function(Locale) onChangeLanguage;

  const NavigationScreen({super.key, required this.onChangeLanguage});

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  int currentIndex = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestPermission();
    Favourites();
  }

  Future<void> requestPermission() async {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
  }

  late final List<Widget> screens = [
    HomeScreen(),
    Favourites(),
    Setting(widget.onChangeLanguage),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final pdf = ref.watch(pdfFiles);
    final words = ref.watch(wordFiles);
    final excel = ref.watch(excelFiles);
    final ppt = ref.watch(pptFiles);
    final totalDoc = pdf.length + words.length + excel.length + ppt.length;
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: totalDoc == 0
          ? Text("")
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.home,
                    color: currentIndex == 0
                        ? Colors.blue
                        : themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  label: AppLocalizations.of(context)!.home,
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.star,
                    color: currentIndex == 1
                        ? Colors.blue
                        : themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  label: AppLocalizations.of(context)!.favourite,
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.settings,
                    color: currentIndex == 2
                        ? Colors.blue
                        : themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  label: AppLocalizations.of(context)!.settings,
                ),
              ],
            ),
    );
  }
}
