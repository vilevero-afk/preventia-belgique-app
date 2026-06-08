import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../utils/platform_capabilities.dart';
import 'file_export_service.dart';

class PdfDeliveryService {
  const PdfDeliveryService._();

  static Future<void> exportPdf({
    required BuildContext context,
    required String name,
    required FutureOr<Uint8List> Function(PdfPageFormat format) onLayout,
  }) async {
    try {
      if (FileExportService.usesSaveDialog) {
        final bytes = await onLayout(PdfPageFormat.a4);
        if (!context.mounted) {
          return;
        }
        await FileExportService.savePdfBytes(
          bytes: bytes,
          suggestedFileName: name,
          context: context,
        );
        return;
      }

      await Printing.layoutPdf(
        name: FileExportService.cleanPdfFileName(name),
        onLayout: onLayout,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PlatformCapabilities.pdfUnavailableMessage)),
      );
    }
  }
}
