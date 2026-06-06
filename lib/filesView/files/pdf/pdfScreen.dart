import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_reader/filesView/customFiles.dart';
import 'package:pdfx/pdfx.dart';

class PdfScreen extends StatefulWidget {
  File file;
  PdfScreen({required this.file});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  double scrollPosition = 0;
  int currentPage = 1;
  bool isPort = true;
  bool appBar = true;
  late File file;

  late PdfControllerPinch controller;
  @override
  void initState() {
    // TODO: implement initState
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    // orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.file.path),
    );
    controller.addListener(_onPdfChanged);
    findPos();
    file = widget.file;
  }

  void _onPdfChanged() {
    final page = controller.page;
    if (page != null && page != currentPage) {
      setState(() {
        currentPage = page;
      });
    }
  }

  // scrolling the page
  void findPos() {
    controller.addListener(() {
      final page = controller.page;
      final total = controller.pagesCount;

      if (page != null && total != null && total > 0) {
        setState(() {
          scrollPosition = page / total;
        });
      }
    });
  }

  Icon getFileIcon(String path) {
    if (path.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (path.endsWith('.jpg') || path.endsWith('.png')) {
      return Icon(Icons.image, color: Colors.blue);
    } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
      return Icon(Icons.description, color: Colors.blueAccent);
    } else {
      return Icon(Icons.insert_drive_file);
    }
  }

  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    controller.removeListener(_onPdfChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String fileName = p.basename(file.path);
    return Scaffold(
      appBar: appBar == true
          ? AppBar(
              title: Text(fileName),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text("$currentPage /"),
                      Text(" ${controller.pagesCount.toString()}"),
                      SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          if (isPort == false) {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            isPort = !isPort;
                          } else {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                            isPort = !isPort;
                          }
                          setState(() {});
                        },
                        icon: Icon(
                          isPort == true
                              ? Icons.stay_primary_landscape_rounded
                              : Icons.stay_primary_portrait,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final result = await FileUtils.showFileOptionsSheet(
                            context,
                            file,
                          );

                          if (result != null) {
                            setState(() {
                              file = result;
                            });
                          }
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Stack(
            children: [
              PdfViewPinch(
                controller: controller,
                scrollDirection: Axis.vertical,
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                ),
              ),
              Positioned(
                right: isPort == false ? 50 : 8,
                top: 50,
                bottom: 50,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;

                    return Stack(
                      children: [
                        // 🟦 TRACK AREA
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        // 🔴 MOVING BUTTON
                        Positioned(
                          top: scrollPosition * (height - 40),
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              final localY = details.localPosition.dy;
                              final percent = (localY / height).clamp(0.0, 1.0);

                              final total = controller.pagesCount ?? 1;
                              final page = (percent * total).toInt().clamp(
                                1,
                                total,
                              );

                              controller.jumpToPage(page);
                            },
                            child: Container(
                              width: 20,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.drag_indicator,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          isPort == false
              ? Positioned(
                  left: appBar == true ? 40 : 40,
                  top: appBar == true ? 10 : 35,
                  child: IconButton(
                    onPressed: () {
                      appBar = !appBar;
                      setState(() {});
                    },
                    style: IconButton.styleFrom(backgroundColor: Colors.blue),
                    icon: Icon(
                      appBar == true
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }
}
