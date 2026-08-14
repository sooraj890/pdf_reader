import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_reader/screens/allFiles.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/screens/formats/excel.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:pdf_reader/screens/formats/ppt.dart';
import 'formats/pdf/pdfList.dart';
import 'formats/word.dart';
// custom search is only using for except pdf

final pdfFiles = StateProvider<List<File>>((ref) => []);
final excelFiles = StateProvider<List<File>>((ref) => []);
final wordFiles = StateProvider<List<File>>((ref) => []);
final pptFiles = StateProvider<List<File>>((ref) => []);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool loading = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  Future<void> init() async {
    loadFiles();
    loadFavorites();
  }

  Future<void> loadFav() async {
    await loadFavorites();
    setState(() {});
  }

  // scan files with loading
  Future<List<File>> loadFiles() async {
    List<File> foundFiles = [];
    List<File> excel = [];
    List<File> pdf = [];
    List<File> word = [];
    List<File> ppt = [];
    Future<void> scanDir(Directory dir) async {
      try {
        var items = await dir.list().toList();
        for (var item in items) {
          if (item is File) {
            String path = item.path.toLowerCase();
            if (path.endsWith('.pdf')) {
              pdf.add(item);
            } else if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
              excel.add(item);
            } else if (path.endsWith('doc') || path.endsWith('docx')) {
              word.add(item);
            } else if (path.endsWith('ppt') || path.endsWith('pptx')) {
              ppt.add(item);
            }
          } else if (item is Directory) {
            await scanDir(item);
          }
        }
      } catch (_) {}
    }

    await scanDir(Directory('/storage/emulated/0'));
    ref.read(pdfFiles.notifier).state = pdf;
    ref.read(wordFiles.notifier).state = word;
    ref.read(excelFiles.notifier).state = excel;
    ref.read(pptFiles.notifier).state = ppt;
    return foundFiles;
  }

  // build card type constraint box
  Widget buildCard(
    BuildContext context,
    String title,
    Widget screen,
    List<File> w,
    var count,
    Color color,
    Icon icon,
    Widget amount,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Card(
        elevation: 10,
        color: color,
        shadowColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              amount,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    List<File> pdfFiles2 = ref.watch(pdfFiles);
    List<File> excelFiles2 = ref.watch(excelFiles);
    List<File> wordFiles2 = ref.watch(wordFiles);
    List<File> pptFiles2 = ref.watch(pptFiles);

    final pdf = ref.watch(pdfFiles);
    final words = ref.watch(wordFiles);
    final excel = ref.watch(excelFiles);
    final ppt = ref.watch(pptFiles);
    final totalDoc = pdf.length + words.length + excel.length + ppt.length;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text(
                totalDoc == 0 ? "" : "PDF ",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(totalDoc == 0 ? "" : "Reader"),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30),
            child: totalDoc == 0
                ? Text("")
                : Container(
                    height: 30,
                    width: 110,
                    decoration: BoxDecoration(
                      //color: Colors.white70,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "${AppLocalizations.of(context)!.allFiles} : $totalDoc",
                        style: TextStyle(
                          fontSize: 15,
                          color: themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: totalDoc == 0
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Sora Tech",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text("Flutter Development"),
            SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadFiles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 280,
                    bottom: 20,
                    top: 20,
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllFiles(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search, size: 30),
                  ),
                ),

                Expanded(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(12),
                    children: [
                      buildCard(
                        context,
                        AppLocalizations.of(context)!.word,
                        Word(
                          wordFiles2: wordFiles2,
                          count: words.length,
                        ),
                        excelFiles2,
                        words.length,
                        Color(0xFF2B579A).withOpacity(0.10),
                        const Icon(
                          Icons.description,
                          color: Colors.blue,
                        ),
                        Text(
                          "${words.isEmpty ? "..." : words.length}",
                        ),
                      ),

                      buildCard(
                        context,
                        AppLocalizations.of(context)!.excel,
                        Excel(
                          excelFiles2: excelFiles2,
                          count: excel.length,
                        ),
                        excelFiles2,
                        excel.length,
                        Color(0xFF217346).withOpacity(0.10),
                        const Icon(
                          Icons.table_chart,
                          color: Colors.green,
                        ),
                        Text(
                          "${excel.isEmpty ? "..." : excel.length}",
                        ),
                      ),

                      buildCard(
                        context,
                        AppLocalizations.of(context)!.ppt,
                        PPT(
                          pptFiles2: pptFiles2,
                          count: ppt.length,
                        ),
                        pdfFiles2,
                        pdf.length,
                        Color(0xFFD24726).withOpacity(0.10),
                        const Icon(
                          Icons.slideshow,
                          color: Colors.orange,
                        ),
                        Text(
                          "${ppt.isEmpty ? "..." : ppt.length}",
                        ),
                      ),

                      buildCard(
                        context,
                        AppLocalizations.of(context)!.pdf,
                        PdfItemsState(
                          pdfFiles2: pdfFiles2,
                          count: pdf.length,
                        ),
                        pdfFiles2,
                        pdf.length,
                        Color(0xFFD32F2F).withOpacity(0.10),
                        const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        Text(
                          "${pdf.isEmpty ? "..." : pdf.length}",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 300,
                  child: Divider(
                    height: 40,
                    thickness: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
