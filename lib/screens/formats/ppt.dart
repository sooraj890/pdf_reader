import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';

import '../../widgets/customSearch.dart';

class PPT extends ConsumerStatefulWidget {
  List<File> pptFiles2;
  var count;
  PPT({super.key, required this.pptFiles2, required this.count});

  @override
  ConsumerState<PPT> createState() => _PPTState();
}

class _PPTState extends ConsumerState<PPT> {
  late List<String> files = widget.pptFiles2.map((file) => file.path).toList();

  @override
  Widget build(BuildContext context) {
    int counting = widget.count;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.ppt),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25, left: 25),
            child: Text(
              "${AppLocalizations.of(context)!.files} : $counting",
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      body: CustomSearch(files: files),
    );
  }
}
