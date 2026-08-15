// This file is connected with the home screen and navigation screen and related to custom files
// for many custom widgets for build card have same logic while image to pdf convert and folders
// have separate logic

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:pdf_reader/l10n/app_localizations.dart';
import 'package:pdf_reader/main.dart';
import 'package:pdf_reader/screens/folder_suraAppix.dart';
import 'package:pdf_reader/screens/allFiles.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:pdf_reader/screens/formats/excel.dart';
import 'package:pdf_reader/screens/formats/ppt.dart';
import 'package:pdf_reader/screens/formats/word.dart';
import '../services/imageToPDFServices.dart';
import 'formats/pdf/pdfList.dart';
import 'formats/pdf/pdfScreen.dart';

bool isScanning = true;
bool isLoading = true;
bool isPDFLoading = false;

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
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadFiles();
    await loadFavorites();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadFav() async {
    await loadFavorites();

    if (mounted) {
      setState(() {});
    }
  }

  Future<List<File>> loadFiles() async {
    final List<File> foundFiles = [];

    final List<File> excel = [];
    final List<File> pdf = [];
    final List<File> word = [];
    final List<File> ppt = [];

    Future<void> scanDir(Directory dir) async {
      try {
        final items = await dir.list().toList();

        for (final item in items) {
          if (item is File) {
            foundFiles.add(item);

            final String path = item.path.toLowerCase();

            if (path.endsWith('.pdf')) {
              pdf.add(item);
            } else if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
              excel.add(item);
            } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
              word.add(item);
            } else if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
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

    // Update Riverpod providers
    ref.read(pdfFiles.notifier).state = pdf;
    ref.read(wordFiles.notifier).state = word;
    ref.read(excelFiles.notifier).state = excel;
    ref.read(pptFiles.notifier).state = ppt;

    if (mounted) {
      isScanning = false;
      setState(() {});
    }

    return foundFiles;
  }

  Future createPdf(BuildContext context) async {
    try {
      if (mounted) {
        setState(() {
          isPDFLoading = true;
        });
      }

      final ImagePicker picker = ImagePicker();
      final List<XFile> selectedImages = await picker.pickMultiImage();
      if (selectedImages.isEmpty) {
        return;
      }
      final List<File> imageFiles = selectedImages
          .map((image) => File(image.path))
          .toList();
      final File pdfFile = await ImageToPdfService.convertImagesToPdf(
        imageFiles,
      );
      await savePdfToDownloads(pdfFile);
      await loadFiles();
      await loadFav();
      final List<File> updatedPdfFiles = ref.read(pdfFiles);

      final String fileName = pdfFile.path.split(Platform.pathSeparator).last;

      File? savedFile;

      for (final file in updatedPdfFiles) {
        if (file.path.endsWith(fileName)) {
          savedFile = file;
          break;
        }
      }

      // Open PDF
      if (savedFile != null && await savedFile.exists()) {
        if (!context.mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PdfScreen(file: savedFile!)),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF saved but could not find the file.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create PDF: $e')));
      }
    } finally {
      // ALWAYS stop loading
      if (mounted) {
        setState(() {
          isPDFLoading = false;
        });
      }
    }
  }

  Future<SaveInfo?> savePdfToDownloads(File pdfFile) async {
    final mediaStore = MediaStore();

    final result = await mediaStore.saveFile(
      tempFilePath: pdfFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: 'SuraAppix',
    );

    return result;
  }

  Widget buildCard(
    BuildContext context,
    String title,
    Widget screen,
    List<File> files,
    int count,
    Color color,
    Icon icon,
    Widget amount,
  ) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );

        // Refresh after returning
        await loadFiles();
        await loadFavorites();

        if (mounted) {
          setState(() {});
        }
      },

      child: Card(
        elevation: 20,
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
    final List<File> pdfFiles2 = ref.watch(pdfFiles);
    final List<File> excelFiles2 = ref.watch(excelFiles);
    final List<File> wordFiles2 = ref.watch(wordFiles);
    final List<File> pptFiles2 = ref.watch(pptFiles);
    final List<File> pdf = ref.watch(pdfFiles);
    final List<File> words = ref.watch(wordFiles);
    final List<File> excel = ref.watch(excelFiles);
    final List<File> ppt = ref.watch(pptFiles);
    final int totalDoc = pdf.length + words.length + excel.length + ppt.length;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),

          child: Row(
            children: [
              Text(
                isScanning
                    ? ""
                    : isPDFLoading
                    ? ""
                    : AppLocalizations.of(context)!.documents,

                style: TextStyle(
                  fontFamily: 'serif',
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 30),

            child: isScanning
                ? const Text("")
                : isPDFLoading
                ? Text("")
                : Container(
                    height: 30,
                    width: 110,

                    decoration: BoxDecoration(
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

      body: isPDFLoading
          ? Center(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 40),
                    Text("Working... ", style: TextStyle(fontFamily: 'serif')),
                  ],
                ),
              ),
            )
          : isScanning
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 50),
                  Text(
                    "Scanning...",
                    style: TextStyle(
                      fontFamily: 'serif',

                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      //color: themeMode==ThemeMode.dark?Colors.white:Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : totalDoc == 0
          ? RefreshIndicator(
              onRefresh: loadFiles,

              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,

                      child: Column(
                        children: [
                          SizedBox(height: 80),

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

                                  wordFiles2,
                                  words.length,

                                  Color(0xFF2B579A).withOpacity(0.10),

                                  const Icon(
                                    Icons.description,
                                    color: Colors.blue,
                                  ),

                                  words.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${words.length}'),
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

                                  //Text(excel.isEmpty ? "..." : "${excel.length}"),
                                  excel.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${excel.length}'),
                                ),

                                buildCard(
                                  context,

                                  AppLocalizations.of(context)!.ppt,

                                  PPT(pptFiles2: pptFiles2, count: ppt.length),

                                  pptFiles2,
                                  ppt.length,

                                  Color(0xFFD24726).withOpacity(0.10),

                                  const Icon(
                                    Icons.slideshow,
                                    color: Colors.orange,
                                  ),

                                  //Text(ppt.isEmpty ? "..." : "${ppt.length}"),
                                  ppt.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${ppt.length}'),
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

                                  pdf.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${pdf.length}'),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: themeMode==ThemeMode.dark?Colors.purple.withOpacity(0.20):Colors.purple.withOpacity(0.20),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        createPdf(context);
                                      },

                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: const [
                                          Icon(
                                            Icons.change_circle,
                                            color: Colors.blue,
                                          ),

                                          SizedBox(height: 10),

                                          Text(
                                            "Image to PDF",

                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: themeMode==ThemeMode.dark?Colors.yellow.withOpacity(0.20):Colors.yellow.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SuraAppixScreen(),
                                          ),
                                        );
                                      },

                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: const [
                                          Icon(
                                            Icons.folder_copy,
                                            color: Colors.orange,
                                          ),

                                          SizedBox(height: 10),

                                          Text(
                                            "Folders",

                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 280,
                        bottom: 20,
                        top: 20,
                      ),

                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          //color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) => AllFiles(),
                                ),
                              );
                            },

                            icon: const Icon(
                              Icons.search,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadFiles,

              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,

                      child: Column(
                        children: [
                          SizedBox(height: 80),

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

                                  wordFiles2,
                                  words.length,

                                  Color(0xFF2B579A).withOpacity(0.10),

                                  const Icon(
                                    Icons.description,
                                    color: Colors.blue,
                                  ),

                                  words.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${words.length}'),
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

                                  //Text(excel.isEmpty ? "..." : "${excel.length}"),
                                  excel.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${excel.length}'),
                                ),

                                buildCard(
                                  context,

                                  AppLocalizations.of(context)!.ppt,

                                  PPT(pptFiles2: pptFiles2, count: ppt.length),

                                  pptFiles2,
                                  ppt.length,

                                  Color(0xFFD24726).withOpacity(0.10),

                                  const Icon(
                                    Icons.slideshow,
                                    color: Colors.orange,
                                  ),

                                  //Text(ppt.isEmpty ? "..." : "${ppt.length}"),
                                  ppt.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${ppt.length}'),
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

                                  pdf.isEmpty
                                      ? Icon(
                                          Icons.search_off,
                                          size: 20,
                                          color: Colors.blue,
                                        )
                                      : Text('${pdf.length}'),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: themeMode == ThemeMode.dark
                                          ? Colors.purple.withOpacity(0.20)
                                          : Colors.purple.withOpacity(0.20),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        createPdf(context);
                                      },

                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: [
                                          const Icon(
                                            Icons.change_circle,
                                            color: Colors.purple,
                                          ),

                                          const SizedBox(height: 10),

                                          Text(
                                            AppLocalizations.of(context)!.image_to_pdf,

                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: themeMode == ThemeMode.dark
                                          ? Colors.yellow.withOpacity(0.10)
                                          : Colors.yellow.withOpacity(0.30),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SuraAppixScreen(),
                                          ),
                                        );
                                      },

                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,

                                        children: [
                                          const Icon(
                                            Icons.folder_copy,
                                            color: Colors.orange,
                                          ),

                                          const SizedBox(height: 10),

                                          Text(
                                            AppLocalizations.of(context)!.folders,

                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 280,
                        bottom: 20,
                        top: 20,
                        right: 20
                      ),

                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) => AllFiles(),
                                ),
                              );
                            },

                            icon: const Icon(
                              Icons.search,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
