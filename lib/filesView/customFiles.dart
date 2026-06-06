import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_reader/filesView/favourites.dart';
import 'package:share_plus/share_plus.dart';

class FileUtils {
  static String getFileName(File file) {
    return p.basename(file.path);
  }

  static Icon getFileIcon(String path) {
    if (path.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (path.endsWith('.jpg') || path.endsWith('.png')) {
      return const Icon(Icons.image, color: Colors.blue);
    } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
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
      final newPath = '$dir/$newName.pdf';

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
              onPressed: () => Navigator.pop(context),
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
    File file,
  ) async {
    return showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("Share"),
                onTap: () {
                  FileUtils.shareFile(file);
                },
              ),

              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Rename"),
                onTap: () async {
                  final renamed = await FileUtils.showRenameDialog(
                    context,
                    file,
                  );
                  if (renamed != null) {
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
                  fav.contains(file.path) ? "Remove " : "Add",
                  style: const TextStyle(fontSize: 17),
                ),
                onTap: () {
                  Icon icon = getFileIcon(file.path);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Favourites(files: file, icon: icon),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
