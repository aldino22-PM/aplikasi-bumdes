import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget pdfStatCard(String title, String value, PdfColor color) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    ),
  );
}
