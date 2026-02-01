import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'app_state.dart';


import 'package:intl/intl.dart';

Future<void> printOrderReceipt(
  List<OrderItem> orders, {
  String? title,
  String? tableName,
  String? orderName,
}) async {
  final pdf = pw.Document();
  // استخدام خط Noto Naskh Arabic الذي يدعم العربية والإنجليزية معاً بشكل مثالي
  final arabicFont = await PdfGoogleFonts.notoNaskhArabicMedium();
  final titleFont = await PdfGoogleFonts.notoNaskhArabicBold();
  final bodyFont = await PdfGoogleFonts.notoNaskhArabicRegular();
  final now = DateTime.now();
  final formattedDate = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(now);
  const hallName = 'BERLIN GAME';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, 150 * PdfPageFormat.mm),
      build: (context) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(hallName,
                style: pw.TextStyle(font: titleFont, fontSize: 20, letterSpacing: 2, color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 2),
            if (tableName != null && tableName.isNotEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text('الطاولة: $tableName',
                  style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  textAlign: pw.TextAlign.center),
              ),
            if (orderName != null && orderName.isNotEmpty)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text('الطلب: $orderName',
                  style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  textAlign: pw.TextAlign.center),
              ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text('التاريخ: $formattedDate',
                  style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.black)),
            ),
            if (title != null) ...[
              pw.SizedBox(height: 2),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(title, style: pw.TextStyle(font: arabicFont, fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black), textAlign: pw.TextAlign.center),
              ),
            ],
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(2), // المنتج
                1: const pw.FlexColumnWidth(1), // الكمية
                2: const pw.FlexColumnWidth(1.2), // السعر
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text('المنتج', style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text('الكمية', style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Text('السعر', style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
                ...orders.map((order) =>
                  order.name == 'ملاحظة'
                    ? pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              order.name,
                              style: pw.TextStyle(font: arabicFont, fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text('', style: pw.TextStyle(font: arabicFont, fontSize: 13), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              order.notes ?? '',
                              style: pw.TextStyle(font: arabicFont, fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              order.name,
                              style: pw.TextStyle(font: arabicFont, fontSize: 13, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(order.quantity.toString(), style: pw.TextStyle(font: arabicFont, fontSize: 13), textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text((order.price * order.quantity).toStringAsFixed(0), style: pw.TextStyle(font: arabicFont, fontSize: 13), textAlign: pw.TextAlign.center),
                          ),
                        ],
                      )
                ),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
                color: PdfColors.white,
              ),
              child: pw.Text(
                'الإجمالي:  ${((orders.fold(0.0, (double sum, o) => sum + (o.price * o.quantity)) / 250).round().toDouble() * 250).toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold, fontSize: 15),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
