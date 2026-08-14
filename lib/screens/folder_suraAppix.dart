import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_reader/services/select_files_folders.dart';
import 'package:share_plus/share_plus.dart';

import '../services/Folder_Services.dart';
import '../widgets/customFiles.dart';
import 'formats/pdf/pdfScreen.dart';

class SuraAppixScreen extends StatefulWidget {
  const SuraAppixScreen({super.key});

  @override
  State<SuraAppixScreen> createState() => _SuraAppixScreenState();
}

class _SuraAppixScreenState extends State<SuraAppixScreen> {
  static const String rootPath = '/storage/emulated/0/SuraAppix';

  List<Directory> folders = [];

  @override
  void initState() {
    super.initState();
    loadFolders();
  }


  Future<void> initializeRootFolder() async {
    final root = Directory(rootPath);

    if (!await root.exists()) {
      await root.create(recursive: true);
    }
  }

  Future<void> loadFolders() async {
    try {
      await initializeRootFolder();

      final root = Directory(rootPath);

      final items = await root.list().toList();

      final loadedFolders = items.whereType<Directory>().toList();

      loadedFolders.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

      if (!mounted) return;

      setState(() {
        folders = loadedFolders;
      });
    } catch (e) {
      debugPrint('Load folders error: $e');
    }
  }


  Future<void> createNewFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return const CreateFolderDialog();
      },
    );

    if (name == null || name.trim().isEmpty) {
      return;
    }

    final folderName = name.trim();

    try {
      await initializeRootFolder();

      final newFolder = Directory(
        '$rootPath/$folderName',
      );

      if (await newFolder.exists()) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder already exists'),
          ),
        );

        return;
      }

      await newFolder.create(recursive: true);

      // Reload folders
      await loadFolders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$folderName created'),
        ),
      );
    } catch (e) {
      debugPrint('Create folder error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create folder: $e'),
        ),
      );
    }
  }


  void openFolder(Directory folder) {
    final folderName = folder.path.split(Platform.pathSeparator).last;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderScreen(
          folder: folder,
          folderName: folderName,
        ),
      ),
    );
  }

  TextEditingController folderRename=TextEditingController();



  Future<String?> showRenameFolderDialog(
      BuildContext context,
      String currentName,
      ) async {
    final controller = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Folder'),

          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter new folder name',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteFolder(Directory folder) async {
    try {
      await folder.delete(recursive: true);

      await loadFolders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder deleted'),
        ),
      );
    } catch (e) {
      debugPrint('Delete folder error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete folder: $e'),
        ),
      );
    }
  }

  Future<void> renameFolder(Directory folder) async {
    final oldName = folder.path
        .split(Platform.pathSeparator)
        .last;

    final newName = await showRenameFolderDialog(
      context,
      oldName,
    );

    if (newName == null || newName.isEmpty) {
      return;
    }

    // Don't allow the same name
    if (newName == oldName) {
      return;
    }

    try {
      final newFolder = Directory('$rootPath/$newName');

      if (await newFolder.exists()) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A folder with this name already exists'),
          ),
        );

        return;
      }

      await folder.rename(newFolder.path);

      await loadFolders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renamed to $newName'),
        ),
      );
    } catch (e) {
      debugPrint('Rename folder error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not rename folder: $e'),
        ),
      );
    }
  }

  Future<void> shareFolder(Directory folder) async {
    try {
      final archive = Archive();

      await for (final entity in folder.list(recursive: true)) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();

          final relativePath = path.relative(
            entity.path,
            from: folder.path,
          );

          archive.addFile(
            ArchiveFile(
              relativePath,
              bytes.length,
              bytes,
            ),
          );
        }
      }

      final zipData = ZipEncoder().encode(archive);

      if (zipData == null) {
        throw Exception('Could not create ZIP file');
      }

      final tempDir = await getTemporaryDirectory();

      final zipFile = File(
        path.join(
          tempDir.path,
          '${path.basename(folder.path)}.zip',
        ),
      );

      await zipFile.writeAsBytes(zipData);

      await Share.shareXFiles(
        [XFile(zipFile.path)],
        text: 'Sharing folder: ${path.basename(folder.path)}',
      );
    } catch (e) {
      debugPrint('Share folder error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share folder: $e'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuraAppix'),
      ),

      body: folders.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'No folders',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: folders.length,

        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),

        itemBuilder: (context, index) {
          final folder = folders[index];

          final folderName = folder.path
              .split(Platform.pathSeparator)
              .last;

          return Card(
            elevation: 3,
            clipBehavior: Clip.antiAlias,

            child: InkWell(
              onTap: () {
                openFolder(folder);
              },

              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [
                  const Icon(
                    Icons.folder,
                    size: 50,
                    color: Colors.amber,
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),

                    child: Text(
                      folderName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //crossAxisAlignment: CrossAxisAlignment.s,
                    children: [
                      IconButton(onPressed: () async {
                        shareFolder(folder);
                        loadFolders();
                        setState(() {

                        });
                      }, icon: Icon(Icons.share,color: Colors.green,)),
                      IconButton(onPressed: () async {
                        renameFolder(folder);
                        setState(() {

                        });
                      }, icon: Icon(Icons.drive_file_rename_outline,color: Colors.blue,)),
                      IconButton(onPressed: () async {
                        deleteFolder(folder);
                        loadFolders();
                        setState(() {

                        });
                      }, icon: Icon(Icons.delete,color: Colors.red,))
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: createNewFolder,
        child: const Icon(Icons.add),
      ),
    );
  }
}


class FolderScreen extends StatefulWidget {
  final Directory folder;
  final String folderName;

  const FolderScreen({
    super.key,
    required this.folder,
    required this.folderName,
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<File> files = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    final directory = widget.folder;

    final files = directory
        .listSync()
        .whereType<File>()
        .toList();

    setState(() {
      this.files = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
      ),

      body: files.isEmpty
          ? const Center(
        child: Text('No files'),
      )
          : ListView.builder(
        itemCount: files.length,

        itemBuilder: (context, index) {
          final file = files[index];

          final fileName = file.path
              .split(Platform.pathSeparator)
              .last;

          return ListTile(
            leading: Icon(
              file.path.endsWith('.pdf')
                  ? Icons.picture_as_pdf
                  : file.path.endsWith('.ppt') ||
                  file.path.endsWith('.pptx')
                  ? Icons.slideshow
                  : file.path.endsWith('.xls') ||
                  file.path.endsWith('.xlsx')
                  ? Icons.table_chart
                  : Icons.description,
              color: file.path.endsWith('.pdf')
                  ? Colors.red
                  : file.path.endsWith('.ppt') ||
                  file.path.endsWith('.pptx')
                  ? Colors.orange
                  : file.path.endsWith('.xls') ||
                  file.path.endsWith('.xlsx')
                  ? Colors.green
                  : Colors.blue,
            ),
            onTap: () {
              if (file.path.endsWith('.pdf')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfScreen(file: file),
                  ),
                );
              } else {
                OpenFilex.open(file.path);
              }
            },
            // trailing: IconButton(onPressed: () async {
            //   final file=files[index];
            //   if(await file.exists()){
            //     file.delete();
            //   }
            //   await loadFiles();
            //   setState(() {
            //
            //   });
            // }, icon: Icon(Icons.delete)),

            trailing: IconButton(onPressed: () async {
              final result = await FileUtils.showFileOptionsSheet(
                context,
                file,
              );



              if (result != null) {
                setState(() {
                  files[index] = result;
                });
              }
            }, icon: Icon(Icons.more_vert)),

            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        final selectedFiles=await Navigator.push(context, MaterialPageRoute(builder: (context)=>MoveFiles(folderPath:widget.folder)));
        if(selectedFiles != null){
          files.addAll(selectedFiles);
          loadFiles();
        }
        setState(() {

        });
      },child: Icon(Icons.add),),
    );
  }
}





