import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/screens/formats/pdf/pdfScreen.dart';
import 'package:pdf_reader/widgets/customFiles.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:share_plus/share_plus.dart';

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

  late List<String> files = widget.pdfFiles2.map((file) => file.path).toList();
  List<String> filteredItems = [];

  int? selectedIndex;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    filteredItems = files;
  }

  void filterSearch(String query) {
    List<String> results = [];
    if (query.isEmpty) {
      results = files;
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

  static Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: "Sharing file");
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int counting = widget.count;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pdf),
        actions: [
          if (!isSelectionMode)
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
            ),

          if (isSelectionMode) ...[
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
                    ? "${selectedFiles.length} Selected"
                    : "${AppLocalizations.of(context)!.files} : $counting",
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
              onChanged: filterSearch, // method
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
                    children: [Text("No Files"), Icon(Icons.search_off)],
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      var file = widget.pdfFiles2[index];
                      final file2 = filteredItems[index];
                      Icon icon = Icon(Icons.picture_as_pdf, color: Colors.red);

                      return Card(
                        child: ListTile(
                          leading: isSelectionMode
                              ? Checkbox(
                                  value: selectedFiles.contains(file2),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedFiles.add(file2);
                                      } else {
                                        selectedFiles.remove(file2);
                                      }
                                    });
                                  },
                                )
                              : Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(file2.split('/').last),
                          onTap: () {
                            if (isSelectionMode) {
                              setState(() {
                                if (selectedFiles.contains(file2)) {
                                  selectedFiles.remove(file2);
                                } else {
                                  selectedFiles.add(file2);
                                }
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfScreen(file: file),
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
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Favourites(
                                                files: file,
                                                icon: icon,
                                              ),
                                            ),
                                          );
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          Icons.star,
                                          color: fav.contains(file2)
                                              ? Colors.yellow
                                              : themeMode == ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black38,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          final result =
                                              await FileUtils.showFileOptionsSheet(
                                                context,
                                                file,
                                              );

                                          if (result != null) {
                                            setState(() {
                                              file = result;
                                            });
                                          }
                                        },
                                        icon: Icon(Icons.more_vert),
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
