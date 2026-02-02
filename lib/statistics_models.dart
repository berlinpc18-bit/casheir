// Server-only mode: Hive removed from statistics models

class DayStatistics {
  String dayName;
  DateTime date;
  Map<String, OrderStatistic> orders;
  double totalAmount;
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

class OrderStatistic {
  String itemName;
  int quantity;
  double unitPrice;
  double totalPrice;
  DateTime firstOrderTime;
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