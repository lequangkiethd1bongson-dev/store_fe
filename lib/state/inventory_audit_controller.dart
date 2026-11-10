import 'package:flutter/foundation.dart';
import '../models/inventory_audit_models.dart';
import '../models/product.dart';
import '../services/inventory_audit_service.dart';

class InventoryAuditController extends ChangeNotifier {
  final InventoryAuditService _service = InventoryAuditService();

  bool isLoading = false;
  List<InventoryBalanceItem> balanceReport = [];
  List<Product> reorderAlerts = [];
  List<StocktakeRecord> stocktakes = [];

  Future<void> loadAllData() async {
    isLoading = true;
    notifyListeners();

    try {
      balanceReport = await _service.getBalanceReport();
      reorderAlerts = await _service.getReorderAlerts();
      stocktakes = await _service.getStocktakes();
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addStocktake(StocktakeRecord record) async {
    final success = await _service.createStocktake(record);
    if (success) {
      await loadAllData();
    }
    return success;
  }
}
