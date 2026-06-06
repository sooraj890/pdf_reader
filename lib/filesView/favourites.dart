import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart';
import 'package:pdf_reader/filesView/files/pdf/pdfScreen.dart';
import 'package:pdf_reader/filesView/home.dart';
import 'package:pdf_reader/filesView/navigationScreen.dart';
import 'package:pdf_reader/filesView/setting.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/p1.dart';
import 'package:pdf_reader/p2.dart';
import 'package:shared_preferences/shared_preferences.dart';

// it's icon is not showing for fav items

List<String> fav = [];

Future<void> loadFavorites() async {
  final pref = await SharedPreferences.getInstance();
  fav = pref.getStringList('list') ?? [];
}

class Favourites extends StatefulWidget {
  File? files;
  Icon? icon;
  Favourites({this.files, this.icon});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadAndAdd();
  }

  Future<void> loadAndAdd() async {
    final pref = await SharedPreferences.getInstance();
    fav = pref.getStringList('list') ?? [];
    final file = widget.files;
    if (file != null) {
      if (!fav.contains(file.path)) {
        fav.add(file.path);
        await pref.setStringList('list', fav);
      }
    }
    setState(() {});
  }

  Future<void> removeFav(int index) async {
    final pref = await SharedPreferences.getInstance();
    fav.removeAt(index);
    await pref.setStringList('list', fav);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.favourite),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25,left: 25),
            child: Text(
              "${AppLocalizations.of(context)!.files} : ${fav.length}",
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      body: fav.isEmpty?Expanded(child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off),
          Text("No Files"),
        ],
      ),)):ListView.builder(
        itemCount: fav.length,
        itemBuilder: (context, index) {
          //final file = widget.files;
          final file2 = fav[index];
          final Icon? icon = widget.icon;
          return Card(
            child: ListTile(
              leading: Icon(
                file2.endsWith('.pdf')
                    ? Icons.picture_as_pdf
                    : file2.endsWith('.ppt') || file2.endsWith('.pptx')
                    ? Icons.slideshow
                    : file2.endsWith('.xls') || file2.endsWith('.xlsx')
                    ? Icons.table_chart
                    : Icons.description,
                color: file2.endsWith('.pdf')
                    ? Colors.red
                    : file2.endsWith('.ppt') || file2.endsWith('.pptx')
                    ? Colors.orange
                    : file2.endsWith('.xls') || file2.endsWith('.xlsx')
                    ? Colors.green
                    : Colors.blue,
              ),
              title: Text(file2.split('/').last),
              onTap: () {
                if (file2.endsWith('.pdf')) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfScreen(file: File(file2)),
                    ),
                  );
                } else {
                  OpenFilex.open(file2);
                }
              },
              trailing: IconButton(
                onPressed: () async {
                  removeFav(index);
                },
                icon: Icon(Icons.star, color: Colors.yellow),
              ),
            ),
          );
        },
      ),
    );
  }
}
