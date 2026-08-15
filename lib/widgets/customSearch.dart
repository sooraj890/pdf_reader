// this is search functionality that works except pdf files while pdf files have it's own
// logic

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_reader/widgets/customFiles.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';

class CustomSearch extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  final Set<String> selectedFiles;
  final Function(String) onFileSelected;
  final List<String> files;
  const CustomSearch({
    super.key,
    required this.files,
    required Future<Null> Function() onFileChanged,
    required this.selectedFiles,
    required this.isSelectionMode,
    required this.onFileSelected,
  });
  @override
  ConsumerState<CustomSearch> createState() => _CustomSearchState();
}

class _CustomSearchState extends ConsumerState<CustomSearch> {
  List<String> filteredItems = [];

  void initState() {
    // TODO: implement initState
    super.initState();
    filteredItems = widget.files;
  }

  void filterSearch(String query) {
    List<String> results = [];
    if (query.isEmpty) {
      results = widget.files;
    } else {
      results = widget.files.where((item) {
        return item.toLowerCase().contains(query.toLowerCase());
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: filterSearch, // function for filter
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: Colors.blue),
                        Text(
                          "\nNo Files",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      String file = filteredItems[index];
                      File file3 = File(file);
                      Icon icon;
                      if (file.endsWith('.doc') || file.endsWith('.docx')) {
                        icon = Icon(Icons.description, color: Colors.blue);
                      } else if (file.endsWith('.xls') ||
                          file.endsWith('.xlsx')) {
                        icon = Icon(Icons.table_chart, color: Colors.green);
                      } else {
                        icon = Icon(Icons.slideshow, color: Colors.orange);
                      }
                      return Card(
                        child: ListTile(
                          leading: widget.isSelectionMode
                              ? Checkbox(
                                  value: widget.selectedFiles.contains(file),
                                  onChanged: (_) {
                                    widget.onFileSelected(file);
                                  },
                                )
                              : icon,
                          title: Text(file.split('/').last),
                          onTap: () async {
                            if (widget.isSelectionMode) {
                              widget.onFileSelected(file);
                            } else {
                              await OpenFilex.open(file);
                            }
                          },
                          trailing: SizedBox(
                            width: 96,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Favourites(
                                          files: file3,
                                          icon: icon,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.star,
                                    color: fav.contains(file)
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
                                          file3,
                                        );
                                    if (result != null) {
                                      setState(() {
                                        file3 = result;
                                        loadFavorites();
                                      });
                                    }
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
