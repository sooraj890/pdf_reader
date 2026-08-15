// shows ppt files list screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/customSearch.dart';

class PPT extends ConsumerStatefulWidget {
  final List<File> pptFiles2;
  final int count;
  const PPT({super.key, required this.pptFiles2, required this.count});
  @override
  ConsumerState<PPT> createState() => _PPTState();
}

class _PPTState extends ConsumerState<PPT> {
  late List<File> files;

  @override
  void initState() {
    super.initState();
    files = List<File>.from(widget.pptFiles2);
  }

  Future<void> loadFiles() async {
    final List<File> ppt = [];
    Future<void> scanDir(Directory dir) async {
      try {
        final items = await dir.list().toList();
        for (final item in items) {
          if (item is File) {
            final String path = item.path.toLowerCase();
            if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
              ppt.add(item);
            }
          } else if (item is Directory) {
            await scanDir(item);
          }
        }
      } catch (_) {
        // Ignore folders that cannot be accessed
      }
    }

    await scanDir(Directory('/storage/emulated/0'));
    if (!mounted) return;
    setState(() {
      files = ppt;
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
        title: Text(AppLocalizations.of(context)!.ppt),
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
