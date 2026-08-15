// showing list of excel files

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/customSearch.dart';

class Excel extends ConsumerStatefulWidget {
  final List excelFiles2;
  final int count;
  const Excel({super.key, required this.excelFiles2, required this.count});
  @override
  ConsumerState<Excel> createState() => _ExcelState();
}

class _ExcelState extends ConsumerState<Excel> {
  late List<File> files;
  @override
  void initState() {
    super.initState();
    files = widget.excelFiles2.map<File>((file) => file as File).toList();
  }

  Future<void> loadFiles() async {
    final List<File> excel = [];
    Future<void> scanDir(Directory dir) async {
      try {
        final items = await dir.list().toList();
        for (final item in items) {
          if (item is File) {
            final String path = item.path.toLowerCase();

            if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
              excel.add(item);
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
      files = excel;
    });
  }

  bool isSelectionMode = false;
  Set<String> selectedFiles = {};
  void toggleFileSelection(String path) {
    setState(() {
      if (selectedFiles.contains(path)) {
        selectedFiles.remove(path);
      } else {
        selectedFiles.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.excel),
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

      body: CustomSearch(
        files: files.map((file) => file.path).toList(),
        isSelectionMode: isSelectionMode,
        selectedFiles: selectedFiles,
        onFileSelected: toggleFileSelection,
        onFileChanged: () async {
          await loadFiles();
        },
      ),
    );
  }
}
