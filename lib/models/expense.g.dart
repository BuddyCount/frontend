// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 2;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      currency: fields[3] as String,
      paidBy: fields[4] as String,
      splitBetween: (fields[5] as List).cast<String>(),
      date: fields[6] as DateTime,
      groupId: fields[7] as String,
      category: fields[8] as String?,
      exchangeRate: fields[9] as double?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      version: fields[12] as int?,
      customShares: (fields[13] as Map?)?.cast<String, double>(),
      customPaidBy: (fields[14] as Map?)?.cast<String, double>(),
      images: (fields[15] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.paidBy)
      ..writeByte(5)
      ..write(obj.splitBetween)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.groupId)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.exchangeRate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.version)
      ..writeByte(13)
      ..write(obj.customShares)
      ..writeByte(14)
      ..write(obj.customPaidBy)
      ..writeByte(15)
      ..write(obj.images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
