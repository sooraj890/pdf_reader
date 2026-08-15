// responsible for creating images to pdf conversion

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class ImageToPdfService {
  static Future<File> convertImagesToPdf(
    List<File> images, {
    String? fileName,
  }) async {
    if (images.isEmpty) {
      throw Exception('No images selected');
    }
    final pdf = pw.Document();
    for (final imageFile in images) {
      if (!await imageFile.exists()) {
        continue;
      }
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        continue;
      }
      final orientedImage = img.bakeOrientation(decodedImage);
      final resizedImage = orientedImage.width > 1600
          ? img.copyResize(orientedImage, width: 1600)
          : orientedImage;
      final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      final pdfImage = pw.MemoryImage(compressedBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
          },
        ),
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final name = fileName ?? 'Images_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File('${directory.path}/$name');
    final pdfBytes = await pdf.save();
    await pdfFile.writeAsBytes(pdfBytes, flush: true);
    return pdfFile;
  }
}
