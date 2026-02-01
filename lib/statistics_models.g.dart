// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayStatisticsAdapter extends TypeAdapter<DayStatistics> {
  @override
  final int typeId = 10;

  @override
  DayStatistics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayStatistics(
      dayName: fields[0] as String,
      date: fields[1] as DateTime,
      orders: (fields[2] as Map).cast<String, OrderStatistic>(),
      totalAmount: fields[3] as double,
      totalQuantity: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DayStatistics obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dayName)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.orders)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.totalQuantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayStatisticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrderStatisticAdapter extends TypeAdapter<OrderStatistic> {
  @override
  final int typeId = 11;

  @override
  OrderStatistic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderStatistic(
      itemName: fields[0] as String,
      quantity: fields[1] as int,
      unitPrice: fields[2] as double,
      totalPrice: fields[3] as double,
      firstOrderTime: fields[4] as DateTime,
      lastOrderTime: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OrderStatistic obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.itemName)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unitPrice)
      ..writeByte(3)
      ..write(obj.totalPrice)
      ..writeByte(4)
      ..write(obj.firstOrderTime)
      ..writeByte(5)
      ..write(obj.lastOrderTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderStatisticAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
