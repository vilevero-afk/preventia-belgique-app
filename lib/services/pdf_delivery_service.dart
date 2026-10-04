import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../utils/platform_capabilities.dart';
import 'file_export_service.dart';
import 'preventia_document_storage_service.dart';

class PdfDeliveryService {
  const PdfDeliveryService._();

  static Future<PreventiaSavedDocument?> exportPdf({
    required BuildContext context,
    required String name,
    required FutureOr<Uint8List> Function(PdfPageFormat format) onLayout,
    ProjectExportDetails? projectDetails,
    bool showResultMessage = true,
  }) async {
    try {
      if (FileExportService.usesSaveDialog) {
        final bytes = await onLayout(PdfPageFormat.a4);
        if (!context.mounted) {
          return null;
        }
        return FileExportService.savePdfBytes(
          bytes: bytes,
          suggestedFileName: name,
          context: context,
          projectDetails: projectDetails,
          showResultMessage: showResultMessage,
        );
      }

      await Printing.layoutPdf(
        name: FileExportService.cleanPdfFileName(name),
        onLayout: onLayout,
      );
      return null;
    } catch (_) {
      if (!context.mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PlatformCapabilities.pdfUnavailableMessage)),
      );
      return null;
    }
  }
}
