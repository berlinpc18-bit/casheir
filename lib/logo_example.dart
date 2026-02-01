// مثال على كيفية استخدام اللوغو في الطباعة
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'printer_service.dart';
import 'app_state.dart';

class LogoExampleScreen extends StatefulWidget {
  @override
  _LogoExampleScreenState createState() => _LogoExampleScreenState();
}

class _LogoExampleScreenState extends State<LogoExampleScreen> {
  final PrinterService _printerService = PrinterService();
  String? _logoPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات اللوغو'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.image, size: 60, color: Colors.blue[800]),
                    SizedBox(height: 10),
                    Text(
                      'إضافة لوغو للفواتير',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'يمكنك إضافة لوغو خاص بك في أعلى جميع الفواتير المطبوعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // خيار 1: استخدام لوغو من Assets
            Card(
              child: ListTile(
                leading: Icon(Icons.folder, color: Colors.green),
                title: Text('استخدام لوغو من Assets'),
                subtitle: Text('ضع الصورة في مجلد assets/'),
                trailing: ElevatedButton(
                  onPressed: _useAssetsLogo,
                  child: Text('تجربة'),
                ),
              ),
            ),

            // خيار 2: اختيار ملف لوغو
            Card(
              child: ListTile(
                leading: Icon(Icons.upload_file, color: Colors.orange),
                title: Text('اختيار ملف لوغو'),
                subtitle: Text(_logoPath ?? 'لم يتم اختيار ملف'),
                trailing: ElevatedButton(
                  onPressed: _pickLogoFile,
                  child: Text('اختيار'),
                ),
              ),
            ),

            SizedBox(height: 30),

            // أزرار الاختبار
            Text(
              'اختبار الطباعة مع اللوغو:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testKitchenPrint,
                    icon: Icon(Icons.restaurant),
                    label: Text('طباعة مطبخ'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testCashierPrint,
                    icon: Icon(Icons.receipt),
                    label: Text('طباعة كاشير'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // استخدام لوغو من Assets (يجب إضافة الصورة في pubspec.yaml)
  void _useAssetsLogo() async {
    final logo = await _printerService.loadLogoFromAssets('assets/logo.png');
    if (logo != null) {
      _showSuccessMessage('تم تحميل اللوغو من Assets بنجاح!');
    } else {
      _showErrorMessage('فشل في تحميل اللوغو. تأكد من وجود الملف في assets/logo.png');
    }
  }

  // اختيار ملف لوغو من الجهاز
  void _pickLogoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _logoPath = result.files.single.path;
      });
      _showSuccessMessage('تم اختيار الملف بنجاح!');
    }
  }

  // اختبار طباعة المطبخ مع لوغو
  void _testKitchenPrint() async {
    final logo = await _getSelectedLogo();
    final testOrders = [
      OrderItem(name: 'شاي أحمر', quantity: 2, price: 1000),
      OrderItem(name: 'قهوة تركية', quantity: 1, price: 1500),
    ];

    await _printerService.printKitchenOrder(
      testOrders,
      tableName: 'طاولة 1',
      logoImage: logo,
    );

    _showSuccessMessage('تم إرسال طلب الطباعة للمطبخ!');
  }

  // اختبار طباعة الكاشير مع لوغو
  void _testCashierPrint() async {
    final logo = await _getSelectedLogo();
    final testOrders = [
      OrderItem(name: 'شاي أحمر', quantity: 2, price: 1000),
      OrderItem(name: 'قهوة تركية', quantity: 1, price: 1500),
      OrderItem(name: 'كعك', quantity: 1, price: 2000),
    ];

    await _printerService.printCashierBill(
      testOrders,
      tableName: 'طاولة 1',
      title: 'فاتورة اختبار',
      logoImage: logo,
    );

    _showSuccessMessage('تم إرسال فاتورة الكاشير للطباعة!');
  }

  // الحصول على اللوغو المختار
  Future<pw.ImageProvider?> _getSelectedLogo() async {
    if (_logoPath != null) {
      // استخدام الملف المختار
      try {
        final bytes = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png', 'jpeg'],
        );
        if (bytes != null && bytes.files.first.bytes != null) {
          return await _printerService.loadLogoFromFile(bytes.files.first.bytes!);
        }
      } catch (e) {
        print('خطأ في تحميل الملف المختار');
      }
    }
    
    // محاولة استخدام لوغو من Assets
    return await _printerService.loadLogoFromAssets('assets/logo.png');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}