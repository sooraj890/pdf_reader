// this opens the bottom sheet that has multiple other options as rename, fav etc this contians
// two sheets one for outer as for lists and other is for inner when pdf files opens
// inner is only for pdf items because this app till now not supporting other files

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_reader/screens/folder_suraAppix.dart';
import 'package:pdf_reader/screens/favourites.dart';
import 'package:share_plus/share_plus.dart';

import '../screens/formats/pdf/pdfScreen.dart';

class FileUtils {
  static String getFileName(File file) {
    return p.basename(file.path);
  }

  static Icon getFileIcon(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.blue);
    } else if (lowerPath.endsWith('.doc') || lowerPath.endsWith('.docx')) {
      return const Icon(Icons.description, color: Colors.blueAccent);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }

  static Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: "Sharing file");
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  static Future<File?> renameFile(File file, String newName) async {
    try {
      final dir = file.parent.path;
      final extension = p.extension(file.path);
      final newPath = p.join(dir, '$newName$extension');
      final renamed = await file.rename(newPath);
      return renamed;
    } catch (e) {
      debugPrint("Rename error: $e");
      return null;
    }
  }

  static Future<File?> showRenameDialog(BuildContext context, File file) async {
    final controller = TextEditingController();
    return showDialog<File>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final renamed = await FileUtils.renameFile(file, name);
                  Navigator.pop(context, renamed);
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  static Future<File?> showFileOptionsSheet(
    BuildContext context,
    File file, {
    Future<void> Function()? onFileChanged,
  }) async {
    return showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text(
                  "             Share",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FileUtils.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text(
                  "             Rename",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final renamed = await FileUtils.showRenameDialog(
                    context,
                    file,
                  );
                  if (renamed != null) {
                    await onFileChanged?.call();
                    Navigator.pop(context, renamed);
                  }
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.star,
                  color: fav.contains(file.path) ? Colors.yellow : Colors.white,
                ),
                title: Text(
                  fav.contains(file.path)
                      ? "              Un Favourite"
                      : "             Favourite",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final icon = getFileIcon(file.path);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favourites(files: file, icon: icon),
                    ),
                  );
                  await onFileChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.blue),
                title: const Text(
                  "             Open",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  if (file.path.toLowerCase().endsWith(".pdf")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfScreen(file: file),
                      ),
                    );
                  } else {
                    await OpenFilex.open(file.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "             Delete",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Delete File"),
                        content: Text(
                          "Are you sure you want to delete "
                          "${getFileName(file)}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    try {
                      await file.delete();
                      await onFileChanged?.call();
                      Navigator.pop(context, file);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("File deleted successfully"),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Delete error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to delete file")),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<File?> showFileOptionsSheetInner(
    BuildContext context,
    File file, {
    Future<void> Function()? onFileChanged,
  }) async {
    return showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // SHARE
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text(
                  "             Share",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FileUtils.shareFile(file);
                },
              ),

              // RENAME
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text(
                  "             Rename",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final renamed = await FileUtils.showRenameDialog(
                    context,
                    file,
                  );

                  if (renamed != null) {
                    await onFileChanged?.call();

                    Navigator.pop(context, renamed);
                  }
                },
              ),

              // FAVOURITE
              ListTile(
                leading: Icon(
                  Icons.star,
                  color: fav.contains(file.path) ? Colors.yellow : Colors.white,
                ),
                title: Text(
                  fav.contains(file.path)
                      ? "              Un Favourite"
                      : "             Favourite",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final icon = getFileIcon(file.path);

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favourites(files: file, icon: icon),
                    ),
                  );

                  await onFileChanged?.call();
                },
              ),

              // CLOSE / OPEN
              ListTile(
                leading: const Icon(Icons.close, color: Colors.blue),
                title: const Text(
                  "             Close",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  if (file.path.toLowerCase().endsWith(".pdf")) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  } else {
                    await OpenFilex.open(file.path);
                  }
                },
              ),

              // DELETE
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "             Delete",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Delete File"),
                        content: Text(
                          "Are you sure you want to delete "
                          "${getFileName(file)}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    try {
                      await file.delete();

                      await onFileChanged?.call();

                      Navigator.pop(context, file);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("File deleted successfully"),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Delete error: $e");

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to delete file")),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  static Future<File?> showFileOptionsSheetFolders(
      BuildContext context,
      File file, {
        Future<void> Function()? onFileChanged,
      }) async {
    return showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 350,
          child: Column(
            children: [
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text(
                  "             Share",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FileUtils.shareFile(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text(
                  "             Rename",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final renamed = await FileUtils.showRenameDialog(
                    context,
                    file,
                  );
                  if (renamed != null) {
                    await onFileChanged?.call();
                    Navigator.pop(context, renamed);
                  }
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.star,
                  color: fav.contains(file.path) ? Colors.yellow : Colors.white,
                ),
                title: Text(
                  fav.contains(file.path)
                      ? "              Un Favourite"
                      : "             Favourite",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final icon = getFileIcon(file.path);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favourites(files: file, icon: icon),
                    ),
                  );
                  await onFileChanged?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.blue),
                title: const Text(
                  "             Open",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  if (file.path.toLowerCase().endsWith(".pdf")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfScreen(file: file),
                      ),
                    );
                  } else {
                    await OpenFilex.open(file.path);
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.playlist_remove_outlined, color: Colors.red),
                title: const Text(
                  "             Remove",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Remove File"),
                        content: Text(
                          "Are you sure you want to remove "
                              "${getFileName(file)}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              "Remove",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    try {
                      await file.delete();
                      await onFileChanged?.call();
                      Navigator.pop(context, file);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("File removed successfully"),
                        ),
                      );
                    } catch (e) {
                      debugPrint("Remove error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to remove file")),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
