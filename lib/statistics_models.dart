import 'package:hive/hive.dart';

part 'statistics_models.g.dart';

@HiveType(typeId: 10)
class DayStatistics extends HiveObject {
  @HiveField(0)
  String dayName;
  
  @HiveField(1)
  DateTime date;
  
  @HiveField(2)
  Map<String, OrderStatistic> orders;
  
  @HiveField(3)
  double totalAmount;
  
  @HiveField(4)
  int totalQuantity;

  DayStatistics({
    required this.dayName,
    required this.date,
    required this.orders,
    this.totalAmount = 0.0,
    this.totalQuantity = 0,
  });

  // حساب الإجماليات تلقائياً
  void calculateTotals() {
    totalAmount = 0.0;
    totalQuantity = 0;
    
    for (var orderStat in orders.values) {
      totalAmount += orderStat.totalPrice;
      totalQuantity += orderStat.quantity;
    }
  }
}

@HiveType(typeId: 11)
class OrderStatistic extends HiveObject {
  @HiveField(0)
  String itemName;
  
  @HiveField(1)
  int quantity;
  
  @HiveField(2)
  double unitPrice;
  
  @HiveField(3)
  double totalPrice;
  
  @HiveField(4)
  DateTime firstOrderTime;
  
  @HiveField(5)
  DateTime lastOrderTime;

  OrderStatistic({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.firstOrderTime,
    required this.lastOrderTime,
  });

  // إضافة كمية جديدة
  void addQuantity(int additionalQuantity, double newUnitPrice) {
    quantity += additionalQuantity;
    unitPrice = newUnitPrice; // تحديث السعر للأحدث
    totalPrice = quantity * unitPrice;
    lastOrderTime = DateTime.now();
  }
}