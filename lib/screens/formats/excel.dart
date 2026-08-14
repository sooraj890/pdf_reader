import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';

import '../../widgets/customSearch.dart';

class Excel extends ConsumerStatefulWidget {
  final List<File> excelFiles2;
  final int count;

  const Excel({
    super.key,
    required this.excelFiles2,
    required this.count,
  });

  @override
  ConsumerState<Excel> createState() => _ExcelState();
}

class _ExcelState extends ConsumerState<Excel> {
  late List<String> files;

  @override
  void initState() {
    super.initState();

    files = widget.excelFiles2
        .map((file) => file.path)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.excel,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              "files: ${widget.count}",
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      body: CustomSearch(files: files),
    );
  }
}