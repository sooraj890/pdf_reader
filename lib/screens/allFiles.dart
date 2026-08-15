// // shows total files that app have also choose files in folders logic is also taken from here
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:pdf_reader/screens/home.dart';
// import 'package:pdf_reader/l10n/app_localizations.dart';
// import 'package:pdf_reader/main.dart';
// import 'formats/pdf/pdfScreen.dart';
//
// class AllFiles extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<AllFiles> createState() => _AllFilesState();
// }
//
// class _AllFilesState extends ConsumerState<AllFiles> {
//   List<File> filteredFiles = [];
//
//   void filterSearch(String query, List<File> allFiles) {
//     List<File> results;
//     if (query.isEmpty) {
//       results = allFiles;
//     } else {
//       results = allFiles.where((file) {
//         final fileName = file.path.split('/').last;
//         return fileName.toLowerCase().contains(query.toLowerCase());
//       }).toList();
//     }
//     setState(() {
//       filteredFiles = results;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final themeMode = ref.watch(themeProvider);
//     final pdf = ref.watch(pdfFiles);
//     final word = ref.watch(wordFiles);
//     final excel = ref.watch(excelFiles);
//     final ppt = ref.watch(pptFiles);
//     final List<File> allFiles = [...pdf, ...word, ...excel, ...ppt];
//     if (filteredFiles.isEmpty) {
//       filteredFiles = allFiles;
//     }
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(AppLocalizations.of(context)!.allFiles),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 20, left: 20),
//             child: Text(
//               "${AppLocalizations.of(context)!.files} : ${allFiles.length}",
//               style: TextStyle(fontSize: 15, color: themeMode==ThemeMode.dark?Colors.white:Colors.black),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: TextField(
//               onChanged: (value) => filterSearch(value, allFiles),
//               style: TextStyle(
//                 color: themeMode == ThemeMode.dark
//                     ? Colors.white
//                     : Colors.black,
//               ),
//               decoration: InputDecoration(
//                 hintText: AppLocalizations.of(context)!.searchFiles,
//                 hintStyle: TextStyle(
//                   color: themeMode == ThemeMode.dark
//                       ? Colors.white
//                       : Colors.black,
//                 ),
//                 prefixIcon: Icon(
//                   Icons.search,
//                   color: themeMode == ThemeMode.dark
//                       ? Colors.white
//                       : Colors.black,
//                 ),
//                 filled: true,
//                 fillColor: themeMode == ThemeMode.dark
//                     ? Colors.grey.shade900
//                     : Colors.black12,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredFiles.length,
//               itemBuilder: (context, index) {
//                 final file = filteredFiles[index];
//
//                 return ListTile(
//                   title: Text(file.path.split('/').last),
//
//                   leading: Icon(
//                     file.path.endsWith('.pdf')
//                         ? Icons.picture_as_pdf
//                         : file.path.endsWith('.ppt') ||
//                               file.path.endsWith('.pptx')
//                         ? Icons.slideshow
//                         : file.path.endsWith('.xls') ||
//                               file.path.endsWith('.xlsx')
//                         ? Icons.table_chart
//                         : Icons.description,
//                     color: file.path.endsWith('.pdf')
//                         ? Colors.red
//                         : file.path.endsWith('.ppt') ||
//                               file.path.endsWith('.pptx')
//                         ? Colors.orange
//                         : file.path.endsWith('.xls') ||
//                               file.path.endsWith('.xlsx')
//                         ? Colors.green
//                         : Colors.blue,
//                   ),
//                   onTap: () {
//                     if (file.path.endsWith('.pdf')) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PdfScreen(file: file),
//                         ),
//                       );
//                     } else {
//                       OpenFilex.open(file.path);
//                     }
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'formats/pdf/pdfScreen.dart';
import 'home.dart';

class AllFiles extends ConsumerStatefulWidget {
  const AllFiles({super.key});

  @override
  ConsumerState<AllFiles> createState() => _AllFilesState();
}

class _AllFilesState extends ConsumerState<AllFiles> {
  List<File> filteredFiles = [];

  // Selected files
  final Set<String> selectedFiles = {};

  bool isSelectionMode = false;

  void filterSearch(String query, List<File> allFiles) {
    List<File> results;

    if (query.isEmpty) {
      results = allFiles;
    } else {
      results = allFiles.where((file) {
        final fileName = file.path.split('/').last;

        return fileName.toLowerCase().contains(
          query.toLowerCase(),
        );
      }).toList();
    }

    setState(() {
      filteredFiles = results;
    });
  }

  void toggleSelection(File file) {
    setState(() {
      if (selectedFiles.contains(file.path)) {
        selectedFiles.remove(file.path);
      } else {
        selectedFiles.add(file.path);
      }

      if (selectedFiles.isEmpty) {
        isSelectionMode = false;
      }
    });
  }

  void selectAll(List<File> allFiles) {
    setState(() {
      selectedFiles.clear();

      for (final file in allFiles) {
        selectedFiles.add(file.path);
      }

      isSelectionMode = true;
    });
  }

  void clearSelection() {
    setState(() {
      selectedFiles.clear();
      isSelectionMode = false;
    });
  }

  Future<void> shareSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    final files = selectedFiles
        .map((path) => XFile(path))
        .toList();

    await Share.shareXFiles(
      files,
      text: 'Shared files',
    );
  }

  Future<void> deleteSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete files'),
          content: Text(
            'Are you sure you want to delete '
                '${selectedFiles.length} file(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Delete physical files
    for (final path in selectedFiles) {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      selectedFiles.clear();
      isSelectionMode = false;
    });

    // Refresh providers.
    //
    // If your providers are StateProvider<List<File>>, update them here.
    // Example:
    //
    // ref.read(pdfFiles.notifier).state =
    //     ref.read(pdfFiles).where((file) => file.existsSync()).toList();

    setState(() {
      filteredFiles = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Files deleted'),
      ),
    );
  }

  IconData getFileIcon(File file) {
    final path = file.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }

    if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
      return Icons.slideshow;
    }

    if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
      return Icons.table_chart;
    }

    return Icons.description;
  }

  Color getFileColor(File file) {
    final path = file.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return Colors.red;
    }

    if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
      return Colors.orange;
    }

    if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
      return Colors.green;
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final pdf = ref.watch(pdfFiles);
    final word = ref.watch(wordFiles);
    final excel = ref.watch(excelFiles);
    final ppt = ref.watch(pptFiles);

    final List<File> allFiles = [
      ...pdf,
      ...word,
      ...excel,
      ...ppt,
    ];

    // Keep filtered list synchronized with provider data.
    if (!isSelectionMode && filteredFiles.isEmpty) {
      filteredFiles = allFiles;
    }

    final bool allSelected =
        allFiles.isNotEmpty &&
            selectedFiles.length == allFiles.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.allFiles,
        ),

        actions: [
          if (isSelectionMode) ...[
            // Select all / deselect all

            // Share
            IconButton(
              tooltip: 'Share',
              onPressed: selectedFiles.isEmpty
                  ? null
                  : shareSelectedFiles,
              icon: const Icon(Icons.share),
            ),

            // Delete
            IconButton(
              tooltip: 'Delete',
              onPressed: selectedFiles.isEmpty
                  ? null
                  : deleteSelectedFiles,
              icon: const Icon(Icons.delete),
            ),

            // Cancel selection
            IconButton(
              tooltip: 'Cancel',
              onPressed: clearSelection,
              icon: const Icon(Icons.close),
            ),
            Text("${selectedFiles.length}"),
            SizedBox(width: 20,),
          ] else ...[
            IconButton(
              tooltip: 'Select files',
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
              icon: const Icon(Icons.check_circle),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 8,
                left: 8,
              ),
              child: Text(
                '${AppLocalizations.of(context)!.files} : '
                    '${allFiles.length}',
                style: TextStyle(
                  fontSize: 15,
                  color: themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            SizedBox(width: 10,)
          ],
        ],
      ),

      body: allFiles.isEmpty?Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search_off,color: Colors.blue,size: 30,),
          SizedBox(height: 10,),
          Text("No Files",style: TextStyle(fontWeight: FontWeight.bold),),
        ],
      )):Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                filterSearch(value, allFiles);
              },
              style: TextStyle(
                color: themeMode == ThemeMode.dark
                    ? Colors.white
                    : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .searchFiles,
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

          // Select all row
          if (isSelectionMode)
            ListTile(
              leading: Checkbox(
                value: allSelected,
                onChanged: (_) {
                  if (allSelected) {
                    clearSelection();
                  } else {
                    selectAll(allFiles);
                  }
                },
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredFiles.length,
              itemBuilder: (context, index) {
                final file = filteredFiles[index];

                final bool isSelected =
                selectedFiles.contains(file.path);

                return ListTile(
                  leading: isSelectionMode
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      toggleSelection(file);
                    },
                  )
                      : Icon(
                    getFileIcon(file),
                    color: getFileColor(file),
                  ),

                  title: Text(
                    file.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  selected: isSelected,

                  onTap: () {
                    if (isSelectionMode) {
                      toggleSelection(file);
                      return;
                    }

                    if (file.path
                        .toLowerCase()
                        .endsWith('.pdf')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfScreen(file: file),
                        ),
                      );
                    } else {
                      OpenFilex.open(file.path);
                    }
                  },

                  onLongPress: () {
                    if (!isSelectionMode) {
                      setState(() {
                        isSelectionMode = true;
                        selectedFiles.add(file.path);
                      });
                    } else {
                      toggleSelection(file);
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
