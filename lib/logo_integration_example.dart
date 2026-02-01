// مثال بسيط لإضافة اللوغو في التطبيق الحالي
import 'package:flutter/material.dart';
import 'printer_service.dart';
import 'app_state.dart';

class LogoPrintExample {
  static final PrinterService _printerService = PrinterService();

  // مثال 1: طباعة مع لوغو من Assets
  static Future<void> printWithAssetsLogo(List<OrderItem> orders, String? tableName) async {
    // تحميل اللوغو من assets/logo.png (تأكد من إضافته في pubspec.yaml)
    final logo = await _printerService.loadLogoFromAssets('assets/logo.png');
    
    // طباعة الكاشير مع اللوغو
    await _printerService.printCashierBill(
      orders,
      tableName: tableName,
      logoImage: logo,
    );
  }

  // مثال 2: طباعة المطبخ مع لوغو
  static Future<void> printKitchenWithLogo(List<OrderItem> orders, String? tableName) async {
    final logo = await _printerService.loadLogoFromAssets('assets/logo.png');
    
    await _printerService.printKitchenOrder(
      orders,
      tableName: tableName,
      logoImage: logo,
    );
  }

  // مثال 3: الطباعة الذكية مع لوغو
  static Future<void> printSmartWithLogo(
    List<OrderItem> orders, 
    Map<String, String> categories,
    String? tableName,
  ) async {
    final logo = await _printerService.loadLogoFromAssets('assets/logo.png');
    
    await _printerService.printOrdersByCategory(
      orders,
      categories,
      tableName: tableName,
      logoImage: logo,
    );
  }

  // دالة لإضافة زر اللوغو في أي شاشة
  static Widget createLogoButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // إضافة شاشة إعدادات اللوغو
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LogoSettingsScreen()),
        );
      },
      icon: Icon(Icons.image),
      label: Text('إعدادات اللوغو'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// شاشة مبسطة لإعدادات اللوغو
class LogoSettingsScreen extends StatefulWidget {
  @override
  _LogoSettingsScreenState createState() => _LogoSettingsScreenState();
}

class _LogoSettingsScreenState extends State<LogoSettingsScreen> {
  bool _logoEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعدادات اللوغو'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('تفعيل اللوغو في الفواتير'),
                subtitle: Text('إظهار اللوغو في أعلى جميع الفواتير المطبوعة'),
                trailing: Switch(
                  value: _logoEnabled,
                  onChanged: (value) {
                    setState(() {
                      _logoEnabled = value;
                    });
                  },
                ),
              ),
            ),
            
            if (_logoEnabled) ...[
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'خطوات إضافة اللوغو:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. ضع صورة اللوغو في مجلد assets/',
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        '2. اسمها logo.png أو logo.jpg',
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        '3. فعل السطر في pubspec.yaml:',
                        textAlign: TextAlign.right,
                      ),
                      Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'assets:\n  - assets/logo.png',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      Text(
                        '4. أعد تشغيل التطبيق',
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Spacer(),
            
            // أزرار الاختبار
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPrint,
                    icon: Icon(Icons.print),
                    label: Text('اختبار طباعة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testPrint() async {
    // إنشاء طلب تجريبي
    final testOrders = [
      OrderItem(name: 'شاي أحمر', quantity: 1, price: 1000),
      OrderItem(name: 'قهوة تركية', quantity: 1, price: 1500),
    ];

    if (_logoEnabled) {
      await LogoPrintExample.printWithAssetsLogo(testOrders, 'طاولة تجريبية');
    } else {
      await PrinterService().printCashierBill(testOrders, tableName: 'طاولة تجريبية');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الطلب للطباعة!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}