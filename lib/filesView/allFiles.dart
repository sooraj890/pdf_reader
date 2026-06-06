import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_reader/filesView/files/pdf/pdfScreen.dart';
import 'package:pdf_reader/filesView/home.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';

class AllFiles extends ConsumerStatefulWidget {
  @override
  ConsumerState<AllFiles> createState() => _AllFilesState();
}

class _AllFilesState extends ConsumerState<AllFiles> {
  List<File> filteredFiles = [];

  @override
  void initState() {
    super.initState();
  }

  void filterSearch(String query, List<File> allFiles) {
    List<File> results;

    if (query.isEmpty) {
      results = allFiles;
    } else {
      results = allFiles.where((file) {
        final fileName = file.path.split('/').last;
        return fileName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredFiles = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final pdf = ref.watch(pdfFiles);
    final word = ref.watch(wordFiles);
    final excel = ref.watch(excelFiles);
    final ppt = ref.watch(pptFiles);
    final List<File> allFiles = [...pdf, ...word, ...excel, ...ppt];
    if (filteredFiles.isEmpty) {
      filteredFiles = allFiles;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.allFiles),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 20),
            child: Text(
              "${AppLocalizations.of(context)!.files} : ${allFiles.length}",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => filterSearch(value, allFiles),
              style: TextStyle(
                color: themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchFiles,
                hintStyle: TextStyle(
                  color: themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
                filled: true,
                fillColor: themeMode == ThemeMode.dark
                    ? Colors.grey.shade900
                    : Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                final file = filteredFiles[index];

                return ListTile(
                  title: Text(file.path.split('/').last),

                  leading: Icon(
                    file.path.endsWith('.pdf')
                        ? Icons.picture_as_pdf
                        : file.path.endsWith('.ppt') ||
                              file.path.endsWith('.pptx')
                        ? Icons.slideshow
                        : file.path.endsWith('.xls') ||
                              file.path.endsWith('.xlsx')
                        ? Icons.table_chart
                        : Icons.description,
                    color: file.path.endsWith('.pdf')
                        ? Colors.red
                        : file.path.endsWith('.ppt') ||
                              file.path.endsWith('.pptx')
                        ? Colors.orange
                        : file.path.endsWith('.xls') ||
                              file.path.endsWith('.xlsx')
                        ? Colors.green
                        : Colors.blue,
                  ),

                  onTap: () {
                    if (file.path.endsWith('.pdf')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfScreen(file: file),
                        ),
                      );
                    } else {
                      OpenFilex.open(file.path);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
