// creates the main suraAppix folder if not created

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({super.key});
  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Folder'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Folder name',
          prefixIcon: Icon(Icons.folder),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(name);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class SuraAppixFolderService {
  static const String rootPath = '/storage/emulated/0/SuraAppix';
  static Directory get rootDirectory => Directory(rootPath);
  static Future<void> initialize() async {
    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }
  }

  static Future<List<Directory>> getFolders() async {
    await initialize();
    final items = await rootDirectory.list().toList();
    return items.whereType<Directory>().toList();
  }
}
