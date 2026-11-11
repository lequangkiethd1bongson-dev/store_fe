// Các mô hình dữ liệu cho:
// - Dashboard Quản lý thông tin Cửa hàng (Trang chủ & Tab Cửa hàng)
// - Quản lý Nhân viên (Chấm công theo cơ sở, Quản lý tài khoản nhân viên, Tạo tài khoản nhân viên)
// - Quản lý Thống kê (Lượng hàng tồn & lượng bán/xuất của các cơ sở Kho và Cửa hàng)

class BranchLocation {
  const BranchLocation({
    required this.id,
    required this.name,
    required this.type, // 'STORE' | 'WAREHOUSE'
    this.address = '',
    this.phone = '',
    this.managerId,
    this.managerName = '',
    this.staffCount = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String? managerId;
  final String managerName;
  final int staffCount;
  final bool isActive;

  bool get isStore => type.toUpperCase() == 'STORE';
  bool get isWarehouse => type.toUpperCase() == 'WAREHOUSE';

  factory BranchLocation.fromJson(
    Map<String, dynamic> json, {
    String defaultType = 'STORE',
  }) {
    return BranchLocation(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? defaultType).toString().toUpperCase(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      managerId: json['managerId']?.toString() ?? json['manager_id']?.toString(),
      managerName:
          (json['managerName'] ?? json['manager_name'] ?? '').toString(),
      staffCount:
          int.tryParse((json['staffCount'] ?? json['staff_count'] ?? 0).toString()) ?? 0,
      isActive: json['isActive'] == null
          ? (json['is_active'] == null ? true : json['is_active'] == true)
          : json['isActive'] == true,
    );
  }
}

class EmployeeRecord {
  const EmployeeRecord({
    required this.id,
    required this.code,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role, // 'admin' | 'store_manager' | 'sales' | 'kho_manager' | 'kho'
    required this.isActive,
    this.storeId,
    this.storeName = '',
    this.warehouseId,
    this.warehouseName = '',
    this.todayShift = 'SHIFT_1',
    this.isWorkingToday = true,
    this.workDays = 24,
    this.notifyShift = true,
    this.notifyEmail = true,
    this.createdAt,
  });

  final String id;
  final String code;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? storeId;
  final String storeName;
  final String? warehouseId;
  final String warehouseName;
  final String todayShift;
  final bool isWorkingToday;
  final int workDays;
  final bool notifyShift;
  final bool notifyEmail;
  final DateTime? createdAt;

  String get roleLabel => labelForRole(role);

  String get branchDisplay {
    if (role == 'admin') return 'Toàn hệ thống (Trụ sở chính SSM4)';
    if (storeName.isNotEmpty) return 'Cửa hàng: $storeName';
    if (warehouseName.isNotEmpty) return 'Kho: $warehouseName';
    if (role == 'store_manager' || role == 'sales') {
      return 'Chưa phân công Cửa hàng';
    }
    if (role == 'kho_manager' || role == 'kho') {
      return 'Chưa phân công Kho';
    }
    return 'Chưa phân công';
  }

  /// Tên cơ sở làm việc ngắn gọn dùng để gom nhóm theo từng cơ sở.
  String get facilityGroupName {
    if (role == 'admin') return 'Trụ sở Quản trị Hệ thống';
    if (storeName.isNotEmpty) return storeName;
    if (warehouseName.isNotEmpty) return warehouseName;
    if (isStoreRole) return 'Khối Cửa hàng (Chưa gán cơ sở)';
    if (isWarehouseRole) return 'Khối Kho hàng (Chưa gán cơ sở)';
    return 'Cơ sở chung SSM4';
  }

  bool get isStoreRole => role == 'store_manager' || role == 'sales';
  bool get isWarehouseRole => role == 'kho_manager' || role == 'kho';

  static String normalizeRole(String raw) {
    final clean = raw.trim().toLowerCase();
    switch (clean) {
      case 'admin':
        return 'admin';
      case 'store_manager':
      case 'storemanager':
        return 'store_manager';
      case 'sales':
      case 'sales_staff':
        return 'sales';
      case 'kho_manager':
      case 'warehouse_manager':
        return 'kho_manager';
      case 'kho':
      case 'warehouse_staff':
      case 'kho_staff':
        return 'kho';
      default:
        return 'sales';
    }
  }

  static String labelForRole(String raw) {
    switch (normalizeRole(raw)) {
      case 'admin':
        return 'Quản trị viên (Admin)';
      case 'store_manager':
        return 'Quản lý Cửa hàng';
      case 'sales':
        return 'Nhân viên Bán hàng';
      case 'kho_manager':
        return 'Quản lý Kho';
      case 'kho':
        return 'Nhân viên Kho';
      default:
        return 'Nhân viên';
    }
  }

  static String buildCode(String id, String role) {
    final norm = normalizeRole(role);
    final prefix = switch (norm) {
      'admin' => 'NV-ADM-',
      'store_manager' => 'NV-QLCH-',
      'sales' => 'NV-POS-',
      'kho_manager' => 'NV-QLK-',
      'kho' => 'NV-KHO-',
      _ => 'NV-',
    };
    final cleanId = id.replaceAll('-', '').toUpperCase();
    final suffix = cleanId.length >= 4 ? cleanId.substring(0, 4) : '1001';
    return '$prefix$suffix';
  }

  EmployeeRecord copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    String? storeId,
    String? storeName,
    String? warehouseId,
    String? warehouseName,
    String? todayShift,
    bool? isWorkingToday,
    int? workDays,
    bool? notifyShift,
    bool? notifyEmail,
  }) {
    final nextRole = role != null ? normalizeRole(role) : this.role;
    return EmployeeRecord(
      id: id,
      code: buildCode(id, nextRole),
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: nextRole,
      isActive: isActive ?? this.isActive,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      todayShift: todayShift ?? this.todayShift,
      isWorkingToday: isWorkingToday ?? this.isWorkingToday,
      workDays: workDays ?? this.workDays,
      notifyShift: notifyShift ?? this.notifyShift,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      createdAt: createdAt,
    );
  }

  factory EmployeeRecord.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['employeeId'] ?? '').toString();
    final role = normalizeRole((json['role'] ?? 'sales').toString());
    final code = (json['code'] ?? '').toString().trim();

    String storeName =
        (json['storeName'] ?? json['store_name'] ?? '').toString();
    if (storeName.isEmpty && json['stores'] is Map) {
      storeName = (json['stores']['name'] ?? '').toString();
    }

    String warehouseName =
        (json['warehouseName'] ?? json['warehouse_name'] ?? '').toString();
    if (warehouseName.isEmpty && json['warehouses'] is Map) {
      warehouseName = (json['warehouses']['name'] ?? '').toString();
    }

    final rawStoreId = json['storeId'] ?? json['store_id'];
    final rawWarehouseId = json['warehouseId'] ?? json['warehouse_id'];
    final isActive = json['isActive'] != null
        ? json['isActive'] == true
        : (json['is_active'] == null ? true : json['is_active'] == true);
    final todayShift =
        (json['todayShift'] ?? json['shiftCode'] ?? (isActive ? 'SHIFT_1' : 'OFF'))
            .toString()
            .toUpperCase();
    final isWorkingToday = json['isWorkingToday'] != null
        ? json['isWorkingToday'] == true
        : (json['isWorking'] != null
            ? json['isWorking'] == true
            : todayShift != 'OFF');

    return EmployeeRecord(
      id: id,
      code: code.isNotEmpty ? code : buildCode(id, role),
      fullName: (json['fullName'] ??
              json['full_name'] ??
              json['name'] ??
              'Chưa đặt tên')
          .toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: role,
      isActive: isActive,
      storeId: rawStoreId?.toString(),
      storeName: storeName,
      warehouseId: rawWarehouseId?.toString(),
      warehouseName: warehouseName,
      todayShift: todayShift,
      isWorkingToday: isWorkingToday,
      workDays:
          int.tryParse((json['workDays'] ?? json['work_days'] ?? 24).toString()) ??
              24,
      notifyShift: json['notifyShift'] != null
          ? json['notifyShift'] == true
          : (json['notify_shift'] == null
              ? true
              : json['notify_shift'] == true),
      notifyEmail: json['notifyEmail'] != null
          ? json['notifyEmail'] == true
          : (json['notify_email'] == null
              ? true
              : json['notify_email'] == true),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null),
    );
  }
}

class WorkShiftRecord {
  const WorkShiftRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.role,
    required this.workDate, // YYYY-MM-DD
    required this.shiftCode, // 'SHIFT_1' | 'SHIFT_2' | 'OFF'
    this.storeId,
    this.storeName = '',
    this.warehouseId,
    this.warehouseName = '',
    this.note = '',
  });

  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String role;
  final String workDate;
  final String shiftCode;
  final String? storeId;
  final String storeName;
  final String? warehouseId;
  final String warehouseName;
  final String note;

  bool get isWorking => shiftCode.toUpperCase() != 'OFF';

  factory WorkShiftRecord.fromJson(Map<String, dynamic> json) {
    final empId = (json['employeeId'] ?? json['employee_id'] ?? '').toString();
    final role =
        EmployeeRecord.normalizeRole((json['role'] ?? 'sales').toString());
    final rawDate = (json['workDate'] ?? json['work_date'] ?? '').toString();
    final datePart = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

    return WorkShiftRecord(
      id: (json['id'] ?? '$empId-$datePart').toString(),
      employeeId: empId,
      employeeCode:
          (json['employeeCode'] ?? EmployeeRecord.buildCode(empId, role))
              .toString(),
      employeeName:
          (json['employeeName'] ?? json['employee_name'] ?? '').toString(),
      role: role,
      workDate: datePart,
      shiftCode:
          (json['shiftCode'] ?? json['shift_code'] ?? 'SHIFT_1')
              .toString()
              .toUpperCase(),
      storeId: (json['storeId'] ?? json['store_id'])?.toString(),
      storeName: (json['storeName'] ?? json['store_name'] ?? '').toString(),
      warehouseId: (json['warehouseId'] ?? json['warehouse_id'])?.toString(),
      warehouseName:
          (json['warehouseName'] ?? json['warehouse_name'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

class TimesheetPayrollRecord {
  const TimesheetPayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.email,
    required this.phone,
    required this.role,
    required this.branchName,
    required this.monthYear,
    required this.workDays,
    required this.standardDays,
    required this.totalHours,
    required this.overtimeHours,
    required this.hourlyRate,
    required this.allowance,
    required this.deduction,
    required this.totalSalary,
    required this.status,
    this.note = '',
  });

  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String email;
  final String phone;
  final String role;
  final String branchName;
  final String monthYear;
  final int workDays;
  final int standardDays;
  final double totalHours;
  final double overtimeHours;
  final int hourlyRate;
  final int allowance;
  final int deduction;
  final int totalSalary;
  final String status;
  final String note;

  TimesheetPayrollRecord copyWith({
    int? workDays,
    int? standardDays,
    double? totalHours,
    double? overtimeHours,
    int? hourlyRate,
    int? allowance,
    int? deduction,
    int? totalSalary,
    String? status,
    String? note,
  }) {
    final nextHours = totalHours ?? this.totalHours;
    final nextOt = overtimeHours ?? this.overtimeHours;
    final nextRate = hourlyRate ?? this.hourlyRate;
    final nextAllow = allowance ?? this.allowance;
    final nextDed = deduction ?? this.deduction;
    final computedSalary = totalSalary ??
        ((nextHours * nextRate) +
                (nextOt * nextRate * 1.5) +
                nextAllow -
                nextDed)
            .round()
            .clamp(0, 999999999);

    return TimesheetPayrollRecord(
      id: id,
      employeeId: employeeId,
      employeeCode: employeeCode,
      employeeName: employeeName,
      email: email,
      phone: phone,
      role: role,
      branchName: branchName,
      monthYear: monthYear,
      workDays: workDays ?? this.workDays,
      standardDays: standardDays ?? this.standardDays,
      totalHours: nextHours,
      overtimeHours: nextOt,
      hourlyRate: nextRate,
      allowance: nextAllow,
      deduction: nextDed,
      totalSalary: computedSalary,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  factory TimesheetPayrollRecord.fromJson(Map<String, dynamic> json) {
    final empId = (json['employeeId'] ?? json['employee_id'] ?? '').toString();
    final role =
        EmployeeRecord.normalizeRole((json['role'] ?? 'sales').toString());
    final workDays =
        int.tryParse((json['workDays'] ?? json['work_days'] ?? 24).toString()) ??
            24;
    final standardDays = int.tryParse(
            (json['standardDays'] ?? json['standard_days'] ?? 26).toString()) ??
        26;
    final totalHours = double.tryParse(
            (json['totalHours'] ?? json['total_hours'] ?? (workDays * 8))
                .toString()) ??
        (workDays * 8.0);
    final overtimeHours = double.tryParse(
            (json['overtimeHours'] ?? json['overtime_hours'] ?? 0).toString()) ??
        0.0;
    final hourlyRate = double.tryParse(
                (json['hourlyRate'] ?? json['hourly_rate'] ?? 35000).toString())
            ?.round() ??
        35000;
    final allowance =
        double.tryParse((json['allowance'] ?? 500000).toString())?.round() ??
            500000;
    final deduction =
        double.tryParse((json['deduction'] ?? 0).toString())?.round() ?? 0;
    final rawTotal = double.tryParse(
                (json['totalSalary'] ?? json['total_salary'] ?? 0).toString())
            ?.round() ??
        0;
    final computedSalary = rawTotal > 0
        ? rawTotal
        : ((totalHours * hourlyRate) +
                (overtimeHours * hourlyRate * 1.5) +
                allowance -
                deduction)
            .round()
            .clamp(0, 999999999);

    return TimesheetPayrollRecord(
      id: (json['id'] ?? '$empId-${json['monthYear'] ?? json['month_year']}')
          .toString(),
      employeeId: empId,
      employeeCode:
          (json['employeeCode'] ?? EmployeeRecord.buildCode(empId, role))
              .toString(),
      employeeName: (json['employeeName'] ??
              json['employee_name'] ??
              'Nhân viên')
          .toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: role,
      branchName:
          (json['branchName'] ?? json['branch_name'] ?? 'Chi nhánh SSM4')
              .toString(),
      monthYear: (json['monthYear'] ?? json['month_year'] ?? '').toString(),
      workDays: workDays,
      standardDays: standardDays,
      totalHours: totalHours,
      overtimeHours: overtimeHours,
      hourlyRate: hourlyRate,
      allowance: allowance,
      deduction: deduction,
      totalSalary: computedSalary,
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      note: (json['note'] ?? '').toString(),
    );
  }
}

/// Thông tin Dashboard Quản lý Cửa hàng trên Trang chủ Admin & Tab Cửa hàng.
class StoreRevenueSummary {
  const StoreRevenueSummary({
    required this.storeId,
    required this.storeName,
    required this.address,
    required this.phone,
    required this.managerName,
    required this.staffCount,
    required this.workingTodayCount,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.monthlyTarget,
    required this.todayOrders,
    required this.monthOrders,
    required this.growthPercent,
    this.stockQuantity = 1500,
    this.lowStockCount = 3,
  });

  final String storeId;
  final String storeName;
  final String address;
  final String phone;
  final String managerName;
  final int staffCount;
  final int workingTodayCount;
  final int todayRevenue;
  final int weekRevenue;
  final int monthRevenue;
  final int monthlyTarget;
  final int todayOrders;
  final int monthOrders;
  final double growthPercent;
  final int stockQuantity;
  final int lowStockCount;

  double get targetProgress =>
      monthlyTarget <= 0 ? 0.0 : (monthRevenue / monthlyTarget).clamp(0.0, 1.0);
}

/// Thông tin thống kê Lượng hàng (tồn kho / tồn kệ) & Lượng bán / Xuất hàng
/// của từng Cơ sở Kho hàng hoặc Cửa hàng dành cho màn hình Quản lý Thống kê Admin.
class FacilityStatisticsRecord {
  const FacilityStatisticsRecord({
    required this.facilityId,
    required this.facilityName,
    required this.facilityType, // 'STORE' | 'WAREHOUSE'
    required this.address,
    required this.phone,
    required this.managerName,
    required this.staffCount,
    required this.stockQuantity,
    required this.maxCapacity,
    required this.skuCount,
    required this.lowStockCount,
    required this.inboundQuantity,
    required this.soldOrExportedQuantity,
    required this.orderOrExportCount,
    required this.revenueOrStockValue,
    required this.growthPercent,
    this.topProducts = const [],
  });

  final String facilityId;
  final String facilityName;
  final String facilityType;
  final String address;
  final String phone;
  final String managerName;
  final int staffCount;
  final int stockQuantity;
  final int maxCapacity;
  final int skuCount;
  final int lowStockCount;
  final int inboundQuantity;
  final int soldOrExportedQuantity;
  final int orderOrExportCount;
  final int revenueOrStockValue;
  final double growthPercent;
  final List<String> topProducts;

  bool get isStore => facilityType.toUpperCase() == 'STORE';
  bool get isWarehouse => facilityType.toUpperCase() == 'WAREHOUSE';

  double get capacityRatio =>
      maxCapacity <= 0 ? 0.5 : (stockQuantity / maxCapacity).clamp(0.0, 1.0);

  factory FacilityStatisticsRecord.fromJson(Map<String, dynamic> json) {
    final topRaw = json['topProducts'];
    final topList = topRaw is List
        ? topRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return FacilityStatisticsRecord(
      facilityId: (json['facilityId'] ?? json['id'] ?? '').toString(),
      facilityName: (json['facilityName'] ?? json['name'] ?? '').toString(),
      facilityType: (json['facilityType'] ?? json['type'] ?? 'STORE')
          .toString()
          .toUpperCase(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      managerName: (json['managerName'] ?? '').toString(),
      staffCount: int.tryParse((json['staffCount'] ?? 6).toString()) ?? 6,
      stockQuantity:
          int.tryParse((json['stockQuantity'] ?? 0).toString()) ?? 0,
      maxCapacity:
          int.tryParse((json['maxCapacity'] ?? 2000).toString()) ?? 2000,
      skuCount: int.tryParse((json['skuCount'] ?? 0).toString()) ?? 0,
      lowStockCount:
          int.tryParse((json['lowStockCount'] ?? 0).toString()) ?? 0,
      inboundQuantity:
          int.tryParse((json['inboundQuantity'] ?? 0).toString()) ?? 0,
      soldOrExportedQuantity:
          int.tryParse((json['soldOrExportedQuantity'] ?? 0).toString()) ?? 0,
      orderOrExportCount:
          int.tryParse((json['orderOrExportCount'] ?? 0).toString()) ?? 0,
      revenueOrStockValue:
          int.tryParse((json['revenueOrStockValue'] ?? 0).toString()) ?? 0,
      growthPercent:
          double.tryParse((json['growthPercent'] ?? 10.0).toString()) ?? 10.0,
      topProducts: topList,
    );
  }
}

