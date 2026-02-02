import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'app_state.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final String deviceName;
  final AppState appState;

  const ReceiptPreviewScreen({
    super.key,
    required this.deviceName,
    required this.appState,
  });

  double _calculateNoteTotal(String note) {
    double total = 0.0;
    
    // البحث عن أنماط العمليات الحسابية مثل "1 * 2000" أو "3*4000"
    RegExp pattern = RegExp(r'(\d+)\s*\*\s*(\d+)');
    Iterable<RegExpMatch> matches = pattern.allMatches(note);
    
    for (RegExpMatch match in matches) {
      try {
        int quantity = int.parse(match.group(1) ?? '0');
        int price = int.parse(match.group(2) ?? '0');
        total += (quantity * price);
      } catch (e) {
        print('خطأ في تحليل العملية: ${match.group(0)}');
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(now);
    const hallName = 'BERLIN GAME';
    
    // Get device data
    final orders = appState.getOrders(deviceName);
    final elapsed = appState.getElapsedTime(deviceName);
    final mode = appState.getMode(deviceName);
    final customerCount = appState.getCustomerCount(deviceName);
    final price = appState.calculatePrice(deviceName, elapsed, mode);
    final note = appState.getNote(deviceName);

    String elapsedStr = '';
    final hours = elapsed.inHours;
    final minutes = (elapsed.inMinutes % 60);
    final seconds = (elapsed.inSeconds % 60);
    if (hours > 0) {
      elapsedStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      elapsedStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    String modeStr = mode == 'زوجي' ? 'زوجي' : (mode == 'فردي' ? 'فردي' : mode);

    // تحديد نوع الجهاز بناءً على اسم الجهاز
    String deviceTypeName;
    String deviceInfo;
    
    if (deviceName.toUpperCase().contains('PC')) {
      deviceTypeName = 'PC';
      deviceInfo = 'عدد الأشخاص: $customerCount | الوقت: $elapsedStr';
    } else if (deviceName.toUpperCase().contains('TABLE') || deviceName.contains('طاولة')) {
      deviceTypeName = 'طاولة';
      deviceInfo = 'عدد الأشخاص: $customerCount | الوقت: $elapsedStr';
    } else if (deviceName.toUpperCase().contains('PS') || deviceName.contains('بلايستيشن')) {
      deviceTypeName = 'بلايستيشن';
      deviceInfo = 'الوضع: $modeStr | الوقت: $elapsedStr';
    } else {
      deviceTypeName = 'جهاز';
      deviceInfo = 'الوضع: $modeStr | الوقت: $elapsedStr';
    }

    // إضافة منتج خاص بنوع الجهاز يحوي التفاصيل
    final List<OrderItem> allOrders = [
      OrderItem(
        name: deviceTypeName,
        price: price,
        quantity: 1,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
        notes: deviceInfo,
      ),
      ...orders
    ];
    
    // إضافة الملاحظة لجميع أنواع الأجهزة مع حساب المجموع
    if (note.isNotEmpty) {
      double noteTotal = _calculateNoteTotal(note);
      
      allOrders.add(OrderItem(
        name: 'ملاحظة',
        price: noteTotal,
        quantity: 1,
        firstOrderTime: DateTime.now(),
        lastOrderTime: DateTime.now(),
        notes: note,
      ));
    }
    
    // Calculate total (rounded to nearest 250)
    final rawTotal = allOrders.fold(0.0, (sum, o) => sum + (o.price * o.quantity));
    final roundedTotal = ((rawTotal / 250).round().toDouble() * 250);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('معاينة الفاتورة'),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 58 * 3.7795275591, // 58mm converted to logical pixels
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hall Name
                    Text(
                      hallName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Table Name
                    Text(
                      'الطاولة: $deviceName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Date
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'التاريخ: $formattedDate',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Title
                    const SizedBox(height: 8),
                    const Text(
                      'حساب الطاولة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const Divider(thickness: 2, color: Colors.black),
                    const SizedBox(height: 8),
                    
                    // Orders Table
                    Table(
                      border: TableBorder.all(color: Colors.black, width: 1),
                      columnWidths: const {
                        0: FlexColumnWidth(2),   // المنتج
                        1: FlexColumnWidth(1),   // الكمية
                        2: FlexColumnWidth(1.2), // السعر
                      },
                      children: [
                        // Header
                        TableRow(
                          decoration: const BoxDecoration(color: Colors.white),
                          children: [
                            _buildTableCell('المنتج', isHeader: true),
                            _buildTableCell('الكمية', isHeader: true),
                            _buildTableCell('السعر', isHeader: true),
                          ],
                        ),
                        // Orders
                        ...allOrders.map((order) {
                          if (order.name == 'ملاحظة') {
                            return TableRow(
                              children: [
                                _buildTableCell(order.name, isBold: true),
                                _buildTableCell(''),
                                _buildTableCell(order.notes ?? '', isBold: true),
                              ],
                            );
                          } else {
                            return TableRow(
                              children: [
                                _buildTableCell(order.name, isBold: true),
                                _buildTableCell(order.quantity.toString()),
                                _buildTableCell((order.price * order.quantity).toStringAsFixed(0)),
                              ],
                            );
                          }
                        }),
                      ],
                    ),
                    
                    const Divider(thickness: 1),
                    const SizedBox(height: 12),
                    
                    // Total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        color: Colors.grey[100],
                      ),
                      child: Text(
                        'الإجمالي:  ${roundedTotal.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pop(context),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.close, color: Colors.white),
          label: const Text(
            'إغلاق',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 14 : 15,
          fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

