class InventoryBalanceItem {
  final int productId;
  final String productName;
  final int openingStock;
  final int imported;
  final int exported;
  final int closingStock;

  InventoryBalanceItem({
    required this.productId,
    required this.productName,
    required this.openingStock,
    required this.imported,
    required this.exported,
    required this.closingStock,
  });

  factory InventoryBalanceItem.fromJson(Map<String, dynamic> json) {
    return InventoryBalanceItem(
      productId: json['productId'] is int ? json['productId'] : int.tryParse(json['productId'].toString()) ?? 0,
      productName: json['productName']?.toString() ?? '',
      openingStock: json['openingStock'] is int ? json['openingStock'] : int.tryParse(json['openingStock'].toString()) ?? 0,
      imported: json['imported'] is int ? json['imported'] : int.tryParse(json['imported'].toString()) ?? 0,
      exported: json['exported'] is int ? json['exported'] : int.tryParse(json['exported'].toString()) ?? 0,
      closingStock: json['closingStock'] is int ? json['closingStock'] : int.tryParse(json['closingStock'].toString()) ?? 0,
    );
  }
}

class StocktakeRecord {
  final int? id;
  final int productId;
  final String productName;
  final int systemQuantity;
  final int actualQuantity;
  final int differenceQuantity;
  final String? note;
  final String? createdBy;

  StocktakeRecord({
    this.id,
    required this.productId,
    required this.productName,
    required this.systemQuantity,
    required this.actualQuantity,
    required this.differenceQuantity,
    this.note,
    this.createdBy,
  });

  factory StocktakeRecord.fromJson(Map<String, dynamic> json) {
    return StocktakeRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['productId'] is int ? json['productId'] : int.tryParse(json['productId'].toString()) ?? 0,
      productName: json['productName']?.toString() ?? '',
      systemQuantity: json['systemQuantity'] is int ? json['systemQuantity'] : int.tryParse(json['systemQuantity'].toString()) ?? 0,
      actualQuantity: json['actualQuantity'] is int ? json['actualQuantity'] : int.tryParse(json['actualQuantity'].toString()) ?? 0,
      differenceQuantity: json['differenceQuantity'] is int ? json['differenceQuantity'] : int.tryParse(json['differenceQuantity'].toString()) ?? 0,
      note: json['note']?.toString(),
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'systemQuantity': systemQuantity,
      'actualQuantity': actualQuantity,
      'note': note,
      'createdBy': createdBy,
    };
  }
}
