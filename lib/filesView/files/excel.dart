import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/filesView/customSearch.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';

class Excel extends ConsumerStatefulWidget {
  List<File> excelFiles2;
  var count;
  Excel({super.key, required this.excelFiles2, required this.count});

  @override
  ConsumerState<Excel> createState() => _ExcelState();
}

class _ExcelState extends ConsumerState<Excel> {
  late List<String> files = widget.excelFiles2
      .map((file) => file.path)
      .toList();
  @override
  Widget build(BuildContext context) {
    int counting = widget.count;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.excel),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25, left: 25),
            child: Text("files : $counting", style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
      body: CustomSearch(files: files),
    );
  }
}
