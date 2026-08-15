// pdf outer screen that have a list of pdf files

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/screens/formats/pdf/pdfScreen.dart';
import 'package:pdf_reader/widgets/customFiles.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:share_plus/share_plus.dart';

import '../../home.dart';

class PdfItemsState extends ConsumerStatefulWidget {
  List<File> pdfFiles2;
  var count;
  PdfItemsState({super.key, required this.pdfFiles2, required this.count});
  @override
  ConsumerState<PdfItemsState> createState() => _PdfItemsStateState();
}

class _PdfItemsStateState extends ConsumerState<PdfItemsState> {
  bool isSelectionMode = false;
  Set<String> selectedFiles = {};
  late List<String> files;
  List<String> filteredItems = [];
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    files = widget.pdfFiles2.map((file) => file.path).toList();
    filteredItems = List.from(files);
  }

  Future<void> loadFiles() async {
    final List<File> pdf = [];
    Future<void> scanDir(Directory dir) async {
      try {
        final items = await dir.list().toList();
        for (final item in items) {
          if (item is File) {
            final path = item.path.toLowerCase();
            if (path.endsWith('.pdf')) {
              pdf.add(item);
            }
          } else if (item is Directory) {
            await scanDir(item);
          }
        }
      } catch (_) {}
    }

    await scanDir(Directory('/storage/emulated/0'));
    if (!mounted) return;
    setState(() {
      files = pdf.map((file) => file.path).toList();
      filteredItems = List.from(files);
      selectedFiles.removeWhere((path) => !files.contains(path));
    });
    ref.read(pdfFiles.notifier).state = pdf;
  }

  void filterSearch(String query) {
    List<String> results;
    if (query.isEmpty) {
      results = List.from(files);
    } else {
      results = files.where((item) {
        final fileName = item.split('/').last;
        return fileName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    setState(() {
      filteredItems = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pdf),
        actions: [
          // Selection button
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
            ),

          // Selection mode
          if (isSelectionMode) ...[
            // SHARE SELECTED
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                if (selectedFiles.isEmpty) return;
                await Share.shareXFiles(
                  selectedFiles.map((path) => XFile(path)).toList(),
                  text: "Sharing files",
                );
                setState(() {
                  selectedFiles.clear();
                  isSelectionMode = false;
                });
              },
            ),

            // DELETE SELECTED
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (selectedFiles.isEmpty) return;
                for (final path in selectedFiles) {
                  final file = File(path);
                  if (await file.exists()) {
                    try {
                      await file.delete();
                    } catch (e) {
                      debugPrint("Delete error: $e");
                    }
                  }
                }

                // Reload files from storage
                await loadFiles();

                if (!mounted) return;

                setState(() {
                  selectedFiles.clear();
                  isSelectionMode = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  selectedFiles.clear();
                  isSelectionMode = false;
                });
              },
            ),
          ],

          Padding(
            padding: const EdgeInsets.only(right: 25, left: 25),
            child: Center(
              child: Text(
                isSelectionMode
                    ? "${selectedFiles.length}"
                    : "${AppLocalizations.of(context)!.files} : ${files.length}",
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: filterSearch,

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
          filteredItems.isEmpty
              ? Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [Text("No Files"), Icon(Icons.search_off)],
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredItems.length,

                    itemBuilder: (context, index) {
                      final filePath = filteredItems[index];

                      final File file = File(filePath);

                      final Icon icon = const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      );

                      return Card(
                        child: ListTile(
                          leading: isSelectionMode
                              ? Checkbox(
                                  value: selectedFiles.contains(filePath),

                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedFiles.add(filePath);
                                      } else {
                                        selectedFiles.remove(filePath);
                                      }
                                    });
                                  },
                                )
                              : icon,
                          title: Text(filePath.split('/').last),
                          onTap: () async {
                            if (isSelectionMode) {
                              setState(() {
                                if (selectedFiles.contains(filePath)) {
                                  selectedFiles.remove(filePath);
                                } else {
                                  selectedFiles.add(filePath);
                                }
                              });
                            } else if (await file.exists()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfScreen(file: file),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("File doesn't exist"),
                                ),
                              );
                            }
                          },
                          trailing: isSelectionMode
                              ? null
                              : SizedBox(
                                  width: 96,

                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Favourites(
                                                files: file,
                                                icon: icon,
                                              ),
                                            ),
                                          );
                                          await loadFiles();
                                        },

                                        icon: Icon(
                                          Icons.star,

                                          color: fav.contains(filePath)
                                              ? Colors.yellow
                                              : themeMode == ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black38,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await FileUtils.showFileOptionsSheet(
                                            context,
                                            file,

                                            // THIS IS THE IMPORTANT PART
                                            onFileChanged: () async {
                                              await loadFiles();
                                            },
                                          );
                                        },

                                        icon: const Icon(Icons.more_vert),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
