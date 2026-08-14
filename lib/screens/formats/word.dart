import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import '../../widgets/customSearch.dart';

class Word extends ConsumerStatefulWidget {
  List<File> wordFiles2;
  var count;
  Word({super.key, required this.wordFiles2, required this.count});

  @override
  ConsumerState<Word> createState() => _WordState();
}

class _WordState extends ConsumerState<Word> {
  late List<String> files = widget.wordFiles2.map((file) => file.path).toList();

  @override
  Widget build(BuildContext context) {
    int counting = widget.count;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.word),
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
