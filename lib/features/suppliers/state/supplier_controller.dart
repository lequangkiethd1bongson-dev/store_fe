import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';

class SupplierController extends ChangeNotifier {
  SupplierController({SupplierService? supplierService})
    : _supplierService = supplierService ?? SupplierService(),
      _ownsService = supplierService == null;

  final SupplierService _supplierService;
  final bool _ownsService;

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  String _searchQuery = '';
  String _statusFilter = 'ALL';

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  Supplier? get selectedSupplier => _selectedSupplier;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  List<Supplier> get filteredSuppliers {
    return _suppliers.where((s) {
      if (_statusFilter == 'ACTIVE' && !s.isActive) return false;
      if (_statusFilter == 'INACTIVE' && s.isActive) return false;

      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;

      final nameMatch = s.name.toLowerCase().contains(q);
      final phoneMatch = s.phone != null && s.phone!.contains(q);
      final emailMatch = s.email != null && s.email!.toLowerCase().contains(q);

      return nameMatch || phoneMatch || emailMatch;
    }).toList();
  }

  @override
  void dispose() {
    if (_ownsService) {
      _supplierService.dispose();
    }
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  /// Lấy danh sách nhà cung cấp từ API theo chuẩn Backend.
  Future<void> fetchSuppliers({bool? activeOnly, int? page, int? size}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    bool? isActiveParam;
    if (activeOnly == true || _statusFilter == 'ACTIVE') {
      isActiveParam = true;
    } else if (_statusFilter == 'INACTIVE') {
      isActiveParam = false;
    } else {
      isActiveParam = null; // Tất cả -> Không truyền `isActive`
    }

    try {
      final list = await _supplierService.getSuppliers(
        isActive: isActiveParam,
        keyword: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        page: page,
        size: size,
      );
      _suppliers = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _parseError(e);
      notifyListeners();
    }
  }

  Future<void> fetchSupplierById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supplier = await _supplierService.getSupplierById(id);
      _selectedSupplier = supplier;

      final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (idx != -1) {
        _suppliers[idx] = supplier;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _parseError(e);
      notifyListeners();
    }
  }

  Future<Supplier?> createSupplier({
    required String name,
    required String phone,
    required String address,
    String? email,
    String? fax,
    bool isActive = true,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _supplierService.createSupplier(
        name: name,
        phone: phone,
        address: address,
        email: email,
        fax: fax,
        isActive: isActive,
      );

      _suppliers.insert(0, created);
      _selectedSupplier = created;
      _isSaving = false;
      notifyListeners();
      return created;
    } catch (e) {
      _isSaving = false;
      _error = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<Supplier?> updateSupplier({
    required String id,
    required String name,
    required String phone,
    required String address,
    String? email,
    String? fax,
    bool? isActive,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _supplierService.updateSupplier(
        id: id,
        name: name,
        phone: phone,
        address: address,
        email: email,
        fax: fax,
        isActive: isActive,
      );

      final idx = _suppliers.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _suppliers[idx] = updated;
      }
      if (_selectedSupplier?.id == id) {
        _selectedSupplier = updated;
      }
      _isSaving = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _isSaving = false;
      _error = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  /// Đổi trạng thái hoạt động / ngừng hoạt động.
  /// Truyền đầy đủ name, phone, address từ object NCC hiện tại để gửi payload hợp lệ lên Backend.
  Future<bool> toggleSupplierActive(String id, bool currentStatus) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    final targetStatus = !currentStatus;

    Supplier? supp;
    if (_selectedSupplier?.id == id) {
      supp = _selectedSupplier;
    } else {
      final idx = _suppliers.indexWhere((s) => s.id == id);
      if (idx != -1) supp = _suppliers[idx];
    }

    if (supp == null || supp.name.isEmpty) {
      try {
        supp = await _supplierService.getSupplierById(id);
      } catch (_) {}
    }

    try {
      final updated = await _supplierService.toggleSupplierStatus(
        id: id,
        isActive: targetStatus,
        name: supp?.name,
        phone: supp?.phone,
        address: supp?.address,
        email: supp?.email,
      );

      final idx = _suppliers.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _suppliers[idx] = updated;
      }
      if (_selectedSupplier?.id == id) {
        _selectedSupplier = updated;
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  String _parseError(Object e) {
    if (e is ApiException) {
      switch (e.statusCode) {
        case 400:
          return e.message.isNotEmpty
              ? e.message
              : 'Dữ liệu nhập không hợp lệ (400).';
        case 401:
          return 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại (401).';
        case 403:
          return 'Bạn không có quyền thực hiện thao tác này (403).';
        case 404:
          return 'Không tìm thấy nhà cung cấp (404).';
        case 409:
          return e.message.isNotEmpty
              ? e.message
              : 'Dữ liệu nhà cung cấp bị xung đột hoặc đã tồn tại (409).';
        case 500:
          return e.message.isNotEmpty
              ? e.message
              : 'Lỗi máy chủ (500). Vui lòng thử lại sau.';
        default:
          return e.message;
      }
    }
    return e.toString().replaceFirst('ApiException: ', '');
  }
}
