// this contain the settings for the app

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'formats/pdf/pdfScreen.dart';

class Setting extends ConsumerStatefulWidget {
  final Function(Locale) onChangeLanguage;
  Setting(this.onChangeLanguage);
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends ConsumerState<Setting> {
  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  Future<void> openFileManager() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String? path = result.files.single.path;
      File file = File(path!);
      if (path.endsWith('.pdf')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PdfScreen(file: file)),
        );
      } else {
        OpenFilex.open(file.path);
      }
      print(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = Localizations.localeOf(context).languageCode;
    final themeMode = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 50, right: 20),
            child: InkWell(
              child: Card(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.folder,
                        color: Colors.yellowAccent,
                        size: 25,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.fileManager,
                      style: TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
              onTap: () {
                openFileManager();
              },
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Card(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: themeMode == ThemeMode.dark
                        ? Icon(Icons.dark_mode, color: Colors.white)
                        : Icon(Icons.light_mode, color: Colors.yellow),
                  ),
                  Text(
                    themeMode == ThemeMode.dark
                        ? AppLocalizations.of(context)!.darkTheme
                        : AppLocalizations.of(context)!.lightTheme,
                    style: TextStyle(fontSize: 17),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      value: themeMode == ThemeMode.light,
                      onChanged: (value) async {
                        ref.read(themeProvider.notifier).state = value
                            ? ThemeMode.light
                            : ThemeMode.dark;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Card(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.language, color: Colors.blue),
                  ),
                  Text(
                    AppLocalizations.of(context)!.selectLanguage,
                    style: TextStyle(fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 80, right: 80),
              child: ListView(
                children: [
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.english),
                    trailing: currentLang == 'en'
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      widget.onChangeLanguage(const Locale('en'));
                    },
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.urdu),
                    trailing: currentLang == 'ur'
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      widget.onChangeLanguage(const Locale('ur'));
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: InkWell(
                  onTap: () {
                    openLink("https://sooraj-portfolio.web.app");
                  },
                  child: Icon(
                    Icons.connect_without_contact_outlined,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
