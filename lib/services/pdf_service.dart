import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/message_model.dart';

class PdfService {
  Future<void> generateInterviewPdf({
    required List<MessageModel> messages,
    required String score,
    required String summary,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogoBytes();
    final logoImage =
        logoBytes == null ? null : pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(logoImage, height: 42),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Welp.Ai Interview Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Final score: $score/10'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(summary.isEmpty ? 'No summary available.' : summary),
          pw.SizedBox(height: 20),
          pw.Text(
            'Conversation',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...messages.map(
            (message) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#D6E6EC')),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    message.isUser ? 'You' : 'AI Interviewer',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: message.isUser
                          ? PdfColor.fromHex('#0C6E87')
                          : PdfColor.fromHex('#132A3A'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(message.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load('assets/images/welp_logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
